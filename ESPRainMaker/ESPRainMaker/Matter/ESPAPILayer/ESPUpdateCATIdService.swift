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
    let fabricDetails = ESPMatterFabricDetails.shared
    
    init() {
        index = 0
        matterNodes = self.getNodes()
    }
    
    /// Get nodes list
    /// - Returns: nodes list
    func getNodes() -> [Node] {
        var matterNodes: [Node] = [Node]()
        if let nodes = User.shared.associatedNodeList {
            for node in nodes {
                if node.isMatter, let matterNodeId = node.getMatterNodeId {
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
    
    /// Initialize matter controller
    /// - Parameters:
    ///   - groupId: group id
    ///   - group: group
    func initMatterController(groupId: String, group: ESPNodeGroup) {
        ESPMTRCommissioner.shared.shutDownController()
        ESPMTRCommissioner.shared.group = group
        if let noc = self.fabricDetails.getUserNOCDetails(groupId: groupId) {
            ESPMTRCommissioner.shared.initializeMTRControllerWithUserNOC(matterFabricData: group, userNOCData: noc)
        }
    }
    
    /// Get ACL entries to be updated
    /// - Parameters:
    ///   - entries: ACL entries read from device
    ///   - catIdOperate: CAT Id Operate
    /// - Returns: (updated ACL list, should update)
    func getUpdatedACL(entries: [MTRAccessControlClusterAccessControlEntryStruct], catIdOperate: UInt64) -> ([MTRAccessControlClusterAccessControlEntryStruct], Bool) {
        var updateACL: Bool = false
        var newEntries = [MTRAccessControlClusterAccessControlEntryStruct]()
        for entry in entries {
            var newEntry = MTRAccessControlClusterAccessControlEntryStruct()
            if let subjects = entry.subjects as? [NSNumber] {
                let privilege = entry.privilege.intValue
                if privilege == 5 {
                    newEntries.append(entry)
                } else if privilege == 3 {
                    if !subjects.contains(NSNumber(value: catIdOperate)) {
                        newEntry = entry
                        newEntry.subjects = [NSNumber(value: catIdOperate)]
                        newEntries.append(newEntry)
                        updateACL = true
                    }
                } else {
                    newEntries.append(entry)
                }
            }
        }
        return (newEntries, updateACL)
    }
    
    /// Updte CAT id
    /// - Parameter completion: completion
    func updateCATId(completion: @escaping () -> Void) {
        self.completion = completion
        self.update(index: index)
    }
    
    /// Update
    /// - Parameter index: group index in groups list
    func update(index: Int) {
        if let matterNodes = self.matterNodes, index < matterNodes.count {
            let node = matterNodes[index]
            if let nodeId = node.node_id, let groupId = self.fabricDetails.getGroupId(nodeId: nodeId), let group = self.fabricDetails.getGroupData(groupId: groupId), let matterNodeId = node.getMatterNodeId, User.shared.isMatterNodeConnected(matterNodeId: matterNodeId), let deviceId = matterNodeId.hexToDecimal {
                if let _ = ESPMTRCommissioner.shared.sController {
                    if let group = ESPMTRCommissioner.shared.group, let grpId = group.groupID, grpId != groupId {
                        self.initMatterController(groupId: groupId, group: group)
                    }
                } else {
                    self.initMatterController(groupId: groupId, group: group)
                }
                ESPMTRCommissioner.shared.readAllACLAttributes(deviceId: deviceId) { entries in
                    if let entries = entries, let fabricDetails = group.fabricDetails, let catIdOperate = fabricDetails.catIdOperateDecimal {
                        let newEntries = self.getUpdatedACL(entries: entries, catIdOperate: catIdOperate)
                        if newEntries.0.count > 0, newEntries.1 == true {
                            ESPMTRCommissioner.shared.writeAllACLAttributes(deviceId: deviceId, accessControlEntry: newEntries.0) { status in
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
