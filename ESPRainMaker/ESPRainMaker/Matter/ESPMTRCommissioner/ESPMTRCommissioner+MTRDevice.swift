// Copyright 2023 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  ESPMTRCommissioner+MTRDevice.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter


// Matter Device Info Models
struct MatterDeviceInfo {
    struct Endpoint {
        let id: UInt16
        let servers: [Cluster]
        let clients: [Cluster]
    }
    
    struct Cluster {
        let id: UInt32
        let name: String
        let attributes: [Attribute]
        let events: [Event]
    }
    
    struct Attribute {
        let id: UInt32
        let name: String
        let value: Any
    }
    
    struct Event {
        let id: UInt32
        let name: String
    }
    
    let endpoints: [Endpoint]
}


@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Read all the important data from the matter device
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion handler
    func readAttribute(groupId: String, deviceId: UInt64, completion: @escaping ([[String : Any]]?) -> Void) {
        if let controller = sController {
            if let device = try? controller.getDeviceBeingCommissioned(deviceId) {
                device.readAttributes(withEndpointID: nil,
                                            clusterID: nil,
                                            attributeID: nil,
                                            params: nil,
                                            queue: self.matterQueue) { paths, _ in
                    completion(paths)
                }
            } else {
                controller.getBaseDevice(deviceId, queue: self.matterQueue) { device, _ in
                    if let device = device {
                        device.readAttributes(withEndpointID: nil,
                                                    clusterID: nil,
                                                    attributeID: nil,
                                                    params: nil,
                                                    queue: self.matterQueue) { paths, _ in
                            completion(paths)
                        }
                    }
                }
            }
        } else {
            completion(nil)
        }
    }
    
    /// Parse matter device info
    /// - Parameter result: result
    /// - Returns: MatterDeviceInfo object
    static func parseDeviceInfo(from result: [[String: Any]]) -> MatterDeviceInfo {
        var endpointMap: [UInt16: (servers: [MatterDeviceInfo.Cluster], clients: [MatterDeviceInfo.Cluster])] = [:]
        
        for item in result {
            guard let attributePath = item["attributePath"] as? MTRAttributePath,
                  let data = item["data"] as? [String: Any] else {
                continue
            }
            
            let endpoint = UInt16(attributePath.endpoint.uint32Value)
            let clusterId = attributePath.cluster.uint32Value
            let attributeId = attributePath.attribute.uint32Value
            
            // Initialize endpoint if not exists
            if endpointMap[endpoint] == nil {
                endpointMap[endpoint] = (servers: [], clients: [])
            }
            
            // Handle Descriptor cluster data (0x1d)
            if clusterId == 0x1d {
                switch attributeId {
                case 0x1: // ServerList
                    if let serverData = data["value"] as? [[String: Any]] {
                        let servers = serverData.compactMap { serverDict -> UInt32? in
                            if let serverInfo = serverDict["data"] as? [String: Any],
                               let value = serverInfo["value"] as? NSNumber {
                                return UInt32(value.uint32Value)
                            }
                            return nil
                        }
                        
                        // Create empty clusters for servers
                        endpointMap[endpoint]?.servers = servers.map { serverId in
                            MatterDeviceInfo.Cluster(id: serverId,
                                                   name: "Cluster 0x\(String(format: "%x", serverId))",
                                                   attributes: [],
                                                   events: [])
                        }
                    }
                    
                case 0x2: // ClientList
                    if let clientData = data["value"] as? [[String: Any]] {
                        let clients = clientData.compactMap { clientDict -> UInt32? in
                            if let clientInfo = clientDict["data"] as? [String: Any],
                               let value = clientInfo["value"] as? NSNumber {
                                return UInt32(value.uint32Value)
                            }
                            return nil
                        }
                        
                        // Create empty clusters for clients
                        endpointMap[endpoint]?.clients = clients.map { clientId in
                            MatterDeviceInfo.Cluster(id: clientId,
                                                   name: "Cluster 0x\(String(format: "%x", clientId))",
                                                   attributes: [],
                                                   events: [])
                        }
                    }
                default:
                    break
                }
            } else {
                // Handle attribute data for other clusters
                // Find the cluster in servers or clients and add the attribute
                let attribute = MatterDeviceInfo.Attribute(
                    id: attributeId,
                    name: "Attribute 0x\(String(format: "%x", attributeId))",
                    value: data["value"] ?? "Unknown"
                )
                
                // Add attribute to appropriate cluster
                if var servers = endpointMap[endpoint]?.servers {
                    if let index = servers.firstIndex(where: { $0.id == clusterId }) {
                        var cluster = servers[index]
                        var attributes = cluster.attributes
                        attributes.append(attribute)
                        cluster = MatterDeviceInfo.Cluster(id: cluster.id,
                                                         name: cluster.name,
                                                         attributes: attributes,
                                                         events: cluster.events)
                        servers[index] = cluster
                        endpointMap[endpoint]?.servers = servers
                    }
                }
            }
        }
        
        // Convert the map to array of endpoints
        let endpoints = endpointMap.map { (endpointId, clusterInfo) in
            MatterDeviceInfo.Endpoint(id: endpointId,
                                    servers: clusterInfo.servers,
                                    clients: clusterInfo.clients)
        }.sorted { $0.id < $1.id }
        
        return MatterDeviceInfo(endpoints: endpoints)
    }
    
    /// Convert MatterDeviceInfo to JSON format with endpoints organized by clusters
    /// - Parameter deviceInfo: MatterDeviceInfo object
    /// - Returns: Dictionary representation in the specified format
    static func convertToJSONFormat(from deviceInfo: MatterDeviceInfo) -> [String: Any] {
        var endpointsDict: [String: Any] = [:]
        
        for endpoint in deviceInfo.endpoints {
            let endpointKey = String(format: "0x%x", endpoint.id)
            var clustersDict: [String: Any] = [:]
            
            // Process servers
            if !endpoint.servers.isEmpty {
                var serversDict: [String: Any] = [:]
                for server in endpoint.servers {
                    let clusterKey = String(format: "0x%x", server.id)
                    let attributeIds = server.attributes.map { String(format: "0x%x", $0.id) }
                    serversDict[clusterKey] = ["attributes": attributeIds]
                }
                clustersDict["servers"] = serversDict
            }
            
            // Process clients
            if !endpoint.clients.isEmpty {
                var clientsDict: [String: Any] = [:]
                for client in endpoint.clients {
                    let clusterKey = String(format: "0x%x", client.id)
                    let attributeIds = client.attributes.map { String(format: "0x%x", $0.id) }
                    clientsDict[clusterKey] = ["attributes": attributeIds]
                }
                clustersDict["clients"] = clientsDict
            }
            
            endpointsDict[endpointKey] = ["clusters": clustersDict]
        }
        
        return ["endpoints": endpointsDict]
    }
}
#endif
