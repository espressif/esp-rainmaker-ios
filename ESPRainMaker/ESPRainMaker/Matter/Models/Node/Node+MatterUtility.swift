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
//  Node+MatterUtility.swift
//  ESPRainMaker
//

import Foundation

extension Node {
    
    var matterMetadata: [String: Any]? {
        if let metadata = metadata, let value = metadata[ESPMatterConstants.matter] as? [String: Any] {
            return value
        }
        return nil
    }
    
    /// Is on off client supported
    var isOnOffClientSupported: Bool {
        if let metadata = matterMetadata, let clientsData = metadata[ESPMatterConstants.clientsData] as? [String: [UInt]] {
            for key in clientsData.keys {
                if let list = clientsData[key], list.count > 0, list.contains(onOff.clusterId.uintValue) {
                    return true
                }
            }
        }
        return false
    }
    
    /// On off clients
    var onOffClients: [String: UInt] {
        var endpointClusters: [String: UInt] = [String: UInt]()
        if let metadata = matterMetadata, let val = metadata[ESPMatterConstants.clientsData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(onOff.clusterId.uintValue) {
                    endpointClusters[key] = onOff.clusterId.uintValue
                }
            }
        }
        return endpointClusters
    }
    
    /// Binding servers
    var bindingServers: [String: UInt] {
        var endpointClusters: [String: UInt] = [String: UInt]()
        if let metadata = matterMetadata, let val = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(binding.clusterId.uintValue) {
                    endpointClusters[key] = binding.clusterId.uintValue
                }
            }
        }
        return endpointClusters
    }
    
    /// Is controllerserver supported
    var isControllerServerSupported: (Bool, String?) {
        if let metadata = matterMetadata, let val = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(rainmakerController.clusterId.uintValue) {
                    return (true, key)
                }
            }
        }
        return (false, nil)
    }
    
    /// Is on off server supported
    var isOnOffServerSupported: (Bool, String?) {
        if let metadata = matterMetadata, let val = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(onOff.clusterId.uintValue) {
                    return (true, key)
                }
            }
        }
        return (false, nil)
    }
    
    /// Is level control server supported
    var isLevelControlServerSupported: (Bool, String?) {
        if let metadata = matterMetadata, let val = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(levelControl.clusterId.uintValue) {
                    return (true, key)
                }
            }
        }
        return (false, nil)
    }
    
    /// Is color control server supported
    var isColorControlServerSupported: (Bool, String?) {
        if let metadata = matterMetadata, let val = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(colorControl.clusterId.uintValue) {
                    return (true, key)
                }
            }
        }
        return (false, nil)
    }
    
    /// Is open commissioning window supported
    var isOpenCommissioningWindowSupported: (Bool, String?) {
        if let metadata = matterMetadata, let val = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(commissioningWindow.clusterId.uintValue) {
                    return (true, key)
                }
            }
        }
        return (false, nil)
    }
    
    /// Is rainmaker
    var isRainmaker: Bool {
        if let node_type = node_type {
            if node_type.lowercased() == ESPMatterConstants.rainmakerMatter.lowercased() {
                return true
            }
        }
        if let metadata = matterMetadata, let val = metadata[ESPMatterConstants.isRainmaker] as? Bool {
            return val
        }
        return false
    }
    
    var userDefinaedName: String? {
        if let metadata = matterMetadata, let matterDeviceName = metadata[ESPMatterConstants.deviceName] as? String {
            return matterDeviceName
        }
        return nil
    }
    
    /// Matter device name
    var matterDeviceName: String? {
        if let groupId = self.groupId, let matterNodeId = self.matter_node_id, let deviceId = matterNodeId.hexToDecimal, let name = ESPMatterFabricDetails.shared.getNodeLabel(groupId: groupId, deviceId: deviceId) {
            return name
        }
        if let metadata = matterMetadata, let matterDeviceName = metadata[ESPMatterConstants.deviceName] as? String {
            return matterDeviceName
        }
        if let deviceName = self.rainmakerDeviceName {
            return deviceName
        }
        return nil
    }
    
    /// Original matter node id
    var originalMatterNodeId: String? {
        if let matterNodeId = self.matter_node_id {
            return matterNodeId
        }
        return nil
    }
    
    /// IPK string
    var ipkString: String? {
        if let metadata = matterMetadata, let ipkString = metadata[ESPMatterConstants.ipk] as? String {
            return ipkString
        }
        return nil
    }
    
    /// Vendor Id
    var vendorId: Int? {
        if let metadata = matterMetadata, let vid = metadata[ESPMatterConstants.vendorId] as? Int {
            return vid
        }
        return nil
    }
    
    /// Product Id
    var productId: Int? {
        if let metadata = matterMetadata, let pid = metadata[ESPMatterConstants.productId] as? Int {
            return pid
        }
        return nil
    }
    
    /// Software version
    var swVersion: Int? {
        if let metadata = matterMetadata, let sw = metadata[ESPMatterConstants.softwareVersion] as? Int {
            return sw
        }
        return nil
    }
    
    /// Software version string
    var swVersionString: Int? {
        if let metadata = matterMetadata, let swString = metadata[ESPMatterConstants.softwareVersionString] as? Int {
            return swString
        }
        return nil
    }
    
    /// Software version
    var serialNumber: Int? {
        if let metadata = matterMetadata, let serialNumber = metadata[ESPMatterConstants.serialNumber] as? Int {
            return serialNumber
        }
        return nil
    }
    
    /// Software version
    var manufacturerName: String? {
        if let metadata = matterMetadata, let manufacturerName = metadata[ESPMatterConstants.manufacturerName] as? String {
            return manufacturerName
        }
        return nil
    }
    
    /// Software version
    var productName: String? {
        if let metadata = matterMetadata, let productName = metadata[ESPMatterConstants.productName] as? String {
            return productName
        }
        return nil
    }
    
    /// group Id
    var groupId: String? {
        if let metadata = matterMetadata, let id = metadata[ESPMatterConstants.groupId] as? String {
            return id
        }
        return nil
    }
    
    /// Is on off client supported
    var isRainmakerControllerSupported: (Bool, String?) {
        if let metadata = matterMetadata, let serversData = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in serversData.keys {
                if let list = serversData[key], list.count > 0, list.contains(rainmakerController.clusterId.uintValue) {
                    return (true, key)
                }
            }
        }
        return (true, nil)
    }
    
    var deviceType: Int? {
        if let metadata = matterMetadata, let type = metadata[ESPMatterConstants.deviceType] as? Int {
            return type
        }
        return nil
    }
    
    var rainmakerDeviceName: String? {
        if self.isRainmaker, let devices = self.devices, devices.count > 0 {
            let device = devices[0]
            if let params = device.params {
                for param in params {
                    if let type = param.type, type == Constants.deviceNameParam, let properties = param.properties, properties.contains("write"), let value = param.value as? String {
                        return value
                    }
                }
            }
        }
        return nil
    }
    
    func setControllerServiceName(serviceName: String) {
        if let id = self.node_id {
            let key = "esp.service.matter-controller.\(id)"
            UserDefaults.standard.set(serviceName, forKey: key)
        }
    }
    
    var controllerServiceName: String {
        if let id = self.node_id {
            let key = "esp.service.matter-controller.\(id)"
            if let value = UserDefaults.standard.value(forKey: key) as? String {
                return value
            }
        }
        return "Matter-Controller"
    }
    
    func setMatterDevicesParamName(matterDevicesParamName: String) {
        if let id = self.node_id {
            let key = "esp.param.matter-devices.\(id)"
            UserDefaults.standard.set(matterDevicesParamName, forKey: key)
        }
    }
    
    var matterDevicesParamName: String {
        if let id = self.node_id {
            let key = "esp.param.matter-devices.\(id)"
            if let value = UserDefaults.standard.value(forKey: key) as? String {
                return value
            }
        }
        return "Matter-Devices"
    }
    
    func setMatterControllerDataVersion(matterControllerDataVersion: String) {
        if let id = self.node_id {
            let key = "esp.param.matter-controller-data-version.\(id)"
            UserDefaults.standard.set(matterControllerDataVersion, forKey: key)
        }
    }
    
    var matterControllerDataVersion: String {
        if let id = self.node_id {
            let key = "esp.param.matter-controller-data-version.\(id)"
            if let value = UserDefaults.standard.value(forKey: key) as? String {
                return value
            }
        }
        return "Matter-Controller-Data-Version"
    }
    
    func setMatterControllerData(matterControllerData: String) {
        if let id = self.node_id {
            let key = "esp.param.matter-controller-data.\(id)"
            UserDefaults.standard.set(matterControllerData, forKey: key)
        }
    }
    
    var matterControllerData: String {
        if let id = self.node_id {
            let key = "esp.param.matter-controller-data.\(id)"
            if let value = UserDefaults.standard.value(forKey: key) as? String {
                return value
            }
        }
        return "Matter-Controller-Data"
    }
    
    func getBindingEndpoint(switchIndex: Int?) -> UInt? {
        let bindingServers = self.bindingServers
        if let index = switchIndex {
            let sortedKeys = bindingServers.keys.sorted { $0 < $1 }
            if index < sortedKeys.count {
                let key = sortedKeys[index]
                if let endpoint = UInt(key) {
                    return endpoint
                }
            }
        } else {
            let sortedKeys = bindingServers.keys.sorted { $0 < $1 }
            if sortedKeys.count == 1, let key = sortedKeys.first { 
                if let endpoint = UInt(key) {
                    return endpoint
                }
            }
        }
        return nil
    }
    
    func getAllFabricDevices() -> [Node] {
        var fabricNodes: [Node] = [Node]()
        if let groupId = self.groupId {
            if let nodes = User.shared.associatedNodeList {
                for node in nodes {
                    if let grpId = node.groupId, grpId == groupId {
                        fabricNodes.append(node)
                    }
                }
            }
        }
        return fabricNodes
    }
    
    func getOnOffDevices() -> [Node] {
        var onOffNodes: [Node] = [Node]()
        let fabricNodes = self.getAllFabricDevices()
        if fabricNodes.count > 0 {
            for node in fabricNodes {
                if node.isOnOffServerSupported.0 {
                    onOffNodes.append(node)
                }
            }
        }
        return onOffNodes
    }
}
