// Copyright 2022 Espressif Systems
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
//  ESPDeleteAutomationService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPDeleteAutomationLogic {
    func deleteAutomation(_ automationID: String)
}

class ESPDeleteAutomationService : ESPDeleteAutomationLogic {
    
    var url: String
    var apiResponseParser: ESPAutomationResponseParser
    var apiWorker: ESPAutomationAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    var presenter: ESPDeleteAutomationPresentationLogic?
    
    convenience init(presenter: ESPDeleteAutomationPresentationLogic? = nil) {
        self.init(url: ESPAutomationConstants.automationsURL, apiResponseParser: ESPAutomationResponseParser(), apiWorker: ESPAutomationAPIWorker(), sessionWorker: ESPExtendUserSessionWorker(), presenter: presenter)
    }
    
    private init(url: String,
         apiResponseParser: ESPAutomationResponseParser,
         apiWorker: ESPAutomationAPIWorker,
         sessionWorker: ESPExtendUserSessionWorker,
         presenter: ESPDeleteAutomationPresentationLogic? = nil) {
        self.url = url
        self.apiResponseParser = apiResponseParser
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    /// Method to delete an existing automation trigger.
    ///
    /// - Parameters:
    ///   - automationID: Automation ID that needs to be deleted.
    func deleteAutomation(_ automationID: String) {
        sessionWorker.checkUserSession { accessToken, error in
            if let token = accessToken, token.count > 0 {
                self.apiWorker.callAPI(endPoint: .deletAutomation(url: self.url + "?automation_id=" + automationID, accessToken: token), encoding: JSONEncoding.default) {
                    data, error in
                    guard let responseData = data else {
                        if let serverError = error {
                            // Error occured while sending the API request.
                            self.presenter?.didFinishDeletingAutomationWith(automationID: automationID, error: .serverError(serverError))
                            return
                        }
                        // No respose received.
                        self.presenter?.didFinishDeletingAutomationWith(automationID: automationID, error: .noData)
                        return
                    }
                    // Check status of API request.
                    let parsedResponse = self.apiResponseParser.parseAutomationResponse(responseData)
                    if parsedResponse.success {
                        // Automation deleted.
                        self.presenter?.didFinishDeletingAutomationWith(automationID: automationID, error: nil)
                    } else {
                        self.presenter?.didFinishDeletingAutomationWith(automationID: automationID, error: parsedResponse.error)
                    }
                }
            } else {
                self.presenter?.didFinishDeletingAutomationWith(automationID: automationID, error: error)
            }
        }
    }
}
