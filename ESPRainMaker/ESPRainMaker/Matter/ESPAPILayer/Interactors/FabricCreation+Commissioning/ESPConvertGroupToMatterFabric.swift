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
//  ESPConvertGroupToMatterFabric.swift
//  ESPRainMaker
//

import Foundation

import Foundation

protocol ESPConvertGroupToMatterFabricLogic {
    
    func convertNodeGroupToMatterFabric(url: String?,
                                        groupId: String?,
                                        token: String?)
}

protocol ESPConvertGroupToMatterFabricPresentationLogic: AnyObject {
    func matterFabricUpdated(data: ESPCreateMatterFabricResponse?, error: Error?)
}

class ESPConvertGroupToMatterFabricService: ESPConvertGroupToMatterFabricLogic {
    
    var apiWorker: ESPAPIWorker
    var presenter: ESPConvertGroupToMatterFabricPresentationLogic?
    
    private init(apiWorker: ESPAPIWorker,
                 presenter: ESPConvertGroupToMatterFabricPresentationLogic? = nil) {
        self.apiWorker = apiWorker
        self.presenter = presenter
    }
    
    convenience init(presenter: ESPConvertGroupToMatterFabricPresentationLogic? = nil) {
        self.init(apiWorker: ESPAPIWorker(),
                  presenter: presenter)
    }
    
    func convertNodeGroupToMatterFabric(url: String?, groupId: String?, token: String?) {
        if let token = token, let url = url, let groupId = groupId {
            let apiEndpoint = ESPMatterAPIEndpoint.convertNodeGroupToMatterFabric(url: url, groupId: groupId, token: token)
            self.apiWorker.callDataAPI(endPoint: apiEndpoint) { data, error in
                if let data = data {
                    let decoder = JSONDecoder()
                    if let response = try? decoder.decode(ESPCreateMatterFabricResponse.self, from: data) {
                        self.presenter?.matterFabricUpdated(data: response, error: nil)
                        return
                    }
                }
                self.presenter?.matterFabricUpdated(data: nil, error: nil)
            }
        } else {
            self.presenter?.matterFabricUpdated(data: nil, error: nil)
        }
    }
}
