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
//  ESPDeleteNodeGroupService.swift
//  ESPRainMaker
//

import Foundation

protocol ESPDeleteMatterFabricLogic {
    
    func deleteMatterFabric(url: String?,
                            groupId: String?,
                            token: String?)
}

protocol ESPDeleteMatterFabricPresentationLogic: AnyObject {
    func matterFabricDeleted(data: ESPDeleteMatterFabricResponse?, error: Error?)
}

class ESPDeleteMatterFabricService: ESPDeleteMatterFabricLogic {
    
    var apiWorker: ESPAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    var presenter: ESPDeleteMatterFabricPresentationLogic?
    
    private init(apiWorker: ESPAPIWorker,
                 sessionWorker: ESPExtendUserSessionWorker,
                 presenter: ESPDeleteMatterFabricPresentationLogic? = nil) {
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    convenience init(presenter: ESPDeleteMatterFabricPresentationLogic? = nil) {
        self.init(apiWorker: ESPAPIWorker(),
                  sessionWorker: ESPExtendUserSessionWorker(),
                  presenter: presenter)
    }
    
    
    func deleteMatterFabric(url: String?, groupId: String?, token: String?) {
        if let url = url, let groupId = groupId, let token = token {
            let endpoint = ESPMatterAPIEndpoint.deleteMatterFabric(url: url, groupId: groupId, token: token)
            apiWorker.callDataAPI(endPoint: endpoint) { data, error in
                if let data = data {
                    let decoder = JSONDecoder()
                    if let response = try? decoder.decode(ESPDeleteMatterFabricResponse.self, from: data) {
                        self.presenter?.matterFabricDeleted(data: response, error: nil)
                        return
                    }
                }
                self.presenter?.matterFabricDeleted(data: nil, error: nil)
            }
        } else {
            self.presenter?.matterFabricDeleted(data: nil, error: nil)
        }
    }
}
