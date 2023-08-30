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
//  ESPMatterFabricDetails.swift
//  ESPRainmaker
//

import Foundation

class ESPMatterFabricDetails {
    
    static let shared: ESPMatterFabricDetails = ESPMatterFabricDetails()
    
    /// Get random nonce
    /// - Returns: nonce value
    func getNonce() -> Data? {
        let s = NSMutableData(length: 32)
        if let s = s {
            _ = SecRandomCopyBytes(kSecRandomDefault, s.length, UnsafeMutableRawPointer(s.mutableBytes))
        }
        return s as? Data
    }
    
    /// Get devices
    /// - Returns: devices
    func getDevices() -> [String] {
        if let devices = UserDefaults.standard.value(forKey: ESPMatterFabricKeys.shared.devicesKey) as? [String], devices.count > 0 {
            return devices
        }
        return []
    }
    
    /// Save matter fabric data
    /// - Parameter data: ESPCreateMatterFabricResponse instance
    func saveMatterFabricData(data: ESPCreateMatterFabricResponse) {
        if let groupId = data.groupId {
            let key = ESPMatterFabricKeys.shared.matterFabricDataKey(groupId)
            let encoder = JSONEncoder()
            if let groupData = try? encoder.encode(data) {
                UserDefaults.standard.set(groupData, forKey: key)
            }
        }
    }
    
    /// Get matter fabric data
    /// - Parameter groupId: matter fabric group Id
    /// - Returns: ESPCreateMatterFabricResponse optional instance
    func getMatterFabricData(groupId: String) -> ESPCreateMatterFabricResponse? {
        let key: String = ESPMatterFabricKeys.shared.matterFabricDataKey(groupId)
        let decoder = JSONDecoder()
        if let groupData = UserDefaults.standard.value(forKey: key) as? Data {
            if let value = try? decoder.decode(ESPCreateMatterFabricResponse.self, from: groupData) {
                return value
            }
        }
        return nil
    }
    
    /// Get device name for device id
    /// - Parameter deviceId: device Id
    /// - Returns: device name
    func getDeviceNameForDeviceId(deviceId: UInt64) -> String? {
        if let dict = UserDefaults.standard.value(forKey: ESPMatterFabricKeys.shared.deviceIdsKey) as? [String: UInt64], dict.count > 0 {
            for key in dict.keys {
                if let id = dict[key], id == deviceId {
                    return key
                }
            }
        }
        return nil
    }
    
    /// Get device id for device name
    /// - Parameter deviceName: name
    /// - Returns: device id
    func getDeviceIdForName(deviceName: String) -> UInt64? {
        if let dict = UserDefaults.standard.value(forKey: ESPMatterFabricKeys.shared.deviceIdsKey) as? [String: UInt64], dict.count > 0 {
            for key in dict.keys {
                if key == deviceName {
                    return dict[key]
                }
            }
        }
        return nil
    }
    
    /// Clear matter device data
    /// - Parameter deviceId: device id
    func clearMatterDeviceData(forDeviceId deviceId: UInt64) {
        UserDefaults.standard.removeObject(forKey: "\(deviceId).endpoints.data")
        UserDefaults.standard.removeObject(forKey: "\(deviceId).clients.data")
        UserDefaults.standard.removeObject(forKey: "\(deviceId).servers.data")
        UserDefaults.standard.removeObject(forKey: "\(deviceId).device.type")
        if let deviceName = self.getDeviceNameForDeviceId(deviceId: deviceId) {
            if let dict = UserDefaults.standard.value(forKey: ESPMatterFabricKeys.shared.deviceIdsKey) as? [String: UInt64], dict.count > 0 {
                if var devices = UserDefaults.standard.value(forKey: ESPMatterFabricKeys.shared.deviceIdsKey) as? [String: Int64], let _ = devices[deviceName] {
                    devices[deviceName] = nil
                    UserDefaults.standard.set(devices, forKey: ESPMatterFabricKeys.shared.deviceIdsKey)
                }
            }
            if let devices = UserDefaults.standard.value(forKey: ESPMatterFabricKeys.shared.devicesKey) as? [String] {
                var tempDevices = devices
                if let index = tempDevices.firstIndex(of: deviceName) {
                    tempDevices.remove(at: index)
                }
                UserDefaults.standard.set(tempDevices, forKey: ESPMatterFabricKeys.shared.devicesKey)
            }
        }
    }
    
    /// Save sharing requests
    /// - Parameter data: sharing requests data
    func saveSharingRequestsSent(data: Data) {
        let key = ESPMatterFabricKeys.shared.sharingRequestsSentKey
        UserDefaults.standard.set(data, forKey: key)
    }
    
    /// Get sharing requests
    /// - Returns: sharing requests
    func getSharingRequestsSent() -> Data? {
        let key = ESPMatterFabricKeys.shared.sharingRequestsSentKey
        if let data = UserDefaults.standard.value(forKey: key) as? Data {
            return data
        }
        return nil
    }
    
    /// Save node group sharing requests
    /// - Parameter data: node group sharing requests data
    func saveNodeGroupSharingRequestsSent(data: Data) {
        let key = ESPMatterFabricKeys.shared.nodeGroupSharingRequestsSentKey
        UserDefaults.standard.set(data, forKey: key)
    }
    
    /// Get node group sharing requests sent
    func getNodeGroupSharingRequestsSent() -> ESPSharingRequests? {
        let key = ESPMatterFabricKeys.shared.nodeGroupSharingRequestsSentKey
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: key) as? Data, let sharingRequests = try? decoder.decode(ESPSharingRequests.self, from: data) {
            return sharingRequests
        }
        return nil
    }
    
    /// Save node group sharing requests
    /// - Parameter data: node group sharing requests data
    func saveNodeGroupSharingRequestsReceived(data: Data) {
        let key = ESPMatterFabricKeys.shared.nodeGroupSharingRequestsReceivedKey
        UserDefaults.standard.set(data, forKey: key)
    }
    
    /// Get node group sharing requests sent
    func getNodeGroupSharingRequestsReceived() -> ESPSharingRequests? {
        let key = ESPMatterFabricKeys.shared.nodeGroupSharingRequestsReceivedKey
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: key) as? Data, let sharingRequests = try? decoder.decode(ESPSharingRequests.self, from: data) {
            return sharingRequests
        }
        return nil
    }
    
    /// Save node group sharing requests
    /// - Parameter data: node group sharing requests data
    func saveNodeGroupSharing(data: Data) {
        let key = ESPMatterFabricKeys.shared.nodeGroupSharingKey
        UserDefaults.standard.set(data, forKey: key)
    }
    
    /// Remove node group sharing
    func removeNodeGroupSharing() {
        let key = ESPMatterFabricKeys.shared.nodeGroupSharingKey
        if let _ = UserDefaults.standard.value(forKey: key) as? Data {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    /// Get node group sharing requests sent
    func getNodeGroupSharing() -> ESPNodeGroupSharings? {
        let key = ESPMatterFabricKeys.shared.nodeGroupSharingKey
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: key) as? Data, let sharingRequests = try? decoder.decode(ESPNodeGroupSharings.self, from: data) {
            return sharingRequests
        }
        return nil
    }
    
    /// Get ipk
    /// - Parameter groupId: group id
    /// - Returns: ipk string
    func getIPK(groupId: String) -> String? {
        if let groupDetails = self.getNodeGroupDetails(groupId: groupId), let groups = groupDetails.groups, let group = groups.last, let details = group.fabricDetails, let ipk = details.ipk {
            return ipk
        }
        return nil
    }
    
    /// Save group metadata
    /// - Parameters:
    ///   - groupId: group id
    ///   - groupMetadata: group metadata
    func saveGroupMetadata(groupId: String, groupMetadata: [String: Any]) {
        let key = "group.metadata.\(groupId)"
        if let data = try? JSONSerialization.data(withJSONObject: groupMetadata) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Get group metadata
    /// - Parameter groupId: group id
    /// - Returns: group metadata
    func getGroupMetadata(groupId: String) -> [String: Any]? {
        let key = "group.metadata.\(groupId)"
        if let data = UserDefaults.standard.object(forKey: key) as? Data, let groupMetadata = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return groupMetadata
        }
        return nil
    }
    
    /// Remove metadata
    /// - Parameter groupId: group id
    func removeGroupMetadata(groupId: String) {
        let key = "group.metadata.\(groupId)"
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    /// Save AWS tokens
    /// - Parameters:
    ///   - cloudResponse: cloud response
    ///   - groupId: group id
    ///   - matterNodeId: matter node id
    func saveAWSTokens(cloudResponse: ESPSessionResponse, groupId: String, matterNodeId: String) {
        let key = "matter.aws.tokens.\(groupId).\(matterNodeId)"
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(cloudResponse) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    /// Get AWS tokens
    /// - Parameters:
    ///   - groupId: group id
    ///   - matterNodeId: matter node id
    /// - Returns: response
    func getAWSTokens(groupId: String, matterNodeId: String) -> ESPSessionResponse? {
        let decoder = JSONDecoder()
        let key = "matter.aws.tokens.\(groupId).\(matterNodeId)"
        if let data = UserDefaults.standard.value(forKey: key) as? Data, let response = try? decoder.decode(ESPSessionResponse.self, from: data) {
            return response
        }
        return nil
    }

}
