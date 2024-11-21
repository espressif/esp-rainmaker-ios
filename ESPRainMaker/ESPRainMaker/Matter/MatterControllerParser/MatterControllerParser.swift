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
@available(iOS 16.4, *)
class MatterControllerParser {
    
    static let shared = MatterControllerParser()
    
    /// Check the matter controller data version and parse the matter controller data accordingly
    /// - Parameters:
    ///   - node: node
    ///   - matterControllerData: matter controller data
    /// - Returns: matter controller object
    func parseMatterControllerData(node: Node, matterControllerData: [String: Any]) -> MatterController? {
        var controllerData = MatterController()
        if let matterController = matterControllerData[node.controllerServiceName] as? [String: Any] {
            if let dataVersion = matterController[node.matterControllerDataVersion] as? String, dataVersion > "1.0.0" {
                return parseNewMatterControllerData(node: node, matterControllerData: matterControllerData, controllerData: &controllerData)
            } else {
                return parseOldMatterControllerData(node: node, matterControllerData: matterControllerData, controllerData: &controllerData)
            }
        }
        return nil
    }
    
    //MARK: new controller version parser
    
    /// Parse controller data for newer controller version
    /// - Parameters:
    ///   - node: node
    ///   - matterControllerData: matter controller data
    ///   - controllerData: controller data reference
    /// - Returns: MatterController object
    func parseNewMatterControllerData(node: Node, matterControllerData: [String: Any], controllerData: inout MatterController) -> MatterController? {
        if let matterController = matterControllerData[node.controllerServiceName] as? [String: Any] {
            if let dataVersion = matterController[node.matterControllerDataVersion] as? String {
                controllerData.matterControllerDataVersion = dataVersion
            }
            if let data = matterController[node.matterDevicesParamName] as? [String: Any] {
                controllerData.matterControllerData = self.populateMatterControllerData(data: data)
            }
            return controllerData
        }
        return nil
    }
    
    func populateMatterControllerData(data: [String: Any]) -> MatterControllerData {
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
                self.populateEndpointsData(matterNodeData: &matterNodeData, nodeData: nodeData)
            }
            matterControllerData.matterNodesData?[nodeId] = matterNodeData
        }
        return matterControllerData
    }
    
    func populateEndpointsData(matterNodeData: inout MatterNodeData, nodeData: [String: Any]) {
        var endpointsData = MatterEndpointsData()
        if let endpoints = nodeData[ESPControllerAPIKeys.endpoints] as? [String: Any] {
            endpointsData.endpoints = [MatterEndpointData]()
            matterNodeData.finalEndpointsData = [String: MatterEndpointData]()
            for endpoint in endpoints.keys {
                var endpointData = MatterEndpointData()
                endpointData.clustersData = [String: MatterClusterData]()
                endpointData.clients = [String: [String]]()
                if let clustersData = endpoints[endpoint] as? [String: Any] {
                    if let clusters = clustersData[ESPControllerAPIKeys.clusters] as? [String: Any] {
                        var clusterData = MatterClusterData()
                        if let clients = clusters[ESPControllerAPIKeys.clients] as? [String] {
                            endpointData.clients?[endpoint] = clients
                        }
                        if let servers = clusters[ESPControllerAPIKeys.servers] as? [String: Any] {
                            for clusterId in servers.keys {
                                clusterData.servers = [MatterServersData]()
                                if let serverData = servers[clusterId] as? [String: Any] {
                                    var serversData = MatterServersData()
                                    if let attributes = serverData[ESPControllerAPIKeys.attributes] as? [String: Any] {
                                        serversData.attributes = attributes
                                    }
                                    
                                    if let events = servers[ESPControllerAPIKeys.events] as? [String: Any] {
                                        serversData.events = events
                                    }
                                    clusterData.servers?.append(serversData)
                                }
                                endpointData.clustersData?[clusterId] = clusterData
                            }
                        }
                        matterNodeData.finalEndpointsData?[endpoint] = endpointData
                    }
                }
            }
        }
    }
    
    //MARK: old controller version parser
    
    /// Parse matter controller data
    /// - Parameter matterControllerData: matter controller data
    /// - Returns: matter controller object
    func parseOldMatterControllerData(node: Node, matterControllerData: [String: Any], controllerData: inout MatterController) -> MatterController? {
        if let matterController = matterControllerData[node.controllerServiceName] as? [String: Any] {
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
        if isControllerFwVersionUpdated(controllerNodeId: controllerNodeId) {
            return getFinalMatterEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId, clusterId: ESPControllerAPIKeys.onOffClusterId)
        } else {
            return getMatterEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId, clusterId: ESPControllerAPIKeys.onOffClusterId)
        }
        return nil
    }
    
    /// Get on off cluster value
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    /// - Returns: on/off status
    func getOnOffValue(controllerNodeId: String, matterNodeId: String) -> Bool? {
        if isControllerFwVersionUpdated(controllerNodeId: controllerNodeId) {
            if let finalEndpointsData = getFinalMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId), let eId = getOnOffEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId), let value = getFinalClusterAttributeValue(finalEndpointsData: finalEndpointsData, endpointId: eId, clusterId: ESPControllerAPIKeys.onOffClusterId, attributeId: ESPControllerAPIKeys.onOffAttributeId) as? Bool {
                return value
            }
        } else {
            // Existing implementation for old version
            if let endpointsData = getMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId),
               let eId = getOnOffEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId), let endpoints = getMatterEndpoints(endpointsData: endpointsData, endpointId: eId) {
                for endpoint in endpoints {
                    if let clusters = endpoint.clusters {
                        for clusterData in clusters {
                            if let cluster = clusterData.cluster,
                               let onOffValue = getClusterAttributeValue(cluster: cluster, clusterId: ESPControllerAPIKeys.onOffClusterId, attributeId: ESPControllerAPIKeys.onOffAttributeId) {
                                if onOffValue == "1" {
                                    return true
                                }
                                return false
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
        if isControllerFwVersionUpdated(controllerNodeId: controllerNodeId) {
            return getFinalMatterEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId, clusterId: ESPControllerAPIKeys.levelControlClusterId)
        } else {
            return getMatterEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId, clusterId: ESPControllerAPIKeys.levelControlClusterId)
        }
    }
    
    /// Get brightness level
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    /// - Returns: brightness level
    func getBrightnessLevel(controllerNodeId: String, matterNodeId: String) -> Int? {
        if isControllerFwVersionUpdated(controllerNodeId: controllerNodeId) {
            if let finalEndpointsData = getFinalMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId),
               let eId = getBrightnessLevelEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId),
               let value = getFinalClusterAttributeValue(finalEndpointsData: finalEndpointsData, endpointId: eId, clusterId: ESPControllerAPIKeys.levelControlClusterId, attributeId: ESPControllerAPIKeys.brightnessLevelAttributeId) as? Int {
                return value
            }
        } else {
            // Existing implementation for old version
            if let endpointsData = getMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId),
               let eId = getBrightnessLevelEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId),
               let endpoints = getMatterEndpoints(endpointsData: endpointsData, endpointId: eId) {
                for endpoint in endpoints {
                    if let clusters = endpoint.clusters {
                        for clusterData in clusters {
                            if let cluster = clusterData.cluster,
                               let brightnessLevel = getClusterAttributeValue(cluster: cluster, clusterId: ESPControllerAPIKeys.levelControlClusterId, attributeId: ESPControllerAPIKeys.brightnessLevelAttributeId) {
                                return Int(brightnessLevel)
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
        if isControllerFwVersionUpdated(controllerNodeId: controllerNodeId) {
            return getFinalMatterEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId, clusterId: ESPControllerAPIKeys.colorControlClusterId)
        } else {
            return getMatterEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId, clusterId: ESPControllerAPIKeys.colorControlClusterId)
        }
    }
    
    /// Get brightness level
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    /// - Returns: brightness level
    func getCurrentHue(controllerNodeId: String, matterNodeId: String) -> Int? {
        if isControllerFwVersionUpdated(controllerNodeId: controllerNodeId) {
            if let finalEndpointsData = getFinalMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId),
               let eId = getHueEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId),
               let value = getFinalClusterAttributeValue(finalEndpointsData: finalEndpointsData, endpointId: eId, clusterId: ESPControllerAPIKeys.colorControlClusterId, attributeId: ESPControllerAPIKeys.currentHueAttributeId) as? Int {
                return value
            }
        } else {
            // Existing implementation
            if let endpointsData = getMatterNodesEndpointsData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId),
               let eId = getHueEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId),
               let endpoints = getMatterEndpoints(endpointsData: endpointsData, endpointId: eId) {
                for endpoint in endpoints {
                    if let clusters = endpoint.clusters {
                        for clusterData in clusters {
                            if let cluster = clusterData.cluster,
                               let currentHue = getClusterAttributeValue(cluster: cluster, clusterId: ESPControllerAPIKeys.colorControlClusterId, attributeId: ESPControllerAPIKeys.currentHueAttributeId) {
                                return Int(currentHue)
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
#endif

