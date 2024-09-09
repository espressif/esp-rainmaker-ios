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
//  FirmwareUpdateViewController.swift
//  ESPRainMaker
//

import UIKit

class FirmwareUpdateViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet var checkUpdateView: UIView!
    @IBOutlet var alreadyUpToDateView: UIView!
    @IBOutlet var updateAvailableView: UIView!
    @IBOutlet var currentUpdateStatusView: UIView!
    @IBOutlet var updateStatusLabel: UILabel!
    @IBOutlet var updateProgressLabel: UILabel!
    @IBOutlet var updateInProgressIcon: UIImageView!
    @IBOutlet var updateAvailableIcon: UIImageView!
    @IBOutlet var checkForUpdateLabel: UILabel!
    @IBOutlet var updateButton: UIButton!
    @IBOutlet var currentFirmwareVersionLabel: UILabel!
    @IBOutlet var newFirmwareVersionLabel: UILabel!
    @IBOutlet var checkFirmwareUpdateIcon: UIImageView!
    @IBOutlet var otaUpdateAvlDescLabel: UILabel!
    @IBOutlet weak var backButton: BarButton!
    
    // MARK: - Constants
    let checkAgainConstant = "Check Again"
    let updateConstant = "Update"
    let timeoutInterval = 180.0
    let checkUpdateIcon = "checkUpdate"
    let updateInProgressGIF = "updateInProgress"
    let checkingUpdateLabelText = "Checking for update"
    let pushingOTAUpdateMsg = "Pushing OTA update..."
    let checkForUpdateLabelText = "Click below to check for firmare update."
    let updateSuccessLabelText = "Firmware update is successful."
    let failOTAUpdateStatusMsg = "Failed to get OTA update status. Please try again."
    let updateRejectedMsg = "OTA update rejected."
    let pushOTAUpdateFailMsg = "Failed to push OTA update."
    
    // MARK: - Properties
    var currentNode: Node!
    var getOTAUpdateService: ESPGetOTAUpdateStatusService?
    var checkOTAUpdateService: ESPCheckOTAUpdateService?
    var pushOTAUpdateService: ESPPushOTAUpdateService?
    var currentOTAJob: ESPOTAUpdate?
    var timer: Timer?
    var isFromNotification: Bool = false

    // MARK: - Overriden Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if isFromNotification {
            self.backButton.setTitle("Close", for: .normal)
        }
        getOTAUpdateService = ESPGetOTAUpdateStatusService(presenter: self)
        checkOTAUpdateService = ESPCheckOTAUpdateService(presenter: self)
        pushOTAUpdateService = ESPPushOTAUpdateService(presenter: self)
        checkForOTAUpdate()
    }
    
    // MARK: - IBActions
    @IBAction func backButtonPressed(_: Any) {
        if isFromNotification {
            self.dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func updateButtonTapped(sender: UIButton) {
        if sender.title(for: .normal) == checkAgainConstant {
            checkForOTAUpdate()
        } else {
            pushOTAUpdate()
        }
    }
    
    // MARK: - Helper Methods
    
    private func addUpdateAnimation() {
        let checkUpdateGIF = UIImage.gifImageWithName(checkUpdateIcon)
        checkFirmwareUpdateIcon.image = checkUpdateGIF
    }
    
    /// Method to check if OTA update is available.
    private func checkForOTAUpdate() {
        // Prepare UI
        addUpdateAnimation()
        updateButton.isHidden = true
        hideAllViews()
        // Add animation to label text
        timer = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { (timer) in
            var string: String {
                switch self.checkForUpdateLabel.text {
                case self.checkingUpdateLabelText + ".":       return self.checkingUpdateLabelText + ".."
                case self.checkingUpdateLabelText + "..":      return self.checkingUpdateLabelText + "..."
                case self.checkingUpdateLabelText + "...":     return self.checkingUpdateLabelText + "."
                default:
                    return self.checkingUpdateLabelText + "."
                }
            }
            self.checkForUpdateLabel.text = string
        }
        checkUpdateView.isHidden = false
        // Call API for checking OTA update
        checkOTAUpdateService?.checkOTAUpdateFor(nodeID: currentNode.node_id ?? "")
    }
    
    
    /// Method to push OTA update to node.
    private func pushOTAUpdate() {
        // Check if current Node is connected to network
        if currentNode.isConnected {
            let alertController = UIAlertController(title: "Do you want to proceed?", message: "", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "No", style: .default))
            alertController.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
                Utility.showLoader(message: self.pushingOTAUpdateMsg, view: self.view)
                self.updateButton.isHidden = true
                // Call API for pushing OTA update
                self.pushOTAUpdateService?.pushOTAUpdateFor(nodeID: self.currentNode.node_id ?? "", otaJobID: self.currentOTAJob?.otaJobID ?? "")
            })
            self.present(alertController, animated: true)
        } else {
            showOfflineAlert()
        }
    }
    
    
    /// Method to show progress of OTA update
    /// - Parameter otaUpdateStatus: contains information of current status for OTA update.
    private func showUpdateProgress(otaUpdateStatus: ESPOTAUpdateStatus) {
        hideAllViews()
        currentUpdateStatusView.isHidden = false
        let image = UIImage.gifImageWithName(updateInProgressGIF)
        updateInProgressIcon.image = image
        updateProgressLabel.text = otaUpdateStatus.additionalInfo
        updateStatusLabel.text = "Current status: " + otaUpdateStatus.status
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.getOTAUpdateService?.getOTAUpdateStatusFor(nodeID: self.currentNode.node_id ?? "", otaJobID: self.currentOTAJob?.otaJobID ?? "")
        }
    }
    
    /// Show UI if there is no update available
    private func setAlreadyUpdatedView() {
        hideAllViews()
        alreadyUpToDateView.isHidden = false
        updateButton.setTitle(checkAgainConstant, for: .normal)
        updateButton.isHidden = false
    }
    
    /// Show UI for checking if firmware update is available
    private func checkFirmwareUpdateView() {
        checkForUpdateLabel.text = checkForUpdateLabelText
        updateButton.setTitle(checkAgainConstant, for: .normal)
        updateButton.isHidden = false
        checkFirmwareUpdateIcon.image = UIImage(named: checkUpdateIcon)
    }
    
    /// Show UI when firmware update is successful
    private func setOTAUpdatedView() {
        hideAllViews()
        checkUpdateView.isHidden = false
        checkFirmwareUpdateIcon.image = UIImage(named: "updated_icon")
        checkForUpdateLabel.text = updateSuccessLabelText
        updateButton.setTitle(checkAgainConstant, for: .normal)
        updateButton.isHidden = false
        updateButton.isEnabled = true
        currentNode.info?.fw_version = currentOTAJob?.fwVersion
    }
    
    /// Show UI when OTA update fails
    private func failToUpdateView() {
        hideAllViews()
        currentUpdateStatusView.isHidden = false
        updateStatusLabel.text = pushOTAUpdateFailMsg
        updateInProgressIcon.image = UIImage(named: "rejected_icon")
        updateProgressLabel.text = "Check your connections and please try again after some time."
        updateButton.setTitle(updateConstant, for: .normal)
        updateButton.isHidden = false
    }
    
    /// Show UI when OTA update fails with error
    private func failedToUpdateView(otaUpdateStatus: ESPOTAUpdateStatus) {
        hideAllViews()
        currentUpdateStatusView.isHidden = false
        updateStatusLabel.text = otaUpdateStatus.additionalInfo
        updateInProgressIcon.image = UIImage(named: "rejected_icon")
        updateProgressLabel.text = "Failed to push OTA Update."
        updateButton.setTitle(updateConstant, for: .normal)
        updateButton.isHidden = false
    }
    
    /// Show UI when OTA update is rejected
    private func rejectedOTAUpdate(otaUpdateStatus: ESPOTAUpdateStatus) {
        hideAllViews()
        currentUpdateStatusView.isHidden = false
        updateStatusLabel.text = otaUpdateStatus.additionalInfo
        updateInProgressIcon.image = UIImage(named: "rejected_icon")
        updateProgressLabel.text = updateRejectedMsg
        updateButton.setTitle(checkAgainConstant, for: .normal)
        updateButton.isHidden = false
    }
    
    /// Prepare UI for firmware update if available
    private func prepareForFirmwareUpdate() {
        if let otaUpdate = currentOTAJob {
            hideAllViews()
            updateAvailableView.isHidden = false
            let image = UIImage(named: checkUpdateIcon)
            updateAvailableIcon.image = image
            updateButton.isHidden = false
            updateButton.setTitle(updateConstant, for: .normal)
            currentFirmwareVersionLabel.text = "Current version: " + (currentNode.info?.fw_version ?? "")
            newFirmwareVersionLabel.text = "Available version: " + (otaUpdate.fwVersion ?? "")
        } else {
            setAlreadyUpdatedView()
        }
    }
    
    /// Show alert if node is offline
    private func showOfflineAlert() {
        let alert = UIAlertController(title: "Error", message: "Device is offline. Please connect your device to network and try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default))
        self.present(alert, animated: true)
    }
    
    /// Reset screen by hiding all views
    private func hideAllViews() {
        alreadyUpToDateView.isHidden = true
        updateAvailableView.isHidden = true
        currentUpdateStatusView.isHidden = true
        checkUpdateView.isHidden = true
    }

}

extension FirmwareUpdateViewController: ESPOTAUpdateStatusPresentationLogic {
    func getOTAUpdateStatus(otaUpdateStatus: ESPOTAUpdateStatus?, error: ESPAPIError?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            // Check for error
            guard let otaUpdateStatus = otaUpdateStatus else {
                if let error = error {
                    Utility.showToastMessage(view: self.view, message: error.description, duration: 4.0)
                }
                // Failed to get OTA update status
                self.currentUpdateStatusView.isHidden = true
                self.checkUpdateView.isHidden = false
                self.checkForUpdateLabel.text = self.failOTAUpdateStatusMsg
                self.updateButton.setTitle(self.checkAgainConstant, for: .normal)
                self.updateButton.isHidden = false
                return
            }
            // Handle status for OTA update
            switch otaUpdateStatus.otaStatus {
            // Firmware update is not pushed
            case .triggered:
                self.prepareForFirmwareUpdate()
            // Firmware update is in progress
            case .inprogress, .started:
                // Set timeout for 3000 seconds. If OTA update is still in progress mark this as failed attempt.
                if (Date().timeIntervalSince1970 - Double(otaUpdateStatus.timestamp)/1000) > self.timeoutInterval {
                    self.failToUpdateView()
                } else {
                    self.showUpdateProgress(otaUpdateStatus: otaUpdateStatus)
                }
            // Firmware update is rejected
            case .rejected:
                self.rejectedOTAUpdate(otaUpdateStatus: otaUpdateStatus)
            // Firmware update is completed
            case .completed, .success:
                self.setOTAUpdatedView()
            // Unknown status. Check OTA update status again.
            case .unknown:
                Utility.showToastMessage(view: self.view, message: "Some error occured while fetching OTA update status. Retrying..", duration: 2.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.getOTAUpdateService?.getOTAUpdateStatusFor(nodeID: self.currentNode.node_id ?? "", otaJobID: self.currentOTAJob?.otaJobID ?? "")
                }
            case .failed:
                self.failedToUpdateView(otaUpdateStatus: otaUpdateStatus)
            }
        }
    }
}

extension FirmwareUpdateViewController: ESPCheckOTAUpdatePresentationLogic {
    func checkOTAUpdate(otaUpdate: ESPOTAUpdate?, error: ESPAPIError?) {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            // Check error while checking for OTA update
            guard let otaUpdate = otaUpdate else {
                if let error = error {
                    Utility.showToastMessage(view: self.view, message: error.description, duration: 4.0)
                    self.checkFirmwareUpdateView()
                    return
                }
                return
            }
            self.currentOTAJob = otaUpdate
            // OTA update is available
            if otaUpdate.otaAvailable {
                if let desc = otaUpdate.otaStatusDescription {
                    self.otaUpdateAvlDescLabel.text = desc
                }
                Utility.showLoader(message: "Checking OTA update status...", view: self.view)
                self.getOTAUpdateService?.getOTAUpdateStatusFor(nodeID: self.currentNode.node_id ?? "", otaJobID: otaUpdate.otaJobID ?? "")
            } else {
                self.setAlreadyUpdatedView()
            }
        }
    }
}

extension FirmwareUpdateViewController: ESPPushOTAUpdatePresentationLogic {
    func pushOTAUpdateStatus(pushOTAUpdateStatus: ESPPushOTAUpdateResponse?, error: ESPAPIError?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            // Check for error while pushing OTA update
            guard let pushOTAUpdateStatus = pushOTAUpdateStatus else {
                if let error = error {
                    Utility.showToastMessage(view: self.view, message: error.description, duration: 4.0)
                }
                return
            }
            if pushOTAUpdateStatus.status.lowercased() == "success" {
                // Push OTA update is successful
                Utility.showToastMessage(view: self.view, message: pushOTAUpdateStatus.description, duration: 3.0)
                self.getOTAUpdateService?.getOTAUpdateStatusFor(nodeID: self.currentNode.node_id ?? "", otaJobID: self.currentOTAJob?.otaJobID ?? "")
            } else {
                Utility.showToastMessage(view: self.view, message: pushOTAUpdateStatus.description, duration: 3.0)
                self.updateButton.isHidden = false
            }
        }
    }
}
