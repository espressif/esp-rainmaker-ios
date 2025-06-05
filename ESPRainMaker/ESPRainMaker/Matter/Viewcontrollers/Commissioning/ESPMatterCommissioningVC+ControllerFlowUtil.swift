// Copyright 2024 Espressif Systems
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
//  ESPMatterCommissioningVC+ControllerFlowUtil.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import UIKit
import MatterSupport
import Matter
import Foundation

//MARK: rainmaker controller methods
@available(iOS 16.4, *)
extension ESPMatterCommissioningVC: RainmakerControllerFlowDelegate {
    
    /// Show Rainmaker Login Screen
    func showRainmakerLoginScreen(groupId: String, matterNodeId: String) {
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
    
    /// Controller flow cancelled
    func controllerFlowCancelled() {
        DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    /// Append refresh token
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoint: endpoint
    ///   - groupId: group id
    ///   - refreshToken: refresh token
    ///   - completion: completion
    func appendRefreshToken(deviceId: UInt64, endpoint: UInt16, groupId: String, refreshToken: String, completion: @escaping (Bool) -> Void) {
        let index = refreshToken.index(refreshToken.startIndex, offsetBy: 960)
        let firstPayload = refreshToken[..<index]
        let secondPayload = refreshToken.replacingOccurrences(of: firstPayload, with: "")
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
        commissioner.appendRefreshTokenToDevice(deviceId: deviceId, endpoint: endpoint, token: String(firstPayload)) { result in
            if result {
                commissioner.appendRefreshTokenToDevice(deviceId: deviceId, endpoint: endpoint, token: secondPayload) { result in
                    completion(result)
                }
                return
            }
            completion(false)
        }
    }

    /// Authorize
    /// - Parameters:
    ///   - matterNodeId: matter node id
    ///   - deviceId: device id
    ///   - endpoint: endpoint
    ///   - groupId: group id
    ///   - endpointURL: endpoint URL
    func authorize(matterNodeId: String, deviceId: UInt64, endpoint: UInt16, groupId: String, endpointURL: String) {
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
        commissioner.authorizeDevice(deviceId: deviceId, endpoint: endpoint, endpointURL: Configuration.shared.awsConfiguration.baseURL) { result in
            if result {
                commissioner.updateUserNOCOnDevice(deviceId: deviceId, endpoint: endpoint) { result in
                    if result {
                        commissioner.updateDeviceListOnDevice(deviceId: deviceId, endpoint: endpoint) { isDeviceListUpdated in
                            DispatchQueue.main.async {
                                if isDeviceListUpdated {
                                    self.goToHomeScreen(isRainmaker: true)
                                } else {
                                    self.hideLoaderAndAlertUser()
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.hideLoaderAndAlertUser()
                        }
                    }
                }
                return
            }
            DispatchQueue.main.async {
                self.hideLoaderAndAlertUser()
            }
        }
    }

    /// Cloud login completed
    /// - Parameters:
    ///   - cloudResponse: cloud response
    ///   - groupId: group id
    ///   - matterNodeId: matter node id
    func cloudLoginConcluded(cloudResponse: ESPSessionResponse?, groupId: String, matterNodeId: String) {
        if let cloudResponse = cloudResponse, var refreshToken = cloudResponse.refreshToken, let deviceId = matterNodeId.hexToDecimal {
            let clusterInfo = ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: groupId, deviceId: deviceId)
            var endpoint: UInt16 = 0
            if let point = clusterInfo.1, let id = UInt16(point) {
                endpoint = id
            }
            self.fabricDetails.saveAWSTokens(cloudResponse: cloudResponse, groupId: groupId, matterNodeId: matterNodeId)
            DispatchQueue.main.async {
                Utility.showLoader(message: ESPMatterConstants.updatingDeviceListMsg, view: self.view)
            }
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
            commissioner.resetRefreshTokenInDevice(deviceId: deviceId, endpoint: endpoint) { result in
                if result {
                    self.appendRefreshToken(deviceId: deviceId, endpoint: endpoint, groupId: groupId, refreshToken: refreshToken) { result in
                        if result {
                            self.authorize(matterNodeId: matterNodeId, deviceId: deviceId, endpoint: endpoint, groupId: groupId, endpointURL: Configuration.shared.awsConfiguration.baseURL)
                        } else {
                            DispatchQueue.main.async {
                                self.hideLoaderAndAlertUser()
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.hideLoaderAndAlertUser()
                    }
                }
            }
        }
    }
}
#endif
