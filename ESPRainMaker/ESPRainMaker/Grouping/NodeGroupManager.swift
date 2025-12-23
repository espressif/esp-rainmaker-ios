// Copyright 2021 Espressif Systems
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
//  NodeGroupManager.swift
//  ESPRainMaker
//

import Alamofire
import Foundation

// Class to manage group related methods
class NodeGroupManager {
    private var apiManager = ESPAPIManager()
    
    // Convert to computed property for dynamic URL resolution  
    private var nodeGroupURL: String { Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/node_group" }

    var nodeGroups: [NodeGroup] = []
    var primaryGroup: NodeGroup?
    static let shared = NodeGroupManager()
    var listUpdated = false
    let fabricDetails = ESPMatterFabricDetails.shared

    private init() {
        // Listen for configuration updates and reinitialize API manager
        NotificationCenter.default.addObserver(self, selector: #selector(configurationUpdated), name: NSNotification.Name(Constants.configurationUpdateNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func configurationUpdated() {
        // Reinitialize the API manager to pick up new server trust configuration
        apiManager = ESPAPIManager()
    }
    
    /// Get node group for group id
    /// - Parameter id: group id
    /// - Returns: node group
    func getGroupForId(id: String) -> NodeGroup? {
        return nodeGroups.first(where: {
            if let gId = $0.group_id, gId == id {
                return true
            }
            return false
        })
    }

    /// Returns true when cached group data lists this node id (uses `NodeGroup.nodes` from last fetch).
    /// Call after `getNodeGroups` has populated `nodeGroups` (e.g. fabric selection already loads groups).
    func isNodeInGroup(nodeId: String, groupId: String) -> Bool {
        guard let nodes = getGroupForId(id: groupId)?.nodes else {
            return false
        }
        return nodes.contains(nodeId)
    }

    /// Method to get node groups for the current user
    ///
    /// - Parameters:
    ///   - completionHandler: Callback method that is invoked in case request is successfully processed or fails in between.
    func getNodeGroups(partialNodeGroupList: [NodeGroup]? = nil, nextID: String? = nil, completionHandler: @escaping ([NodeGroup]?, ESPNetworkError?) -> Void) {
        var url = nodeGroupURL + "?node_list=true"
        if let nextID = nextID {
            url = url + "&start_id=" + nextID
        }
        apiManager.genericAuthorizedDataRequest(url: url, parameter: nil, method: .get) { result, error in
            guard let response = result else {
                completionHandler(nil, error!)
                return
            }
            do {
                let decoder = JSONDecoder()
                // Check for failure in response
                if let failureResponse = try? decoder.decode(ESPCloudResponse.self, from: response) {
                    completionHandler(nil, .serverError(failureResponse.description))
                    return
                } else {
                    // Initializing Group objects from response data
                    
                    #if ESPRainMakerMatter
                    // Save group metadata
                    if let groupsData = try? JSONSerialization.jsonObject(with: response) as? [String: Any], let groups = groupsData[ESPMatterConstants.groups] as? [[String: Any]] {
                        for group in groups {
                            if let groupId = group[ESPMatterConstants.groupId] as? String {
                                if let groupMetadata = group[ESPMatterConstants.groupMetadata] as? [String: Any] {
                                    self.fabricDetails.saveGroupMetadata(groupId: groupId, groupMetadata: groupMetadata)
                                } else {
                                    self.fabricDetails.removeGroupMetadata(groupId: groupId)
                                }
                            }
                        }
                    }
                    #endif
                    
                    let groups = try decoder.decode(Group.self, from: response)
                    
                    // Check if additional node group is present
                    var groupList:[NodeGroup] = []
                    if let partialNodeGroupList = partialNodeGroupList {
                        groupList = partialNodeGroupList
                    }
                    groupList.append(contentsOf: groups.groups)
                    if let nextID = groups.nextID {
                        self.getNodeGroups(partialNodeGroupList: groupList, nextID: nextID, completionHandler: completionHandler)
                    } else {
                        // Sorting Groups by their name ascending
                        groupList.sort(by: { $0.group_name?.lowercased() ?? "" < $1.group_name?.lowercased() ?? "" })
                        // Adding reference of node object in groups
                        self.updateNodeListInNodeGroup(nodeGroup: groupList)
                        self.nodeGroups = groupList
                        ESPLocalStorageHandler().saveNodeGroups(self.nodeGroups)
                        completionHandler(groupList, nil)
                    }
                    return
                }
            } catch {
                completionHandler(nil, .parsingError(error.localizedDescription))
            }
        }
    }

    /// Method to create node groups for the logged-in user
    ///
    /// - Parameters:
    ///   - group: Group for which create request will be made.
    ///   - completionHandler: Callback method that is invoked in case request is successfully processed or fails in between.
    func createNodeGroup(group: NodeGroup, completionHandler: @escaping (NodeGroup?, ESPNetworkError?) -> Void) {
        // Initializing parameter for create group request
        var parameter: [String: Any] = ["group_name": group.group_name!]
        if let nodes = group.nodes {
            parameter["nodes"] = nodes
        }
        apiManager.genericAuthorizedDataRequest(url: nodeGroupURL, parameter: parameter, method: .post) { result, error in
            guard let response = result else {
                completionHandler(nil, error!)
                return
            }
            do {
                let decoder = JSONDecoder()
                // Check for failure in response
                if let failureResponse = try? decoder.decode(ESPCloudResponse.self, from: response) {
                    completionHandler(nil, .serverError(failureResponse.description))
                    return
                } else {
                    let createNodeGroup = try decoder.decode(CreateNodeGroupResponse.self, from: response)
                    // Check if group ID is present before marking the response as successful
                    group.group_id = createNodeGroup.group_id
                    completionHandler(group, nil)
                    return
                }
            } catch {
                completionHandler(nil, .parsingError(error.localizedDescription))
            }
        }
    }

    /// Method to perform group operations like remove, add nodes, rename etc.
    ///
    /// - Parameters:
    ///   - group: Group for which operation will be performed.
    ///   - completionHandler: Callback method that is invoked in case request is successfully processed or fails in between.
    func performNodeGroupOperation(group: NodeGroup, parameter: [String: Any]?, method: HTTPMethod, completionHandler: @escaping (Bool, ESPNetworkError?) -> Void) {
        apiManager.genericAuthorizedDataRequest(url: nodeGroupURL + "?group_id=\(group.group_id!)", parameter: parameter, method: method) { result, error in
            guard let response = result else {
                completionHandler(false, error!)
                return
            }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ESPCloudResponse.self, from: response)
                // Check for success in response
                if response.status.lowercased() == "success" {
                    completionHandler(true, nil)
                    return
                } else {
                    completionHandler(false, .serverError(response.description))
                }
            } catch {
                completionHandler(false, .parsingError(error.localizedDescription))
            }
        }
    }
    
    /// Add a node to an existing group.
    /// - Parameters:
    ///   - nodeId: Node id to be added.
    ///   - groupId: Group id where node should be added.
    ///   - completionHandler: Callback invoked with operation status.
    func addNodeToGroup(nodeId: String, groupId: String, completionHandler: @escaping (Bool, ESPNetworkError?) -> Void) {
        guard let group = getGroupForId(id: groupId) else {
            completionHandler(false, .serverError("Group not found"))
            return
        }
        let parameter: [String: Any] = ["operation": "add", "nodes": [nodeId]]
        performNodeGroupOperation(group: group, parameter: parameter, method: .put, completionHandler: completionHandler)
    }

    /// Method to add reference of node object in groups
    ///
    ///
    func updateNodeListInNodeGroup(nodeGroup: [NodeGroup]?) {
        if let groups = nodeGroup {
            // Iterate through groups and find associated node by node ID
            for group in groups {
                var nodeList: [Node] = []
                for node in User.shared.associatedNodeList ?? [] {
                    if let groupNodes = group.nodes, groupNodes.contains(node.node_id ?? "") {
                        nodeList.append(node)
                    }
                }
                group.nodeList = nodeList
            }
        }
    }
}
