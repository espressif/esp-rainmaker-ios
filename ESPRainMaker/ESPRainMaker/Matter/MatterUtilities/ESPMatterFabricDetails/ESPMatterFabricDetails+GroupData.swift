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
//  ESPMatterFabricDetails+GroupData.swift
//  ESPRainmaker
//

import Foundation

extension ESPMatterFabricDetails {
    
    /// Add request created
    /// - Parameters:
    ///   - groupId: group id
    ///   - requestId: request id
    func addRequestCreated(groupId: String, _ requestId: String) {
        let key = "sharing.requests.created.\(groupId)"
        if var json = UserDefaults.standard.value(forKey: key) as? [String] {
            if !json.contains(requestId) {
                json.append(requestId)
                UserDefaults.standard.set(json, forKey: key)
            }
        } else {
            UserDefaults.standard.set([requestId], forKey: key)
        }
    }
    
    /// Get created requests
    /// - Parameter groupId: group id
    /// - Returns: [request ids]]
    func getRequestsCreated(groupId: String) -> [String]? {
        let key = "sharing.requests.created.\(groupId)"
        if let json = UserDefaults.standard.value(forKey: key) as? [String] {
            return json
        }
        return nil
    }
}
