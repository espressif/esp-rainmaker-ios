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
//  ESPMatterNodeDetailsService.swift
//  ESPRainMaker
//

import Foundation

class ESPMatterNodeDetailsService {
    
    var index: Int
    var groups: [NodeGroup]
    var groupId: String?
    var completion: (() -> Void)?
    var service: ESPGetNodeGroupsService?
    
    init(groups: [NodeGroup]) {
        index = 0
        self.groups = groups
        self.service = ESPGetNodeGroupsService(presenter: self)
    }
    
    func getNodeDetails(completion: @escaping () -> Void) {
        self.getNodeDetails(index: self.index, completion: completion)
    }
    
    func getNodeDetails(index: Int, completion: @escaping () -> Void) {
        self.completion = completion
        if self.groups.count > 0, self.index < self.groups.count {
            let group = groups[self.index]
            if let groupId = group.group_id {
                self.groupId = groupId
                let worker = ESPExtendUserSessionWorker()
                worker.checkUserSession { token, _ in
                    if let token = token {
                        let nodeGroupURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion
                        self.service?.getNodeDetails(url: nodeGroupURL, token: token, groupId: groupId)
                    }
                }
            } else {
                self.index+=1
                self.getNodeDetails(index: self.index+1, completion: completion)
            }
        } else {
            completion()
        }
    }
}

extension ESPMatterNodeDetailsService: ESPGetNodeGroupsPresentationLogic {
    
    func receivedNodeGroupsData(data: ESPNodeGroups?, error: Error?) {}
    
    func receivedNodeGroupDetailsData(data: ESPNodeGroupDetails?, error: Error?) {
        self.index+=1
        if let completion = self.completion {
            guard let _ = error else {
                if let data = data, let groupId = self.groupId {
                    ESPMatterFabricDetails.shared.saveNodeGroupDetails(groupId: groupId, data: data)
                    if let groups = data.groups, groups.count > 0, let group = groups.last {
                        if let nodeDetails = group.nodeDetails {
                            for nodeDetail in nodeDetails {
                                if let nodeId = nodeDetail.nodeID {
                                    ESPMatterFabricDetails.shared.saveNodeDetails(nodeId: nodeId, groupId: groupId, data: nodeDetail)
                                    for node in User.shared.associatedNodeList ?? [] {
                                        if let id = node.node_id, id == nodeId {
                                            if let metadata = node.metadata, let matterNodeId = nodeDetail.matterNodeID {
                                                ESPMatterFabricDetails.shared.saveMetadata(details: metadata, groupId: groupId, matterNodeId: matterNodeId)
                                            }
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                self.getNodeDetails(index: self.index+1, completion: completion)
                return
            }
            self.getNodeDetails(index: self.index+1, completion: completion)
        }
    }
}
