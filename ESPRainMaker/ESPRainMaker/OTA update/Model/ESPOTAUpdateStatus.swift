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
//  ESPOTAUpdateStatus.swift
//  ESPRainMaker
//

import Foundation

enum ESPOTAStatus: String {
    case triggered = "triggered"
    case inprogress = "in-progress"
    case completed = "completed"
    case success = "success"
    case rejected = "rejected"
    case failed = "failed"
    case unknown = "unknown"
    case started = "started"
}

struct ESPOTAUpdateStatus: Codable {
    let nodeID, status, additionalInfo: String
    let timestamp: Int

    enum CodingKeys: String, CodingKey {
        case nodeID = "node_id"
        case status
        case additionalInfo = "additional_info"
        case timestamp
    }
    
    var otaStatus: ESPOTAStatus {
        return ESPOTAStatus(rawValue: status.lowercased()) ?? .unknown
    }
}

