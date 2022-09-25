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
//  ESPGetOTAUpdateStatusService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPGetOTAUpdateStatusLogic {
    func getOTAUpdateStatusFor(nodeID: String, otaJobID: String)
}

struct ESPGetOTAUpdateStatusService: ESPGetOTAUpdateStatusLogic {
    
    var url: String
    var apiParser: ESPOTAUpdateStatusParser
    var apiWorker: ESPOTAAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    var presenter: ESPOTAUpdateStatusPresentationLogic?

    /// Init method
    /// - Parameter presenter: Delegate for sending API response.
    init(presenter: ESPOTAUpdateStatusPresentationLogic? = nil) {
        self.init(url: ESPOTAConstants.otaStatusURL,
                  apiParser: ESPOTAUpdateStatusParser(),
                  apiWorker: ESPOTAAPIWorker(),
                  sessionWorker: ESPExtendUserSessionWorker(),
                  presenter: presenter)
    }
    
    /// Private init method
    /// - Parameters:
    ///   - url: URL for checking OTA update status
    ///   - apiParser: Parser
    ///   - apiWorker: API handler
    ///   - sessionWorker: Maintains user session
    ///   - presenter: Delegate
    private init(url: String,
         apiParser: ESPOTAUpdateStatusParser,
         apiWorker: ESPOTAAPIWorker,
         sessionWorker: ESPExtendUserSessionWorker,
         presenter: ESPOTAUpdateStatusPresentationLogic? = nil) {
        self.url = url
        self.apiParser = apiParser
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    /// Method to get OTA update status
    /// - Parameters:
    ///   - nodeID: ID of node for which status is requested
    ///   - otaJobID: Job ID of the the OTA update task
    func getOTAUpdateStatusFor(nodeID: String, otaJobID: String) {
        sessionWorker.checkUserSession { accessToken, error in
            if let token = accessToken, token.count > 0 {
                self.apiWorker.callAPI(endPoint: .getOTAUpdateStatus(url: self.url, accessToken: token, nodeID: nodeID, otaJobID: otaJobID), encoding: JSONEncoding.default) {
                    data, error in
                    guard let responseData = data else {
                        if let serverError = error {
                            // Error occured while sending the API request.
                            self.presenter?.getOTAUpdateStatus(otaUpdateStatus: nil, error: .serverError(serverError))
                            return
                        }
                        // No respose received.
                        self.presenter?.getOTAUpdateStatus(otaUpdateStatus: nil, error: .noData)
                        return
                    }
                    // Check status of API request.
                    let otaUpdateStatusResponse = self.apiParser.getOTAStatus(responseData)
                    self.presenter?.getOTAUpdateStatus(otaUpdateStatus: otaUpdateStatusResponse.otaUpdateStatus, error: otaUpdateStatusResponse.error)
                }
            } else {
                self.presenter?.getOTAUpdateStatus(otaUpdateStatus: nil, error: .noAccessToken)
            }
        }
    }
    
}



