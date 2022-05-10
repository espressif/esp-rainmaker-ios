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
//  ESPAutomationResponseParser.swift
//  ESPRainMaker
//

import Foundation

protocol ESPAutomationResponseParsable {
    func parseAutomationResponse(_ data: Data) -> (success: Bool, error: ESPAPIError?)
}

struct ESPAutomationResponseParser: ESPAutomationResponseParsable {
    /// Method to parse API response of automation service.
    ///
    /// - Parameters:
    ///   - data: Response data for automation API..
    func parseAutomationResponse(_ data: Data) -> (success: Bool, error: ESPAPIError?) {
        // Check status of API request.
        let decoder = JSONDecoder()
        if let apiResponse = try? decoder.decode(ESPAPIStatus.self, from: data) {
            if apiResponse.isRequestSuccessfull() {
                return (success: true, error: nil)
            } else {
                return (success: false, error: .errorCode(code: String(apiResponse.error_code ?? 0), description: apiResponse.description))
            }
        }
        return (success: false, error: .noData)
    }
}
