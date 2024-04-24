// Copyright 2024 Espressif Systems
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
//  ESPUpdateNodeMetadataService.swift
//  ESPRainMaker
//

import Foundation

protocol ESPUpdateNodeMetadaPresentationLogic: AnyObject {
    func nodeMetadataUpdated(status: Bool)
}


class ESPUpdateNodeMetadataService {
    
    var apiWorker: ESPAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    weak var presenter: ESPUpdateNodeMetadaPresentationLogic?
    
    private init(apiWorker: ESPAPIWorker,
                 sessionWorker: ESPExtendUserSessionWorker,
                 presenter: ESPUpdateNodeMetadaPresentationLogic? = nil) {
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    convenience init(presenter: ESPUpdateNodeMetadaPresentationLogic? = nil) {
        self.init(apiWorker: ESPAPIWorker(),
                  sessionWorker: ESPExtendUserSessionWorker(),
                  presenter: presenter)
    }
    
    func updateNodeMetadata(nodeId: String, metdata: [String: Any?]) {
        if let token = ESPTokenWorker.shared.accessTokenString {
            let endpoint = ESPMatterAPIEndpoint.updateNodeMetadata(nodeId: nodeId, token: token, metadata: metdata)
            self.apiWorker.callDataAPI(endPoint: endpoint) { data, _ in
                if let data = data, let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = response[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success {
                    if let string = String(data: data, encoding: .utf8) {
                        print(string)
                    }
                    self.presenter?.nodeMetadataUpdated(status: true)
                } else {
                    self.presenter?.nodeMetadataUpdated(status: false)
                }
            }
        } else {
            self.presenter?.nodeMetadataUpdated(status: false)
        }
    }
}
