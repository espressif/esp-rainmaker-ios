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

@available(iOS 16.4, *)
class ESPMatterCommissioningVC: UIViewController {

    static let storyboardId = "ESPMatterCommissioningVC"
    let csrQueue = DispatchQueue(label: "com.matterqueue.generate.csr")
    var groupId: String?
    var group: ESPNodeGroup?
    var nodes: [ESPNodeDetails]?
    var onboardingPayload: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavigationBar()
        self.issueUserNOC()
    }
    
    func setNavigationBar() {
        //Navigation bar clear color
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
        //Custom Bottom Line
        self.navigationController?.addCustomBottomLine(color: .darkGray, height: 0.5)
        //Title text attributes
        self.title = "Commissioning"
        //Navigation text attributes
        self.setNavigationTextAttributes(color: .darkGray)
        //Left bar button item
        let goBackButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(goBack))
        goBackButton.tintColor = .darkGray
        self.navigationItem.leftBarButtonItem = goBackButton
    }
    
    /// Issue user NOC
    func issueUserNOC() {
        if let group = group, let groupId = group.groupID {
            guard let _ = ESPMatterFabricDetails.shared.getUserNOCDetails(groupId: groupId) else {
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
            self.startCommissioningProcess()
        }
    }
    
    /// Initialize matter controller
    func initializeMatterController() {
        if let group = group, let grpId = group.groupID, let userNOCData = ESPMatterFabricDetails.shared.getUserNOCDetails(groupId: grpId) {
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
}

//MARK: commissioning methods
@available(iOS 16.4, *)
extension ESPMatterCommissioningVC {
    
    /// Setup commissioning session
    func setup() async {
        ESPMatterEcosystemInfo.shared.removeOnboardingPayload()
        ESPMatterEcosystemInfo.shared.removeDeviceName()
        ESPMatterEcosystemInfo.shared.removeCertDeclaration()
        ESPMatterEcosystemInfo.shared.removeAttestationInfo()
        if let group = self.group, let groupName = group.groupName, let _ = self.onboardingPayload {
            self.launchCommissioningDialog(groupName: groupName)
        }
    }
    
    /// Launch commissioning dialog
    /// - Parameter groupName: group name
    func launchCommissioningDialog(groupName: String) {
        self.alertUser(title: ESPMatterConstants.info, message: ESPMatterConstants.scanQRCodeMsg, buttonTitle: ESPMatterConstants.okTxt, callback: {
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
            self.showErrorAlert(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.commissioningFailureMsg, buttonTitle: ESPMatterConstants.okTxt, callback: {})
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
                ESPMatterFabricDetails.shared.saveUserNOCDetails(groupId: groupId, data: response)
                ESPMTRCommissioner.shared.shutDownController()
                self.startCommissioningProcess()
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
    
    func reloadData() {
        DispatchQueue.main.async {
            User.shared.updateDeviceList = true
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func showError(title: String, message: String, buttonTitle: String) {
        DispatchQueue.main.async {
            self.showErrorAlert(title: title, message: message, buttonTitle: buttonTitle, callback: {})
        }
    }
    
    //TODO: update_device_cat_ids: Write to ACL
    func updateDeviceCATIds(completion: @escaping () -> Void) {
        var index = 0
        if let group = self.group, group.shouldUpdate, let fabricDetails = group.fabricDetails, let catIdAdminHex = fabricDetails.catIdAdmin, let catIdAdmin = "FFFFFFFD\(catIdAdminHex)".hexToDecimal, let catIdOperateHex = fabricDetails.catIdOperate, let catIdOperate = "FFFFFFFD\(catIdOperateHex)".hexToDecimal, let nodes = self.nodes, nodes.count > 0 {
            for node in nodes {
                if let matterNodeId = node.matterNodeID, let deviceId = matterNodeId.hexToDecimal {
                    ESPMTRCommissioner.shared.readAllACLAttributes(deviceId: deviceId) { accessControlEntries in
                        if var accessControlEntries = accessControlEntries, accessControlEntries.count > 0 {
                            var entries = [MTRAccessControlClusterAccessControlEntryStruct]()
                            for index in 0..<accessControlEntries.count {
                                var entry = accessControlEntries[index]
                                if entry.privilege.intValue == 5 {
                                    entry.subjects = [catIdAdmin]
                                } else if entry.privilege.intValue == 3 {
                                    entry.subjects = [catIdOperate]
                                }
                                entries.append(entry)
                            }
                            ESPMTRCommissioner.shared.writeAllACLAttributes(deviceId: deviceId, accessControlEntry: entries) { result in
                                if result {
                                    print("cat ids updated successfully: admin: \(catIdAdmin), operate: \(catIdOperate)")
                                }
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
#endif
