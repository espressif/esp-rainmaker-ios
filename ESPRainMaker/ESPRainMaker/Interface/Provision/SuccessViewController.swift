// Copyright 2020 Espressif Systems
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
//  SuccessViewController.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation
import UIKit

class SuccessViewController: UIViewController {
    var statusText: String?
    var deviceID: String?
    var requestID: String?
    var success = false
    var sessionInit = true
    var ssid: String!
    var passphrase: String!
    var isThread: Bool = false
    var shouldScanThreadNetworks: Bool = false
    var threadOperationalDataset: Data?
    var espthreadNetwork: ESPThreadNetwork?
    var addDeviceStatusTimeout: Timer?
    var step1Failed = false
    var count: Int = 0
    var espDevice: ESPDevice!
    var failureMessage = ""
    private var nodeDetailsFetched = false
    private var nodeIsConnected = false
    private var setupTimeout = Timer()

    @IBOutlet var step1Image: UIImageView!
    @IBOutlet var step2Image: UIImageView!
    @IBOutlet var step3Image: UIImageView!
    @IBOutlet var step4Image: UIImageView!
    @IBOutlet var step5Image: UIImageView!
    @IBOutlet var step1Indicator: UIActivityIndicatorView!
    @IBOutlet var step2Indicator: UIActivityIndicatorView!
    @IBOutlet var step3Indicator: UIActivityIndicatorView!
    @IBOutlet var step4Indicator: UIActivityIndicatorView!
    @IBOutlet var step5Indicator: UIActivityIndicatorView!
    @IBOutlet var step1ErrorLabel: UILabel!
    @IBOutlet var step2ErrorLabel: UILabel!
    @IBOutlet var step3ErrorLabel: UILabel!
    @IBOutlet var step4ErrorLabel: UILabel!
    @IBOutlet var step5ErrorLabel: UILabel!
    @IBOutlet var finalStatusLabel: UILabel!
    @IBOutlet var okayButton: UIButton!
    
    @IBOutlet weak var step1Label: UILabel!
    @IBOutlet weak var step2Label: UILabel!
    @IBOutlet weak var step3Label: UILabel!
    @IBOutlet weak var step4Label: UILabel!
    @IBOutlet weak var step5Label: UILabel!
    @IBOutlet weak var step5TopSpaceConstraint: NSLayoutConstraint!
    
    let deviceAddedMessage = "device added successfully"
    
    var finalNode: Node?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let device = self.espDevice, let versionInfo = device.versionInfo, versionInfo.isChallengeResponseSupported() {
            self.executeChallengeResponseWorkflow()
        } else {
            if step1Failed {
                if failureMessage.count > 0 {
                    step1FailedWithMessage(message: failureMessage)
                } else {
                    step1FailedWithMessage(message: ESPProvisionConstants.wrongPOPEntered)
                }
            } else {
                startProvisioning()
            }
        }
    }
    
    // Execute Challenge Response Workflow:
    private func executeChallengeResponseWorkflow() {
        self.setupUIForChallengeResponse()
        self.startStep1()
        self.startChallengeResponseFlow { result, nodeId, errorDescription in
            guard result, let nodeId = nodeId else {
                if let errorDescription = errorDescription {
                    self.step1FailedWithMessage(message: errorDescription)
                }
                return
            }
            self.startStep2()
            self.provisionDevice(nodeId: nodeId) { provisionError in
                guard let provisionError = provisionError else {
                    User.shared.updateDeviceList = true
                    self.startStep3()
                    self.step5SetupNode(nodeID: nodeId)
                    return
                }
                self.step2FailedWithMessage(error: provisionError)
            }
        }
    }
    
    /// This method is used to setup the initial UI of the screen
    /// Number of steps is different from normal provisioning
    private func setupUIForChallengeResponse() {
        self.step1Label.text = ESPProvisionConstants.confirmingNodeAssociation
        self.step2Label.text = ESPProvisionConstants.confirmingWifiConnection
        self.step5Label.text = ESPProvisionConstants.settingUpNode
        
        self.step3Image.isHidden = true
        self.step3Indicator.isHidden = true
        self.step3Label.isHidden = true
        self.step3ErrorLabel.isHidden = true
        
        self.step4Image.isHidden = true
        self.step4Indicator.isHidden = true
        self.step4Label.isHidden = true
        self.step4ErrorLabel.isHidden = true
        
        self.step5TopSpaceConstraint.constant-=104
    }
    
    private func startStep1() {
        DispatchQueue.main.async {
            self.step1Image.isHidden = true
            self.step1Indicator.isHidden = false
            self.step1Indicator.startAnimating()
        }
    }
    
    private func startStep2() {
        DispatchQueue.main.async {
            self.step1Indicator.stopAnimating()
            self.step1Image.image = UIImage(named: "checkbox_checked")
            self.step1Image.isHidden = false
            self.step2Image.isHidden = true
            self.step2Indicator.isHidden = false
            self.step2Indicator.startAnimating()
        }
    }
    
    private func startStep3() {
        DispatchQueue.main.async {
            self.step2Indicator.stopAnimating()
            self.step2Image.image = UIImage(named: "checkbox_checked")
            self.step2Image.isHidden = false
        }
    }
    
    private func provisionDevice(nodeId: String, completion: @escaping (ESPProvisionError?) -> Void) {
        self.provision { status in
            switch status {
            case .success:
                completion(nil)
            case let .failure(error):
                completion(error)
                self.step2FailedWithMessage(error: error)
            case .configApplied:
                break
            }
        }
    }
    
    private func startChallengeResponseFlow(completionHandler: @escaping (Bool, String?, String?) -> ()) {
        User.shared.initiateMapping { [weak self] challenge, requestId, error in
            guard let self = self else { return }
            
            if let error = error {
                completionHandler(false, nil, error.localizedDescription)
                return
            }
            
            guard let challenge = challenge, let requestId = requestId else {
                completionHandler(false, nil, ESPProvisionConstants.challengeFailed)
                return
            }
            
            // Create protobuf challenge request
            var payload = RmakerMisc_RMakerMiscPayload()
            payload.msg = .typeCmdChallengeResponse
            payload.status = .success
            
            var cmdPayload = RmakerMisc_CmdCRPayload()
            cmdPayload.payload = challenge.data(using: .utf8) ?? Data()
            payload.payload = .cmdChallengeResponsePayload(cmdPayload)
            
            do {
                // Serialize to bytes
                let data = try payload.serializedData()
                
                // Send challenge to device
                self.espDevice.sendData(path: ESPScanConstants.challengeResponse, data: data) { [weak self] response, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        Utility.hideLoader(view: self.view)
                        completionHandler(false, nil, error.localizedDescription)
                        return
                    }
                    
                    guard let response = response else {
                        Utility.hideLoader(view: self.view)
                        completionHandler(false, nil, ESPProvisionConstants.noResponseFromDevice)
                        return
                    }
                    
                    // Parse protobuf response
                    do {
                        let challengeResponse = try RmakerMisc_RMakerMiscPayload(serializedData: response)
                        
                        // Check response status
                        if challengeResponse.status != .success {
                            completionHandler(false, nil, "\(ESPProvisionConstants.deviceReturnsErrorStatus): \(challengeResponse.status)")
                            return
                        }
                        
                        // Extract response payload
                        guard case let .respChallengeResponsePayload(respPayload) = challengeResponse.payload else {
                            Utility.hideLoader(view: self.view)
                            completionHandler(false, nil, ESPProvisionConstants.invalidResponseFormat)
                            return
                        }
                        
                        // Convert payload to hex string with validation
                        let bytes = [UInt8](respPayload.payload)
                        if bytes.count != 256 {
                            completionHandler(false, nil, "Invalid challenge response length: \(bytes.count), expected: 256")
                            return
                        }
                        
                        // Convert bytes to hex string
                        var hexString = ""
                        for byte in bytes {
                            // Use String(format: "%02x") to ensure exactly 2 hex chars per byte
                            // Use byte & 0xFF to handle signed bytes correctly
                            hexString += String(format: "%02x", byte & 0xFF)
                        }
                        
                        // Validate hex string length (256 bytes * 2 = 512 chars)
                        if hexString.count != 512 {
                            completionHandler(false, nil, "Invalid hex string length: \(hexString.count), expected: 512")
                            return
                        }
                        
                        // Call verify mapping API
                        User.shared.verifyUserNodeMapping(requestId: requestId, nodeId: respPayload.nodeID, challengeResponse: hexString) { [weak self] success, error in
                            guard let self = self else { return }
                            
                            if let error = error {
                                completionHandler(false, nil, error.localizedDescription)
                                return
                            }
                            
                            if success {
                                // Only after successful challenge response, proceed to provisioning
                                completionHandler(true, respPayload.nodeID, nil)
                            } else {
                                completionHandler(false, nil, ESPProvisionConstants.challengeResponseVerificationFailed)
                            }
                        }
                    } catch {
                        completionHandler(false, nil, ESPProvisionConstants.deviceResponseParsingFailed)
                    }
                }
            } catch {
                completionHandler(false, nil, ESPProvisionConstants.challengeRequestCreationFailed)
            }
        }
    }

    func startProvisioning() {
        step1Image.isHidden = true
        step1Indicator.isHidden = false
        step1Indicator.startAnimating()

        self.provision { status in
            switch status {
            case .success:
                self.step3SendRequestToAddDevice()
            case let .failure(error):
                switch error {
                case .configurationError:
                    self.step1FailedWithMessage(message: "Failed to apply network configuration to device")
                case .sessionError:
                    self.step1FailedWithMessage(message: "Session is not established")
                case .wifiStatusDisconnected:
                    self.step3SendRequestToAddDevice()
                default:
                    self.step2FailedWithMessage(error: error)
                }
            case .configApplied:
                self.step2applyConfigurations()
            }
        }
    }
    
    func provision(completionHandler: @escaping (ESPProvisionStatus) -> Void) {
        if let threadOperationalDataset = self.threadOperationalDataset {
            espDevice.provision(ssid: nil, passPhrase: nil, threadOperationalDataset: threadOperationalDataset) { status in
                completionHandler(status)
            }
        } else {
            espDevice.provision(ssid: ssid, passPhrase: passphrase, threadOperationalDataset: nil) { status in
                completionHandler(status)
            }
        }
    }

    private func step2applyConfigurations() {
        DispatchQueue.main.async {
            self.step1Indicator.stopAnimating()
            self.step1Image.image = UIImage(named: "checkbox_checked")
            self.step1Image.isHidden = false
            self.step2Image.isHidden = true
            self.step2Indicator.isHidden = false
            self.step2Indicator.startAnimating()
        }
    }

    private func step3SendRequestToAddDevice() {
        DispatchQueue.main.async {
            self.step2Indicator.stopAnimating()
            self.step2Image.image = UIImage(named: "checkbox_checked")
            self.step2Image.isHidden = false
            self.step3Image.isHidden = true
            self.step3Indicator.isHidden = false
            self.step3Indicator.startAnimating()
            self.count = 5
            self.sendRequestToAddDevice()
        }
    }

    private func step4ConfirmNodeAssociation(requestID: String) {
        okayButton.isEnabled = true
        okayButton.alpha = 1.0
        step4Image.isHidden = true
        step4Indicator.isHidden = false
        step4Indicator.startAnimating()
        checkDeviceAssoicationStatus(nodeID: User.shared.currentAssociationInfo!.nodeID, requestID: requestID)
    }

    func checkDeviceAssoicationStatus(nodeID: String, requestID: String) {
        fetchDeviceAssociationStatus(nodeID: nodeID, requestID: requestID)
    }

    @objc func timeoutFetchingStatus() {
        step4FailedWithMessage(message: "Node addition not confirmed")
        addDeviceStatusTimeout?.invalidate()
    }

    func fetchDeviceAssociationStatus(nodeID: String, requestID: String) {
        NetworkManager.shared.deviceAssociationStatus(nodeID: nodeID, requestID: requestID) { status in
            if status == "confirmed" {
                User.shared.updateDeviceList = true
                self.step4Indicator.stopAnimating()
                self.step4Image.image = UIImage(named: "checkbox_checked")
                self.step4Image.isHidden = false
                self.addDeviceStatusTimeout?.invalidate()
                self.step5SetupNode(nodeID: nodeID)
            } else if status == "timedout" {
                self.step4FailedWithMessage(message: "Node addition not confirmed")
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.fetchDeviceAssociationStatus(nodeID: nodeID, requestID: requestID)
                }
            }
        }
    }

    private func step5SetupNode(nodeID: String) {
        DispatchQueue.main.async {
            self.step5Image.isHidden = true
            self.step5Indicator.isHidden = false
            self.step5Indicator.startAnimating()
            self.setupTimeout = Timer(timeInterval: 35.0, target: self, selector: #selector(self.setupTimeOut), userInfo: nil, repeats: false)
            self.getNodeDetails(nodeID: nodeID)
            self.getNodeStatus(nodeID: nodeID)
        }
    }

    @objc private func getNodeStatus(nodeID: String) {
        let node = Node()
        node.node_id = nodeID
        NetworkManager.shared.getNodeStatus(node: node) { newNode, _ in
            if let responseNode = newNode {
                if responseNode.isConnected {
                    self.nodeIsConnected = true
                    self.check5thStepStatus()
                    return
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.getNodeStatus(nodeID: nodeID)
            }
        }
    }

    private func getNodeDetails(nodeID: String) {
        NetworkManager.shared.getNodeInfo(nodeId: nodeID) { node, _ in
            DispatchQueue.main.async {
                self.nodeDetailsFetched = true
                if let newNode = node {
                    
                    // Always store the node, regardless of client-only controller support
                    self.finalNode = newNode
                    
                    for service in newNode.services ?? [] {
                        if service.type?.lowercased() == Constants.timezoneServiceName {
                            if let param = service.params?.first(where: { $0.type?.lowercased() == Constants.timezoneServiceParam }) {
                                let timezone = param.value as? String
                                if timezone == nil || timezone!.isEmpty {
                                    DeviceControlHelper.shared.updateParam(nodeID: nodeID, parameter: [service.name ?? "Time": [param.name ?? "": TimeZone.current.identifier]], delegate: nil)
                                }
                            }
                            self.check5thStepStatus()
                        }
                    }
                }
            }
        }
    }

    @objc private func setupTimeOut() {
        DispatchQueue.main.async {
            self.step5Image.isHidden = false
            self.step5Indicator.isHidden = true
            self.step5Indicator.stopAnimating()
            if self.nodeDetailsFetched, self.nodeIsConnected {
                self.step5Image.image = UIImage(named: "checkbox_checked")
            } else {
                self.step5Image.image = UIImage(named: "warning_icon")
                self.step5ErrorLabel.isHidden = false
                self.step5ErrorLabel.text = "Failed to setup node."
            }
            self.provisionFinsihedWithStatus(message: "Device Added Successfully!!")
        }
    }

    private func check5thStepStatus() {
        DispatchQueue.main.async {
            if self.nodeDetailsFetched, self.nodeIsConnected {
                self.step5Image.image = UIImage(named: "checkbox_checked")
                self.step5Image.isHidden = false
                self.step5Indicator.isHidden = true
                self.step5Indicator.stopAnimating()
                self.provisionFinsihedWithStatus(message: "Device Added Successfully!!")
                
                //Client-Only-Controller - Only call for devices that support this flow
                if let finalNode = self.finalNode {
                    if finalNode.isClientOnlyControllerFlowSupported, let _ = finalNode.clientOnlyControllerGroupParam {
                        self.handleClientOnlyControllerFlow()
                    } else if finalNode.isRmakerControllerSupported {
                        self.showRainmakerLoginScreen()
                    }
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    func step1FailedWithMessage(message: String) {
        DispatchQueue.main.async {
            self.step1Indicator.stopAnimating()
            self.step1Image.image = UIImage(named: "error_icon")
            self.step1Image.isHidden = false
            self.step1ErrorLabel.text = message
            self.step1ErrorLabel.isHidden = false
            self.espDevice.disconnect()
            self.provisionFinsihedWithStatus(message: "Reboot your board and try again.")
        }
    }

    func step2FailedWithMessage(error: ESPProvisionError) {
        DispatchQueue.main.async {
            self.step2Indicator.stopAnimating()
            self.step2Image.image = UIImage(named: "error_icon")
            self.step2Image.isHidden = false
            var errorMessage = ""
            switch error {
            case .wifiStatusUnknownError, .wifiStatusDisconnected, .wifiStatusNetworkNotFound, .wifiStatusAuthenticationError:
                errorMessage = error.description
                self.espDevice.disconnect()
                self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
            case .wifiStatusError:
                errorMessage = "Unable to fetch Wi-Fi state."
                self.step3SendRequestToAddDevice()
            default:
                errorMessage = "Unknown error."
                self.espDevice.disconnect()
                self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
            }
            self.step2ErrorLabel.text = errorMessage
            self.step2ErrorLabel.isHidden = false
        }
    }

    func step3FailedWithMessage(message: String) {
        DispatchQueue.main.async {
            self.step3Indicator.stopAnimating()
            self.step3Image.image = UIImage(named: "error_icon")
            self.step3Image.isHidden = false
            self.step3ErrorLabel.text = message
            self.step3ErrorLabel.isHidden = false
            self.espDevice.disconnect()
            self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
        }
    }

    func step4FailedWithMessage(message: String) {
        DispatchQueue.main.async {
            self.step4Indicator.stopAnimating()
            self.step4Image.image = UIImage(named: "error_icon")
            self.step4Image.isHidden = false
            self.step4ErrorLabel.text = message
            self.step4ErrorLabel.isHidden = false
            self.espDevice.disconnect()
            self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
        }
    }

    func step5FailedWithMessage(message: String) {
        DispatchQueue.main.async {
            self.step5Indicator.stopAnimating()
            self.step5Image.image = UIImage(named: "warning_icon")
            self.step5Image.isHidden = false
            self.step5ErrorLabel.text = message
            self.step5ErrorLabel.isHidden = false
            self.provisionFinsihedWithStatus(message: "Device added successfully!!")
        }
    }

    func provisionFinsihedWithStatus(message: String) {
        okayButton.isEnabled = true
        okayButton.alpha = 1.0
        finalStatusLabel.text = message
        finalStatusLabel.isHidden = false
        // Trigger in-app review for device provisioning success
        if message.lowercased().contains(deviceAddedMessage) {
            ESPReviewManager.shared.onDeviceProvisioned()
        }
    }

    @objc func sendRequestToAddDevice() {
        let parameters = ["user_id": User.shared.userInfo.userID, "node_id": User.shared.currentAssociationInfo!.nodeID, "secret_key": User.shared.currentAssociationInfo!.uuid, "operation": "add"]
        NetworkManager.shared.addDeviceToUser(parameter: parameters as! [String: String]) { requestID, error in
            if error != nil, self.count > 0 {
                self.count = self.count - 1
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self.perform(#selector(self.sendRequestToAddDevice), with: nil, afterDelay: 5.0)
                }
            } else {
                if let requestid = requestID {
                    self.step3Indicator.stopAnimating()
                    self.step3Image.image = UIImage(named: "checkbox_checked")
                    self.step3Image.isHidden = false
                    self.step4ConfirmNodeAssociation(requestID: requestid)
                } else {
                    self.step3FailedWithMessage(message: error?.description ?? "Unrecognized error. Please check your internet.")
                }
            }
        }
    }

    @IBAction func goToFirstView(_: Any) {
        let destinationVC = navigationController?.viewControllers.first as! DevicesViewController
        destinationVC.checkDeviceAssociation = true
        navigationController?.navigationBar.isHidden = false
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: Controller service utility methods
extension SuccessViewController {
    
    /// Handle workflow for client only controller device type
    private func handleClientOnlyControllerFlow() {
        if let finalNode = self.finalNode, finalNode.isClientOnlyControllerFlowSupported {
            NodeGroupManager.shared.getNodeGroups { nodeGroups, _ in
                if let nodeGroups = nodeGroups, nodeGroups.count > 0 {
                    self.showGroupSelectionScreen()
                } else {
                    self.showErrorAlert(title: "Warning", message: "You don't have a single group created. Please create a group so that this controller device can be associated to it.", buttonTitle: "OK") {}
                }
            }
        }
    }
    
    /// Show Rainmaker Login Screen
    func showRainmakerLoginScreen(groupId: String? = nil) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        if let nav = storyboard.instantiateViewController(withIdentifier: "signInController") as? UINavigationController {
            if let signInVC = nav.viewControllers.first as? SignInViewController, let tab = self.tabBarController {
                signInVC.setClientOnlyControllerFlow(isRainmakerControllerFlow: true,
                                                     isClientOnlyControllerFlow: true,
                                                     groupId: groupId)
                signInVC.clientOnlyControllerDelegate = self
                self.navigationController?.pushViewController(signInVC, animated: true)
            }
        }
    }
    
    func showGroupSelectionScreen() {
        #if ESPRainMakerMatter
        let storyBrd = UIStoryboard(name: ESPMatterConstants.matterStoryboardId, bundle: nil)
        let fabricSelectionVC = storyBrd.instantiateViewController(withIdentifier: ESPFabricSelectionVC.storyboardId) as! ESPFabricSelectionVC
        fabricSelectionVC.isClientOnlyContoller = true
        fabricSelectionVC.clientOnlyControllerDelegate = self
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.pushViewController(fabricSelectionVC, animated: true)
        #endif
    }
}

#if ESPRainMakerMatter
extension SuccessViewController: ClientOnlyControllerGroupSelectionDelegate {
    
    func groupSelected(groupId: String) {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
            if groupId.count > 0 {
                self.showRainmakerLoginScreen(groupId: groupId)
            }
        }
    }
}
#endif

extension SuccessViewController: ClientOnlyControllerCredentialsDelegate {
    
    func loginCompleted(cloudResponse: ESPSessionResponse, groupId: String?) {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
        
        let baseURL = Configuration.shared.awsConfiguration.baseURL
        let refreshToken = cloudResponse.refreshToken ?? ""
        
        if let node = self.finalNode {
            if node.isClientOnlyControllerFlowSupported {
                self.updateParamsForClientOnlyController(baseURL: baseURL, refreshToken: refreshToken, groupId: groupId, node: node)
            } else if node.isRmakerControllerSupported {
                self.updateParamsForRmakerController(baseURL: baseURL, refreshToken: refreshToken, node: node)
            }
        }
    }
    
    private func updateParamsForClientOnlyController(baseURL: String?, refreshToken: String, groupId: String?, node: Node) {
        if refreshToken.count > 0,
           let baseURL = baseURL,
           let serviceName = node.getServiceName(forServiceType: Constants.matterControllerServiceType),
           let nodeId = node.node_id,
           let grpIdParamName = node.clientOnlyControllerGroupParam?.name,
           let baseURLParamName = node.clientOnlyControllerBaseURLParam?.name,
           let userTokenName = node.clientOnlyControllerUserTokenParam?.name,
           let groupId = groupId {
            
            let params: [String: Any] = [serviceName : [baseURLParamName: baseURL,
                                                           userTokenName: refreshToken,
                                                          grpIdParamName: groupId] as Any]
            DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: params, delegate: self) { status in
                if status == .success {
                    //Client-Only-Controller
                }
            }
        }
    }
    
    private func updateParamsForRmakerController(baseURL: String?, refreshToken: String, node: Node) {
        if refreshToken.count > 0,
           let baseURL = baseURL,
           let serviceName = node.getServiceName(forServiceType: RainmakerControllerConstants.rmakerControllerServiceType),
           let nodeId = node.node_id,
           let baseURLParamName = node.rmakerControllerBaseURLParam?.name,
           let userTokenName = node.rmakerControllerUserTokenParam?.name {
            
            let params: [String: Any] = [serviceName : [baseURLParamName: baseURL,
                                            userTokenName: refreshToken] as Any]
            DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: params, delegate: self) { status in
                if status == .success {
                    //Rainmaker-Controller
                }
            }
        }
    }
}

extension SuccessViewController: ParamUpdateProtocol {
    
    func failureInUpdatingParam() {
        
    }
}
