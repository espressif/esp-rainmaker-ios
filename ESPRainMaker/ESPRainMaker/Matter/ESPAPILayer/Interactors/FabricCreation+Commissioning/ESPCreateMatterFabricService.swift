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
//  ESPCreateMatterFabricService.swift
//  ESPRainMaker
//

import Foundation

protocol ESPCreateMatterFabricLogic {
    
    func createMatterFabric(url: String?,
                            groupName: String?,
                            type: String?,
                            mutuallyExclusive: Bool?,
                            description: String?,
                            isMatter: Bool?)
}

protocol ESPCreateMatterFabricPresentationLogic: AnyObject {
    func matterFabricCreated(data: ESPCreateMatterFabricResponse?, error: Error?)
}

class ESPCreateMatterFabricService: ESPCreateMatterFabricLogic {
    
    var apiWorker: ESPAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    var presenter: ESPCreateMatterFabricPresentationLogic?
    
    private init(apiWorker: ESPAPIWorker,
                 sessionWorker: ESPExtendUserSessionWorker,
                 presenter: ESPCreateMatterFabricPresentationLogic? = nil) {
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    convenience init(presenter: ESPCreateMatterFabricPresentationLogic? = nil) {
        self.init(apiWorker: ESPAPIWorker(),
                  sessionWorker: ESPExtendUserSessionWorker(),
                  presenter: presenter)
    }
    
    
    /// Create matter fabric/node group
    /// - Parameters:
    ///   - url: node group URL
    ///   - groupName: group name
    ///   - type: group type
    ///   - mutuallyExclusive: mutually exclusive
    ///   - description: description
    ///   - isMatter: is matter
    func createMatterFabric(url: String?, groupName: String?, type: String?, mutuallyExclusive: Bool?, description: String?, isMatter: Bool?) {
        if let url = url, let groupName = groupName, let type = type, let mutuallyExclusive = mutuallyExclusive, let description = description, let isMatter = isMatter, let token = ESPTokenWorker.shared.accessTokenString {
            let endpoint = ESPMatterAPIEndpoint.createMatterFabric(url: url, groupName: groupName, type: type, mutuallyExclusive: mutuallyExclusive, description: description, isMatter: isMatter, token: token)
            apiWorker.callDataAPI(endPoint: endpoint) { data, error in
                if let data = data {
                    let decoder = JSONDecoder()
                    if let response = try? decoder.decode(ESPCreateMatterFabricResponse.self, from: data) {
                        self.presenter?.matterFabricCreated(data: response, error: nil)
                        return
                    }
                }
                self.presenter?.matterFabricCreated(data: nil, error: nil)
            }
        } else {
            self.presenter?.matterFabricCreated(data: nil, error: nil)
        }
    }
}
