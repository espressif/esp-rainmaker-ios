// Copyright 2024 Espressif Systems
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
//  ESPNodeMetadataService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

class ESPNodeMetadataService {
    
    static let shared = ESPNodeMetadataService()
    let extendSessionWorker = ESPExtendUserSessionWorker()
    let apiWorker = ESPAPIWorker()
    static let nodeMetadataURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes"
    static let metadataKey = "metadata"
    static let isThreadKey = "is_thread_device"
    static let statusKey = "status"
    static let errorCodeKey = "error_code"
    static let descriptionKey = "description"
    static let success = "success"
    
    /// Set device name for matter only device to user metadata
    /// - Parameters:
    ///   - nodeId: node id
    ///   - deviceName: device name
    ///   - completion: completion
    func setMatterDeviceName(node: Node, deviceName: String, completion: @escaping (Bool, ESPAPIError?) -> Void) {
        self.extendSessionWorker.checkUserSession { accessToken, error in
            guard let accessToken = accessToken, let nodeId = node.node_id, var metadata = node.metadata, var matterMetadata = metadata[ESPMatterConstants.matter] as? [String: Any] else {
                completion(false, ESPAPIError.noAccessToken)
                return
            }
            
            matterMetadata[ESPMatterConstants.deviceName] = deviceName
            metadata[ESPMatterConstants.matter] = matterMetadata
            let url = ESPNodeMetadataService.nodeMetadataURL + "?node_id=\(nodeId)"
            let headers: HTTPHeaders = [ESPMatterConstants.contentType: ESPMatterConstants.applicationJSON,
                           ESPMatterConstants.authorization: accessToken]
            let params = [ESPNodeMetadataService.metadataKey: metadata]
            self.callCloudAPI(url: url, method: .put, headers: headers, parameters: params, completion: completion)
        }
    }
    
    /// Call the cloud API to update the matter only device name to device metadata
    /// - Parameters:
    ///   - url:API endpoint
    ///   - headers: headers
    ///   - parameters: params in the API
    ///   - completion: complletion handler
    private func callCloudAPI(url: String, method: HTTPMethod, headers: HTTPHeaders, parameters: Parameters?, completion: @escaping (Bool, ESPAPIError?) -> Void) {
        self.apiWorker.callDataAPI(url: url, method: .put, parameters: parameters, headers: headers, apiDescription: "") { data, error in
            guard let error = error else {
                if let responseData = data, let response = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                    if let status = response[ESPNodeMetadataService.statusKey] as? String, status.lowercased() == ESPNodeMetadataService.success {
                        completion(true, nil)
                    } else {
                        if let errorCode = response[ESPNodeMetadataService.errorCodeKey] as? String, let description = response[ESPNodeMetadataService.descriptionKey] as? String {
                            completion(false, ESPAPIError.errorCode(code: errorCode, description: description))
                        }
                    }
                }
                return
            }
            completion(false, ESPAPIError.errorDescription(error.localizedDescription))
        }
    }
}
