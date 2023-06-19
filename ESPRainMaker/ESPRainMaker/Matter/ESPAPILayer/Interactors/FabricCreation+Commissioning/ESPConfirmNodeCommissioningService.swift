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
//  ESPConfirmNodeCommissioningService.swift
//  ESPRainMaker
//

import Foundation

protocol ESPConfirmNodeCommissioningLogic {
    
    func confirmNodeCommissioning(url: String?,
                                  groupId: String,
                                  requestId: String?,
                                  status: String?)
}

protocol ESPConfirmNodeCommissioningPresentationLogic: AnyObject {
    func nodeCommissioningConfirmed(response: ESPConfirmNodeCommissioningResponse?, error: Error?)
    func matterRainmakerCommissioningConfirmed(status: String?, token: String)
}

class ESPConfirmNodeCommissioningService: ESPConfirmNodeCommissioningLogic {
    
    var apiWorker: ESPAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    var presenter: ESPConfirmNodeCommissioningPresentationLogic?
    
    private init(apiWorker: ESPAPIWorker,
                 sessionWorker: ESPExtendUserSessionWorker,
                 presenter: ESPConfirmNodeCommissioningPresentationLogic? = nil) {
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    convenience init(presenter: ESPConfirmNodeCommissioningPresentationLogic? = nil) {
        self.init(apiWorker: ESPAPIWorker(),
                  sessionWorker: ESPExtendUserSessionWorker(),
                  presenter: presenter)
    }
    
    
    func confirmNodeCommissioning(url: String?, groupId: String, requestId: String?, status: String?) {
        
        if let url = url, let requestId = requestId, let status = status, let token = ESPTokenWorker.shared.accessTokenString {
            let endpoint = ESPMatterAPIEndpoint.confirmNodeCommissioning(url: url, groupId: groupId, requestId: requestId, status: status, token: token)
            apiWorker.callDataAPI(endPoint: endpoint) { data, error in
                if let data = data {
                    let decoder = JSONDecoder()
                    if let response = try? decoder.decode(ESPConfirmNodeCommissioningResponse.self, from: data) {
                        self.presenter?.nodeCommissioningConfirmed(response: response, error: nil)
                        return
                    }
                }
                self.presenter?.nodeCommissioningConfirmed(response: nil, error: nil)
            }
        } else {
            self.presenter?.nodeCommissioningConfirmed(response: nil, error: nil)
        }
    }
    
    func confirmMatterRainmakerCommissioning(url: String, groupId: String, requestId: String, rainmakerNodeId: String, challenge: String, token: String) {
        let endpoint = ESPMatterAPIEndpoint.confirmMatterRainmakerCommissioning(url: url, groupId: groupId, requestId: requestId, challenge: challenge, rainmakerNodeId: rainmakerNodeId, token: token)
        self.apiWorker.callDataAPI(endPoint: endpoint) { data, error in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = json[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success {
                self.presenter?.matterRainmakerCommissioningConfirmed(status: rainmakerNodeId, token: token)
            } else {
                self.presenter?.matterRainmakerCommissioningConfirmed(status: nil, token: token)
            }
        }
    }
}
