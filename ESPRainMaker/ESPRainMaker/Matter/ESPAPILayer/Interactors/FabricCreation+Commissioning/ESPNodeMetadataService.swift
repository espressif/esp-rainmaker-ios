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
//  ESPNodeMetadataService.swift
//  ESPRainMaker
//

import Foundation

class ESPNodeMetadataService {
    
    /// Fetch node metadata
    /// - Parameters:
    ///   - token: access token
    ///   - nodes: nodes
    ///   - completionHandler: completion
    func fetchNodeMetadata(forSingleNode singleNode: Bool, groupId: String, token: String, nodes: [ESPNodeDetails], completionHandler: @escaping () -> Void) {
        if singleNode {
            self.fetchSingleNodeMetadata(index: 0, groupId: groupId, token: token, nodes: nodes, completionHandler: completionHandler)
        } else {
            self.fetchMutipleNodeMetadata(groupId: groupId, token: token, nodes: nodes, completionHandler: completionHandler)
        }
    }
    
    /// Fetch multiple nodes metadata
    /// - Parameters:
    ///   - groupId: group id
    ///   - token: token
    ///   - nodes: nodes
    ///   - completionHandler: completion handler
    private func fetchMutipleNodeMetadata(groupId: String, token: String, nodes: [ESPNodeDetails], completionHandler: @escaping () -> Void) {
        self.fetchNodeMetadata(token: token, nodeId: nil) { nodeDetails in
            if let nodeDetails = nodeDetails {
                for detail in nodeDetails {
                    for node in nodes {
                        if let nodeId = node.nodeID, let nodeDetailId = detail[ESPMatterConstants.id] as? String, nodeId == nodeDetailId, let matterNodeId = node.getMatterNodeId() {
                            ESPMatterFabricDetails.shared.saveMetadata(details: detail, groupId: groupId, matterNodeId: matterNodeId)
                            break
                        }
                    }
                }
            }
            completionHandler()
        }
    }
    
    /// Fetch single node metadata
    /// - Parameters:
    ///   - index: index
    ///   - token: access token
    ///   - nodes: nodes
    ///   - completionHandler: completion
    private func fetchSingleNodeMetadata(index: Int, groupId: String, token: String, nodes: [ESPNodeDetails], completionHandler: @escaping () -> Void) {
        if index < nodes.count {
            let node = nodes[index]
            if let nodeId = node.nodeID, let matterNodeId = node.getMatterNodeId() {
                self.fetchNodeMetadata(token: token, nodeId: nodeId) { nodeDetails in
                    if let nodeDetails = nodeDetails, let details = nodeDetails.first {
                        ESPMatterFabricDetails.shared.saveMetadata(details: details, groupId: groupId, matterNodeId: matterNodeId)
                    }
                    self.fetchSingleNodeMetadata(index: index+1, groupId: groupId, token: token, nodes: nodes, completionHandler: completionHandler)
                }
            } else {
                self.fetchSingleNodeMetadata(index: index+1, groupId: groupId, token: token, nodes: nodes, completionHandler: completionHandler)
            }
        } else {
            completionHandler()
        }
    }
    
    /// Fetch node metadata
    /// - Parameters:
    ///   - token: access token
    ///   - nodeId: node id
    ///   - completion: completion
    private func fetchNodeMetadata(token: String, nodeId: String?, completion: @escaping ([[String: Any]]?) -> Void) {
        let endpoint = ESPMatterAPIEndpoint.getNodeMetadata(url: Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion, token: token, nodeId: nodeId)
        let apiWorker = ESPAPIWorker()
        apiWorker.callDataAPI(endPoint: endpoint) { data, _ in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let nodeDetails = json[ESPMatterConstants.nodeDetails] as? [[String: Any]], nodeDetails.count > 0 {
                completion(nodeDetails)
                return
            }
            completion(nil)
        }
    }
}
