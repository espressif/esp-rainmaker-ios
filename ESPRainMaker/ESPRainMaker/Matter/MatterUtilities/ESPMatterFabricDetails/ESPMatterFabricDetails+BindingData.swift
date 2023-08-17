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
//  ESPMatterFabricDetails+BindingData.swift
//  ESPRainmaker
//

import Foundation
#if ESPRainMakerMatter
import Matter
#endif

extension ESPMatterFabricDetails {
    
    /// Save bindings data
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - linkedNodes: linked nodes
    ///   - unlinkedNodes: unlnkned nodes
    func saveBindingData(groupId: String, deviceId: UInt64, linkedNodes: [ESPNodeDetails], unlinkedNodes: [ESPNodeDetails], endpointClusterId: [String: Any]?) {
        var str = ""
        if let endpointClusterId = endpointClusterId, endpointClusterId.keys.count > 0, let key = endpointClusterId.keys.first {
            str = key
        }
        let linkedDevicesKey = ESPMatterFabricKeys.shared.groupLinkedDevicesKey(groupId, deviceId) + ".\(str)"
        let unlinkedDevicesKey = ESPMatterFabricKeys.shared.groupUnlinkedDevicesKey(groupId, deviceId) + ".\(str)"
        let encoder = JSONEncoder()
        if linkedNodes.count > 0, let data = try? encoder.encode(linkedNodes) {
            UserDefaults.standard.set(data, forKey: linkedDevicesKey)
        } else {
            UserDefaults.standard.removeObject(forKey: linkedDevicesKey)
        }
        if unlinkedNodes.count > 0, let data = try? encoder.encode(unlinkedNodes) {
            UserDefaults.standard.set(data, forKey: unlinkedDevicesKey)
        } else {
            UserDefaults.standard.removeObject(forKey: unlinkedDevicesKey)
        }
    }
    
    /// Save linked devices
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: source device id
    ///   - linkedNodes: linked nodes
    func saveLinkedDevices(groupId: String, sourceDeviceId: UInt64, linkedNodes: [ESPNodeDetails], endpointClusterId: [String: Any]?) {
        var str = ""
        if let endpointClusterId = endpointClusterId, endpointClusterId.keys.count > 0, let key = endpointClusterId.keys.first {
            str = key
        }
        let linkedDevicesKey = ESPMatterFabricKeys.shared.groupLinkedDevicesKey(groupId, sourceDeviceId) + ".\(str)"
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(linkedNodes) {
            UserDefaults.standard.set(data, forKey: linkedDevicesKey)
        }
    }
    
    /// Save unlinked devices
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: source device id
    ///   - linkedNodes: unlinked nodes
    func saveUnlinkedDevices(groupId: String, deviceId: UInt64, unlinkedNodes: [ESPNodeDetails], endpointClusterId: [String: Any]?) {
        var str = ""
        if let endpointClusterId = endpointClusterId, endpointClusterId.keys.count > 0, let key = endpointClusterId.keys.first {
            str = key
        }
        let unlinkedDevicesKey = ESPMatterFabricKeys.shared.groupUnlinkedDevicesKey(groupId, deviceId) + ".\(str)"
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(unlinkedNodes) {
            UserDefaults.standard.set(data, forKey: unlinkedDevicesKey)
        }
    }
    
    /// Get linked devices
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: linked nodes
    func getLinkedDevices(groupId: String, deviceId: UInt64, endpointClusterId: [String: Any]?) -> [ESPNodeDetails]? {
        var str = ""
        if let endpointClusterId = endpointClusterId, endpointClusterId.keys.count > 0, let key = endpointClusterId.keys.first {
            str = key
        }
        let linkedDevicesKey = ESPMatterFabricKeys.shared.groupLinkedDevicesKey(groupId, deviceId) + ".\(str)"
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: linkedDevicesKey) as? Data, let linkedNodes = try? decoder.decode([ESPNodeDetails].self, from: data) {
            return linkedNodes
        }
        return nil
    }
    
    /// Get unlinked devices
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: linked nodes
    func getUnlinkedDevices(groupId: String, deviceId: UInt64, endpointClusterId: [String: Any]?)  -> [ESPNodeDetails]? {
        var str = ""
        if let endpointClusterId = endpointClusterId, endpointClusterId.keys.count > 0, let key = endpointClusterId.keys.first {
            str = key
        }
        let unlinkedDevicesKey = ESPMatterFabricKeys.shared.groupUnlinkedDevicesKey(groupId, deviceId) + ".\(str)"
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: unlinkedDevicesKey) as? Data, let unlinkedNodes = try? decoder.decode([ESPNodeDetails].self, from: data) {
            return unlinkedNodes
        }
        return nil
    }
    
    /// Remove linked device data
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    func removeLinkedDevice(groupId: String, deviceId: UInt64, endpointClusterId: [String: Any]?) {
        var str = ""
        if let endpointClusterId = endpointClusterId, endpointClusterId.keys.count > 0, let key = endpointClusterId.keys.first {
            str = key
        }
        let linkedDevicesKey = ESPMatterFabricKeys.shared.groupLinkedDevicesKey(groupId, deviceId) + ".\(str)"
        let unlinkedDevicesKey = ESPMatterFabricKeys.shared.groupUnlinkedDevicesKey(groupId, deviceId) + ".\(str)"
        if let _ = UserDefaults.standard.value(forKey: linkedDevicesKey) {
            UserDefaults.standard.removeObject(forKey: linkedDevicesKey)
        }
        if let _ = UserDefaults.standard.value(forKey: unlinkedDevicesKey) {
            UserDefaults.standard.removeObject(forKey: unlinkedDevicesKey)
        }
        if let nodeDetails = ESPMatterFabricDetails.shared.getNodeGroupDetails(groupId: groupId), let groups = nodeDetails.groups, groups.count > 0, let nodes = groups[0].nodeDetails, nodes.count > 0 {
            for node in nodes {
                if let nodeId = node.getMatterNodeId()?.hexToDecimal, nodeId != deviceId {
                    self.removeDeviceFromLinkedDevices(groupId: groupId, sourceDeviceId: nodeId, deviceId: deviceId, endpointClusterId: endpointClusterId)
                    self.removeDeviceFromUnlinkedDevices(groupId: groupId, sourceDeviceId: nodeId, deviceId: deviceId, endpointClusterId: endpointClusterId)
                }
            }
        }
    }
    
    /// Remove device from linked devices list
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    func removeDeviceFromLinkedDevices(groupId: String, sourceDeviceId: UInt64, deviceId: UInt64, endpointClusterId: [String: Any]?) {
        var str = ""
        if let endpointClusterId = endpointClusterId, endpointClusterId.keys.count > 0, let key = endpointClusterId.keys.first {
            str = key
        }
        let linkedDevicesKey = ESPMatterFabricKeys.shared.groupLinkedDevicesKey(groupId, sourceDeviceId) + ".\(str)"
        let decoder = JSONDecoder()
        var devices = [ESPNodeDetails]()
        if let data = UserDefaults.standard.value(forKey: linkedDevicesKey) as? Data, let linkedDevices = try? decoder.decode([ESPNodeDetails].self, from: data), linkedDevices.count > 0 {
            for device in linkedDevices {
                if let matterNodeID = device.getMatterNodeId(), let id = matterNodeID.hexToDecimal, id == deviceId {
                    continue
                }
                devices.append(device)
            }
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(devices) {
                UserDefaults.standard.set(data, forKey: linkedDevicesKey)
            }
        }
    }
    
    /// Remove device from unlinked devices list
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    func removeDeviceFromUnlinkedDevices(groupId: String, sourceDeviceId: UInt64, deviceId: UInt64, endpointClusterId: [String: Any]?) {
        var str = ""
        if let endpointClusterId = endpointClusterId, endpointClusterId.keys.count > 0, let key = endpointClusterId.keys.first {
            str = key
        }
        let unlinkedDevicesKey = ESPMatterFabricKeys.shared.groupUnlinkedDevicesKey(groupId, sourceDeviceId) + ".\(str)"
        let decoder = JSONDecoder()
        var devices = [ESPNodeDetails]()
        if let data = UserDefaults.standard.value(forKey: unlinkedDevicesKey) as? Data, let unlinkedDevices = try? decoder.decode([ESPNodeDetails].self, from: data), unlinkedDevices.count > 0 {
            for device in unlinkedDevices {
                if let matterNodeID = device.getMatterNodeId(), let id = matterNodeID.hexToDecimal, id == deviceId {
                    continue
                }
                devices.append(device)
            }
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(devices) {
                UserDefaults.standard.set(data, forKey: unlinkedDevicesKey)
            }
        }
    }
}
