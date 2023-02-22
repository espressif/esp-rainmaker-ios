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
//  ESPCheckOTAUpdateParser.swift
//  ESPRainMaker
//

import Foundation

protocol ESPOTAUpdateParsable {
    func parseOTAUpdateInformation(_ data: Data) -> (otaUpdate: ESPOTAUpdate?, error: ESPAPIError?)
}

struct ESPCheckOTAUpdateParser: ESPOTAUpdateParsable {
    func parseOTAUpdateInformation(_ data: Data) -> (otaUpdate: ESPOTAUpdate?, error: ESPAPIError?) {
        let decoder = JSONDecoder()
        if let otaUpdateRespone = try? decoder.decode(ESPOTAUpdate.self, from: data) {
            return (otaUpdateRespone, nil)
        } else if let failureResponse = try? decoder.decode(ESPOTAFailure.self, from: data) {
            return (nil, .errorCode(code: String(failureResponse.errorCode), description: failureResponse.otaStatusDescription))
        } else {
            return (nil, .parsingError())
        }
    }
}
