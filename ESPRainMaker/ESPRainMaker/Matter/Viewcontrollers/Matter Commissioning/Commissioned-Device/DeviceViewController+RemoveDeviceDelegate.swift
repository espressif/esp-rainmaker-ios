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
//  DeviceViewController+RemoveDeviceDelegate.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import UIKit

@available(iOS 16.4, *)
extension DeviceViewController: RemoveDeviceDelegate {
    
    /// Remove device
    func removeDevice() {
        let yesAction = UIAlertAction(title: ESPMatterConstants.yesTxt, style: .destructive) {_ in
            let worker = ESPExtendUserSessionWorker()
            worker.checkUserSession { token, _ in
                if let token = token, let node = self.node, let nodeId = node.nodeID, let rainmakerNode = User.shared.getNode(id: nodeId), let groupId = rainmakerNode.groupId {
                    self.checkConnectionAndRemoveFabric(node: node) { _ in
                        DispatchQueue.main.async {
                            Utility.showLoader(message: ESPMatterConstants.removingDeviceMsg, view: self.view)
                        }
                        let userId = User.shared.userInfo.userID
                        let params = [ESPMatterConstants.nodes: [nodeId],
                                      ESPMatterConstants.operation: ESPMatterConstants.remove]
                        let endpoint = ESPMatterAPIEndpoint.removeNodeFromFabric(groupId: groupId, token: token, params: params)
                        let service = ESPAddNodeToMatterFabricService(presenter: self)
                        service.removeNode(endpoint: endpoint)
                    }
                }
            }
        }
        let cancelAction = UIAlertAction(title: ESPMatterConstants.cancelTxt, style: .cancel) { _ in }
        self.showAlertWithOptions(title: ESPMatterConstants.rmDeviceTxt, message: ESPMatterConstants.removeDeviceMsg, actions: [yesAction, cancelAction])
    }
    
    /// Check matter connection and remove fabric
    /// - Parameters:
    ///   - node: node
    ///   - completion: completion
    func checkConnectionAndRemoveFabric(node: ESPNodeDetails, completion: @escaping (Bool) -> Void) {
        if let nodeId = node.nodeID, let matterNodeId = node.matterNodeID, User.shared.isMatterNodeConnected(matterNodeId: matterNodeId), let deviceId = matterNodeId.hexToDecimal {
            ESPMTRCommissioner.shared.readCurrentFabricIndex(deviceId: deviceId) { index in
                guard let index = index else {
                    completion(false)
                    return
                }
                ESPMTRCommissioner.shared.removeFabricAtIndex(deviceId: deviceId, atIndex: index) { result in
                    completion(result)
                }
            }
        } else {
            completion(false)
        }
    }
}
#endif
