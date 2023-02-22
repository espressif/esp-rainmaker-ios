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
//  ESPOTAConstants.swift
//  ESPRainMaker
//

import Foundation

struct ESPOTAConstants {
    static let otaUpdateURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/ota_update"
    static let otaStatusURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/ota_status"
    
    // API keys
    static let nodeIDKey = "node_id"
    static let otaJobIDKey = "ota_job_id"
}
