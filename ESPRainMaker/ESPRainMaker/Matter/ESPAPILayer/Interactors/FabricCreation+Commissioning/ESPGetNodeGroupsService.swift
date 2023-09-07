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
//  ESPGetNodeGroupsService.swift
//  ESPRainMaker
//

import Foundation

protocol ESPGetNodeGroupsLogic {
    
    func getNodeGroupsMatterFabricDetails(url: String?, token: String?)
    func getNodeDetails(url: String?, token: String?, groupId: String?)
}

protocol ESPGetNodeGroupsPresentationLogic: AnyObject {
    
    func receivedNodeGroupsData(data: ESPNodeGroups?, error: Error?)
    func receivedNodeGroupDetailsData(data: ESPNodeGroupDetails?, error: Error?)
}

class ESPGetNodeGroupsService: ESPGetNodeGroupsLogic {
    
    var apiWorker: ESPAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    var presenter: ESPGetNodeGroupsPresentationLogic?
    
    private init(apiWorker: ESPAPIWorker,
                 sessionWorker: ESPExtendUserSessionWorker,
                 presenter: ESPGetNodeGroupsPresentationLogic? = nil) {
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    convenience init(presenter: ESPGetNodeGroupsPresentationLogic? = nil) {
        self.init(apiWorker: ESPAPIWorker(),
                  sessionWorker: ESPExtendUserSessionWorker(),
                  presenter: presenter)
    }
    
    func getNodeGroupsMatterFabricDetails(url: String?,
                                          token: String?) {
        if let url = url, let token = token {
            let endpoint = ESPMatterAPIEndpoint.getNodeGroupsMatterFabricDetails(url: url, token: token)
            apiWorker.callDataAPI(endPoint: endpoint) { data, error in
                if let data = data {
                    let decoder = JSONDecoder()
                    if let response = try? decoder.decode(ESPNodeGroups.self, from: data) {
                        self.presenter?.receivedNodeGroupsData(data: response, error: nil)
                        return
                    }
                }
                self.presenter?.receivedNodeGroupsData(data: nil, error: error)
            }
        } else {
            self.presenter?.receivedNodeGroupsData(data: nil, error: nil)
        }
    }
    
    func getNodeDetails(url: String?,
                        token: String?,
                        groupId: String?) {
        if let url = url, let token = token, let groupId = groupId {
            let endpoint = ESPMatterAPIEndpoint.getNodeDetails(url: url, token: token, groupId: groupId)
            self.apiWorker.callDataAPI(endPoint: endpoint) { data, error in
                if let data = data {
                    let decoder = JSONDecoder()
                    if let response = try? decoder.decode(ESPNodeGroupDetails.self, from: data) {
                        self.presenter?.receivedNodeGroupDetailsData(data: response, error: nil)
                        return
                    }
                }
                self.presenter?.receivedNodeGroupDetailsData(data: nil, error: error)
            }
        } else {
            self.presenter?.receivedNodeGroupDetailsData(data: nil, error: nil)
        }
    }
}
