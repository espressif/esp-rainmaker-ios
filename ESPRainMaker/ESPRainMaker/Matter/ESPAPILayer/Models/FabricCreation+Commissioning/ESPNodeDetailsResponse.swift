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
//  ESPNodeGroupsReponse.swift
//  ESPRainmaker
//

import Foundation

// MARK: - Welcome
struct ESPNodeGroupDetails: Codable {
    var groups: [ESPNodeDetailsGroup]?
}

// MARK: - Group
struct ESPNodeDetailsGroup: Codable {
    var groupID, groupName, fabricID: String?
    var isMatter: Bool?
    var nodeDetails: [ESPNodeDetails]?
    var fabricDetails: ESPFabricDetails?
    let total: Int

    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case groupName = "group_name"
        case fabricID = "fabric_id"
        case isMatter = "is_matter"
        case nodeDetails = "node_details"
        case fabricDetails = "fabric_details"
        case total
    }
}

// MARK: - NodeDetail
class ESPNodeDetails: Codable {
    var nodeID, matterNodeID: String?
    var metadata: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case nodeID = "node_id"
        case matterNodeID = "matter_node_id"
    }
    
    /// Returns matter light status key
    var matterLightStatusKey: (UInt64) -> String = { deviceId in
        return "\(deviceId).matter.light.status"
    }
    
    /// Returns matter light status key
    var matterLevelValueKey: (UInt64) -> String = { deviceId in
        return "\(deviceId).matter.level.value"
    }
    
    /// Returns matter light status key
    var matterHueValueKey: (UInt64) -> String = { deviceId in
        return "\(deviceId).matter.hue.value"
    }
    
    /// Returns matter light status key
    var matterSaturationValueKey: (UInt64) -> String = { deviceId in
        return "\(deviceId).matter.saturation.value"
    }
    
    /// Device id
    var deviceId: UInt64? {
        if let matterNodeID = matterNodeID, let deviceId = matterNodeID.hexToDecimal {
            return deviceId
        }
        return nil
    }
    
    /// Set matter light on/off status
    /// - Parameters:
    ///   - status: status
    ///   - matterNodeId: matter node id
    func setMatterLightOnStatus(status: Bool, deviceId: UInt64) {
        UserDefaults.standard.set(status, forKey: matterLightStatusKey(deviceId))
    }
    
    /// Get matter light on/off status
    /// - Parameter matterNodeId: matter node id
    /// - Returns: status
    func isMatterLightOn(deviceId: UInt64) -> Bool? {
        if let status = UserDefaults.standard.value(forKey: matterLightStatusKey(deviceId)) as? Bool {
            return status
        }
        return nil
    }
    
    /// Set matter level
    /// - Parameters:
    ///   - level: level
    ///   - deviceId: device id
    func setMatterLevelValue(level: Int, deviceId: UInt64) {
        UserDefaults.standard.set(level, forKey: matterLevelValueKey(deviceId))
    }
    
    /// Get matter level value
    /// - Parameter deviceId: device id
    /// - Returns: value
    func getMatterLevelValue(deviceId: UInt64) -> Int? {
        if let value = UserDefaults.standard.value(forKey: matterLevelValueKey(deviceId)) as? Int {
            return value
        }
        return nil
    }
    
    /// Set matter hue value
    /// - Parameters:
    ///   - hue: hue
    ///   - deviceId: device id
    func setMatterHueValue(hue: Int, deviceId: UInt64) {
        UserDefaults.standard.set(hue, forKey: matterHueValueKey(deviceId))
    }
    
    /// Gte matter hue value
    /// - Parameter deviceId: device id
    /// - Returns: heu value
    func getMatterHueValue(deviceId: UInt64) -> Int? {
        if let value = UserDefaults.standard.value(forKey: matterHueValueKey(deviceId)) as? Int {
            return value
        }
        return nil
    }
    
    /// Set saturation value
    /// - Parameters:
    ///   - level: level value
    ///   - deviceId: device id
    func setMatterSaturationValue(saturation: Int, deviceId: UInt64) {
        UserDefaults.standard.set(saturation, forKey: matterSaturationValueKey(deviceId))
    }
    
    /// Get matter saturation value
    /// - Parameter deviceId: device id
    /// - Returns: saturation value
    func getMatterSaturationValue(deviceId: UInt64) -> Int? {
        if let saturation = UserDefaults.standard.value(forKey: matterSaturationValueKey(deviceId)) as? Int {
            return saturation
        }
        return nil
    }
    
    /// Returns matter local temperature key
    var matterLocalTempKey: (UInt64) -> String = { deviceId in
        return "\(deviceId).matter.local.temperature.value"
    }
    
    /// Returns matter light status key
    var matterOCSValueKey: (UInt64) -> String = { deviceId in
        return "\(deviceId).matter.ocs.value"
    }
    
    /// Returns matter light status key
    var matterOHSValueKey: (UInt64) -> String = { deviceId in
        return "\(deviceId).matter.ohs.value"
    }
    
    /// Returns matter light status key
    var matterControlSequenceOfOperationKey: (UInt64) -> String = { deviceId in
        return "\(deviceId).matter.control.sequence.operation.value"
    }
    
    /// Returns matter light status key
    var matterSystemModeKey: (UInt64) -> String = { deviceId in
        return "\(deviceId).matter.system.mode.value"
    }
    
    /// Set saturation value
    /// - Parameters:
    ///   - level: level value
    ///   - deviceId: device id
    func setMatterLocalTemperatureValue(temperature: Int16, deviceId: UInt64) {
        UserDefaults.standard.set(temperature, forKey: matterLocalTempKey(deviceId))
    }
    
    /// Get matter saturation value
    /// - Parameter deviceId: device id
    /// - Returns: saturation value
    func getMatterLocalTemperatureValue(deviceId: UInt64) -> Int16? {
        if let temperature = UserDefaults.standard.value(forKey: matterLocalTempKey(deviceId)) as? Int16 {
            return temperature
        }
        return nil
    }
    
    /// Set matter occupied cooling setpoint value
    /// - Parameters:
    ///   - ocs: occupied cooling setpoint
    ///   - deviceId: device id
    func setMatterOccupiedCoolingSetpoint(ocs: Int16, deviceId: UInt64) {
        UserDefaults.standard.set(ocs, forKey: matterOCSValueKey(deviceId))
    }
    
    /// Get matter occupied cooling setpoint value
    /// - Parameter deviceId: device id
    /// - Returns: saturation value
    func getMatterOccupiedCoolingSetpoint(deviceId: UInt64) -> Int16? {
        if let ocs = UserDefaults.standard.value(forKey: matterOCSValueKey(deviceId)) as? Int16 {
            return ocs
        }
        return nil
    }
    
    /// Set matter occupied cooling setpoint value
    /// - Parameters:
    ///   - ocs: occupied cooling setpoint
    ///   - deviceId: device id
    func setMatterOccupiedHeatingSetpoint(ohs: Int16, deviceId: UInt64) {
        UserDefaults.standard.set(ohs, forKey: matterOHSValueKey(deviceId))
    }
    
    /// Get matter occupied cooling setpoint value
    /// - Parameter deviceId: device id
    /// - Returns: saturation value
    func getMatterOccupiedHeatingSetpoint(deviceId: UInt64) -> Int16? {
        if let ohs = UserDefaults.standard.value(forKey: matterOHSValueKey(deviceId)) as? Int16 {
            return ohs
        }
        return nil
    }
    
    /// Set matter controlled sequence of operation value
    /// - Parameters:
    ///   - ocs: occupied cooling setpoint
    ///   - deviceId: device id
    func setMatterControlledSequenceOfOperation(cso: String, deviceId: UInt64) {
        UserDefaults.standard.set(cso, forKey: matterControlSequenceOfOperationKey(deviceId))
    }
    
    /// Get matter occupied cooling setpoint value
    /// - Parameter deviceId: device id
    /// - Returns: saturation value
    func getMatterControlledSequenceOfOperation(deviceId: UInt64) -> String? {
        if let cso = UserDefaults.standard.value(forKey: matterControlSequenceOfOperationKey(deviceId)) as? String {
            return cso
        }
        return nil
    }
    
    /// Set matter system mode
    /// - Parameters:
    ///   - ocs: occupied cooling setpoint
    ///   - deviceId: device id
    func setMatterSystemMode(systemMode: String, deviceId: UInt64) {
        UserDefaults.standard.set(systemMode, forKey: matterControlSequenceOfOperationKey(deviceId))
    }
    
    /// Get matter system mode
    /// - Parameter deviceId: device id
    /// - Returns: saturation value
    func getMatterSystemMode(deviceId: UInt64) -> String? {
        if let systemMode = UserDefaults.standard.value(forKey: matterControlSequenceOfOperationKey(deviceId)) as? String {
            return systemMode
        }
        return nil
    }
    
    /// Get rainmaker node
    /// - Returns: node
    func getRainmakerNode() -> Node? {
        if let nodes = User.shared.associatedNodeList {
            for node in nodes {
                if let id = self.nodeID, let nodeId = node.node_id, id == nodeId {
                    return node
                }
            }
        }
        return nil
    }
}

// MARK: - Fabric Details
class ESPFabricDetails: Codable {
    var rootCA: String?
    var groupCATIdAdmin: String?
    var groupCATIdOperate: String?
    var matterUserId: String?
    var userCATId: String?
    var ipk: String?
    
    enum CodingKeys: String, CodingKey {
        case rootCA = "root_ca"
        case groupCATIdAdmin = "group_cat_id_admin"
        case groupCATIdOperate = "group_cat_id_operate"
        case matterUserId = "matter_user_id"
        case userCATId = "user_cat_id"
        case ipk
    }
}
