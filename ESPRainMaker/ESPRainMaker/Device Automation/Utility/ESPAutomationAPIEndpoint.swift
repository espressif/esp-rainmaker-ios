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
//  ESPAutomationAPIEndpoint.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

enum ESPAutomationAPIEndpoint {
    
    case addNewAutomation(url: String, accessToken: String, automationPayload: [String: Any])
    case updateAutomation(url: String, accessToken: String, automationPayload: [String: Any])
    case getAllAutomations(url: String, accessToken: String)
    case deletAutomation(url: String, accessToken: String)
    
    var url: String {
        switch self {
        case .addNewAutomation(let url, _, _), .deletAutomation(let url, _), .getAllAutomations(let url, _), .updateAutomation(let url, _, _):
            return url
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .addNewAutomation:
            return .post
        case .updateAutomation:
            return .put
        case .getAllAutomations:
            return .get
        case .deletAutomation:
            return .delete
        }
    }
    
    var headers: HTTPHeaders {
        switch self {
        case .addNewAutomation(_,let accessToken,_):
            return [ESPAPIKeys.contentType: ESPAPIKeys.applicationJSON,
                    ESPAPIKeys.authorization: accessToken]
        case .updateAutomation(_, let accessToken,_):
            return [ESPAPIKeys.contentType: ESPAPIKeys.applicationJSON,
                    ESPAPIKeys.authorization: accessToken]
        case .getAllAutomations(_, let accessToken):
            return [ESPAPIKeys.contentType: ESPAPIKeys.applicationJSON,
                    ESPAPIKeys.authorization: accessToken]
        case .deletAutomation(_, let accessToken):
            return [ESPAPIKeys.contentType: ESPAPIKeys.applicationJSON,
                    ESPAPIKeys.authorization: accessToken]
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .addNewAutomation(_,_, automationPayload: let automationPayload):
            return automationPayload
        case .updateAutomation(_,_, automationPayload: let automationPayload):
            return automationPayload
        case .getAllAutomations(_, _):
            return nil
        case .deletAutomation(_, _):
            break
        }
        return nil
    }
}
