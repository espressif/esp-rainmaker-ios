// Copyright 2024 Espressif Systems
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
//  MatterControllerParser.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation

class ESPControllerAPIKeys {
    
    static let matterController = "matter-controller"
    static let matterControllerDataVersion = "matter-controller-data-version"
    static let matterControllerData = "matter-controller-data"
    static let data = "data"
    static let enabled = "enabled"
    static let reachable = "reachable"
    static let matterNodes = "matter-nodes"
    static let matterNodeId = "matter-node-id"
    static let endpoints = "endpoints"
    static let endpointId = "endpoint-id"
    static let clusters = "clusters"
    static let clusterId = "cluster-id"
    static let commands = "commands"
    static let commandId = "command-id"
    
    static let onOffClusterId = "0x6"
    static let offCommandId = "0x0"
    static let onCommandId = "0x1"
    static let toggleCommandId = "0x2"
    static let onOffAttributeId = "0x0"
    static let levelControlClusterId = "0x8"
    static let colorControlClusterId =  "0x300"
    static let moveToLevelWithOnOffCommandId = "0x0"
    static let brightnessLevelAttributeId = "0x0"
    static let moveToSaturationCommandId = "0x3"
    static let moveToHueCommandId = "0x0"
    static let currentHueAttributeId = "0x0"
    static let currentSaturationAttributeId = "0x1"
    static let thermostatClusterId = "0x201"
    static let localTemperatureAttributeId = "0x0"
    static let systemModeAttributeId = "0x1c"
    static let occupiedCoolingSetpointAttributeId = "0x11"
    static let occupiedHeatingSetpointAttributeId = "0x12"
    static let temperatureMeasurementClusterId = "0x402"
    static let measuredTemperatureAttributeId = "0x0"
}


@available(iOS 16.4, *)
class MatterControllerParser {
    
    static let shared = MatterControllerParser()
    
    /// Parse matter controller data
    /// - Parameter matterControllerData: matter controller data
    /// - Returns: matter controller object
    func parseMatterControllerData(node: Node, matterControllerData: [String: Any]) -> MatterController? {
        if let matterController = matterControllerData[node.controllerServiceName] as? [String: Any] {
            var controllerData = MatterController()
            if let dataVersion = matterController[node.matterControllerDataVersion] as? String, let data = matterController[node.matterDevicesParamName] as? [String: Any] {
                controllerData.matterControllerDataVersion = dataVersion
                var matterControllerData = MatterControllerData()
                matterControllerData.matterNodesData = [String: MatterNodeData]()
                for nodeId in data.keys {
                    var matterNodeData = MatterNodeData()
                    matterNodeData.endpointsData = [String: MatterEndpointsData]()
                    if let nodeData = data[nodeId] as? [String: Any] {
                        if let enabled = nodeData[ESPControllerAPIKeys.enabled] as? Bool {
                            matterNodeData.enabled = enabled
                        }
                        if let reachable = nodeData[ESPControllerAPIKeys.reachable] as? Bool {
                            matterNodeData.reachable = reachable
                        }
                        var endpointsData = MatterEndpointsData()
                        if let endpoints = nodeData[ESPControllerAPIKeys.endpoints] as? [String: Any] {
                            endpointsData.endpoints = [MatterEndpointData]()
                            var endpointData = MatterEndpointData()
                            for endpoint in endpoints.keys {
                                if let clustersData = endpoints[endpoint] as? [String: Any] {
                                    if let clusters = clustersData[ESPControllerAPIKeys.clusters] as? [String: Any] {
                                        endpointData.clusters = [MatterClusterData]()
                                        for cluster in clusters.keys {
                                            var clusterData = MatterClusterData()
                                            if let attributes = clusters[cluster] as? [String: String] {
                                                var attributesData = MatterAttributeData()
                                                attributesData.attributes = attributes
                                                clusterData.cluster = [cluster: attributesData]
                                                endpointData.clusters?.append(clusterData)
                                            }
                                        }
                                        endpointsData.endpoints?.append(endpointData)
                                    }
                                }
                                matterNodeData.endpointsData?[endpoint] = endpointsData
                            }
                        }
                    }
                    matterControllerData.matterNodesData?[nodeId] = matterNodeData
                }
                controllerData.matterControllerData = matterControllerData
            }
            return controllerData
        }
        return nil
    }
    
    /// Save matter controller data
    /// - Parameters:
    ///   - matterControllerData: matter controller data
    ///   - nodeId: node id
    func saveMatterControllerData(matterControllerData: [String: Any], nodeId: String) {
        let key = "matter.controller.data.\(nodeId)"
        if let data = try? JSONSerialization.data(withJSONObject: matterControllerData) {
            UserDefaults.standard.setValue(data, forKey: key)
        }
    }
    
    /// Fetch matter controller data
    /// - Parameter nodeId: node id
    /// - Returns: matter controller data
    func fetchMatterControllerData(nodeId: String) -> MatterController? {
        if let node = User.shared.getNode(id: nodeId) {
            let key = "matter.controller.data.\(nodeId)"
            let decoder = JSONDecoder()
            if let data = UserDefaults.standard.value(forKey: key) as? Data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let controllerData = MatterControllerParser.shared.parseMatterControllerData(node: node, matterControllerData: json) as? MatterController {
                return controllerData
            }
        }
        return nil
    }
    
    /// Get on off cluster endpoint id
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    func getOnOffEndpointId(controllerNodeId: String, matterNodeId: String) -> String? {
        if let endpointId = self.getMatterEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId, clusterId: ESPControllerAPIKeys.onOffClusterId) {
            return endpointId
        }
        return nil
    }
    
    /// Get on off cluster value
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    /// - Returns: on/off status
    func getOnOffValue(controllerNodeId: String, matterNodeId: String) -> Bool? {
        if let endpointsData = self.getMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
            if let eId = self.getOnOffEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId), let endpoints = self.getMatterEndpoints(endpointsData: endpointsData, endpointId: eId) {
                for endpoint in endpoints {
                    if let clusters = endpoint.clusters {
                        for clusterData in clusters {
                            if let cluster = clusterData.cluster {
                                if let onOffValue = self.getClusterAttributeValue(cluster: cluster, clusterId: ESPControllerAPIKeys.onOffClusterId, attributeId: ESPControllerAPIKeys.onOffAttributeId) {
                                    if onOffValue.lowercased() == "1" {
                                        return true
                                    }
                                    return false
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    /// Get level cluster endpoint id
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    func getBrightnessLevelEndpointId(controllerNodeId: String, matterNodeId: String) -> String? {
        if let endpointId = self.getMatterEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId, clusterId: ESPControllerAPIKeys.levelControlClusterId) {
            return endpointId
        }
        return nil
    }
    
    /// Get brightness level
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    /// - Returns: brightness level
    func getBrightnessLevel(controllerNodeId: String, matterNodeId: String) -> Int? {
        if let endpointsData = self.getMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
            if let eId = self.getBrightnessLevelEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId), let endpoints = self.getMatterEndpoints(endpointsData: endpointsData, endpointId: eId) {
                for endpoint in endpoints {
                    if let clusters = endpoint.clusters {
                        for clusterData in clusters {
                            if let cluster = clusterData.cluster {
                                if let brightnessLevel = self.getClusterAttributeValue(cluster: cluster, clusterId: ESPControllerAPIKeys.levelControlClusterId, attributeId: ESPControllerAPIKeys.brightnessLevelAttributeId) {
                                    return Int(brightnessLevel)
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    /// Get level cluster endpoint id
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    func getHueEndpointId(controllerNodeId: String, matterNodeId: String) -> String? {
        if let endpointId = self.getMatterEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId, clusterId: ESPControllerAPIKeys.colorControlClusterId) {
            return endpointId
        }
        return nil
    }
    
    /// Get brightness level
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    /// - Returns: brightness level
    func getCurrentHue(controllerNodeId: String, matterNodeId: String) -> Int? {
        if let endpointsData = self.getMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
            if let eId = self.getHueEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId), let endpoints = self.getMatterEndpoints(endpointsData: endpointsData, endpointId: eId) {
                for endpoint in endpoints {
                    if let clusters = endpoint.clusters {
                        for clusterData in clusters {
                            if let cluster = clusterData.cluster {
                                if let currentHue = self.getClusterAttributeValue(cluster: cluster, clusterId: ESPControllerAPIKeys.colorControlClusterId, attributeId: ESPControllerAPIKeys.currentHueAttributeId) {
                                    return Int(currentHue)
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    /// Get color control cluster endpoint id
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    func getSaturationLevelEndpointId(controllerNodeId: String, matterNodeId: String) -> String? {
        if let endpointId = self.getMatterEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId, clusterId: ESPControllerAPIKeys.colorControlClusterId) {
            return endpointId
        }
        return nil
    }
    
    /// Get current saturation value
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    /// - Returns: current saturation value
    func getCurrentSaturation(controllerNodeId: String, matterNodeId: String) -> Int? {
        if let matterNodesData = self.getMatterNodesData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
            if let endpointsData = self.getMatterEndpointsData(matterNodeId: matterNodeId, matterNodesData: matterNodesData) {
                if let eId = self.getHueEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId), let endpoints = self.getMatterEndpoints(endpointsData: endpointsData, endpointId: eId) {
                    for endpoint in endpoints {
                        if let clusters = endpoint.clusters {
                            for clusterData in clusters {
                                if let cluster = clusterData.cluster {
                                    if let currentSaturation = self.getClusterAttributeValue(cluster: cluster, clusterId: ESPControllerAPIKeys.colorControlClusterId, attributeId: ESPControllerAPIKeys.currentSaturationAttributeId) {
                                        return Int(currentSaturation)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    /// Get on off cluster endpoint id
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    func getThermostatEndpointId(controllerNodeId: String, matterNodeId: String) -> String? {
        if let endpointId = self.getMatterEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId, clusterId: ESPControllerAPIKeys.thermostatClusterId) {
            return endpointId
        }
        return nil
    }
    
    /// Get on off cluster endpoint id
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    func getTemperatureMeasurementEndpointId(controllerNodeId: String, matterNodeId: String) -> String? {
        if let endpointId = self.getMatterEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId, clusterId: ESPControllerAPIKeys.temperatureMeasurementClusterId) {
            return endpointId
        }
        return nil
    }
    
    /// Get current local temperature
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    /// - Returns: current local temoerature
    func getCurrentLocalTemperature(controllerNodeId: String, matterNodeId: String) -> Int? {
        if let endpointsData = self.getMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
            if let eId = self.getThermostatEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId), let endpoints = self.getMatterEndpoints(endpointsData: endpointsData, endpointId: eId) {
                for endpoint in endpoints {
                    if let clusters = endpoint.clusters {
                        for clusterData in clusters {
                            if let cluster = clusterData.cluster {
                                if let localTemperature = self.getClusterAttributeValue(cluster: cluster, clusterId: ESPControllerAPIKeys.thermostatClusterId, attributeId: ESPControllerAPIKeys.localTemperatureAttributeId) {
                                    if let localTemp = Int(localTemperature) {
                                        return (localTemp/100)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    /// Get current local temperature
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    /// - Returns: current local temoerature
    func getCurrentMeasuredTemperature(controllerNodeId: String, matterNodeId: String) -> Int? {
        if let endpointsData = self.getMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
            if let eId = self.getTemperatureMeasurementEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId), let endpoints = self.getMatterEndpoints(endpointsData: endpointsData, endpointId: eId) {
                for endpoint in endpoints {
                    if let clusters = endpoint.clusters {
                        for clusterData in clusters {
                            if let cluster = clusterData.cluster {
                                if let measuredTemperature = self.getClusterAttributeValue(cluster: cluster, clusterId: ESPControllerAPIKeys.temperatureMeasurementClusterId, attributeId: ESPControllerAPIKeys.measuredTemperatureAttributeId) {
                                    if let measuredTemp = Int(measuredTemperature) {
                                        return (measuredTemp/100)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    /// Get current system mode
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    /// - Returns: current system mode
    func getCurrentSystemMode(controllerNodeId: String, matterNodeId: String) -> Int? {
        if let endpointsData = self.getMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
            if let eId = self.getThermostatEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId), let endpoints = self.getMatterEndpoints(endpointsData: endpointsData, endpointId: eId) {
                for endpoint in endpoints {
                    if let clusters = endpoint.clusters {
                        for clusterData in clusters {
                            if let cluster = clusterData.cluster {
                                if let systemMode = self.getClusterAttributeValue(cluster: cluster, clusterId: ESPControllerAPIKeys.thermostatClusterId, attributeId: ESPControllerAPIKeys.systemModeAttributeId) {
                                    if let mode = Int(systemMode) {
                                        return mode
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    /// Get occupied cooling setpoint
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    /// - Returns: occupied cooling setpoint
    func getCurrentOccupiedCoolingSetpoint(controllerNodeId: String, matterNodeId: String) -> Int? {
        if let endpointsData = self.getMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
            if let eId = self.getThermostatEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId), let endpoints = self.getMatterEndpoints(endpointsData: endpointsData, endpointId: eId) {
                for endpoint in endpoints {
                    if let clusters = endpoint.clusters {
                        for clusterData in clusters {
                            if let cluster = clusterData.cluster {
                                if let ocs = self.getClusterAttributeValue(cluster: cluster, clusterId: ESPControllerAPIKeys.thermostatClusterId, attributeId: ESPControllerAPIKeys.occupiedCoolingSetpointAttributeId), let setpoint = Int(ocs) {
                                    return setpoint/100
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    /// Get occupied heating setpoint
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    /// - Returns: occupied cooling setpoint
    func getCurrentOccupiedHeatingSetpoint(controllerNodeId: String, matterNodeId: String) -> Int? {
        if let endpointsData = self.getMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
            if let eId = self.getThermostatEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId), let endpoints = self.getMatterEndpoints(endpointsData: endpointsData, endpointId: eId) {
                for endpoint in endpoints {
                    if let clusters = endpoint.clusters {
                        for clusterData in clusters {
                            if let cluster = clusterData.cluster {
                                if let ohs = self.getClusterAttributeValue(cluster: cluster, clusterId: ESPControllerAPIKeys.thermostatClusterId, attributeId: ESPControllerAPIKeys.occupiedHeatingSetpointAttributeId), let setpoint = Int(ohs) {
                                    return setpoint/100
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
}

@available(iOS 16.4, *)
struct MatterController: Codable {
    
    var matterControllerDataVersion: String?
    var matterControllerData: MatterControllerData?
    
    enum CodingKeys: String, CodingKey {
        case matterControllerDataVersion = "matter-controller-data-version"
        case matterControllerData = "matter-controller-data"
    }
}

@available(iOS 16.4, *)
struct MatterControllerData: Codable {
    
    var matterNodesData: [String: MatterNodeData]?
}

@available(iOS 16.4, *)
struct MatterNodeData: Codable {
    
    var enabled: Bool?
    var reachable: Bool?
    var endpointsData: [String: MatterEndpointsData]?
}

@available(iOS 16.4, *)
struct MatterEndpointsData: Codable {
    
    var endpoints: [MatterEndpointData]?
}

@available(iOS 16.4, *)
struct MatterEndpointData: Codable {
    
    var clusters: [MatterClusterData]?
}

@available(iOS 16.4, *)
struct MatterClusterData: Codable {
    
    var cluster: [String: MatterAttributeData]?
}

@available(iOS 16.4, *)
struct MatterAttributeData: Codable {
    
    var attributes: [String: String]?
}
#endif
