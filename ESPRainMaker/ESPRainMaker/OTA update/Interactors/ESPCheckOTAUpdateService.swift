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
//  ESPCheckOTAUpdateService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPCheckOTAUpdateLogic {
    func checkOTAUpdateFor(nodeID: String)
}

struct ESPCheckOTAUpdateService: ESPCheckOTAUpdateLogic {
    
    var url: String
    var apiParser: ESPCheckOTAUpdateParser
    var apiWorker: ESPOTAAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    var presenter: ESPCheckOTAUpdatePresentationLogic?
    
    
    /// Init method
    /// - Parameter presenter: Delegate for sending API response.
    init(presenter: ESPCheckOTAUpdatePresentationLogic? = nil) {
        self.init(url: ESPOTAConstants.otaUpdateURL,
                  apiParser: ESPCheckOTAUpdateParser(),
                  apiWorker: ESPOTAAPIWorker(),
                  sessionWorker: ESPExtendUserSessionWorker(),
                  presenter: presenter)
    }
    
    
    /// Private init method
    /// - Parameters:
    ///   - url: URL for checking OTA update availability
    ///   - apiParser: Parser
    ///   - apiWorker: API handler
    ///   - sessionWorker: Maintains user session
    ///   - presenter: Delegate
    private init(url: String,
         apiParser: ESPCheckOTAUpdateParser,
         apiWorker: ESPOTAAPIWorker,
         sessionWorker: ESPExtendUserSessionWorker,
         presenter: ESPCheckOTAUpdatePresentationLogic? = nil) {
        self.url = url
        self.apiParser = apiParser
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    /// Method for checking if OTA update is available
    /// - Parameter nodeID: Node ID for which update is checked
    func checkOTAUpdateFor(nodeID: String) {
        sessionWorker.checkUserSession { accessToken, error in
            if let token = accessToken, token.count > 0 {
                self.apiWorker.callAPI(endPoint: .checkOTAUpdate(url: self.url, accessToken: token, nodeID: nodeID), encoding: JSONEncoding.default) {
                    data, error in
                    guard let responseData = data else {
                        if let serverError = error {
                            // Error occured while sending the API request.
                            self.presenter?.checkOTAUpdate(otaUpdate: nil, error: .serverError(serverError))
                            return
                        }
                        // No respose received.
                        self.presenter?.checkOTAUpdate(otaUpdate: nil, error: .noData)
                        return
                    }
                    // Check status of API request.
                    let checkOTAUpdateResponse = self.apiParser.parseOTAUpdateInformation(responseData)
                    self.presenter?.checkOTAUpdate(otaUpdate: checkOTAUpdateResponse.otaUpdate, error: checkOTAUpdateResponse.error)
                }
            } else {
                self.presenter?.checkOTAUpdate(otaUpdate: nil, error: .noAccessToken)
            }
        }
    }
}
