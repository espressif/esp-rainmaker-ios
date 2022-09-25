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
//  ESPOTAUpdate.swift
//  ESPRainMaker
//

import Foundation

struct ESPOTAUpdate: Codable {
    let status: String
    let otaAvailable: Bool
    let otaStatusDescription, fwVersion, otaJobID: String?
    let fileSize: Int?

    enum CodingKeys: String, CodingKey {
        case status
        case otaAvailable = "ota_available"
        case otaStatusDescription = "description"
        case fwVersion = "fw_version"
        case otaJobID = "ota_job_id"
        case fileSize = "file_size"
    }
}
