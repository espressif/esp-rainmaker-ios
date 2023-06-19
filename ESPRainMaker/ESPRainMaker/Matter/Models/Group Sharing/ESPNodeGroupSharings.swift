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
//  ESPNodeGroupSharings.swift
//  ESPRainMaker
//

import Foundation

struct ESPNodeGroupSharingStruct: Codable {
    
    var groupId: String?
    var sharedWith: String?
    var sharedBy: String?
}

// MARK: - ESPSharedRequests
struct ESPNodeGroupSharings: Codable {
    var groupSharing: [ESPNodeGroupSharing]?

    enum CodingKeys: String, CodingKey {
        case groupSharing = "group_sharing"
    }
}

// MARK: - GroupSharing
struct ESPNodeGroupSharing: Codable {
    var groupID: String?
    var users: ESPUsers?

    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case users
    }
}

// MARK: - ESPSecondaryUsers
struct ESPUsers: Codable {
    var primary: [String]?
    var secondary: [String]?
}
