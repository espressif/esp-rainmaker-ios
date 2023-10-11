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
//  ESPMatterFabricDetails+ClustersData.swift
//  ESPRainmaker
//

import Foundation
import UIKit

extension ESPMatterFabricDetails {
    
    /// Save device type
    /// - Parameters:
    ///   - deviceId: device id
    ///   - type: device type
    func saveDeviceType(groupId: String, deviceId: UInt64, type: Int64) {
        let key = ESPMatterFabricKeys.shared.groupDeviceTypeKey(groupId, deviceId)
        UserDefaults.standard.set(type, forKey: key)
    }
    
    /// Save device type
    /// - Parameters:
    ///   - deviceId: device id
    ///   - type: device type
    func getDeviceType(groupId: String, deviceId: UInt64) -> Int64? {
        let key = ESPMatterFabricKeys.shared.groupDeviceTypeKey(groupId, deviceId)
        if let value = UserDefaults.standard.value(forKey: key) as? Int64 {
            return value
        }
        return nil
    }
    
    /// Set rainmaker type
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - val: val
    func saveRainmakerType(groupId: String, deviceId: UInt64, val: String) {
        let key = ESPMatterFabricKeys.shared.groupDeviceRainmakerTypeKey(groupId, deviceId)
        UserDefaults.standard.set(val, forKey: key)
    }
    
    /// Get rainmaker type
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: val
    func isMatterType(groupId: String, deviceId: UInt64) -> Bool {
        let key = ESPMatterFabricKeys.shared.groupDeviceRainmakerTypeKey(groupId, deviceId)
        if let _ = UserDefaults.standard.value(forKey: key) as? String {
            return true
        }
        return false
    }
    
    /// Get rainmaker type
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: val
    func getRainmakerType(groupId: String, deviceId: UInt64) -> Bool {
        let key = ESPMatterFabricKeys.shared.groupDeviceRainmakerTypeKey(groupId, deviceId)
        if let val = UserDefaults.standard.value(forKey: key) as? String, val.lowercased() == ESPMatterConstants.trueFlag {
            return true
        }
        return false
    }
    
    /// Save all endpoints data
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoints: endpoints
    func saveEndpointsData(groupId: String, deviceId: UInt64, endpoints: [UInt]) {
        let key = ESPMatterFabricKeys.shared.groupEndpointsDataKey(groupId, deviceId)
        if let data = try? JSONSerialization.data(withJSONObject: endpoints) {
            UserDefaults.standard.set(data as Any, forKey: key)
        }
    }
    
    /// Fetch endpoints data
    /// - Parameter deviceId: device id
    /// - Returns: all endpoints array
    func fetchEndpointsData(groupId: String, deviceId: UInt64) -> [UInt] {
        let key = ESPMatterFabricKeys.shared.groupEndpointsDataKey(groupId, deviceId)
        if let data = UserDefaults.standard.value(forKey: key) as? Data, let val = try? JSONSerialization.jsonObject(with: data) as? [UInt] {
            return val
        }
        return [0]
    }
    
    /// Save clients data
    /// - Parameters:
    ///   - deviceId: device id
    ///   - clients: [endpoint: [clients]]
    func saveClientsData(groupId: String, deviceId: UInt64, clients: [String: [UInt]]) {
        let key = ESPMatterFabricKeys.shared.groupClientsDataKey(groupId, deviceId)
        if let data = try? JSONSerialization.data(withJSONObject: clients) {
            UserDefaults.standard.set(data as Any, forKey: key)
        }
    }
    
    /// Fetch all clients data
    /// - Parameter deviceId: device id
    /// - Returns: [endpoint: [clients]]
    func fetchClientsData(groupId: String, deviceId: UInt64) -> [String: [UInt]] {
        let key = ESPMatterFabricKeys.shared.groupClientsDataKey(groupId, deviceId)
        if let data = UserDefaults.standard.value(forKey: key) as? Data, let val = try? JSONSerialization.jsonObject(with: data) as? [String: [UInt]] {
            return val
        }
        return [String: [UInt]]()
    }
    
    /// Save servers data
    /// - Parameters:
    ///   - deviceId: device id
    ///   - servers: servers
    func saveServersData(groupId: String, deviceId: UInt64, servers: [String: [UInt]]) {
        let key = ESPMatterFabricKeys.shared.groupServersDataKey(groupId, deviceId)
        if let data = try? JSONSerialization.data(withJSONObject: servers) {
            UserDefaults.standard.set(data as Any, forKey: key)
        }
    }
    
    /// fetch servers data
    /// - Parameter deviceId: device id
    /// - Returns: [endpoints: [servers]]
    func fetchServersData(groupId: String, deviceId: UInt64) -> [String: [UInt]] {
        let key = ESPMatterFabricKeys.shared.groupServersDataKey(groupId, deviceId)
        if let data = UserDefaults.standard.value(forKey: key) as? Data, let val = try? JSONSerialization.jsonObject(with: data) as? [String: [UInt]] {
            return val
        }
        return [String: [UInt]]()
    }
    
    /// Save vendor id
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - vendorId: vendor id
    func saveVendorId(groupId: String, deviceId: UInt64, vendorId: Int) {
        let key = ESPMatterFabricKeys.shared.groupVendorIdKey(groupId, deviceId)
        UserDefaults.standard.set(vendorId as Any, forKey: key)
    }
    
    /// Get vendor id
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: vendor id
    func getVendorId(groupId: String, deviceId: UInt64) -> Int? {
        let key = ESPMatterFabricKeys.shared.groupVendorIdKey(groupId, deviceId)
        if let vid = UserDefaults.standard.value(forKey: key) as? Int {
            return vid
        }
        return nil
    }
    
    /// Save product id
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - productId: product id
    func saveProductId(groupId: String, deviceId: UInt64, productId: Int) {
        let key = ESPMatterFabricKeys.shared.groupProductIdKey(groupId, deviceId)
        UserDefaults.standard.set(productId as Any, forKey: key)
    }
    
    /// Get product id
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: product id
    func getProductId(groupId: String, deviceId: UInt64) -> Int? {
        let key = ESPMatterFabricKeys.shared.groupProductIdKey(groupId, deviceId)
        if let pid = UserDefaults.standard.value(forKey: key) as? Int {
            return pid
        }
        return nil
    }
    
    /// Save software version
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - softwareVersion: software version
    func saveSoftwareVersion(groupId: String, deviceId: UInt64, softwareVersion: Int) {
        let key = ESPMatterFabricKeys.shared.groupSwVersionKey(groupId, deviceId)
        UserDefaults.standard.set(softwareVersion as Any, forKey: key)
    }
    
    /// Get software version
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: software version
    func getSoftwareVersion(groupId: String, deviceId: UInt64) -> Int? {
        let key = ESPMatterFabricKeys.shared.groupSwVersionKey(groupId, deviceId)
        if let sw = UserDefaults.standard.value(forKey: key) as? Int {
            return sw
        }
        return nil
    }
    
    /// Save device serial number
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - softwareVersion: serial number
    func saveSerialNumber(groupId: String, deviceId: UInt64, serialNumber: String) {
        let key = ESPMatterFabricKeys.shared.groupSerialNumberKey(groupId, deviceId)
        UserDefaults.standard.set(serialNumber as Any, forKey: key)
    }
    
    /// Get serial number
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: serial number
    func getSerialNumber(groupId: String, deviceId: UInt64) -> String? {
        let key = ESPMatterFabricKeys.shared.groupSerialNumberKey(groupId, deviceId)
        if let sw = UserDefaults.standard.value(forKey: key) as? String {
            return sw
        }
        return nil
    }
    
    /// Save device serial number
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - softwareVersion: serial number
    func saveManufacturerName(groupId: String, deviceId: UInt64, manufacturerName: String) {
        let key = ESPMatterFabricKeys.shared.groupManufacturerNameKey(groupId, deviceId)
        UserDefaults.standard.set(manufacturerName as Any, forKey: key)
    }
    
    /// Get serial number
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: serial number
    func getManufacturerName(groupId: String, deviceId: UInt64) -> String? {
        let key = ESPMatterFabricKeys.shared.groupManufacturerNameKey(groupId, deviceId)
        if let manufacturerName = UserDefaults.standard.value(forKey: key) as? String {
            return manufacturerName
        }
        return nil
    }
    
    /// Save product name
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - softwareVersion: serial number
    func saveProductName(groupId: String, deviceId: UInt64, productName: String) {
        let key = ESPMatterFabricKeys.shared.groupProductNameKey(groupId, deviceId)
        UserDefaults.standard.set(productName as Any, forKey: key)
    }
    
    /// Get serial number
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: serial number
    func getProductName(groupId: String, deviceId: UInt64) -> String? {
        let key = ESPMatterFabricKeys.shared.groupProductNameKey(groupId, deviceId)
        if let productName = UserDefaults.standard.value(forKey: key) as? String {
            return productName
        }
        return nil
    }
    
    /// Remove all clusters data
    /// - Parameters:
    ///   - groupId: group ud
    ///   - deviceId: device id
    func removeAllClusterData(groupId: String, deviceId: UInt64) {
        let groupServersDataKey = ESPMatterFabricKeys.shared.groupServersDataKey(groupId, deviceId)
        let groupClientsDataKey = ESPMatterFabricKeys.shared.groupClientsDataKey(groupId, deviceId)
        let groupEndpointsDataKey = ESPMatterFabricKeys.shared.groupEndpointsDataKey(groupId, deviceId)
        UserDefaults.standard.removeObject(forKey: groupServersDataKey)
        UserDefaults.standard.removeObject(forKey: groupClientsDataKey)
        UserDefaults.standard.removeObject(forKey: groupEndpointsDataKey)
    }
    
    /// Save metadata
    /// - Parameters:
    ///   - metadata: metadata
    ///   - groupId: group id
    ///   - matterNodeId: matter node id
    func saveMetadata(details: [String: Any], groupId: String, matterNodeId: String) {
        var metadata = details
        if let data = details[ESPMatterConstants.metadata] as? [String: Any] {
            metadata = data
        }
        if let deviceId = matterNodeId.hexToDecimal {
            if let endpointsData = metadata[ESPMatterConstants.endpointsData] as? [UInt] {
                self.saveEndpointsData(groupId: groupId, deviceId: deviceId, endpoints: endpointsData)
            }
            if let clientsData = metadata[ESPMatterConstants.clientsData] as? [String: [UInt]] {
                self.saveClientsData(groupId: groupId, deviceId: deviceId, clients: clientsData)
            }
            if let serversData = metadata[ESPMatterConstants.serversData] as? [String: [UInt]] {
                self.saveServersData(groupId: groupId, deviceId: deviceId, servers: serversData)
            }
            if let isRainmaker = metadata[ESPMatterConstants.isRainmaker] as? Bool, isRainmaker {
                self.saveRainmakerType(groupId: groupId, deviceId: deviceId, val: ESPMatterConstants.trueFlag)
            } else {
                self.saveRainmakerType(groupId: groupId, deviceId: deviceId, val: ESPMatterConstants.falseFlag)
            }
            if let deviceName = metadata[ESPMatterConstants.deviceName] as? String {
                self.saveDeviceName(groupId: groupId, matterNodeId: matterNodeId, deviceName: deviceName)
            }
        }
    }
    
    /// Save controller node id
    /// - Parameters:
    ///   - controllerNodeId: controllerNodeId
    ///   - matterNodeId: matterNodeId
    func saveControllerNodeId(controllerNodeId: String, matterNodeId: String) {
        let key = "controller.node.id.\(matterNodeId)"
        UserDefaults.standard.set(controllerNodeId, forKey: key)
    }
    
    /// Get controller node id
    /// - Parameter matterNodeId: matterNodeId
    /// - Returns: id
    func getControllerNodeId(matterNodeId: String) -> String? {
        let key = "controller.node.id.\(matterNodeId)"
        if let val = UserDefaults.standard.value(forKey: key) as? String {
            return val
        }
        return nil
    }
    
    /// Remove controller node id for matter node id
    /// - Parameter matterNodeId: matter node id
    func removeControllerNodeId(matterNodeId: String) {
        let key = "controller.node.id.\(matterNodeId)"
        if let _ = self.getControllerNodeId(matterNodeId: matterNodeId) {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}


