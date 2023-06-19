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
//  ESPUpdateCATIdService.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation

@available(iOS 16.4, *)
class ESPUpdateCATIdService {
    
    var index: Int
    var matterNodes: [Node]?
    var completion: (() -> Void)?
    
    init() {
        index = 0
        matterNodes = self.getNodes()
    }
    
    func getNodes() -> [Node] {
        var matterNodes: [Node] = [Node]()
        if let nodes = User.shared.associatedNodeList {
            for node in nodes {
                if node.isMatter, let matterNodeId = node.matterNodeId {
                    for device in User.shared.discoveredNodes {
                        if device.contains(matterNodeId) {
                            matterNodes.append(node)
                        }
                    }
                }
            }
        }
        return matterNodes
    }
    
    func updateCATId(completion: @escaping () -> Void) {
        self.completion = completion
        self.update(index: index)
    }
    
    func update(index: Int) {
        if let matterNodes = self.matterNodes, index < matterNodes.count {
            let node = matterNodes[index]
            if let nodeId = node.node_id, let groupId = ESPMatterFabricDetails.shared.getGroupId(nodeId: nodeId), let group = ESPMatterFabricDetails.shared.getGroupData(groupId: groupId), let matterNodeId = node.matterNodeId, User.shared.isMatterNodeConnected(matterNodeId: matterNodeId), let deviceId = matterNodeId.hexToDecimal {
                ESPMTRCommissioner.shared.shutDownController()
                ESPMTRCommissioner.shared.group = group
                if let noc = ESPMatterFabricDetails.shared.getUserNOCDetails(groupId: groupId) {
                    ESPMTRCommissioner.shared.initializeMTRControllerWithUserNOC(matterFabricData: group, userNOCData: noc)
                }
                ESPMTRCommissioner.shared.readAllACLAttributes(deviceId: deviceId) { entries in
                    if let entries = entries, let fabricDetails = group.fabricDetails, let catIdAdminHex = fabricDetails.catIdAdmin, let catIdAdmin = "FFFFFFFD\(catIdAdminHex)".hexToDecimal, let catIdOperateHex = fabricDetails.catIdOperate, let catIdOperate = "FFFFFFFD\(catIdOperateHex)".hexToDecimal {
                        var updateACL: Bool = false
                        var newEntries = [MTRAccessControlClusterAccessControlEntryStruct]()
                        for entry in entries {
                            var newEntry = MTRAccessControlClusterAccessControlEntryStruct()
                            if let subjects = entry.subjects as? [UInt64] {
                                let privilege = entry.privilege.intValue
                                if privilege == 5, !subjects.contains(catIdAdmin) {
                                    newEntry = entry
                                    newEntry.subjects = [catIdAdmin]
                                    newEntries.append(newEntry)
                                    updateACL = true
                                } else if privilege == 3, !subjects.contains(catIdOperate) {
                                    newEntry = entry
                                    newEntry.subjects = [catIdOperate]
                                    newEntries.append(newEntry)
                                    updateACL = true
                                } else {
                                    newEntries.append(entry)
                                }
                            }
                        }
                        if newEntries.count > 0, updateACL == true {
                            ESPMTRCommissioner.shared.writeAllACLAttributes(deviceId: deviceId, accessControlEntry: newEntries) { _ in
                                self.update(index: index+1)
                            }
                        } else {
                            self.update(index: index+1)
                        }
                    } else {
                        self.update(index: index+1)
                    }
                }
            } else {
                self.update(index: index+1)
            }
        } else {
            self.completion?()
        }
    }
}
#endif
