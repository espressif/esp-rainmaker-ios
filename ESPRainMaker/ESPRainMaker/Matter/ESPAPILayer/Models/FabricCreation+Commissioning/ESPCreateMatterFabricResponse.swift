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
//  ESPCreateMatterFabricResponse.swift
//  ESPRainMaker
//

import Foundation

/// Create matter fabric API
struct ESPCreateMatterFabricResponse: Codable {
    
    var groupId: String?
    var fabricId: String?
    var rootCACertificate: String?
    var rootCAPrivateKey: String?
    var userNOC: String?
    var userPrivateKey: String?
    var matterUserId: String?
    var catIdAdmin: String?
    var catIdOperate: String?
    var status: String?
    var ipk: String?
    
    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case fabricId = "fabric_id"
        case rootCACertificate = "root_ca"
        case userNOC = "user_noc"
        case userPrivateKey = "user_private_key"
        case matterUserId = "matter_user_id"
        case catIdAdmin = "group_cat_id_admin"
        case catIdOperate = "group_cat_id_operate"
        case status = "status"
        case ipk
    }
}
