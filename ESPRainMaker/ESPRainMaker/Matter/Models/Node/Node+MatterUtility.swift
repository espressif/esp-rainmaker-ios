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
    
    /// Is on off client supported
    var isOnOffClientSupported: Bool {
        if let metadata = metadata, let clientsData = metadata[ESPMatterConstants.clientsData] as? [String: [UInt]] {
            for key in clientsData.keys {
                if let list = clientsData[key], list.count > 0, list.contains(ESPMatterConstants.onOffClusterId) {
                    return true
                }
            }
        }
        return false
    }
    
    /// On off clients
    var onOffClients: [String: UInt] {
        var endpointClusters: [String: UInt] = [String: UInt]()
        if let metadata = metadata, let val = metadata[ESPMatterConstants.clientsData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(ESPMatterConstants.onOffClusterId) {
                    endpointClusters[key] = ESPMatterConstants.onOffClusterId
                }
            }
        }
        return endpointClusters
    }
    
    /// Binding servers
    var bindingServers: [String: UInt] {
        var endpointClusters: [String: UInt] = [String: UInt]()
        if let metadata = metadata, let val = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(ESPMatterConstants.bindingClusterId) {
                    endpointClusters[key] = ESPMatterConstants.bindingClusterId
                }
            }
        }
        return endpointClusters
    }
    
    /// Is on off server supported
    var isControllerServerSupported: (Bool, String?) {
        if let metadata = metadata, let val = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(ESPMatterConstants.controllerClusterId) {
                    return (true, key)
                }
            }
        }
        return (false, nil)
    }
    
    /// Is on off server supported
    var isOnOffServerSupported: (Bool, String?) {
        if let metadata = metadata, let val = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(ESPMatterConstants.onOffClusterId) {
                    return (true, key)
                }
            }
        }
        return (false, nil)
    }
    
    /// Is level control server supported
    var isLevelControlServerSupported: (Bool, String?) {
        if let metadata = metadata, let val = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(ESPMatterConstants.levelControlClusterId) {
                    return (true, key)
                }
            }
        }
        return (false, nil)
    }
    
    /// Is color control server supported
    var isColorControlServerSupported: (Bool, String?) {
        if let metadata = metadata, let val = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(ESPMatterConstants.colorControlClusterId) {
                    return (true, key)
                }
            }
        }
        return (false, nil)
    }
    
    /// Is open commissioning window supported
    var isOpenCommissioningWindowSupported: (Bool, String?) {
        if let metadata = metadata, let val = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in val.keys {
                if let list = val[key], list.count > 0, list.contains(ESPMatterConstants.commissioningWindowClusterId) {
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
        if let metadata = metadata, let val = metadata[ESPMatterConstants.isRainmaker] as? Bool {
            return val
        }
        return false
    }
    
    var userDefinaedName: String? {
        if let metadata = metadata, let matterDeviceName = metadata[ESPMatterConstants.deviceName] as? String {
            return matterDeviceName
        }
        return nil
    }
    
    /// Matter device name
    var matterDeviceName: String? {
        if let deviceName = self.rainmakerDeviceName {
            return deviceName
        }
        if let metadata = metadata, let matterDeviceName = metadata[ESPMatterConstants.deviceName] as? String {
            return matterDeviceName
        }
        return nil
    }
    
    /// Matter node id
    var getMatterNodeId: String? {
        if let id = controllerNodeId {
            if User.shared.isMatterNodeConnected(matterNodeId: id) {
                return id
            }
        }
        return originalMatterNodeId
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
        if let metadata = metadata, let ipkString = metadata[ESPMatterConstants.ipk] as? String {
            return ipkString
        }
        return nil
    }
    
    /// Vendor Id
    var vendorId: Int? {
        if let metadata = metadata, let vid = metadata[ESPMatterConstants.vendorId] as? Int {
            return vid
        }
        return nil
    }
    
    /// Product Id
    var productId: Int? {
        if let metadata = metadata, let pid = metadata[ESPMatterConstants.productId] as? Int {
            return pid
        }
        return nil
    }
    
    /// Software version
    var swVersion: Int? {
        if let metadata = metadata, let sw = metadata[ESPMatterConstants.softwareVersion] as? Int {
            return sw
        }
        return nil
    }
    
    /// Software version
    var serialNumber: Int? {
        if let metadata = metadata, let serialNumber = metadata[ESPMatterConstants.serialNumber] as? Int {
            return serialNumber
        }
        return nil
    }
    
    /// Software version
    var manufacturerName: String? {
        if let metadata = metadata, let manufacturerName = metadata[ESPMatterConstants.manufacturerName] as? String {
            return manufacturerName
        }
        return nil
    }
    
    /// Software version
    var productName: String? {
        if let metadata = metadata, let productName = metadata[ESPMatterConstants.productName] as? String {
            return productName
        }
        return nil
    }
    
    /// group Id
    var groupId: String? {
        if let metadata = metadata, let id = metadata[ESPMatterConstants.groupId] as? String {
            return id
        }
        return nil
    }
    
    /// Is on off client supported
    var isRainmakerControllerSupported: (Bool, String?) {
        if let metadata = metadata, let serversData = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
            for key in serversData.keys {
                if let list = serversData[key], list.count > 0, list.contains(ESPMatterConstants.controllerClusterId) {
                    return (true, key)
                }
            }
        }
        return (true, nil)
    }
    
    /// Controller node id
    var controllerNodeId: String? {
        if let metadata = metadata, let id = metadata[ESPMatterConstants.controllerNodeId] as? String {
            return id
        }
        return nil
    }
    
    var deviceType: Int? {
        if let metadata = metadata, let type = metadata[ESPMatterConstants.deviceType] as? Int {
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
}
