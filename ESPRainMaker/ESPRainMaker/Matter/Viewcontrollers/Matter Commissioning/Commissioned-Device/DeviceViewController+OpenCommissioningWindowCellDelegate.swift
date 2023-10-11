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
//  DeviceViewController+OpenCommissioningWindowCellDelegate.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import UIKit

@available(iOS 16.4, *)
extension DeviceViewController: OpenCommissioningWindowCellDelegate {
    
    /// Open commissioning Window
    func openCommissioningWindow() {
        if let matterNodeId = self.matterNodeId, let id = matterNodeId.hexToDecimal {
            if User.shared.discoveredNodes.contains(matterNodeId) {
                ESPMTRCommissioner.shared.isCommissioningWindowOpen(deviceId: id) { status, error in
                    guard let error = error else {
                        if let status = status, !status {
                            ESPMTRCommissioner.shared.openCommissioningWindow(deviceId: id) { setupPasscode in
                                if let setupPasscode = setupPasscode {
                                    self.showManualPairingCode(setupPasscode: setupPasscode)
                                } else {
                                    self.alertUser(title: ESPMatterConstants.failureTxt,
                                                   message: ESPMatterConstants.commissioningWindowOpenFailedMsg,
                                                   buttonTitle: ESPMatterConstants.okTxt,
                                                   callback: {})
                                }
                            }
                        } else {
                            self.alertUser(title: ESPMatterConstants.emptyString,
                                           message: ESPMatterConstants.commissioningWindowAlreadyOpenMsg,
                                           buttonTitle: ESPMatterConstants.okTxt,
                                           callback: {})
                        }
                        return
                    }
                }
            } else {
                Utility.showToastMessage(view: self.view,
                                         message: ESPMatterConstants.deviceNotReachableMsg)
            }
        }
    }
    
    /// Show manual pairing code
    func showManualPairingCode(setupPasscode: String) {
        let dismissAction = UIAlertAction(title: ESPMatterConstants.dismissTxt, style: .default) { _ in}
        let copyMsgAction = UIAlertAction(title: ESPMatterConstants.copyCodeMsg, style: .default) { _ in
            let pasteboard = UIPasteboard.general
            pasteboard.string = setupPasscode
        }
        self.showAlertWithOptions(title: ESPMatterConstants.pairingModeTitle, message: ESPMatterConstants.pairingModeMessage, actions: [copyMsgAction, dismissAction])
    }
}
#endif
