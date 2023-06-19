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
//  ESPAddNodeToMatterFabricService.swift
//  ESPRainMaker
//

import Foundation

protocol ESPAddNodeToMatterFabricLogic {
    
    func addNodeToMatterFabric(url: String?,
                               groupId: String,
                               operation: String?,
                               csr: String?,
                               metadata: [String: Any]?)
    func removeNode(endpoint: ESPMatterAPIEndpoint)
}

protocol ESPAddNodeToMatterFabricPresentationLogic: AnyObject {
    
    func nodeNOCReceived(groupId: String,
                         response: ESPAddNodeToFabricResponse?,
                         error: Error?)
    func nodeRemoved(status: Bool,
                     error: Error?)
}

class ESPAddNodeToMatterFabricService: ESPAddNodeToMatterFabricLogic {
    
    var apiWorker: ESPAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    var presenter: ESPAddNodeToMatterFabricPresentationLogic?
    
    private init(apiWorker: ESPAPIWorker,
                 sessionWorker: ESPExtendUserSessionWorker,
                 presenter: ESPAddNodeToMatterFabricPresentationLogic? = nil) {
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    convenience init(presenter: ESPAddNodeToMatterFabricPresentationLogic? = nil) {
        self.init(apiWorker: ESPAPIWorker(),
                  sessionWorker: ESPExtendUserSessionWorker(),
                  presenter: presenter)
    }
    
    
    func addNodeToMatterFabric(url: String?, groupId: String, operation: String?, csr: String?, metadata: [String: Any]?) {
        
        if let url = url, let operation = operation, let csr = csr, let token = ESPTokenWorker.shared.accessTokenString {
            let endpoint = ESPMatterAPIEndpoint.addNodeToMatterFabric(url: url, groupId: groupId, operation: operation, csr: csr, token: token, metaData: metadata)
            apiWorker.callDataAPI(endPoint: endpoint) { data, error in
                if let data = data {
                    let decoder = JSONDecoder()
                    if let response = try? decoder.decode(ESPAddNodeToFabricResponse.self, from: data) {
                        self.presenter?.nodeNOCReceived(groupId: groupId, response: response, error: nil)
                        return
                    }
                }
                self.presenter?.nodeNOCReceived(groupId: groupId, response: nil, error: nil)
            }
        } else {
            self.presenter?.nodeNOCReceived(groupId: groupId, response: nil, error: nil)
        }
    }
    
    func removeNode(endpoint: ESPMatterAPIEndpoint) {
        self.apiWorker.callDataAPI(endPoint: endpoint) { data, error in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let status = json[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success {
                    self.presenter?.nodeRemoved(status: true, error: nil)
                    return
                }
            }
            self.presenter?.nodeRemoved(status: false, error: error)
        }
    }
}
