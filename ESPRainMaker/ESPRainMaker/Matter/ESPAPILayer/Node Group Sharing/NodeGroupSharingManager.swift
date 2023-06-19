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
//  NodeSharingManager.swift
//  ESPRainmaker
//

import Foundation

/// Group sharing API manager
class NodeGroupSharingManager {
    
    static let shared = NodeGroupSharingManager()
    private let apiManager = ESPAPIManager()
    private let nodeSharing = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/sharing"
    private let nodeSharingRequests = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/sharing/requests"
    private let nodeGroupSharing = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/node_group/sharing"
    private let nodeGroupSharingRequests = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/node_group/sharing/requests"
    
    private init() {}
    
    /// Get node group sharing
    /// - Parameters:
    ///   - group: group
    ///   - completion: completion
    func getNodeGroupSharing(groupId: String? = nil, _ completion: @escaping (Data?) -> Void) {
        var url = nodeGroupSharing
        if let groupId = groupId {
            url += "?group_id=\(groupId)"
        }
        self.apiManager.genericAuthorizedDataRequest(url: url, parameter: nil, method: .get) { data, _ in
            if let data = data {
                completion(data)
            } else {
                completion(nil)
            }
        }
    }
    
    /// Get node group sharing requests
    /// - Parameters:
    ///   - completion: completion
    func getNodeGroupSharingRequests(isPrimary: Bool = true, requestId: String? = nil, _ completion: @escaping (Data?) -> Void) {
        var url = nodeGroupSharingRequests
        if isPrimary {
            url += "?primary_user=true"
        } else {
            url += "?primary_user=false"
        }
        if let requestId = requestId {
            url += "&request_id=\(requestId)"
        }
        self.apiManager.genericAuthorizedDataRequest(url: url, parameter: nil, method: .get) { data, _ in
            if let data = data {
                completion(data)
            } else {
                completion(nil)
            }
        }
    }
    
    /// Share node group
    /// - Parameters:
    ///   - groupId: group id
    ///   - userName: user name
    ///   - isPrimary: is primary
    ///   - completion: completion
    func shareNodeGroup(groupId: String, groupName: String, userName: String, isPrimary: Bool, completion: @escaping (Data?) -> Void) {
        let url = nodeGroupSharing
        let parameter: [String : Any] = [ESPMatterConstants.groups: [groupId] as Any,
                                         ESPMatterConstants.userName: userName as Any,
                                         ESPMatterConstants.primary: isPrimary as Any,
                                         ESPMatterConstants.metadata: [ESPMatterConstants.groupName: groupName] as Any]
        self.apiManager.genericAuthorizedDataRequest(url: url, parameter: parameter, method: .put) { data, _ in
            if let data = data {
                completion(data)
            } else {
                completion(nil)
            }
        }
    }
    
    /// Delete request sent
    /// - Parameter requestId: request id
    func deleteRequest(requestId: String, completion: @escaping (Bool) -> Void) {
        let url = nodeGroupSharingRequests + "?request_id=\(requestId)"
        self.apiManager.genericAuthorizedDataRequest(url: url, parameter: nil, method: .delete) { data, _ in
            if let data = data, let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = response[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success {
                completion(true)
                return
            }
            completion(false)
        }
    }
    
    /// Act on sharing request
    /// - Parameters:
    ///   - requestId: request id
    ///   - accept: accept/decline
    func actOnSharingRequest(requestId: String, accept: Bool, completion: @escaping (Bool) -> Void) {
        let url = nodeGroupSharingRequests
        self.apiManager.genericAuthorizedDataRequest(url: url, parameter: [ESPMatterConstants.accept: accept, ESPMatterConstants.requestId: requestId], method: .put) { data, _ in
            if let data = data, let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = response[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success {
                completion(true)
                return
            }
            completion(false)
        }
    }
    
    
    /// Delete sharing between users
    /// - Parameter groupId: group id
    /// - Parameter email: email id
    /// - Parameter completion: completion
    func revokeAccess(groupId: String, email: String, completion: @escaping (Bool) -> Void) {
        let url = nodeGroupSharing + "?groups=\(groupId)&user_name=\(email)"
        self.apiManager.genericAuthorizedDataRequest(url: url, parameter: nil, method: .delete) { data, _ in
            if let data = data, let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = response[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success {
                completion(true)
                return
            }
            completion(false)
        }
    }
}
