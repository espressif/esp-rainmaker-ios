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

private enum NodeGroupSharingAPIKeys {
    static let primaryUserTrueQuery = "?primary_user=true"
    static let primaryUserFalseQuery = "?primary_user=false"
    static let requestIdQueryPrefix = "&request_id="
    static let startRequestIdQueryPrefix = "&start_request_id="
    static let startUserNameQueryPrefix = "&start_user_name="
    static let sharingRequestsKey = "sharing_requests"
    static let nextRequestIdKey = "next_request_id"
    static let nextUserNameKey = "next_user_name"
}

/// Group sharing API manager
class NodeGroupSharingManager {
    
    static let shared = NodeGroupSharingManager()
    private var apiManager = ESPAPIManager()
    
    // Convert to computed properties for dynamic URL resolution
    private var nodeSharing: String { Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/sharing" }
    private var nodeSharingRequests: String { Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/sharing/requests" }
    private var nodeGroupSharing: String { Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/node_group/sharing" }
    private var nodeGroupSharingRequests: String { Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/node_group/sharing/requests" }
    
    private init() {
        // Listen for configuration updates and reinitialize API manager
        NotificationCenter.default.addObserver(self, selector: #selector(configurationUpdated), name: NSNotification.Name(Constants.configurationUpdateNotification), object: nil)
    }
    
    private func parseStatusAndDescription(from data: Data?) -> (isSuccess: Bool, description: String?) {
        guard
            let data = data,
            let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return (false, nil)
        }
        
        let status = (response[ESPMatterConstants.status] as? String)?.lowercased()
        let description = response[Constants.descriptionKey] as? String
        return (status == ESPMatterConstants.success, description)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func configurationUpdated() {
        // Reinitialize the API manager to pick up new server trust configuration
        apiManager = ESPAPIManager()
    }
    
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
    
    /// Get node group sharing requests. If pagination data is present in response,
    /// fetches all pages and returns a consolidated payload.
    /// - Parameters:
    ///   - isPrimary: true for sent requests, false for received requests.
    ///   - requestId: optional request id filter for backend support.
    ///   - completion: completion
    func getNodeGroupSharingRequests(isPrimary: Bool = true, requestId: String? = nil, _ completion: @escaping (Data?) -> Void) {
        self.getNodeGroupSharingRequests(isPrimary: isPrimary,
                                         requestId: requestId,
                                         startRequestId: nil,
                                         startUserName: nil,
                                         accumulatedRequests: [],
                                         completion)
    }

    private func getNodeGroupSharingRequests(isPrimary: Bool,
                                             requestId: String?,
                                             startRequestId: String?,
                                             startUserName: String?,
                                             accumulatedRequests: [[String: Any]],
                                             _ completion: @escaping (Data?) -> Void) {
        var url = nodeGroupSharingRequests
        url += isPrimary ? NodeGroupSharingAPIKeys.primaryUserTrueQuery : NodeGroupSharingAPIKeys.primaryUserFalseQuery

        if let requestId = requestId {
            url += NodeGroupSharingAPIKeys.requestIdQueryPrefix + requestId
        } else if let startRequestId = startRequestId {
            url += NodeGroupSharingAPIKeys.startRequestIdQueryPrefix + startRequestId
            let userName = startUserName ?? User.shared.userInfo.username
            url += NodeGroupSharingAPIKeys.startUserNameQueryPrefix + userName
        }

        self.apiManager.genericAuthorizedDataRequest(url: url, parameter: nil, method: .get) { data, _ in
            guard let data = data else {
                completion(nil)
                return
            }

            guard var response = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) else {
                completion(data)
                return
            }

            // Preserve failure payload handling in callers.
            if let status = response[ESPMatterConstants.status] as? String,
               status.lowercased() == ESPMatterConstants.failure {
                completion(data)
                return
            }

            let currentRequests = response[NodeGroupSharingAPIKeys.sharingRequestsKey] as? [[String: Any]] ?? []
            let mergedRequests = accumulatedRequests + currentRequests

            let nextRequestId = response[NodeGroupSharingAPIKeys.nextRequestIdKey] as? String
            let nextUserName = response[NodeGroupSharingAPIKeys.nextUserNameKey] as? String

            if let nextRequestId = nextRequestId, !nextRequestId.isEmpty {
                self.getNodeGroupSharingRequests(isPrimary: isPrimary,
                                                 requestId: requestId,
                                                 startRequestId: nextRequestId,
                                                 startUserName: nextUserName,
                                                 accumulatedRequests: mergedRequests,
                                                 completion)
                return
            }

            response[NodeGroupSharingAPIKeys.sharingRequestsKey] = mergedRequests
            response.removeValue(forKey: NodeGroupSharingAPIKeys.nextRequestIdKey)
            response.removeValue(forKey: NodeGroupSharingAPIKeys.nextUserNameKey)
            let mergedData = try? JSONSerialization.data(withJSONObject: response)
            completion(mergedData ?? data)
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
    func deleteRequest(requestId: String, completion: @escaping (Bool, String?) -> Void) {
        let url = nodeGroupSharingRequests + "?request_id=\(requestId)"
        self.apiManager.genericAuthorizedDataRequest(url: url, parameter: nil, method: .delete) { data, _ in
            let result = self.parseStatusAndDescription(from: data)
            completion(result.isSuccess, result.description)
        }
    }
    
    /// Act on sharing request
    /// - Parameters:
    ///   - requestId: request id
    ///   - accept: accept/decline
    func actOnSharingRequest(requestId: String, accept: Bool, completion: @escaping (Bool, String?) -> Void) {
        let url = nodeGroupSharingRequests
        self.apiManager.genericAuthorizedDataRequest(url: url, parameter: [ESPMatterConstants.accept: accept, ESPMatterConstants.requestId: requestId], method: .put) { data, _ in
            let result = self.parseStatusAndDescription(from: data)
            completion(result.isSuccess, result.description)
        }
    }
    
    
    /// Delete sharing between users
    /// - Parameter groupId: group id
    /// - Parameter email: email id
    /// - Parameter completion: completion
    func revokeAccess(groupId: String, email: String, completion: @escaping (Bool, String?) -> Void) {
        let url = nodeGroupSharing + "?groups=\(groupId)&user_name=\(email)"
        self.apiManager.genericAuthorizedDataRequest(url: url, parameter: nil, method: .delete) { data, _ in
            let result = self.parseStatusAndDescription(from: data)
            completion(result.isSuccess, result.description)
        }
    }
}
