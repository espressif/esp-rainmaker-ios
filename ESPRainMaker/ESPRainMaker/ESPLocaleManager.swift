// Copyright 2024 Espressif Systems
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
//  ESPLocaleManager.swift
//  ESPRainMaker
//

import Foundation

class ESPLocaleManager {
    
    static let shared = ESPLocaleManager()
    static let chinaRegionCode = "cn"
    
    var isLocaleChina: Bool {
        if let region = Locale.current.regionCode, region.lowercased() == ESPLocaleManager.chinaRegionCode {
            return true
        }
        return false
    }
    
    /// This returns true if region is set to China Mainland
    /// and WeChat App Id is configured in Configuration.plist.
    var isLocaleChinaWithWeChatConfigured: Bool {
        if isLocaleChina, Configuration.shared.weChatServiceConfiguration.appId.count > 0 {
            return true
        }
        return false
    }
    
    /// This returns true if region is set to China Mainland
    /// and JPushService App Key is configured in Configuration.plist.
    var isLocaleChinaWithAuroraConfigured: Bool {
        if isLocaleChina, Configuration.shared.jPushServiceConfiguration.appKey.count > 0 {
            return true
        }
        return false
    }
}
