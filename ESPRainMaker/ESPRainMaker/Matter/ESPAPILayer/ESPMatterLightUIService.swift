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
//  ESPMatterLightUIService.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation

@available(iOS 16.4, *)
class ESPMatterLightUIService {
    
    var index: Int
    var groupId: String?
    var completion: (() -> Void)?
    var data: [String: Bool] = [String: Bool]()
    let matterNodes = User.shared.discoveredNodes
    let fabricDetails = ESPMatterFabricDetails.shared
    
    init() {
        index = 0
    }
    
    func checkMatterLightStatus(completion: @escaping () -> Void) {
        self.completion = completion
        self.checkMatterLightStatus(index: index)
    }
    
    func checkMatterLightStatus(index: Int) {
        let allNodes = User.shared.associatedNodeList ?? []
        if index < allNodes.count {
            for node in allNodes {
                let isOnOffServerSupported = node.isOnOffServerSupported
                if let nodeId = node.node_id, isOnOffServerSupported.0 {
                    if let groupId = self.fabricDetails.getGroupId(nodeId: nodeId), let matterNodeId = node.getMatterNodeId, User.shared.isMatterNodeConnected(matterNodeId: matterNodeId), let group = self.getGroup(groupId: groupId), let userNOC = self.fabricDetails.getUserNOCDetails(groupId: groupId), let deviceId = matterNodeId.hexToDecimal {
                        if let grp = ESPMTRCommissioner.shared.group, let grpId = grp.groupID, grpId != groupId {
                            ESPMTRCommissioner.shared.shutDownController()
                            ESPMTRCommissioner.shared.group = group
                            ESPMTRCommissioner.shared.initializeMTRControllerWithUserNOC(matterFabricData: group, userNOCData: userNOC)
                        }
                        ESPMTRCommissioner.shared.isLightOn(groupId: groupId, deviceId: deviceId) { isLightOn in
                            self.data[nodeId] = isLightOn
                            self.index+=1
                            self.checkMatterLightStatus(index: self.index)
                        }
                    } else {
                        self.index+=1
                        self.checkMatterLightStatus(index: self.index)
                    }
                } else {
                    self.index+=1
                    self.checkMatterLightStatus(index: self.index)
                }
            }
        } else {
            User.shared.matterLightOnStatus = self.data
            self.completion?()
        }
    }
    
    private func getGroup(groupId: String) -> ESPNodeGroup? {
        if let groupsData = self.fabricDetails.getGroupsData(), let groups = groupsData.groups {
            for group in groups {
                if let id = group.groupID, id == groupId {
                    return group
                }
            }
        }
        return nil
    }
}
#endif
