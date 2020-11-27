// Copyright 2020 Espressif Systems
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
//  ESPProvSettings.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation

struct ESPProvSettings {
    var securityMode: ESPSecurity
    var allowPrefixSearch: Bool

    init() {
        // Assign default values
        allowPrefixSearch = true
        securityMode = .secure

        if let settingInfo = Bundle.main.infoDictionary?["ESP Provision Setting"] as? [String: String] {
            if let allowPrefix = settingInfo["ESP Allow Prefix Search"] {
                allowPrefixSearch = allowPrefix.lowercased() == "no" ? false : true
            }
            if let securityModeVal = settingInfo["ESP Securtiy Mode"] {
                securityMode = securityModeVal.lowercased() == "unsecure" ? .unsecure : .secure
            }
        }
    }
}
