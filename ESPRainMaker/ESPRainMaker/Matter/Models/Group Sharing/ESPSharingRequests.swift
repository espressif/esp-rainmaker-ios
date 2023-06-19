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
//  ESPSharingRequest.swift
//  ESPRainMaker
//

import Foundation

struct ESPNodeGroupSharingRequest: Codable {
    
    var requestId: String?
    var requestStatus: String?
    var requestTimestamp: Int?
    var groupId: String?
    var sharedWith: String?
    var sharedBy: String?
    var groupName: String?
}

struct ESPSharingRequests: Codable {
    
    var sharingRequests: [ESPSharingRequest]?
    
    enum CodingKeys: String, CodingKey {
        case sharingRequests = "sharing_requests"
    }
}

struct ESPSharingRequest: Codable {
    
    var requestId: String?
    var requestStatus: String?
    var requestTimestamp: Int?
    var groupIds: [String]?
    var sharedWith: String?
    var sharedBy: String?
    var metadata: [String: Any]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        requestId = try container.decode(String.self, forKey: .requestId)
        requestStatus = try container.decodeIfPresent(String.self, forKey: .requestStatus)
        requestTimestamp = try container.decodeIfPresent(Int.self, forKey: .requestTimestamp)
        groupIds = try container.decodeIfPresent([String].self, forKey: .groupIds)
        sharedWith = try container.decodeIfPresent(String.self, forKey: .sharedWith)
        sharedBy = try container.decodeIfPresent(String.self, forKey: .sharedBy)
        if let meta = try? container.decode([String: Any].self, forKey: .metadata) {
            metadata = meta
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case requestStatus = "request_status"
        case requestTimestamp = "request_timestamp"
        case groupIds = "group_ids"
        case sharedWith = "user_name"
        case sharedBy = "primary_user_name"
        case metadata = "metadata"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(requestId, forKey: .requestId)
        try container.encode(requestStatus, forKey: .requestStatus)
        try container.encode(requestTimestamp, forKey: .requestTimestamp)
        try container.encode(groupIds, forKey: .groupIds)
        try container.encode(sharedWith, forKey: .sharedWith)
        try container.encode(sharedBy, forKey: .sharedBy)
        if let metadata = metadata, let data = try? JSONSerialization.data(withJSONObject: metadata, options: []) {
            try container.encode(data, forKey: .metadata)
        }
    }
}
