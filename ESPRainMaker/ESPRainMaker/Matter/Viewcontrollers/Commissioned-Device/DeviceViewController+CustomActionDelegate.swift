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
//  DeviceViewController+CustomActionDelegate.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import UIKit

@available(iOS 16.4, *)
extension DeviceViewController: CustomActionDelegate {
    
    func mergeThreadDataset() {}
    func setActiveThreadDataset() {}
    
    //MARK: Custom Action
    /// Launch controller
    func launchController() {
        if let groupId = self.group?.groupID, let node = self.rainmakerNode, let matterNodeId = node.matter_node_id, let deviceId = matterNodeId.hexToDecimal {
            let clusterInfo = ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: groupId, deviceId: deviceId)
            var endpoint: UInt16 = 0
            if let point = clusterInfo.1, let id = UInt16(point) {
                endpoint = id
            }
            DispatchQueue.main.async {
                Utility.showLoader(message: "", view: self.view)
            }
            ESPMTRCommissioner.shared.readAttributeUserNOCInstalledOnDevice(deviceId: deviceId, endpoint: endpoint) { result in
                if result {
                    ESPMTRCommissioner.shared.updateDeviceListOnDevice(deviceId: deviceId, endpoint: endpoint) { result in
                        DispatchQueue.main.async {
                            Utility.hideLoader(view: self.view)
                            if !result {
                                self.alertUser(title: ESPMatterConstants.failureTxt,
                                               message: ESPMatterConstants.operationFailedMsg,
                                               buttonTitle: ESPMatterConstants.okTxt,
                                               callback: {})
                            }
                        }
                    }
                    return
                }
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                    self.launchLoginScreen(groupId: groupId, matterNodeId: matterNodeId)
                }
            }
        }
    }
    
    /// Update thread dataset
    func updateThreadDataset() {
        if let groupId = self.group?.groupID, let node = self.rainmakerNode, let matterNodeId = node.matter_node_id, let deviceId = matterNodeId.hexToDecimal {
            // Show loader
            DispatchQueue.main.async {
                Utility.showLoader(message: "", view: self.view)
            }
            ESPMTRCommissioner.shared.updateThreadDataset(groupId: groupId, deviceId: deviceId) { status, message in
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                    if status {
                        self.alertUser(title: ThreadBRMessages.success.rawValue,
                                       message: message ?? ThreadBRMessages.addthreadCredsSuccess.rawValue,
                                       buttonTitle: ThreadBRMessages.ok.rawValue) {}
                    } else if let message = message {
                        if message == ThreadBRMessages.homepodDatasetNotAvailable.rawValue {
                            ESPMTRCommissioner.shared.updateThreadDataLocally(groupId: groupId, deviceId: deviceId) { result, _ in
                                DispatchQueue.main.async {
                                    self.alertUser(title: result ? ThreadBRMessages.success.rawValue : ThreadBRMessages.failure.rawValue,
                                                   message: result ? ThreadBRMessages.setThreadCredsLocally.rawValue : ThreadBRMessages.failedToSetThreadCredsLocally.rawValue,
                                                   buttonTitle: "OK") {}
                                }
                            }
                        } else {
                            if message.count > 0 {
                                self.alertUser(title: ThreadBRMessages.failure.rawValue,
                                               message: message,
                                               buttonTitle: ThreadBRMessages.ok.rawValue) {}
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Launch login screen
    /// - Parameters:
    ///   - groupId: group Id
    ///   - matterNodeId: matter node id
    func launchLoginScreen(groupId: String, matterNodeId: String) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        if let nav = storyboard.instantiateViewController(withIdentifier: "signInController") as? UINavigationController {
            if let signInVC = nav.viewControllers.first as? SignInViewController, let tab = self.tabBarController {
                signInVC.setRainmakerControllerProperties(isRainmakerControllerFlow: true,
                                                      groupId: groupId,
                                                      matterNodeId: matterNodeId,
                                                      rainmakerControllerDelegate: self)
                nav.modalPresentationStyle = .fullScreen
                tab.present(nav, animated: true, completion: nil)
            }
        }
    }
    
    /// Append refresh token
    /// - Parameters:
    ///   - deviceId: device id
    ///   - refreshToken: refresh token
    ///   - completion: completion
    func appendRefreshToken(deviceId: UInt64, endpoint: UInt16, refreshToken: String, completion: @escaping (Bool) -> Void) {
        let index = refreshToken.index(refreshToken.startIndex, offsetBy: 960)
        let firstPayload = refreshToken[..<index]
        let secondPayload = refreshToken.replacingOccurrences(of: firstPayload, with: "")
        ESPMTRCommissioner.shared.appendRefreshTokenToDevice(deviceId: deviceId, endpoint: endpoint, token: String(firstPayload)) { result in
            if result {
                ESPMTRCommissioner.shared.appendRefreshTokenToDevice(deviceId: deviceId, endpoint: endpoint, token: secondPayload) { result in
                    completion(result)
                }
                return
            }
            completion(false)
        }
    }
    
    /// Authorize
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpointURL: endpoint URL
    ///   - completion: completion
    func authorize(matterNodeId: String, deviceId: UInt64, endpoint: UInt16, endpointURL: String) {
        ESPMTRCommissioner.shared.authorizeDevice(deviceId: deviceId, endpoint: endpoint, endpointURL: Configuration.shared.awsConfiguration.baseURL) { result in
            if result {
                ESPMTRCommissioner.shared.updateUserNOCOnDevice(deviceId: deviceId, endpoint: endpoint) { result in
                    if result  {
                        ESPMTRCommissioner.shared.updateDeviceListOnDevice(deviceId: deviceId, endpoint: endpoint) { isDeviceListUpdated in
                            DispatchQueue.main.async {
                                if isDeviceListUpdated {
                                    Utility.hideLoader(view: self.view)
                                    User.shared.updateDeviceList = true
                                } else {
                                    self.hideLoaderAndShowError()
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.hideLoaderAndShowError()
                        }
                    }
                }
                return
            } else {
                DispatchQueue.main.async {
                    self.hideLoaderAndShowError()
                }
            }
        }
    }
}

@available(iOS 16.4, *)
extension DeviceViewController: RainmakerControllerFlowDelegate {
    
    func controllerFlowCancelled() {}
    
    func cloudLoginConcluded(cloudResponse: ESPSessionResponse?, groupId: String, matterNodeId: String) {
        if let cloudResponse = cloudResponse, cloudResponse.isValid, let refreshToken = cloudResponse.refreshToken {
            self.fabricDetails.saveAWSTokens(cloudResponse: cloudResponse, groupId: groupId, matterNodeId: matterNodeId)
            if let deviceId = matterNodeId.hexToDecimal {
                DispatchQueue.main.async {
                    Utility.showLoader(message: "", view: self.view)
                }
                let clusterInfo = ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: groupId, deviceId: deviceId)
                var endpoint: UInt16 = 0
                if let point = clusterInfo.1, let id = UInt16(point) {
                    endpoint = id
                }
                ESPMTRCommissioner.shared.resetRefreshTokenInDevice(deviceId: deviceId, endpoint: endpoint) { result in
                    if result {
                        self.appendRefreshToken(deviceId: deviceId, endpoint: endpoint, refreshToken: refreshToken) { result in
                            if result {
                                self.authorize(matterNodeId: matterNodeId, deviceId: deviceId, endpoint: endpoint, endpointURL: Configuration.shared.awsConfiguration.baseURL)
                            } else {
                                DispatchQueue.main.async {
                                    self.hideLoaderAndShowError()
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.hideLoaderAndShowError()
                        }
                    }
                }
            }
        }
    }
    
    /// Hide loader and show error
    func hideLoaderAndShowError() {
        Utility.hideLoader(view: self.view)
        self.showErrorAlert(title: ESPMatterConstants.failureTxt,
                            message: ESPMatterConstants.operationFailedMsg,
                            buttonTitle: ESPMatterConstants.okTxt,
                            callback: {})
    }
}
#endif
