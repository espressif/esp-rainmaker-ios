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

protocol SuccessViewControllerDelegate: AnyObject {
    func wifiResetSuccess(withNodeId nodeId: String?, withDevice device: ESPDevice?)
}

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
    weak var successDelegate: SuccessViewControllerDelegate?
    var wifiReset: Bool = false
    var wifiResetNodeId: String?
    var errorMessage: String?
    
    // On Network Provisioning properties
    var isOnNetworkFlow: Bool = false
    var onNetworkDevice: ESPOnNetworkDevice?
    var pop: String?
    private var localDevice: ESPLocalDevice?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Handle on-network flow
        if isOnNetworkFlow, let onNetworkDevice = onNetworkDevice {
            setupOnNetworkFlow()
            return
        }
        
        if let device = self.espDevice, let versionInfo = device.versionInfo, versionInfo.isChallengeResponseSupported() {
            if self.wifiReset, let nodeId = self.wifiResetNodeId {
                self.setupUIForChallengeResponse()
                self.startStep1()
                self.provisionDevicePostChallengeResponse(nodeId: nodeId)
            } else {
                self.executeChallengeResponseWorkflow()
            }
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
    
    /// Execute the challenge-response provisioning workflow.
    /// This sets up the UI for the reduced-step flow, performs the challenge
    /// with the device, and proceeds to provisioning and node setup on success.
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
            self.provisionDevicePostChallengeResponse(nodeId: nodeId)
        }
    }
    
    /// Provision device post challenge-response workflow
    /// - Parameter nodeId: node id of the device
    private func provisionDevicePostChallengeResponse(nodeId: String) {
        self.wifiResetNodeId = nodeId
        self.startStep2()
        self.provisionDevice(nodeId: nodeId) { provisionError in
            guard let provisionError = provisionError else {
                User.shared.updateDeviceList = true
                self.startStep3()
                self.step5SetupNode(nodeID: nodeId)
                return
            }
            switch provisionError {
            case .configurationError, .wifiStatusAuthenticationError, .wifiStatusError, .wifiStatusDisconnected, .wifiStatusNetworkNotFound, .wifiStatusUnknownError:
                self.step2FailedWithMessage(error: provisionError, shouldDisconnectDevice: false)
                self.errorMessage = provisionError.description
                self.sendWifiResetCommand()
            default:
                self.step2FailedWithMessage(error: provisionError)
            }
        }
    }
    
    /// This method is used to setup the initial UI of the screen
    /// Number of steps is different from normal provisioning
    private func setupUIForChallengeResponse(isOnNetwork: Bool = false) {
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
        
        // For on-network flow, also hide WiFi provisioning steps
        if isOnNetworkFlow {
            self.step2Image.isHidden = true
            self.step2Indicator.isHidden = true
            self.step2Label.isHidden = true
            self.step2ErrorLabel.isHidden = true
        }
        
        if isOnNetwork {
            self.step5TopSpaceConstraint.constant-=148
        } else {
            self.step5TopSpaceConstraint.constant-=104
        }
    }
    
    /// Start UI for step 1 (association/challenge). Shows spinner and hides icon.
    private func startStep1() {
        DispatchQueue.main.async {
            self.step1Image.isHidden = true
            self.step1Indicator.isHidden = false
            self.step1Indicator.startAnimating()
        }
    }
    
    /// Transition UI from step 1 to step 2 (Wi‑Fi confirmation).
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
    
    /// Mark step 2 as completed in the UI.
    private func startStep3() {
        DispatchQueue.main.async {
            self.step2Indicator.stopAnimating()
            self.step2Image.image = UIImage(named: "checkbox_checked")
            self.step2Image.isHidden = false
        }
    }
    
    /// Provision device after a successful challenge-response.
    /// - Parameters:
    ///   - nodeId: Node identifier returned after challenge verification.
    ///   - completion: Called with an optional provisioning error.
    private func provisionDevice(nodeId: String, completion: @escaping (ESPProvisionError?) -> Void) {
        self.provision { status in
            switch status {
            case .success:
                completion(nil)
            case let .failure(error):
                switch error {
                case .wifiStatusUnknownError, .wifiStatusDisconnected, .wifiStatusNetworkNotFound, .wifiStatusAuthenticationError:
                    self.step2FailedWithMessage(error: error, shouldDisconnectDevice: false)
                default:
                    self.step2FailedWithMessage(error: error)
                }
                completion(error)
            case .configApplied:
                break
            }
        }
    }
    
    /// Initiates the challenge-response exchange with the device and verifies
    /// the mapping with the cloud.
    /// - Parameter completionHandler: Completion with success flag, optional
    ///   nodeId on success, and optional error description on failure.
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
            var payload = RmakerChResp_RMakerChRespPayload()
            payload.msg = .typeCmdChallengeResponse
            payload.status = .success
            
            var cmdPayload = RmakerChResp_CmdCRPayload()
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
                        let challengeResponse = try RmakerChResp_RMakerChRespPayload(serializedData: response)
                        
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
                        
                        // Convert bytes to hex string
                        var hexString = ""
                        for byte in bytes {
                            // Use String(format: "%02x") to ensure exactly 2 hex chars per byte
                            // Use byte & 0xFF to handle signed bytes correctly
                            hexString += String(format: "%02x", byte & 0xFF)
                        }
                        
                        // Validate hex string length (length > 0)
                        if hexString.count == 0 {
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

    /// Starts the normal provisioning flow and advances step UI based on status.
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
                case .configurationError, .wifiStatusAuthenticationError:
                    self.errorMessage = error.description
                    self.step1FailedWithMessage(message: "Failed to apply network configuration to device", shouldDisconnectDevice: false)
                    self.sendWifiResetCommand()
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
    
    /// Provisions the device with either Wi‑Fi credentials or a Thread
    /// operational dataset.
    /// - Parameter completionHandler: Called with provisioning status updates.
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

    /// Update UI to reflect configuration application (step 2).
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

    /// Update UI to start step 3 and trigger request to add device to the user.
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

    /// Begin polling for node association confirmation using the request ID.
    /// - Parameter requestID: Cloud request identifier returned from add device API.
    private func step4ConfirmNodeAssociation(requestID: String) {
        okayButton.isEnabled = true
        okayButton.alpha = 1.0
        step4Image.isHidden = true
        step4Indicator.isHidden = false
        step4Indicator.startAnimating()
        checkDeviceAssoicationStatus(nodeID: User.shared.currentAssociationInfo!.nodeID, requestID: requestID)
    }

    /// Wrapper to initiate device association status polling.
    /// - Parameters:
    ///   - nodeID: Node identifier.
    ///   - requestID: Request identifier used to confirm association.
    func checkDeviceAssoicationStatus(nodeID: String, requestID: String) {
        fetchDeviceAssociationStatus(nodeID: nodeID, requestID: requestID)
    }

    /// Called when association status polling times out.
    @objc func timeoutFetchingStatus() {
        step4FailedWithMessage(message: "Node addition not confirmed")
        addDeviceStatusTimeout?.invalidate()
    }

    /// Poll device association status from the backend and proceed accordingly.
    /// - Parameters:
    ///   - nodeID: Node identifier.
    ///   - requestID: Association request identifier.
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

    /// Start step 5 (node setup) by fetching node details and status with a timeout.
    /// - Parameter nodeID: Node identifier.
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
    
    /// Periodically fetch node connectivity status until connected or timeout.
    /// - Parameter nodeID: Node identifier.
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

    /// Fetch node details and ensure required metadata (e.g., timezone) is set.
    /// - Parameter nodeID: Node identifier.
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

    /// Called when node setup exceeds the allowed time window.
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

    /// If node details and connectivity are available, finalizes step 5 UI and
    /// triggers controller-specific post-setup flows.
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

    /// Handle step 1 failure and present error UI and next steps to user.
    /// - Parameter message: Error description to display.
    func step1FailedWithMessage(message: String, shouldDisconnectDevice: Bool = true) {
        DispatchQueue.main.async {
            self.step1Indicator.stopAnimating()
            self.step1Image.image = UIImage(named: "error_icon")
            self.step1Image.isHidden = false
            self.step1ErrorLabel.text = message
            self.step1ErrorLabel.isHidden = false
            if shouldDisconnectDevice {
                // For on-network flow, espDevice is nil - we use localDevice instead
                // Local network connections don't need explicit disconnection
                if let espDevice = self.espDevice {
                    espDevice.disconnect()
                }
                self.provisionFinsihedWithStatus(message: "Reboot your board and try again.")
            }
        }
    }

    /// Handle step 2 failure and present error UI and next steps to user.
    /// - Parameter error: Provisioning error for Wi‑Fi/transport.
    func step2FailedWithMessage(error: ESPProvisionError, shouldDisconnectDevice: Bool = true) {
        DispatchQueue.main.async {
            self.step2Indicator.stopAnimating()
            self.step2Image.image = UIImage(named: "error_icon")
            self.step2Image.isHidden = false
            var errorMessage = ""
            switch error {
            case .wifiStatusUnknownError, .wifiStatusDisconnected, .wifiStatusNetworkNotFound, .wifiStatusAuthenticationError:
                errorMessage = error.description
                self.errorMessage = errorMessage
                if shouldDisconnectDevice {
                    // For on-network flow, espDevice is nil - we use localDevice instead
                    if let espDevice = self.espDevice {
                        espDevice.disconnect()
                    }
                }
                self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
            case .wifiStatusError:
                errorMessage = "Unable to fetch Wi-Fi state."
                self.step3SendRequestToAddDevice()
            default:
                errorMessage = "Unknown error."
                if shouldDisconnectDevice {
                    // For on-network flow, espDevice is nil - we use localDevice instead
                    if let espDevice = self.espDevice {
                        espDevice.disconnect()
                    }
                }
                self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
            }
            self.step2ErrorLabel.text = errorMessage
            self.step2ErrorLabel.isHidden = false
        }
    }

    /// Handle step 3 failure and present error UI and next steps to user.
    /// - Parameter message: Error description.
    func step3FailedWithMessage(message: String) {
        DispatchQueue.main.async {
            self.step3Indicator.stopAnimating()
            self.step3Image.image = UIImage(named: "error_icon")
            self.step3Image.isHidden = false
            self.step3ErrorLabel.text = message
            self.step3ErrorLabel.isHidden = false
            // For on-network flow, espDevice is nil - we use localDevice instead
            if let espDevice = self.espDevice {
                espDevice.disconnect()
            }
            self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
        }
    }

    /// Handle step 4 failure and present error UI and next steps to user.
    /// - Parameter message: Error description.
    func step4FailedWithMessage(message: String) {
        DispatchQueue.main.async {
            self.step4Indicator.stopAnimating()
            self.step4Image.image = UIImage(named: "error_icon")
            self.step4Image.isHidden = false
            self.step4ErrorLabel.text = message
            self.step4ErrorLabel.isHidden = false
            // For on-network flow, espDevice is nil - we use localDevice instead
            if let espDevice = self.espDevice {
                espDevice.disconnect()
            }
            self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
        }
    }

    /// Handle step 5 failure and present warning and final status to user.
    /// - Parameter message: Error description.
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

    /// Finalize provisioning UI and enable exit actions.
    /// Triggers in‑app review on success.
    /// - Parameter message: Final status message displayed to the user.
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

    /// Send a backend request to add the provisioned device to the user and
    /// proceed to confirmation on success. Retries on transient errors.
    @objc func sendRequestToAddDevice() {
        // For on-network flow, secretKey is not needed
        let secretKey = isOnNetworkFlow ? nil : User.shared.currentAssociationInfo?.uuid
        var parameters: [String: String] = [
            "user_id": User.shared.userInfo.userID,
            "node_id": User.shared.currentAssociationInfo!.nodeID,
            "operation": "add"
        ]
        
        if let secretKey = secretKey {
            parameters["secret_key"] = secretKey
        }
        
        NetworkManager.shared.addDeviceToUser(parameter: parameters) { requestID, error in
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
                    // For on-network flow, skip step 4 and go directly to step 5
                    if self.isOnNetworkFlow {
                        self.step5SetupNode(nodeID: User.shared.currentAssociationInfo!.nodeID)
                    } else {
                        self.step4ConfirmNodeAssociation(requestID: requestid)
                    }
                } else {
                    self.step3FailedWithMessage(message: error?.description ?? "Unrecognized error. Please check your internet.")
                }
            }
        }
    }

    /// Navigate back to the root devices screen and trigger device association check.
    @IBAction func goToFirstView(_: Any) {
        let destinationVC = navigationController?.viewControllers.first as! DevicesViewController
        destinationVC.checkDeviceAssociation = true
        navigationController?.navigationBar.isHidden = false
        navigationController?.popToRootViewController(animated: true)
    }
    
    // MARK: - On Network Provisioning
    
    /// Establish secure session with local device
    private func establishLocalSession(completion: @escaping (Bool) -> Void) {
        guard let localDevice = localDevice else {
            completion(false)
            return
        }

        // For unsecure connections, no session establishment needed
        if localDevice.security == .unsecure {
            completion(true)
            return
        }

        let sessionPath = "esp_local_ctrl/session"
        localDevice.initialiseSession(sessionPath: sessionPath) { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .connected:
                completion(true)
            case .failedToConnect:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }
    
    /// Setup on-network provisioning flow
    private func setupOnNetworkFlow() {
        guard let onNetworkDevice = onNetworkDevice else {
            step1FailedWithMessage(message: "Device information not available")
            return
        }

        // Create ESPLocalDevice for local network communication
        // Match Android: use secVersion to determine security (0=unsecure, 1=secure, 2=secure2)
        let security: ESPSecurity
        var username: String?

        if onNetworkDevice.secVersion == 2 {
            security = .secure2
            username = Configuration.shared.appConfiguration.localControlSec2Username
        } else if onNetworkDevice.secVersion == 1 {
            security = .secure
            username = nil
        } else {
            security = .unsecure
            username = nil
        }

        localDevice = ESPLocalDevice(
            name: onNetworkDevice.serviceName,
            security: security,
            transport: .softap,
            proofOfPossession: pop ?? "",
            username: username,
            softAPPassword: nil,
            advertisementData: nil
        )

        let resolvedAddress = onNetworkDevice.ipAddress

        if security == .unsecure {
            localDevice?.hostname = "\(resolvedAddress):\(onNetworkDevice.port)"
        } else {
            localDevice?.hostname = resolvedAddress
        }

        let baseUrl = "\(resolvedAddress):\(onNetworkDevice.port)"
        localDevice?.espSoftApTransport = ESPSoftAPTransport(baseUrl: baseUrl)

        // Setup UI for challenge-response (on-network flow always uses challenge-response)
        setupUIForChallengeResponse(isOnNetwork: true)
        
        // Hide WiFi provisioning steps for on-network flow
        step2Image.isHidden = true
        step2Indicator.isHidden = true
        step2Label.isHidden = true
        step2ErrorLabel.isHidden = true
        
        // Start challenge-response flow over local network
        // Note: Session will be established automatically by sendData() when needed
        // (matching Android behavior - they don't establish session upfront)
        startStep1()
        verifyNodeAssociationOnNetwork()
    }
    
    /// Verify node association on local network using challenge-response
    private func verifyNodeAssociationOnNetwork() {
        guard let localDevice = localDevice,
              let onNetworkDevice = onNetworkDevice else {
            step1FailedWithMessage(message: "Local device not initialized")
            return
        }

        User.shared.initiateMapping { [weak self] challenge, requestId, error in
            guard let self = self else { return }

            if let error = error {
                self.step1FailedWithMessage(message: error.localizedDescription)
                return
            }

            guard let challenge = challenge, let requestId = requestId else {
                self.step1FailedWithMessage(message: ESPProvisionConstants.challengeFailed)
                return
            }

            // Create protobuf challenge request
            var payload = RmakerChResp_RMakerChRespPayload()
            payload.msg = .typeCmdChallengeResponse
            payload.status = .success
            
            var cmdPayload = RmakerChResp_CmdCRPayload()
            cmdPayload.payload = challenge.data(using: .utf8) ?? Data()
            payload.payload = .cmdChallengeResponsePayload(cmdPayload)
            
            do {
                let data = try payload.serializedData()
                let endpoint = onNetworkDevice.chRespEndpoint.isEmpty ? "ch_resp" : onNetworkDevice.chRespEndpoint
                self.sendChallengeToDevice(endpoint: endpoint, data: data, requestId: requestId)
            } catch {
                self.step1FailedWithMessage(message: ESPProvisionConstants.challengeRequestCreationFailed)
            }
        }
    }
    
    /// Helper method to send challenge to device with retry mechanism
    /// iOS network disconnections are common, so we retry multiple times with exponential backoff
    private func sendChallengeToDevice(endpoint: String, data: Data, requestId: String, retryCount: Int = 0) {
        let maxRetries = 5
        guard let localDevice = localDevice else {
            step1FailedWithMessage(message: "Local device not available")
            return
        }

        localDevice.sendData(path: endpoint, data: data) { [weak self] response, error in
            guard let self = self else { return }

            if let error = error {
                if retryCount < maxRetries {
                    let delay = min(Double(retryCount + 1) * 0.5, 4.0)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.sendChallengeToDevice(endpoint: endpoint, data: data, requestId: requestId, retryCount: retryCount + 1)
                    }
                } else {
                    self.step1FailedWithMessage(message: "Failed to send challenge to the device")
                }
                return
            }

            guard let response = response else {
                if retryCount < maxRetries {
                    let delay = min(Double(retryCount + 1) * 0.5, 4.0)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.sendChallengeToDevice(endpoint: endpoint, data: data, requestId: requestId, retryCount: retryCount + 1)
                    }
                } else {
                    self.step1FailedWithMessage(message: "No response from device after \(maxRetries + 1) attempts")
                }
                return
            }

            do {
                let challengeResponse = try RmakerChResp_RMakerChRespPayload(serializedData: response)

                if challengeResponse.status != .success {
                    self.step1FailedWithMessage(message: "\(ESPProvisionConstants.deviceReturnsErrorStatus): \(challengeResponse.status)")
                    return
                }

                guard case let .respChallengeResponsePayload(respPayload) = challengeResponse.payload else {
                    self.step1FailedWithMessage(message: ESPProvisionConstants.invalidResponseFormat)
                    return
                }

                let bytes = [UInt8](respPayload.payload)
                var hexString = ""
                for byte in bytes {
                    hexString += String(format: "%02x", byte & 0xFF)
                }

                if hexString.isEmpty {
                    self.step1FailedWithMessage(message: "Invalid challenge response")
                    return
                }

                User.shared.verifyUserNodeMapping(requestId: requestId, nodeId: respPayload.nodeID, challengeResponse: hexString) { [weak self] success, error in
                    guard let self = self else { return }

                    if let error = error {
                        self.step1FailedWithMessage(message: error.localizedDescription)
                        return
                    }

                    if success {
                        if User.shared.currentAssociationInfo == nil {
                            User.shared.currentAssociationInfo = AssociationConfig()
                        }
                        User.shared.currentAssociationInfo?.nodeID = respPayload.nodeID

                        DispatchQueue.main.async {
                            self.step1Indicator.stopAnimating()
                            self.step1Image.image = UIImage(named: "checkbox_checked")
                            self.step1Image.isHidden = false
                            self.sendDisableChallengeResponse(nodeId: respPayload.nodeID)
                        }
                    } else {
                        self.step1FailedWithMessage(message: ESPProvisionConstants.challengeResponseVerificationFailed)
                    }
                }
            } catch {
                self.step1FailedWithMessage(message: ESPProvisionConstants.deviceResponseParsingFailed)
            }
        }
    }
    
    /// Send disable challenge-response command to device
    private func sendDisableChallengeResponse(nodeId: String) {
        guard let localDevice = localDevice,
              let onNetworkDevice = onNetworkDevice else {
            // Still proceed to step 5 even if disable fails
            User.shared.updateDeviceList = true
            step5SetupNode(nodeID: nodeId)
            return
        }
        
        // Create disable challenge-response payload
        var payload = RmakerChResp_RMakerChRespPayload()
        payload.msg = .typeCmdDisableChalResp
        payload.status = .success
        
        var disablePayload = RmakerChResp_CmdDisableChalRespPayload()
        payload.payload = .cmdDisableChalRespPayload(disablePayload)
        
        do {
            let data = try payload.serializedData()
            
            // Use challenge-response endpoint from device
            let endpoint = onNetworkDevice.chRespEndpoint.isEmpty ? "ch_resp" : onNetworkDevice.chRespEndpoint
            
            // Send disable command to device via local network
            localDevice.sendData(path: endpoint, data: data) { [weak self] _, _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    User.shared.updateDeviceList = true
                    self.step5SetupNode(nodeID: nodeId)
                }
            }
        } catch {
            // Still proceed to step 5
            DispatchQueue.main.async {
                User.shared.updateDeviceList = true
                self.step5SetupNode(nodeID: nodeId)
            }
        }
    }
    
    // MARK: - WiFi Reset
    /// Send WiFi reset command to device when provisioning fails
    /// Checks connection status and reconnects if needed before sending reset
    private func sendWifiResetCommand() {
        // For on-network flow, espDevice is nil - WiFi reset doesn't apply
        guard let espDevice = espDevice else {
            return
        }
        
        // Check if device is still connected
        if !espDevice.isSessionEstablished() {
            // Device disconnected - reconnect first
            espDevice.connect { [weak self] status in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch status {
                    case .connected:
                        // Reconnected successfully - now send reset command
                        self.sendResetCommandAfterConnection() { success, error in
                            if success {
                                DispatchQueue.main.async {
                                    self.showReenterPasswordAlert()
                                }
                            }
                        }
                    default:
                        break
                    }
                }
            }
        } else {
            // Device is still connected - send reset command directly
            self.sendResetCommandAfterConnection() { success, error in
                if success {
                    DispatchQueue.main.async {
                        self.showReenterPasswordAlert()
                    }
                }
            }
        }
    }

    /// Send WiFi reset command (assumes device is connected)
    private func sendResetCommandAfterConnection(completion: @escaping (Bool, Error?) -> Void) {
        guard let espDevice = espDevice else {
            completion(false, NSError(domain: "SuccessViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Device not available"]))
            return
        }
        espDevice.resetWifiStatus { [weak self] success, error in
            guard let self = self else {
                return
            }
            completion(success, error)
        }
    }

    /// Show alert dialog to re-enter WiFi password
    private func showReenterPasswordAlert() {
        let title = "Provisioning"
        var message = "Please set up Wi-Fi again using the correct credentials."
        if let msg = self.errorMessage {
            message = "\(msg). Wi-Fi has been reset. Please re-enter the Wi-Fi credentials."
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // OK button
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // For on-network flow, espDevice is nil - pass nil instead
                self.successDelegate?.wifiResetSuccess(withNodeId: self.wifiResetNodeId, withDevice: self.espDevice)
                self.navigationController?.popViewController(animated: true)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
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
    
    /// Navigate to the Matter fabric selection screen (client‑only controller flow).
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
    
    /// Called when a group is selected in the fabric selection screen.
    /// - Parameter groupId: Selected group identifier.
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
    
    /// Callback when Rainmaker login is completed during controller flows.
    /// Updates controller parameters based on the device capabilities.
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
    
    /// Update parameters for client‑only controller devices after successful login.
    /// - Parameters:
    ///   - baseURL: Backend base URL.
    ///   - refreshToken: User refresh token.
    ///   - groupId: Selected group identifier.
    ///   - node: Target node.
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
    
    /// Update parameters for Rainmaker controller devices after successful login.
    /// - Parameters:
    ///   - baseURL: Backend base URL.
    ///   - refreshToken: User refresh token.
    ///   - node: Target node.
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
    
    /// Called when updating controller parameters fails.
    func failureInUpdatingParam() {}
}
