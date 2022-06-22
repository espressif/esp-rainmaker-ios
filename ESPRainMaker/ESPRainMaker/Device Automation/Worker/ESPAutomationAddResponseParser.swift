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
//  ESPAutomationAddResponseParser.swift
//  ESPRainMaker
//

import Foundation
import ESPProvision

protocol ESPAutomationAddResponseParsable {
    func parseAddAutomationResponse(_ data: Data) -> (automationID: String?, error: ESPAPIError?)
}

struct ESPAutomationAddResponseParser: ESPAutomationAddResponseParsable {
    /// Method to parse API response of add automation service.
    ///
    /// - Parameters:
    ///   - data: Response data for add automation API..
    func parseAddAutomationResponse(_ data: Data) -> (automationID: String?, error: ESPAPIError?) {
        // Check status of API request.
        let decoder = JSONDecoder()
        if let apiResponse = try? decoder.decode(ESPAPIStatus.self, from: data) {
            if !apiResponse.isRequestSuccessfull() {
                return (automationID: nil, error: .errorCode(code: String(apiResponse.error_code ?? 0), description: apiResponse.description))
            }
        }
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                if let automationID = json[ESPAutomationConstants.automationID] {
                    return (automationID: automationID, error: nil)
                }
            }
        } catch {
            return (automationID: nil, error: .parsingError(error: error.localizedDescription))
        }
        return (automationID: nil, error: .parsingError(error: ""))
    }
}

