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
//  ESPMatterCommissioningVC.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import UIKit
import MatterSupport
import Matter
import Foundation

@available(iOS 16.4, *)
class ESPMatterCommissioningVC: UIViewController {

    static let storyboardId = "ESPMatterCommissioningVC"
    let csrQueue = DispatchQueue(label: "com.matterqueue.generate.csr")
    var groupId: String?
    var group: ESPNodeGroup?
    var matterNodeId: String?
    var nodes: [ESPNodeDetails]?
    var onboardingPayload: String?
    let fabricDetails = ESPMatterFabricDetails.shared
    let paramTypes = [Constants.scanQRCode,
                 Constants.slider,
                 Constants.hue,
                 Constants.toggle,
                 Constants.hueCircle,
                 Constants.bigSwitch,
                 Constants.dropdown,
                 Constants.trigger,
                 Constants.hidden]
    
    @IBOutlet weak var topBarTitle: BarTitle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.topBarTitle.text = ESPMatterConstants.commissioning
        self.issueUserNOC()
    }
    
    /// Back pressed by user
    /// - Parameter sender: button
    @IBAction func backButtonPressed(_ sender: Any) {
        DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    /// Issue user NOC
    func issueUserNOC() {
        if let group = group, let groupId = group.groupID {
            guard let _ = self.fabricDetails.getUserNOCDetails(groupId: groupId) else {
                Utility.showLoader(message: "Issuing user NOC...", view: self.view)
                var finalCSRString = ""
                self.csrQueue.async {
                    ESPMTRCommissioner.shared.generateCSR(groupId: groupId) { csr in
                        if let csr = csr {
                            finalCSRString = csr.replacingOccurrences(of: "\n", with: "")
                            finalCSRString = "\(ESPMatterConstants.csrHeader)\n" + finalCSRString + "\n\(ESPMatterConstants.csrFooter)"
                        }
                        let nodeGroupURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion
                        let service = ESPIssueUserNOCService(presenter: self)
                        service.issueUserNOC(url: nodeGroupURL, groupId: groupId, operation: ESPMatterConstants.add, csr: finalCSRString)
                    }
                }
                return
            }
            ESPMTRCommissioner.shared.shutDownController()
            Task {
                await self.setup()
            }
        }
    }
    
    /// Initialize matter controller
    func initializeMatterController() {
        if let group = group, let grpId = group.groupID, let userNOCData = self.fabricDetails.getUserNOCDetails(groupId: grpId) {
            ESPMTRCommissioner.shared.shutDownController()
            ESPMTRCommissioner.shared.group = group
            ESPMTRCommissioner.shared.initializeMTRControllerWithUserNOC(matterFabricData: group, userNOCData: userNOCData)
        }
    }
    
    /// Start commissioning process with MatterSupport
    func startCommissioningProcess() {
        Task {
            await self.setup()
        }
    }
    
    /// Setup commissioning session
    func setup() async {
        ESPMatterEcosystemInfo.shared.removeOnboardingPayload()
        ESPMatterEcosystemInfo.shared.removeDeviceName()
        ESPMatterEcosystemInfo.shared.removeCertDeclaration()
        ESPMatterEcosystemInfo.shared.removeAttestationInfo()
        if let group = self.group, let groupName = group.groupName, let groupId = group.groupID {
            if let onboardingPayload = self.onboardingPayload, let setupPayload = try? MTRSetupPayload(onboardingPayload: onboardingPayload) {
                self.startEcosystemCommissioning(matterEcosystemName: Configuration.shared.appConfiguration.matterEcosystemName,
                                                 groupName: groupName,
                                                 setupPayload: setupPayload)
            } else {
                self.startEcosystemCommissioning(matterEcosystemName: Configuration.shared.appConfiguration.matterEcosystemName,
                                                 groupName: groupName,
                                                 groupId: groupId,
                                                 showDeviceCriteria: true,
                                                 setupPayload: nil)
            }
        }
    }
    
    /// Start commissioning to Apple's ecosystem
    /// - Parameters:
    ///   - matterEcosystemName: matter ecosystem name
    ///   - groupName: group name
    ///   - showDeviceCriteria: show device criteria
    ///   - setupPayload: setup payload
    func startEcosystemCommissioning(matterEcosystemName: String, groupName: String, groupId: String? = nil, showDeviceCriteria: Bool = false, setupPayload: MTRSetupPayload?) {
        Task {
            let topology = MatterAddDeviceRequest.Topology(ecosystemName: matterEcosystemName, homes: [MatterAddDeviceRequest.Home(displayName: groupName)])
            var setupRequest = MatterAddDeviceRequest(topology: topology, setupPayload: setupPayload)
            if showDeviceCriteria {
                setupRequest.showDeviceCriteria = .allDevices
            }
            do {
                try await setupRequest.perform()
                self.validatePayloadAndStartCommissioning(groupName: groupName)
            } catch {
                self.validatePayloadAndStartCommissioning(groupName: groupName)
            }
        }
    }
    
    /// Start controller update process
    /// - Parameter deviceId: device id
    func startControllerUpdate(deviceId: UInt64, endpoint: UInt16, matterNodeId: String, refreshToken: String) {
        ESPMTRCommissioner.shared.resetRefreshTokenInDevice(deviceId: deviceId, endpoint: endpoint) { result in
            if result {
                self.appendRefreshToken(deviceId: deviceId, endpoint: endpoint, refreshToken: refreshToken) { result in
                    if result {
                        self.authorize(matterNodeId: matterNodeId, deviceId: deviceId, endpoint: endpoint, endpointURL: Configuration.shared.awsConfiguration.baseURL)
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
    
    /// Hide loader and alert user
    func hideLoaderAndAlertUser() {
        Utility.hideLoader(view: self.view)
        self.alertUser(title: ESPMatterConstants.emptyString,
                       message: ESPMatterConstants.operationFailedMsg,
                       buttonTitle: ESPMatterConstants.okTxt,
                       callback: {
            self.goToHomeScreen()
        })
    }
    
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
    
    /// Go to Home screen
    func goToHomeScreen() {
        if let groupId = self.groupId, let matterNodeId = self.matterNodeId, let deviceId = matterNodeId.hexToDecimal {
            if ESPMatterClusterUtil.shared.isRainmakerServerSupported(groupId: groupId, deviceId: deviceId).0 {
                DispatchQueue.main.async {
                    Utility.showLoader(message: "", view: self.view)
                }
                self.updateDeviceName {
                    DispatchQueue.main.async {
                        Utility.hideLoader(view: self.view)
                        User.shared.updateDeviceList = true
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            } else {
                if let name = ESPMatterEcosystemInfo.shared.getDeviceName() {
                    DispatchQueue.main.async {
                        Utility.showLoader(message: "", view: self.view)
                    }
                    ESPMTRCommissioner.shared.setNodeLabel(deviceId: deviceId, nodeLabel: name) { result in
                        self.fabricDetails.removeNodeLabel(groupId: groupId, deviceId: deviceId)
                        if result {
                            self.fabricDetails.saveNodeLabel(groupId: groupId, deviceId: deviceId, nodeLabel: name)
                        }
                        DispatchQueue.main.async {
                            Utility.hideLoader(view: self.view)
                            User.shared.updateDeviceList = true
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        User.shared.updateDeviceList = true
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                User.shared.updateDeviceList = true
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    /// Update device name for rainmaker + matter nodes
    /// - Parameter completion: completion handler
    func updateDeviceName(completion: @escaping () -> Void) {
        NetworkManager.shared.getNodes { nodes, _ in
            if let nodes = nodes, nodes.count > 0 {
                User.shared.associatedNodeList = nodes
                for node in nodes {
                    if let nodeId = node.node_id, node.isRainmaker, let deviceName = node.userDefinaedName, let groupId = self.groupId, let savedDeviceName = ESPMatterEcosystemInfo.shared.getDeviceName(), savedDeviceName == deviceName, let devices = node.devices, devices.count > 0 {
                        let device = devices[0]
                        for param in device.params ?? [] {
                            if let type = param.type, type == Constants.deviceNameParam, let properties = param.properties, properties.contains("write"), let name = device.name {
                                let attributeKey = param.name ?? ""
                                DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: [name: [attributeKey: deviceName]], delegate: self) { _ in
                                    completion()
                                }
                                return
                            }
                        }
                    }
                }
                completion()
            } else {
                completion()
            }
        }
    }
}

//MARK: rainmaker controller methods
@available(iOS 16.4, *)
extension ESPMatterCommissioningVC: RainmakerControllerFlowDelegate {
    
    /// Controller flow cancelled
    func controllerFlowCancelled() {
        DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: true)
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
                    if result {
                        ESPMTRCommissioner.shared.updateDeviceListOnDevice(deviceId: deviceId, endpoint: endpoint) { isDeviceListUpdated in
                            DispatchQueue.main.async {
                                if isDeviceListUpdated {
                                    self.goToHomeScreen()
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
            ESPMTRCommissioner.shared.resetRefreshTokenInDevice(deviceId: deviceId, endpoint: endpoint) { result in
                if result {
                    self.appendRefreshToken(deviceId: deviceId, endpoint: endpoint, refreshToken: refreshToken) { result in
                        if result {
                            self.authorize(matterNodeId: matterNodeId, deviceId: deviceId, endpoint: endpoint, endpointURL: Configuration.shared.awsConfiguration.baseURL)
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

//MARK: commissioning methods
@available(iOS 16.4, *)
extension ESPMatterCommissioningVC {
    
    /// Validate onboarding payload and start commissioning
    /// - Parameter groupName: group name
    func validatePayloadAndStartCommissioning(groupName: String) {
        if let _ = ESPMatterEcosystemInfo.shared.getOnboardingPayload() {
            self.startCommissioning()
        } else {
            DispatchQueue.main.async {
                self.hideLoaderAndAlertUser()
            }
        }
    }
    
    /// Launch commissioning dialog
    /// - Parameter groupName: group name
    func launchCommissioningDialog(groupName: String) {
        self.alertUser(title: ESPMatterConstants.info,
                       message: ESPMatterConstants.scanQRCodeMsg,
                       buttonTitle: ESPMatterConstants.okTxt,
                       callback: {
            Task {
                let topology = MatterAddDeviceRequest.Topology(ecosystemName: Configuration.shared.appConfiguration.matterEcosystemName, homes: [MatterAddDeviceRequest.Home(displayName: groupName)])
                let setupRequest = MatterAddDeviceRequest(topology: topology)
                do {
                    try await setupRequest.perform()
                    self.matterSupportFlowCompleted()
                } catch {
                    self.matterSupportFlowCompleted()
                }
            }
        })
    }
    
    /// Matter support flow completed
    func matterSupportFlowCompleted() {
        if let _ = ESPMatterEcosystemInfo.shared.getOnboardingPayload() {
            self.startCommissioning()
        } else {
            self.showErrorAlert(title: ESPMatterConstants.failureTxt,
                                message: ESPMatterConstants.commissioningFailureMsg,
                                buttonTitle: ESPMatterConstants.okTxt,
                                callback: {})
        }
    }
    
    /// start custom fabric commissioning flow
    func startCommissioning() {
        if let payload = ESPMatterEcosystemInfo.shared.getOnboardingPayload() {
            self.initializeMatterController()
            let deviceId = ESPMatterDeviceManager.shared.getNextAvailableDeviceID()
            ESPMatterDeviceManager.shared.setNextAvailableDeviceID(deviceId+1)
            ESPMTRCommissioner.shared.uidelegate = self
            ESPMTRCommissioner.shared.startCommissioningWithUserNOC(onboardingPayload: payload, deviceId: deviceId)
        }
    }
}

//MARK: issue user noc
@available(iOS 16.4, *)
extension ESPMatterCommissioningVC: ESPIssueUserNOCPresentationLogic {
    
    func userNOCReceived(groupId: String,
                         response: ESPIssueUserNOCResponse?,
                         error: Error?) {
        Utility.hideLoader(view: self.view)
        guard let _ = error else {
            if let response = response {
                self.fabricDetails.saveUserNOCDetails(groupId: groupId, data: response)
                ESPMTRCommissioner.shared.shutDownController()
                Task {
                    await self.setup()
                }
            }
            return
        }
    }
}

/// UI delegate
@available(iOS 16.4, *)
extension ESPMatterCommissioningVC: ESPMTRUIDelegate {
    
    func showToastMessage(message: String) {
        //show toast message
    }
    
    func hideToastMessage() {
        //hide toast message
    }
    
    func showLoaderInView(message: String) {
        DispatchQueue.main.async {
            Utility.showLoader(message: message, view: self.view)
        }
    }
    
    func hideLoaderFromView() {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
        }
    }
    
    func reloadData(groupId: String? = nil, matterNodeId: String? = nil) {
        self.matterNodeId = matterNodeId
        if let groupId = groupId, let matterNodeId = matterNodeId, let deviceId = matterNodeId.hexToDecimal {
            if ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: groupId, deviceId: deviceId).0 {
                //Show login screen
                self.alertUser(title: ESPMatterConstants.emptyString,
                               message: ESPMatterConstants.controllerNeedsAccessMsg,
                               buttonTitle: ESPMatterConstants.okTxt) {
                    DispatchQueue.main.async {
                        self.showRainmakerLoginScreen(groupId: groupId, matterNodeId: matterNodeId)
                    }
                }
            } else {
                //Go to home screen
                if let nodes = User.shared.associatedNodeList, nodes.count > 0 {
                    var shouldUpdateDeviceList = false
                    var id: UInt64?
                    for node in  nodes {
                        if let grpId = node.groupId, let matterNodeId = node.matter_node_id, let deviceId = matterNodeId.hexToDecimal, grpId == groupId, node.isRainmakerControllerSupported.0 {
                            shouldUpdateDeviceList = true
                            id = deviceId
                            break
                        }
                    }
                    if shouldUpdateDeviceList, let id = id {
                        DispatchQueue.main.async {
                            Utility.showLoader(message: "", view: self.view)
                        }
                        var endpoint: UInt16 = 0
                        let clusterInfo = ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: groupId, deviceId: id)
                        if let point = clusterInfo.1, let id = UInt16(point) {
                            endpoint = id
                        }
                        ESPMTRCommissioner.shared.updateDeviceListOnDevice(deviceId: id, endpoint: endpoint) { result in
                            DispatchQueue.main.async {
                                Utility.hideLoader(view: self.view)
                                self.goToHomeScreen()
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.goToHomeScreen()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.goToHomeScreen()
                    }
                }
            }
        }
    }

    
    func showError(title: String, message: String, buttonTitle: String) {
        DispatchQueue.main.async {
            self.showErrorAlert(title: title,
                                message: message,
                                buttonTitle: buttonTitle,
                                callback: {})
        }
    }
    
    //TODO: update_device_cat_ids: Write to ACL
    func updateDeviceCATIds(completion: @escaping () -> Void) {
        var index = 0
        if let group = self.group, group.shouldUpdate, let fabricDetails = group.fabricDetails, let catIdAdmin = fabricDetails.catIdAdminDecimal, let catIdOperate = fabricDetails.catIdOperateDecimal, let nodes = self.nodes, nodes.count > 0 {
            for node in nodes {
                if let matterNodeId = node.matterNodeID, let deviceId = matterNodeId.hexToDecimal {
                    ESPMTRCommissioner.shared.readAllACLAttributes(deviceId: deviceId) { accessControlEntries in
                        if var accessControlEntries = accessControlEntries, accessControlEntries.count > 0 {
                            var entries = [MTRAccessControlClusterAccessControlEntryStruct]()
                            for index in 0..<accessControlEntries.count {
                                var entry = accessControlEntries[index]
                                if entry.privilege.intValue == 5 {
                                    entry.subjects = [NSNumber(value: catIdAdmin)]
                                } else if entry.privilege.intValue == 3 {
                                    entry.subjects = [NSNumber(value: catIdOperate)]
                                }
                                entries.append(entry)
                            }
                            ESPMTRCommissioner.shared.writeAllACLAttributes(deviceId: deviceId, accessControlEntry: entries) { result in
                                index+=1
                                if index >= nodes.count {
                                    completion()
                                }
                            }
                        } else {
                            index+=1
                            if index >= nodes.count {
                                completion()
                            }
                        }
                    }
                } else {
                    index+=1
                    if index >= nodes.count {
                        completion()
                    }
                }
            }
        } else {
            completion()
        }
    }
}

@available(iOS 16.4, *)
extension ESPMatterCommissioningVC: ParamUpdateProtocol {
    
    func failureInUpdatingParam() {
        
    }
}
#endif
