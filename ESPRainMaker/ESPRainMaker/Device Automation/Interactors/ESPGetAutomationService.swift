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
//  ESPGetAutomationService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPGetAutomationLogic {
    func getAutomation()
    func getAutomationFor(eventType: String)
}

class ESPGetAutomationService : ESPGetAutomationLogic {
    
    var url: String
    var apiParser: ESPAutomationParser
    var apiWorker: ESPAutomationAPIWorker
    var sessionWorker: ESPExtendUserSessionWorker
    var presenter: ESPGetAutomationPresentationLogic?
    
    convenience init(presenter: ESPGetAutomationPresentationLogic? = nil) {
        self.init(url: ESPAutomationConstants.automationsURL,
                  apiParser: ESPAutomationParser(),
                  apiWorker: ESPAutomationAPIWorker(),
                  sessionWorker: ESPExtendUserSessionWorker(),
                  presenter: presenter)
    }
    
    private init(url: String,
         apiParser: ESPAutomationParser,
         apiWorker: ESPAutomationAPIWorker,
         sessionWorker: ESPExtendUserSessionWorker,
         presenter: ESPGetAutomationPresentationLogic? = nil) {
        self.url = url
        self.apiParser = apiParser
        self.apiWorker = apiWorker
        self.sessionWorker = sessionWorker
        self.presenter = presenter
    }
    
    /// Method to get list of all automation triggers for the current user.
    func getAutomation() {
        sessionWorker.checkUserSession { accessToken, error in
            if let token = accessToken, token.count > 0 {
                self.apiWorker.callAPI(endPoint: .getAllAutomations(url: self.url, accessToken: token), encoding: JSONEncoding.default) {
                    data, error in
                    guard let responseData = data else {
                        if let serverError = error {
                            // Error occured while sending the API request.
                            self.presenter?.automationListFetched(automations: nil, error: .serverError(serverError))
                            return
                        }
                        // No respose received.
                        self.presenter?.automationListFetched(automations: nil, error: .noData)
                        return
                    }
                    // Check status of API request.
                    let decoder = JSONDecoder()
                    if let failureResponse = try? decoder.decode(ESPAPIStatus.self, from: responseData) {
                        self.presenter?.automationListFetched(automations: nil, error: .errorCode(code: String(failureResponse.error_code ?? 0), description: failureResponse.description))
                    } else {
                        // Parse result of API response.
                        let getAutomationResponse = self.apiParser.parseAutomationList(responseData)
                        self.presenter?.automationListFetched(automations: getAutomationResponse.automations, error: nil)
                    }
                }
            } else {
                self.presenter?.automationListFetched(automations: nil, error: .noAccessToken)
            }
        }
    }
    
    // TODO: Get Automation List by eventType when supported.
    func getAutomationFor(eventType: String) {}
}
