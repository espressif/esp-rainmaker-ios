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
//  ESPAddAutomationService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPAddAutomationLogic {
    func addNewAutomation(_ automation: ESPAutomationTriggerAction)
}

class ESPAddAutomationService : ESPAddAutomationLogic {
    
    var url: String
    var apiParser: ESPAutomationAddResponseParser
    var apiWorker: ESPAutomationAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    var presenter: ESPAddAutomationPresentationLogic?
    
    convenience init(presenter: ESPAddAutomationPresentationLogic? = nil) {
        self.init(url: ESPAutomationConstants.automationsURL, apiParser: ESPAutomationAddResponseParser(), apiWorker: ESPAutomationAPIWorker(), sessionWorker: ESPExtendUserSessionWorker(), presenter: presenter)
    }
    
    private init(url: String,
         apiParser: ESPAutomationAddResponseParser,
         apiWorker: ESPAutomationAPIWorker,
         sessionWorker: ESPExtendUserSessionWorker,
         presenter: ESPAddAutomationPresentationLogic? = nil) {
        self.url = url
        self.apiParser = apiParser
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    /// Method to provide property info of a device on local netowrk.
    ///
    /// - Parameters:
    ///   - automation: New automation trigger which needs to be added.
    func addNewAutomation(_ automation: ESPAutomationTriggerAction) {
        sessionWorker.checkUserSession { accessToken, error in
            if let token = accessToken, token.count > 0 {
                self.apiWorker.callAPI(endPoint: .addNewAutomation(url: self.url, accessToken: token, automationPayload: automation.getPayload()), encoding: JSONEncoding.default) {
                    data, error in
                    guard let responseData = data else {
                        if let serverError = error {
                            // Error occured while sending the API request.
                            self.presenter?.didFinishAddingAutomationWith(automationID: nil, error: .serverError(serverError))
                            return
                        }
                        // No respose received.
                        self.presenter?.didFinishAddingAutomationWith(automationID: nil, error: .noData)
                        return
                    }
                    // Check status of API request.
                    let response = self.apiParser.parseAddAutomationResponse(responseData)
                    self.presenter?.didFinishAddingAutomationWith(automationID: response.automationID, error: response.error)
                }
            } else {
                self.presenter?.didFinishAddingAutomationWith(automationID: nil, error: .noAccessToken)
            }
        }
    }
}
