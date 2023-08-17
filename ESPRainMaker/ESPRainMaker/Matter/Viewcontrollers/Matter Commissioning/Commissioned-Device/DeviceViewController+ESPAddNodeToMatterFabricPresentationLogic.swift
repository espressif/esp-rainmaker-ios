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
//  DeviceViewController+ESPAddNodeToMatterFabricPresentationLogic.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import UIKit

@available(iOS 16.4, *)
extension DeviceViewController: ESPAddNodeToMatterFabricPresentationLogic {
    
    /// Node NOC received
    /// - Parameters:
    ///   - groupId: group  id
    ///   - response: response
    ///   - error: error
    func nodeNOCReceived(groupId: String,
                         response: ESPAddNodeToFabricResponse?,
                         error: Error?) {}
    
    /// Node removed
    /// - Parameters:
    ///   - status: node removal status
    ///   - error: error
    func nodeRemoved(status: Bool,
                     error: Error?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
        }
        if status {
            if let group = self.group, let groupId = group.groupID, let node = self.node, let matterNodeId = node.getMatterNodeId(), let deviceId = matterNodeId.hexToDecimal {
                ESPMatterFabricDetails.shared.removeControllerNodeId(matterNodeId: matterNodeId)
                ESPMatterFabricDetails.shared.removeLinkedDevice(groupId: groupId, deviceId: deviceId, endpointClusterId: endpointClusterId)
            }
            DispatchQueue.main.async {
                User.shared.updateDeviceList = true
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            DispatchQueue.main.async {
                self.showErrorAlert(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.failedToRemoveDeviceMsg, buttonTitle: ESPMatterConstants.okTxt, callback: {})
            }
        }
    }
}
#endif
