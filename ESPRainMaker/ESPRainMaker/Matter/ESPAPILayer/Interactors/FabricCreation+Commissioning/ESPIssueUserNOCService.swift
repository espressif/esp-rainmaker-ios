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
//  ESPIssueUserNOCService.swift
//  ESPRainMaker
//

import Foundation

protocol ESPIssueUserNOCLogic {
    
    func issueUserNOC(url: String?,
                      groupId: String,
                      operation: String?,
                      csr: String?)
}

protocol ESPIssueUserNOCPresentationLogic: AnyObject {
    
    func userNOCReceived(groupId: String,
                         response: ESPIssueUserNOCResponse?,
                         error: Error?)
}

class ESPIssueUserNOCService: ESPIssueUserNOCLogic {
    
    var apiWorker: ESPAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    var presenter: ESPIssueUserNOCPresentationLogic?
    
    private init(apiWorker: ESPAPIWorker,
                 sessionWorker: ESPExtendUserSessionWorker,
                 presenter: ESPIssueUserNOCPresentationLogic? = nil) {
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    convenience init(presenter: ESPIssueUserNOCPresentationLogic? = nil) {
        self.init(apiWorker: ESPAPIWorker(),
                  sessionWorker: ESPExtendUserSessionWorker(),
                  presenter: presenter)
    }
    
    
    func issueUserNOC(url: String?,
                      groupId: String,
                      operation: String?,
                      csr: String?) {
        
        if let url = url, let operation = operation, let csr = csr, let token = ESPTokenWorker.shared.accessTokenString {
            let endpoint = ESPMatterAPIEndpoint.issueUserNOC(url: url, groupId: groupId, operation: operation, csr: csr, token: token)
            apiWorker.callDataAPI(endPoint: endpoint) { data, error in
                if let data = data {
                    let decoder = JSONDecoder()
                    if let response = try? decoder.decode(ESPIssueUserNOCResponse.self, from: data) {
                        self.presenter?.userNOCReceived(groupId: groupId, response: response, error: nil)
                        return
                    }
                }
                self.presenter?.userNOCReceived(groupId: groupId, response: nil, error: nil)
            }
        } else {
            self.presenter?.userNOCReceived(groupId: groupId, response: nil, error: nil)
        }
    }
}
