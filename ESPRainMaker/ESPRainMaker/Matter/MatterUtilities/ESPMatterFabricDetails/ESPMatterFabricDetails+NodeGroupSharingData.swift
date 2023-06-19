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
//  ESPMatterFabricDetails+NodeGroupSharingData.swift
//  ESPRainmaker
//

import Foundation

extension ESPMatterFabricDetails {
    
    //MARK: acceptedSharings
    func saveAcceptedSharings(acceptedSharings: [ESPNodeGroupSharingStruct]) {
        if acceptedSharings.count > 0 {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(acceptedSharings) {
                UserDefaults.standard.set(data, forKey: ESPMatterConstants.acceptedSharings)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: ESPMatterConstants.acceptedSharings)
        }
    }
    
    func fetchAcceptedSharings() -> [ESPNodeGroupSharingStruct] {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: ESPMatterConstants.acceptedSharings) as? Data, let acceptedSharings = try? decoder.decode([ESPNodeGroupSharingStruct].self, from: data) {
            return acceptedSharings
        }
        return []
    }
    
    //MARK: pendingNodeGroupRequests
    func savePendingNodeGroupRequests(pendingNodeGroupRequests: [ESPNodeGroupSharingRequest]) {
        if pendingNodeGroupRequests.count > 0 {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(pendingNodeGroupRequests) {
                UserDefaults.standard.set(data, forKey: ESPMatterConstants.pendingNodeGroupRequests)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: ESPMatterConstants.pendingNodeGroupRequests)
        }
    }
    
    func fetchPendingNodeGroupRequests() -> [ESPNodeGroupSharingRequest] {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: ESPMatterConstants.pendingNodeGroupRequests) as? Data, let pendingNodeGroupRequests = try? decoder.decode([ESPNodeGroupSharingRequest].self, from: data) {
            return pendingNodeGroupRequests
        }
        return []
    }
    
    //MARK: requestsSent
    func saveRequestsSent(requestsSent: [ESPNodeGroupSharingRequest]) {
        if requestsSent.count > 0 {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(requestsSent) {
                UserDefaults.standard.set(data, forKey: ESPMatterConstants.requestsSent)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: ESPMatterConstants.requestsSent)
        }
    }
    
    func fetchRequestsSent() -> [ESPNodeGroupSharingRequest] {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: ESPMatterConstants.requestsSent) as? Data, let requestsSent = try? decoder.decode([ESPNodeGroupSharingRequest].self, from: data) {
            return requestsSent
        }
        return []
    }
    
    //MARK: sharingsAcceptedBy
    func saveSharingsAcceptedBy(sharingsAcceptedBy: [ESPNodeGroupSharingStruct]) {
        if sharingsAcceptedBy.count > 0 {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(sharingsAcceptedBy) {
                UserDefaults.standard.set(data, forKey: ESPMatterConstants.sharingsAcceptedBy)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: ESPMatterConstants.sharingsAcceptedBy)
        }
    }
    
    func fetchSharingsAcceptedBy() -> [ESPNodeGroupSharingStruct] {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: ESPMatterConstants.sharingsAcceptedBy) as? Data, let sharingsAcceptedBy = try? decoder.decode([ESPNodeGroupSharingStruct].self, from: data) {
            return sharingsAcceptedBy
        }
        return []
    }
    
    //MARK: Clear all data
    func clearGroupSharingData() {
        UserDefaults.standard.removeObject(forKey: ESPMatterConstants.pendingNodeGroupRequests)
        UserDefaults.standard.removeObject(forKey: ESPMatterConstants.acceptedSharings)
        UserDefaults.standard.removeObject(forKey: ESPMatterConstants.requestsSent)
        UserDefaults.standard.removeObject(forKey: ESPMatterConstants.sharingsAcceptedBy)
    }
}
