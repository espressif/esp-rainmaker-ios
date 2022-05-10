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
//  ESPUpdateAutomationService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPUpdateAutomationLogic {
    func updateAutomation(_ automation: ESPAutomationTriggerAction)
}

class ESPUpdateAutomationService : ESPUpdateAutomationLogic {
    
    var url: String
    var apiResponseParser: ESPAutomationResponseParser
    var apiWorker: ESPAutomationAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    var presenter: ESPUpdateAutomationPresentationLogic?
    
    convenience init(presenter: ESPUpdateAutomationPresentationLogic? = nil) {
        self.init(url: ESPAutomationConstants.automationsURL, apiResponseParser: ESPAutomationResponseParser(), apiWorker: ESPAutomationAPIWorker(), sessionWorker: ESPExtendUserSessionWorker(), presenter: presenter)
    }
    
    private init(url: String,
         apiResponseParser: ESPAutomationResponseParser,
         apiWorker: ESPAutomationAPIWorker,
         sessionWorker: ESPExtendUserSessionWorker,
         presenter: ESPUpdateAutomationPresentationLogic? = nil) {
        self.url = url
        self.apiResponseParser = apiResponseParser
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    /// Method to update or edit an existing automation.
    ///
    /// - Parameters:
    ///   - automation: Automation with updated value.
    func updateAutomation(_ automation: ESPAutomationTriggerAction) {
        sessionWorker.checkUserSession { accessToken, error in
            if let token = accessToken, token.count > 0 {
                var payload = automation.getPayload()
                payload[ESPAutomationConstants.enabled] = true
                self.apiWorker.callAPI(endPoint: .updateAutomation(url: self.url + "?automation_id=" + (automation.automationID ?? ""), accessToken: token, automationPayload: payload), encoding: JSONEncoding.default) {
                    data, error in
                    guard let responseData = data else {
                        if let serverError = error {
                            // Error occured while sending the API request.
                            self.presenter?.didFinishUpdatingAutomationWith(error: .serverError(serverError))
                            return
                        }
                        // No respose received.
                        self.presenter?.didFinishUpdatingAutomationWith(error: .noData)
                        return
                    }
                    // Check status of API request.
                    let parsedResponse = self.apiResponseParser.parseAutomationResponse(responseData)
                    if parsedResponse.success {
                        // Automation updated.
                        self.presenter?.didFinishUpdatingAutomationWith(error: nil)
                    } else {
                        self.presenter?.didFinishUpdatingAutomationWith(error: parsedResponse.error)
                    }
                }
            } else {
                self.presenter?.didFinishUpdatingAutomationWith(error: .noAccessToken)
            }
        }
    }
}

