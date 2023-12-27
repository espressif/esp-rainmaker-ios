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
//  ESPMatterFabricDetails+GroupsData.swift
//  ESPRainmaker
//

import Foundation

extension ESPMatterFabricDetails {
    
    /// Save groups data
    /// - Parameter groups: groups
    func saveGroupsData(groups: ESPNodeGroups) {
        let groupsKey = ESPMatterFabricKeys.shared.matterGroupsKey
        let encoder = JSONEncoder()
        var nodeGroups = groups
        self.setFabricUpdateStatus(nodeGroups: &nodeGroups)
        if let groupsData = try? encoder.encode(nodeGroups) {
            UserDefaults.standard.set(groupsData, forKey: groupsKey)
        }
    }
    
    /// Set fabric status
    /// - Parameter nodeGroups: node groups
    func setFabricUpdateStatus(nodeGroups: inout ESPNodeGroups) {
        if let savedGroups = getGroupsData() {
            for savedGroup in savedGroups.groups ?? [] {
                for index in 0..<(nodeGroups.groups ?? []).count {
                    var group = nodeGroups.groups![index]
                    if let savedId = savedGroup.groupID, let id = group.groupID, id == savedId {
                        if let savedGroupCatIdAdmin = savedGroup.fabricDetails?.catIdAdmin, let savedGroupCatIdOperate = savedGroup.fabricDetails?.catIdOperate, let catIdAdmin = group.fabricDetails?.catIdAdmin, let catIdOperate = group.fabricDetails?.catIdOperate {
                            if (savedGroupCatIdAdmin != catIdAdmin) || (savedGroupCatIdOperate != catIdOperate) {
                                group.shouldUpdate = true
                                group.oldCatIdAdmin = savedGroupCatIdAdmin
                                group.oldCatIdOperate = savedGroupCatIdOperate
                                nodeGroups.groups![index] = group
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Get groups data
    /// - Returns: groups data
    func getGroupsData() -> ESPNodeGroups? {
        let groupsKey = ESPMatterFabricKeys.shared.matterGroupsKey
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: groupsKey) as? Data, let groupsData = try? decoder.decode(ESPNodeGroups.self, from: data) {
            return groupsData
        }
        return nil
    }
    
    /// Get group data
    /// - Returns: group data
    /// - Parameter groupId: group id
    func getGroupData(groupId: String) -> ESPNodeGroup? {
        if let groups = self.getGroupsData()?.groups {
            for group in groups {
                if let id = group.groupID, id == groupId {
                    return group
                }
            }
        }
        return nil
    }
    
    /// Get fabric id
    /// - Parameter groupId: group id
    /// - Returns: returns fabric id
    func getFabricId(groupId: String) -> String? {
        if let group = self.getGroupData(groupId: groupId), let fabricId = group.fabricID {
            return fabricId
        }
        return nil
    }
    
    /// Reset groups data
    /// - Parameters:
    ///   - grps: groups
    ///   - grpId: group id
    func resetGroupsData(grps: inout ESPNodeGroups, grpId: String) {
        let groupsKey = ESPMatterFabricKeys.shared.matterGroupsKey
        let encoder = JSONEncoder()
        var finalList = [ESPNodeGroup]()
        for grp in grps.groups ?? [] {
            var newGrp: ESPNodeGroup?
            if grp.groupID ?? "" == grpId {
                newGrp = grp
                newGrp?.shouldUpdate = false
                newGrp?.oldCatIdAdmin = nil
                newGrp?.oldCatIdOperate = nil
                if let _ = newGrp {
                    finalList.append(newGrp!)
                }
            } else {
                finalList.append(grp)
            }
        }
        grps.groups = finalList
        if let groupsData = try? encoder.encode(grps) {
            UserDefaults.standard.set(groupsData, forKey: groupsKey)
        }
    }
    
    /// Remove groups data
    func removeGroupsData() {
        let groupsKey = ESPMatterFabricKeys.shared.matterGroupsKey
        if let _ = UserDefaults.standard.value(forKey: groupsKey) {
            UserDefaults.standard.removeObject(forKey: groupsKey)
        }
    }
    
    /// Save node group details
    /// - Parameter data: node group details
    func saveNodeGroupDetails(groupId: String, data: ESPNodeGroupDetails) {
        let nodeGroupDetailsKey = ESPMatterFabricKeys.shared.matterNodeGroupDetailsKey(groupId)
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(data) {
            UserDefaults.standard.set(data, forKey: nodeGroupDetailsKey)
        }
    }
    
    /// Get node group details
    /// - Returns: node group details
    func getNodeGroupDetails(groupId: String) -> ESPNodeGroupDetails? {
        let nodeGroupDetailsKey = ESPMatterFabricKeys.shared.matterNodeGroupDetailsKey(groupId)
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.value(forKey: nodeGroupDetailsKey) as? Data, let nodeGroupDetails = try? decoder.decode(ESPNodeGroupDetails.self, from: data) {
            return nodeGroupDetails
        }
        return nil
    }
    
    /// Save node details
    /// - Parameter data: node details
    func saveNodeDetails(nodeId: String, groupId: String, data: ESPNodeDetails) {
        let nodeDetailsKey = ESPMatterFabricKeys.shared.matterNodeDetailsKey("\(nodeId).\(groupId)")
        let nodeDetailsGroupIdKey = ESPMatterFabricKeys.shared.matterNodeDetailsKey(nodeId)
        let encoder = JSONEncoder()
        UserDefaults.standard.set(groupId, forKey: "\(nodeDetailsGroupIdKey).group.id")
        if let data = try? encoder.encode(data) {
            UserDefaults.standard.set(data, forKey: nodeDetailsKey)
        }
    }
    
    /// Get group id for node id
    /// - Parameter nodeId: node id
    /// - Returns: group id
    func getGroupId(nodeId: String) -> String? {
        let nodeDetailsGroupIdKey = ESPMatterFabricKeys.shared.matterNodeDetailsKey(nodeId)
        if let groupId = UserDefaults.standard.value(forKey: "\(nodeDetailsGroupIdKey).group.id") as? String {
            return groupId
        }
        return nil
    }
    
    /// Get node details
    /// - Returns: node details
    func getNodeDetails(nodeId: String) -> ESPNodeDetails? {
        if let groupId = self.getGroupId(nodeId: nodeId) {
            let nodeDetailsKey = ESPMatterFabricKeys.shared.matterNodeDetailsKey("\(nodeId).\(groupId)")
            let decoder = JSONDecoder()
            if let data = UserDefaults.standard.value(forKey: nodeDetailsKey) as? Data, let nodeDetails = try? decoder.decode(ESPNodeDetails.self, from: data) {
                return nodeDetails
            }
        }
        return nil
    }
    
    /// Get matter node id
    /// - Parameter nodeId: node id
    /// - Returns: matter node id
    func getMatterNodeId(nodeId: String) -> String? {
        if let details = self.getNodeDetails(nodeId: nodeId), let matterNodeId = details.matterNodeID {
            return matterNodeId
        }
        return nil
    }
    
    /// Remove node group details
    func removeNodeGroupDetails(groupId: String) {
        let nodeGroupDetailsKey = ESPMatterFabricKeys.shared.matterNodeGroupDetailsKey(groupId)
        if let _ = UserDefaults.standard.value(forKey: nodeGroupDetailsKey) {
            UserDefaults.standard.removeObject(forKey: nodeGroupDetailsKey)
        }
    }
    
    /// Get matter group
    /// - Parameter groupId: group id
    /// - Returns: matter group
    func getNodeGroup(groupId: String) -> ESPNodeGroup? {
        if let groupsData = self.getGroupsData(), let groups = groupsData.groups, groups.count > 0 {
            for group in groups {
                if let grpid = group.groupID, grpid == groupId {
                    return group
                }
            }
        }
        return nil
    }
}
