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
//  ESPPushOTAUpdateService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPPushOTAUpdateLogic {
    func pushOTAUpdateFor(nodeID: String, otaJobID: String)
}

struct ESPPushOTAUpdateService: ESPPushOTAUpdateLogic {
    
    var url: String
    var apiParser: ESPPushOTAUpdateParser
    var apiWorker: ESPOTAAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    var presenter: ESPPushOTAUpdatePresentationLogic?
    
    /// Init method
    /// - Parameter presenter: Delegate for sending API response.
    init(presenter: ESPPushOTAUpdatePresentationLogic? = nil) {
        self.init(url: ESPOTAConstants.otaUpdateURL,
                  apiParser: ESPPushOTAUpdateParser(),
                  apiWorker: ESPOTAAPIWorker(),
                  sessionWorker: ESPExtendUserSessionWorker(),
                  presenter: presenter)
    }
    
    /// Private init method
    /// - Parameters:
    ///   - url: URL for pushing OTA update 
    ///   - apiParser: Parser
    ///   - apiWorker: API handler
    ///   - sessionWorker: Maintains user session
    ///   - presenter: Delegate
    private init(url: String,
         apiParser: ESPPushOTAUpdateParser,
         apiWorker: ESPOTAAPIWorker,
         sessionWorker: ESPExtendUserSessionWorker,
         presenter: ESPPushOTAUpdatePresentationLogic? = nil) {
        self.url = url
        self.apiParser = apiParser
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    /// Method to push OTA update
    /// - Parameters:
    ///   - nodeID: Id of the node for which OTA update is pushed
    ///   - otaJobID: Job ID of the the OTA update task
    func pushOTAUpdateFor(nodeID: String, otaJobID: String) {
        sessionWorker.checkUserSession { accessToken, error in
            if let token = accessToken, token.count > 0 {
                self.apiWorker.callAPI(endPoint: .pushOTAUpdate(url: self.url, accessToken: token, nodeID: nodeID, otaJobID: otaJobID), encoding: JSONEncoding.default) {
                    data, error in
                    guard let responseData = data else {
                        if let serverError = error {
                            // Error occured while sending the API request.
                            self.presenter?.pushOTAUpdateStatus(pushOTAUpdateStatus: nil, error: .serverError(serverError))
                            return
                        }
                        // No respose received.
                        self.presenter?.pushOTAUpdateStatus(pushOTAUpdateStatus: nil, error: .noData)
                        return
                    }
                    // Check status of API request.
                    let pushOTAUpdateResponse = self.apiParser.pushOTAUpdateResponse(responseData)
                    self.presenter?.pushOTAUpdateStatus(pushOTAUpdateStatus: pushOTAUpdateResponse.otaUpdateStatus, error: pushOTAUpdateResponse.error)
                }
            } else {
                self.presenter?.pushOTAUpdateStatus(pushOTAUpdateStatus: nil, error: .noAccessToken)
            }
        }
    }
}
