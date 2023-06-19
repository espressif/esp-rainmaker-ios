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
//  ESPMatterFabricDetails+UserNOCDetails.swift
//  ESPRainmaker
//

import Foundation

extension ESPMatterFabricDetails {
    
    /// Save user NOC fabric details in UserDefaults
    /// - Parameters:
    ///   - groupId: groupId
    ///   - data: ESPIssueUserNOCResponse instance
    func saveUserNOCDetails(groupId: String, data: ESPIssueUserNOCResponse) {
        let encoder = JSONEncoder()
        if let groupData = try? encoder.encode(data) {
            let key = ESPMatterFabricKeys.shared.userNOCKey(groupId)
            UserDefaults.standard.set(groupData, forKey: key)
        }
    }
    
    /// Get user noc details
    /// - Parameter groupId: group id
    /// - Returns: issue user NOC data
    func getUserNOCDetails(groupId: String) -> ESPIssueUserNOCResponse? {
        let key = ESPMatterFabricKeys.shared.userNOCKey(groupId)
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: key) as? Data, let userNOCData = try? decoder.decode(ESPIssueUserNOCResponse.self, from: data) {
            return userNOCData
        }
        return nil
    }
    
    /// Remove user noc details
    /// - Parameter groupId: group id
    func removeUserNOCDetails(groupId: String) {
        let key = ESPMatterFabricKeys.shared.userNOCKey(groupId)
        UserDefaults.standard.removeObject(forKey: key)
    }
}
