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
