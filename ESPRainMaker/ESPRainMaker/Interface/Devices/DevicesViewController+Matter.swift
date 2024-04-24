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
//  DevicesViewController+Matter.swift
//  ESPRainMaker
//

import Foundation

#if ESPRainMakerMatter
//MARK: Matter utility methods
@available(iOS 16.4, *)
extension DevicesViewController {
    
    /// Search for nearby matter devices using bonjour services
    /// - Parameter completion: completion handler
    func searchForMatterDevices(completion: @escaping ([String]) -> Void) {
        DispatchQueue.main.async {
            User.shared.startCommissionedMatterServiceDiscovery() { discoveredNodes in
                completion(discoveredNodes)
            }
        }
    }
    
    /// Stop matter discovery
    func stopMatterDiscovery() {
        User.shared.stopMatterDiscovery()
    }
    
    /// Get node group matter fabric details
    func getNodeGroupMatterFabricDetails() {
        DispatchQueue.main.async {
            Utility.showLoader(message: "Fetching group details...", view: self.view)
        }
        let extendSessionWorker = ESPExtendUserSessionWorker()
        extendSessionWorker.checkUserSession { token, _ in
            if let token = token {
                let url = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion
                let service = ESPGetNodeGroupsService(presenter: self)
                service.getNodeGroupsMatterFabricDetails(url: url, token: token)
            }
        }
    }
    
    /// Get matter node details
    /// - Parameters:
    ///   - groups: matter groups
    ///   - completion: completion handler
    func getMatterNodeGroupDetails(groups: [NodeGroup], completion: @escaping () -> Void) {
        let service = ESPMatterNodeDetailsService(groups: groups)
        service.getNodeDetails {
            completion()
        }
    }
    
    /// Fetch user nocs
    /// - Parameters:
    ///   - groups: for groups
    ///   - completion: completion handler
    func fetchUserNOCs(groups: [NodeGroup], completion: @escaping () -> Void) {
        let issueUserNOCService = ESPGetUserNOCService(groups: groups)
        issueUserNOCService.issueUserNOC {
            completion()
        }
    }
    
    /// Check matter light on/off status
    /// - Parameter completion: completion handler
    func checkMatterLightStatus(completion: @escaping () -> Void) {
        let service = ESPMatterLightUIService()
        service.checkMatterLightStatus {
            completion()
        }
    }
    
    /// Remove user nocs for changed cat ids
    /// - Parameters:
    ///   - savedGroups: saved groups
    ///   - groups: recevied groups
    func removeSavedUserNOCs(savedGroups: [ESPNodeGroup], groups: [ESPNodeGroup]) {
        for group in groups {
            for savedGroup in savedGroups {
                if let savedGroupId = savedGroup.groupID, let groupId = group.groupID, savedGroupId == groupId {
                    if let savedCATIdAdmin = savedGroup.fabricDetails?.catIdAdmin, let savedCATIdOperate = savedGroup.fabricDetails?.catIdOperate, let catIdAdmin = group.fabricDetails?.catIdAdmin, let catIdOperate = group.fabricDetails?.catIdOperate {
                        if (savedCATIdAdmin != catIdAdmin) || (savedCATIdOperate != catIdOperate) {
                            self.fabricDetails.removeUserNOCDetails(groupId: groupId)
                        }
                    }
                }
            }
        }
    }
}

@available(iOS 16.4, *)
extension DevicesViewController: ESPGetNodeGroupsPresentationLogic {
    
    func receivedNodeGroupsData(data: ESPNodeGroups?, error: Error?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
        }
        if let data = data, let groups = data.groups, groups.count > 0 {
            if let savedGroupsData = self.fabricDetails.getGroupsData(), let savedGroups = savedGroupsData.groups {
                self.removeSavedUserNOCs(savedGroups: savedGroups, groups: groups)
            }
            self.fabricDetails.saveGroupsData(groups: data)
            self.groups?.removeAll()
            self.groups = data.groups
            if let nodeGroups = self.nodeGroups {
                DispatchQueue.main.async {
                    Utility.showLoader(message: ESPMatterConstants.fetchingDeviceDetailsMsg, view: self.view)
                }
                self.fetchUserNOCs(groups: nodeGroups) {
                    DispatchQueue.main.async {
                        Utility.hideLoader(view: self.view)
                    }
                    self.searchForMatterDevices { _ in
                        DispatchQueue.main.async {
                            self.stopMatterDiscovery()
                            self.collectionView.reloadData()
                        }
                        let updateCATService = ESPUpdateCATIdService()
                        updateCATService.updateCATId {
                            DispatchQueue.main.async {
                                self.stopMatterDiscovery()
                                self.searchForMatterDevicesOnLocalNetwork() {}
                            }
                        }
                    }
                }
            }
        }
    }
    
    func receivedNodeGroupDetailsData(data: ESPNodeGroupDetails?, error: Error?) {}
}
#endif
