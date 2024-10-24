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
//  ClaimViewController.swift
//  ESPRainMaker
//

import ESPProvision
import UIKit
import ThreadNetwork

class ClaimViewController: UIViewController {
    @IBOutlet var progressIndicator: UILabel!
    @IBOutlet var failureLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var okButton: PrimaryButton!
    @IBOutlet var cancelButton: BarButton!
    @IBOutlet var centralIcon: UIImageView!

    var device: ESPDevice!
    var count = 0
    var threadOperationalDataset: Data!
    var provisionCompletionHandler: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            self.cancelButton.isHidden = false
        }
        progressIndicator.text = "Claiming in progress..."
        startAssistedClaiming()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        centralIcon.rotate360Degrees()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        centralIcon.layer.removeAllAnimations()
    }
    
    @available(iOS 15.0, *)
    func provisionDeviceWithThreadNetwork(device: ESPDevice, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            Utility.showLoader(message: "Sending association data", view: self.view)
        }
        self.provisionCompletionHandler = completion
        User.shared.associateNodeWithUser(device: device, delegate: self)
    }

    func startAssistedClaiming() {
        let assistedClaiming = AssistedClaiming(espDevice: device)
        assistedClaiming.initiateAssistedClaiming { result, error in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                if result {
                    if let versionInfo = self.device.versionInfo {
                        let threadCapabilities = versionInfo.checkThreadCapabilities()
                        if threadCapabilities.canProvisionOverThread {
                            if #available(iOS 15.0, *) {
                                self.device.network = .thread
                                self.provisionDeviceWithThreadNetwork(device: self.device) {
                                    DispatchQueue.main.async {
                                        self.showThreadNetworkSelectionVC(shouldScanThreadNetworks: threadCapabilities.shouldScanThreadNetworks, device: self.device)
                                    }
                                }
                            } else {
                                self.centralIcon.layer.removeAllAnimations()
                                self.alertUser(title: Constants.notice, message: AppMessages.upgradeOS15VersionMsg, buttonTitle: "OK") {
                                    DispatchQueue.main.async {
                                        self.navigationController?.popToRootViewController(animated: true)
                                    }
                                }
                            }
                        } else {
                            self.device.network = .wifi
                            if versionInfo.shouldScanWifiNetwork() {
                                self.goToProvision()
                            } else {
                                self.goToJoinNetworkVC()
                            }
                        }
                    }
                } else {
                    self.centralIcon.layer.removeAllAnimations()
                    self.progressIndicator.text = "Claiming failed with error:"
                    self.failureLabel.text = error ?? "Failure"
                    self.failureLabel.isHidden = false
                    var status = "Claiming failed. Please reboot the device and restart provisioning."
                    if error == "BLE characteristic related with claiming cannot be found." {
                        status = "Please restart your iOS device to reset BLE cache and try again."
                    }
                    self.statusLabel.text = status
                    self.statusLabel.isHidden = false
                    self.okButton.isHidden = false
                }
            }
        }
    }

    func goToProvision() {
        let provisionVC = storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
        provisionVC.device = device
        navigationController?.pushViewController(provisionVC, animated: true)
    }
    
    func goToJoinNetworkVC() {
        let joinNetworkVC = storyboard?.instantiateViewController(withIdentifier: JoinNetworkViewController.storyboardId) as! JoinNetworkViewController
        joinNetworkVC.device = device
        navigationController?.pushViewController(joinNetworkVC, animated: true)
    }

    @IBAction func doneButtonPressed(_: Any) {
        device.disconnect()
        navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func cancelPressed(_: Any) {
        device.disconnect()
        navigationController?.popToRootViewController(animated: true)
    }
    
    private func provisionDevice(device: ESPDevice, threadOperationalDataset: Data) {
        Utility.showLoader(message: "Sending association data", view: view)
        self.device = device
        self.threadOperationalDataset = threadOperationalDataset
        User.shared.associateNodeWithUser(device: device, delegate: self)
    }
    
    @available(iOS 15.0, *)
    private func provisionDeviceWithMultipleNetworks(device: ESPDevice, completion: @escaping () -> Void) {
        Utility.showLoader(message: "Sending association data", view: view)
        self.provisionCompletionHandler = completion
        self.device = device
        User.shared.associateNodeWithUser(device: device, delegate: self)
    }
    
    private func showStatusScreenForThread(step1Failed: Bool = false, device: ESPDevice, threadOperationalDataset: Data?) {
        let successVC = self.storyboard?.instantiateViewController(withIdentifier: "successViewController") as! SuccessViewController
        successVC.step1Failed = step1Failed
        successVC.espDevice = device
        successVC.threadOperationalDataset = threadOperationalDataset
        navigationController?.pushViewController(successVC, animated: true)
    }
}

extension ClaimViewController: DeviceAssociationProtocol {
    
    func deviceAssociationFinishedWith(success: Bool, nodeID: String?, error: AssociationError?) {
        User.shared.currentAssociationInfo!.associationInfoDelievered = success
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            if success {
                if let deviceSecret = nodeID {
                    User.shared.currentAssociationInfo!.nodeID = deviceSecret
                }
                if let completion = self.provisionCompletionHandler {
                    completion()
                } else {
                    self.showThreadNetworkSelectionVC(shouldScanThreadNetworks: true, device: self.device)
                }
            } else {
                
                let alertController = UIAlertController(title: "Error", message: error?.description, preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default) { _ in
                    self.navigationController?.popToRootViewController(animated: false)
                }
                alertController.addAction(action)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
