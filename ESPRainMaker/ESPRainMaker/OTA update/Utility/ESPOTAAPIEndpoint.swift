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
//  ESPOTAAPIEndpoint.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

enum ESPOTAAPIEndpoint {
    
    case checkOTAUpdate(url: String, accessToken: String, nodeID: String)
    case getOTAUpdateStatus(url: String, accessToken: String, nodeID: String, otaJobID: String)
    case pushOTAUpdate(url: String, accessToken: String, nodeID: String, otaJobID: String)
    
    var url: String {
        switch self {
        case .checkOTAUpdate(let url, _, let nodeID):
            return url + "?" + ESPOTAConstants.nodeIDKey + "=" + nodeID
        case .getOTAUpdateStatus(let url, _, let nodeID, let otaJobID):
            return url + "?\(ESPOTAConstants.nodeIDKey)=\(nodeID)&\(ESPOTAConstants.otaJobIDKey)=\(otaJobID)"
        case .pushOTAUpdate(let url, _, _, _):
            return url
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .checkOTAUpdate:
            return .get
        case .getOTAUpdateStatus:
            return .get
        case .pushOTAUpdate:
            return .post
        }
    }
    
    var headers: HTTPHeaders {
        switch self {
        case .checkOTAUpdate(_,let accessToken,_):
            return [ESPAPIKeys.contentType: ESPAPIKeys.applicationJSON,
                    ESPAPIKeys.authorization: accessToken]
        case .getOTAUpdateStatus(_, let accessToken,_,_), .pushOTAUpdate(_, let accessToken,_,_):
            return [ESPAPIKeys.contentType: ESPAPIKeys.applicationJSON,
                    ESPAPIKeys.authorization: accessToken]
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .checkOTAUpdate(_, _, _), .getOTAUpdateStatus(_, _, _, _):
            return nil
        case .pushOTAUpdate(_, _, let nodeID, let otaJobID):
            return [ESPOTAConstants.nodeIDKey: nodeID, ESPOTAConstants.otaJobIDKey: otaJobID]
        }
        return nil
    }
}
