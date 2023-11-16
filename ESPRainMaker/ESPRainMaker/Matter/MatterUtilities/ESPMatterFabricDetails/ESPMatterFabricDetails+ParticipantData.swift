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
//  ESPMatterFabricDetails+ParticipantData.swift
//  ESPRainmaker
//

import Foundation

struct ESPParticipantData: Codable {
    var name: String?
    var companyName: String?
    var email: String?
    var contact: String?
    var eventName: String?
}

extension ESPMatterFabricDetails {
    
    
    /// Save participants data
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - participantData: participant's data
    func saveParticipantData(groupId: String, deviceId: UInt64, participantData: ESPParticipantData) {
        let key = ESPMatterFabricKeys.shared.participantDataKey(groupId, deviceId)
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(participantData) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    /// Fetch participant's data
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: participants data
    func fetchParticipantData(groupId: String, deviceId: UInt64) -> ESPParticipantData? {
        let key = ESPMatterFabricKeys.shared.participantDataKey(groupId, deviceId)
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: key) as? Data, let participantData = try? decoder.decode(ESPParticipantData.self, from: data) {
            return participantData
        }
        return nil
    }
}

