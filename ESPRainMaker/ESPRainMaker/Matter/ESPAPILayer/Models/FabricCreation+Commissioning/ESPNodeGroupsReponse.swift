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
//  ESPRainMaker
//

import Foundation

/// Get Node groups API Response
class ESPNodeGroups: Codable {
    
    var groups: [ESPNodeGroup]?
    var total: Int?
}

/// Node group API Response
class ESPNodeGroup: Codable {
    
    var groupID, groupName, fabricID: String?
    var isMatter: Bool?
    var total: Int?
    var shouldUpdate: Bool = false
    var oldCatIdAdmin: String?
    var oldCatIdOperate: String?
    var fabricDetails: ESPNodeGroupMatterFabricDetails?

    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case groupName = "group_name"
        case fabricID = "fabric_id"
        case isMatter = "is_matter"
        case fabricDetails = "fabric_details"
        case total
    }
}

/// Fabric details
class ESPNodeGroupMatterFabricDetails: Codable {
    
    var rootCACertificate: String?
    var catIdAdmin: String?
    var catIdOperate: String?
    var matterUserId: String?
    var userCatId: String?
    var ipk: String?
    
    enum CodingKeys: String, CodingKey {
        case rootCACertificate = "root_ca"
        case catIdAdmin = "group_cat_id_admin"
        case catIdOperate = "group_cat_id_operate"
        case matterUserId = "matter_user_id"
        case userCatId = "user_cat_id"
        case ipk
    }
}
