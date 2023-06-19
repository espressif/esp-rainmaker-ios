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
//  ESPAddNodeToFabricResponse.swift
//  ESPRainMaker
//

import Foundation

/// Add node to matter fabric response
struct ESPAddNodeToFabricResponse: Codable {
    
    var requestId: String?
    var status: String?
    var certificates: [ESPNodeCertificates]?
    var description: String?
    
    enum CodingKeys: String, CodingKey {
        case certificates = "certificates"
        case requestId = "request_id"
        case status = "status"
        case description = "description"
    }
}

