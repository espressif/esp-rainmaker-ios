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
//  ESPNodeGroupMetadataService.swift
//  ESPRainmaker
//

import Foundation
import Alamofire

class ESPNodeGroupMetadataService {
    
    let apiWorker = ESPAPIWorker()
    let sessionWorker = ESPExtendUserSessionWorker()
    let url = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes"
    let groupURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/node_group"
    var switchIndex: Int?
    let fabricDetails = ESPMatterFabricDetails.shared
    
    init(switchIndex: Int? = nil) {
        self.switchIndex = switchIndex
    }
    
    /// Bind device
    /// - Parameters:
    ///   - node: source node
    ///   - destinationNodeId: destination node id
    ///   - completion: completion
    func bindDevice(node: Node, cluster: String, destinationNodeId: String, completion: @escaping (Bool) -> Void) {
        if let groupId = node.groupId, let clusterId = cluster.clusterId {
            self.appendDeviceGroupMetadata(groupId: groupId, clusterId: clusterId, node: node, destinationNodeId: destinationNodeId, completion: completion)
        } else {
            completion(false)
        }
    }
    
    /// Unbind device
    /// - Parameters:
    ///   - node: source node
    ///   - destinationNodeId: detination node id
    ///   - completion: completion
    func unbindDevice(node: Node, cluster: String, destinationNodeId: String, completion: @escaping (Bool) -> Void) {
        if let groupId = node.groupId, let clusterId = cluster.clusterId {
            self.removeDeviceGroupMetadata(groupId: groupId, clusterId: clusterId, node: node, destinationNodeId: destinationNodeId, completion: completion)
        } else {
            completion(false)
        }
    }
    
    //MARK: Update node group metadata (binding data)
    
    /// Get binding string from list of node ids
    /// - Parameter ids: ids
    /// - Returns: bidning string
    func getBindingValue(ids: [String]) -> String {
        var finalStr = ""
        for index in 0..<ids.count {
            if index == ids.count - 1 {
                finalStr+="\(ids[index])"
            } else {
                finalStr+="\(ids[index]),"
            }
        }
        return finalStr
    }
    
    /// Add device binding to group metadaga
    /// - Parameters:
    ///   - groupId: grouip id
    ///   - node: node
    ///   - destinationNodeId: destination node id
    ///   - cluster: cluster id
    ///   - completion: completion
    func appendDeviceGroupMetadata(groupId: String, clusterId: UInt, node: Node, destinationNodeId: String, completion: @escaping (Bool) -> Void) {
        var metadata = [String: Any]()
        if let savedMetadata = self.fabricDetails.getGroupBindingMetadata(groupId: groupId) {
            metadata = savedMetadata
        }
        if let sourceNodeId = node.node_id {
            if let bindingEndpoint = node.getBindingEndpoint(switchIndex: self.switchIndex) {
                if metadata.count > 0 {
                    if var endpointsData = metadata[sourceNodeId] as? [String: Any] {
                        if var clusterData = endpointsData["\(bindingEndpoint)"] as? [String: Any] {
                            if var destinations = clusterData["\(clusterId)"] as? [String], destinations.count > 0 {
                                if !destinations.contains(destinationNodeId) {
                                    destinations.append(destinationNodeId)
                                    clusterData["\(clusterId)"] = destinations
                                    endpointsData["\(bindingEndpoint)"] = clusterData
                                    metadata[sourceNodeId] = endpointsData
                                }
                            } else {
                                clusterData["\(clusterId)"] = [destinationNodeId]
                                endpointsData["\(bindingEndpoint)"] = clusterData
                                metadata[sourceNodeId] = endpointsData
                            }
                        } else {
                            endpointsData["\(bindingEndpoint)"] = ["\(clusterId)" : [destinationNodeId]]
                            metadata[sourceNodeId] = endpointsData
                        }
                    } else {
                        metadata[sourceNodeId] = ["\(bindingEndpoint)": ["\(clusterId)" : [destinationNodeId]]]
                    }
                } else {
                    metadata = [sourceNodeId: ["\(bindingEndpoint)": ["\(clusterId)" : [destinationNodeId]]]]
                }
            }
        }
        self.updateGroupMetadata(groupId: groupId, groupMetadata: metadata) { result, finalPayload  in
            if result {
                if metadata.isEmpty {
                    self.fabricDetails.removeGroupMetadata(groupId: groupId)
                } else if let finalPayload = finalPayload {
                    self.fabricDetails.saveGroupMetadata(groupId: groupId, groupMetadata: finalPayload)
                }
            }
            completion(result)
        }
    }
    
    /// Remove device group metadata
    /// - Parameters:
    ///   - groupId: group id
    ///   - cluster: cluster
    ///   - node: source node
    ///   - destinationNodeId: destionation node id
    ///   - completion: completion
    func removeDeviceGroupMetadata(groupId: String, clusterId: UInt, node: Node, destinationNodeId: String, completion: @escaping (Bool) -> Void) {
        var metadata = [String: Any]()
        if let savedMetadata = self.fabricDetails.getGroupBindingMetadata(groupId: groupId) {
            metadata = savedMetadata
        }
        if let sourceNodeId = node.node_id {
            if let bindingEndpoint = node.getBindingEndpoint(switchIndex: self.switchIndex) {
                if metadata.count > 0 {
                    if var endpointsData = metadata[sourceNodeId] as? [String: Any] {
                        if var clusterData = endpointsData["\(bindingEndpoint)"] as? [String: Any] {
                            if var destinations = clusterData["\(clusterId)"] as? [String], destinations.count > 0 {
                                destinations = destinations.filter {
                                    return $0 != destinationNodeId
                                }
                                clusterData["\(clusterId)"] = destinations
                                endpointsData["\(bindingEndpoint)"] = clusterData
                                metadata[sourceNodeId] = endpointsData
                            }
                        }
                    }
                }
            }
        }
        self.updateGroupMetadata(groupId: groupId, groupMetadata: metadata) { result, finalPayload  in
            if result {
                if metadata.isEmpty {
                    self.fabricDetails.removeGroupMetadata(groupId: groupId)
                } else if let finalPayload = finalPayload {
                    self.fabricDetails.saveGroupMetadata(groupId: groupId, groupMetadata: finalPayload)
                }
            }
            completion(result)
        }
    }
    
    /// Remove source node from group metadata
    /// - Parameters:
    ///   - groupId: groupId
    ///   - node: node to be removed
    ///   - completion: completion
    func removeSourceNodeFromGroupMetadata(groupId: String, node: Node, completion: @escaping (Bool) -> Void) {
        if let sourceNodeId = node.node_id, var metadata = self.fabricDetails.getGroupBindingMetadata(groupId: groupId) {
            if let _ = metadata[sourceNodeId] {
                metadata[sourceNodeId] = nil
            }
            self.updateMetadata(groupId: groupId, groupMetadata: metadata, completion: completion)
        } else {
            completion(false)
        }
    }
    
    /// Remove destination node from groups metadata
    /// - Parameters:
    ///   - groupId: group id
    ///   - destinationNodeId: destination node id
    ///   - completion: completion
    func removeDestinationNodeFromGroupMetadata(groupId: String, destinationNodeId: String, completion: @escaping (Bool) -> Void) {
        if var metadata = self.fabricDetails.getGroupBindingMetadata(groupId: groupId) {
            for key in metadata.keys {
                if let val = metadata[key] as? String {
                    let fields = val.components(separatedBy: ",")
                    let finalList = fields.filter {
                        return !$0.contains(destinationNodeId)
                    }
                    if finalList.count > 0 {
                        let str = self.getBindingValue(ids: finalList)
                        metadata[key] = str
                    } else {
                        metadata[key] = nil
                    }
                }
            }
            self.updateMetadata(groupId: groupId, groupMetadata: metadata, completion: completion)
        } else {
            completion(false)
        }
    }
    
    /// Make API call to update metadata on cloud
    /// - Parameters:
    ///   - groupId: group id
    ///   - groupMetadata: group metadata
    ///   - completion: completion
    func updateMetadata(groupId: String, groupMetadata: [String: Any], completion: @escaping (Bool) -> Void) {
        self.updateGroupMetadata(groupId: groupId, groupMetadata: groupMetadata) { result, finalPayload in
            if result {
                if groupMetadata.isEmpty {
                    self.fabricDetails.removeGroupMetadata(groupId: groupId)
                } else if let finalPayload = finalPayload {
                    self.fabricDetails.saveGroupMetadata(groupId: groupId, groupMetadata: finalPayload)
                }
            }
            completion(result)
        }
    }
    
    /// Update group metadata
    /// - Parameters:
    ///   - groupId: group id
    ///   - groupMetadata: group metadata
    ///   - completion: completion
    func updateGroupMetadata(groupId: String, groupMetadata: [String: Any], completion: @escaping (Bool, [String: Any]?) -> Void) {
        if let group = self.fabricDetails.getGroupData(groupId: groupId), let groupName = group.groupName {
            let sessionWorker = ESPExtendUserSessionWorker()
            sessionWorker.checkUserSession { token, _ in
                if let token = token {
                    let updateURL = self.groupURL + "?group_id=\(groupId)"
                    let headers: HTTPHeaders = [ESPMatterConstants.contentType: ESPMatterConstants.applicationJSON,
                                                ESPMatterConstants.authorization: token]
                    var finalParams: [String: Any] = [ESPMatterConstants.bindings: groupMetadata]
                    var finalPayload = [String: Any]()
                    if var final = ESPMatterFabricDetails.shared.getGroupMetadata(groupId: groupId) {
                        final[ESPMatterConstants.bindings] = groupMetadata
                        finalPayload = [ESPMatterConstants.groupName: groupName,
                                        ESPMatterConstants.groupMetadata: final as Any]
                        finalParams = final
                    } else {
                        finalPayload = [ESPMatterConstants.groupName: groupName,
                                        ESPMatterConstants.groupMetadata: finalParams as Any]
                    }
                    self.apiWorker.callDataAPI(url: updateURL, method: .put, parameters: finalPayload, headers: headers, apiDescription: "Update Group Metadata") { data, _ in
                        guard let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = json[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success else {
                            completion(false, nil)
                            return
                        }
                        completion(true, finalParams)
                    }
                } else {
                    completion(false, nil)
                }
            }
        }
    }
}
