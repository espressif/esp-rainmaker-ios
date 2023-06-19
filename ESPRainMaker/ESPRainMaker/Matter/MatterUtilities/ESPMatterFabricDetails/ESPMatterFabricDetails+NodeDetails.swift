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
//  ESPMatterFabricDetails+NodeDetails.swift
//  ESPRainmaker
//

import Foundation

extension ESPMatterFabricDetails {
    
    /// Save add node to matter fabric details in UserDefaults
    /// - Parameters:
    ///   - groupId: groupId
    ///   - deviceId: deviceId
    ///   - data: ESPAddNodeToFabricResponse instance
    func saveAddNodeToMatterFabricDetails(groupId: String, deviceId: UInt64, data: ESPAddNodeToFabricResponse) {
        let encoder = JSONEncoder()
        if let groupData = try? encoder.encode(data) {
            let key = ESPMatterFabricKeys.shared.addNodeToFabricDataKey(groupId, deviceId)
            UserDefaults.standard.set(groupData, forKey: key)
        }
    }
    
    /// Get add node to matter fabric details
    /// - Parameters:
    ///   - groupId: groupId
    ///   - deviceId: deviceId
    /// - Returns: ESPAddNodeToFabricResponse optional instances
    func getAddNodeToMatterFabricDetails(groupId: String, deviceId: UInt64) -> ESPAddNodeToFabricResponse? {
        let key = ESPMatterFabricKeys.shared.addNodeToFabricDataKey(groupId, deviceId)
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: key) as? Data, let value = try? decoder.decode(ESPAddNodeToFabricResponse.self, from: data) {
            return value
        }
        return nil
    }
    
    /// Remove add node to matter fabric details in UserDefaults
    /// - Parameters:
    ///   - groupId: groupId
    ///   - deviceId: deviceId
    ///   - data: ESPAddNodeToFabricResponse instance
    func removeAddNodeToMatterFabricDetails(groupId: String, deviceId: UInt64) {
        let key = ESPMatterFabricKeys.shared.addNodeToFabricDataKey(groupId, deviceId)
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    /// Save add node to matter fabric details in UserDefaults
    /// - Parameters:
    ///   - groupId: groupId
    ///   - deviceId: deviceId
    ///   - data: ESPAddNodeToFabricResponse instance
    func saveAddNodeToMatterFabricDetailsMatterNodeId(groupId: String, matterNodeId: String, data: ESPAddNodeToFabricResponse) {
        let encoder = JSONEncoder()
        if let groupData = try? encoder.encode(data) {
            let key = ESPMatterFabricKeys.shared.addNodeToFabricMatterNodeIdDataKey(groupId, matterNodeId)
            UserDefaults.standard.set(groupData, forKey: key)
        }
    }
    
    /// Get add node to matter fabric details
    /// - Parameters:
    ///   - groupId: groupId
    ///   - deviceId: deviceId
    /// - Returns: ESPAddNodeToFabricResponse optional instances
    func getAddNodeToMatterFabricDetailsMatterNodeId(groupId: String, matterNodeId: String) -> ESPAddNodeToFabricResponse? {
        let key = ESPMatterFabricKeys.shared.addNodeToFabricMatterNodeIdDataKey(groupId, matterNodeId)
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: key) as? Data, let value = try? decoder.decode(ESPAddNodeToFabricResponse.self, from: data) {
            return value
        }
        return nil
    }
    
    /// Export data from device id used during commissioning to matter node id
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id used for commissioning
    ///   - matterNodeId: matter node id from cloud
    func exportData(groupId: String, temporaryDeviceId: UInt64, matterNodeId: String) {
        if let data = getAddNodeToMatterFabricDetails(groupId: groupId, deviceId: temporaryDeviceId) {
            saveAddNodeToMatterFabricDetailsMatterNodeId(groupId: groupId, matterNodeId: matterNodeId, data: data)
            if let id = matterNodeId.hexToDecimal {
                if ESPMatterFabricDetails.shared.getRainmakerType(groupId: groupId, deviceId: temporaryDeviceId) {
                    ESPMatterFabricDetails.shared.saveRainmakerType(groupId: groupId, deviceId: id, val: ESPMatterConstants.trueFlag)
                }
            }
            removeAddNodeToMatterFabricDetails(groupId: groupId, deviceId: temporaryDeviceId)
        }
    }
    
    /// Save device name against device
    /// - Parameters:
    ///   - groupId: group id
    ///   - matterNodeId: matter node id
    func saveDeviceName(groupId: String, matterNodeId: String) {
        if let deviceName = ESPMatterEcosystemInfo.shared.getDeviceName() {
            let key = ESPMatterFabricKeys.shared.deviceNameKey(groupId, matterNodeId)
            UserDefaults.standard.set(deviceName, forKey: key)
        }
    }
    
    /// Save device name against device
    /// - Parameters:
    ///   - groupId: group id
    ///   - matterNodeId: matter node id
    func saveDeviceName(groupId: String, matterNodeId: String, deviceName: String) {
        let key = ESPMatterFabricKeys.shared.deviceNameKey(groupId, matterNodeId)
        UserDefaults.standard.set(deviceName, forKey: key)
    }
    
    func getDeviceName(groupId: String, matterNodeId: String) -> String? {
        let key = ESPMatterFabricKeys.shared.deviceNameKey(groupId, matterNodeId)
        if let deviceName = UserDefaults.standard.value(forKey: key) as? String {
            return deviceName
        }
        return nil
    }
}
