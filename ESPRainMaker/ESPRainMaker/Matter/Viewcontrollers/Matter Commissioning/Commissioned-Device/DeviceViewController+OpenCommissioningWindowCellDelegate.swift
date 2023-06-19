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
        if let matterNodeId = self.matterNodeId, let id = matterNodeId.hexToDecimal, let controller = ESPMTRCommissioner.shared.sController {
            controller.getBaseDevice(id, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let commissioningWindowCluster = MTRBaseClusterAdministratorCommissioning(device: device, endpointID: NSNumber(value: 0), queue: ESPMTRCommissioner.shared.matterQueue), let saltData = ESPDefaultData.threadSaltData.data(using: .utf8), let pakeVerifierData = ESPDefaultData.threadPAKEVerifierData.data(using: .utf8), let pakeVerifier = Data(base64Encoded: pakeVerifierData), let salt = Data(base64Encoded: saltData) {
                    let params = MTRAdministratorCommissioningClusterOpenCommissioningWindowParams()
                    params.pakeVerifier = pakeVerifier
                    params.salt = salt
                    params.discriminator = NSNumber(value: 3840)
                    params.iterations = NSNumber(value: 15000)
                    params.commissioningTimeout = NSNumber(value: 300)
                    params.timedInvokeTimeoutMs = NSNumber(value: 60000)
                    commissioningWindowCluster.openWindow(with: params) { error in
                        if let error = error {
                            DispatchQueue.main.async {
                                self.showErrorAlert(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.openCWFailureMsg, buttonTitle: ESPMatterConstants.okTxt, callback: {})
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.showManualPairingCode()
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Show manual pairing code
    func showManualPairingCode() {
        let dismissAction = UIAlertAction(title: ESPMatterConstants.dismissTxt, style: .default) { _ in}
        let copyMsgAction = UIAlertAction(title: ESPMatterConstants.copyCodeMsg, style: .default) { _ in
            let pasteboard = UIPasteboard.general
            pasteboard.string = ESPDefaultData.openCWManualPairingCode
        }
        self.showAlertWithOptions(title: ESPMatterConstants.pairingModeTitle, message: ESPMatterConstants.pairingModeMessage, actions: [copyMsgAction, dismissAction])
    }
}
#endif
