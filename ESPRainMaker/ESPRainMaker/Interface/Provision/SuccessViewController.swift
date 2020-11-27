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
    var addDeviceStatusTimeout: Timer?
    var step1Failed = false
    var count: Int = 0
    var espDevice: ESPDevice!

    @IBOutlet var step1Image: UIImageView!
    @IBOutlet var step2Image: UIImageView!
    @IBOutlet var step3Image: UIImageView!
    @IBOutlet var step4Image: UIImageView!
    @IBOutlet var step1Indicator: UIActivityIndicatorView!
    @IBOutlet var step2Indicator: UIActivityIndicatorView!
    @IBOutlet var step3Indicator: UIActivityIndicatorView!
    @IBOutlet var step4Indicator: UIActivityIndicatorView!
    @IBOutlet var step1ErrorLabel: UILabel!
    @IBOutlet var step2ErrorLabel: UILabel!
    @IBOutlet var step3ErrorLabel: UILabel!
    @IBOutlet var step4ErrorLabel: UILabel!
    @IBOutlet var finalStatusLabel: UILabel!
    @IBOutlet var okayButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if step1Failed {
            step1FailedWithMessage(message: "Wrong pop entered!")
        } else {
            startProvisioning()
        }
    }

    func startProvisioning() {
        step1Image.isHidden = true
        step1Indicator.isHidden = false
        step1Indicator.startAnimating()

        espDevice.provision(ssid: ssid, passPhrase: passphrase) { status in
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
                self.provisionFinsihedWithStatus(message: "Device added successfully!!")
            } else if status == "timedout" {
                self.step4FailedWithMessage(message: "Node addition not confirmed")
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.fetchDeviceAssociationStatus(nodeID: nodeID, requestID: requestID)
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
            case .wifiStatusError:
                errorMessage = "Unable to fetch Wi-Fi state."
            default:
                errorMessage = "Unknown error."
            }
            self.step2ErrorLabel.text = errorMessage
            self.step2ErrorLabel.isHidden = false
            self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
        }
    }

    func step3FailedWithMessage(message: String) {
        DispatchQueue.main.async {
            self.step3Indicator.stopAnimating()
            self.step3Image.image = UIImage(named: "error_icon")
            self.step3Image.isHidden = false
            self.step3ErrorLabel.text = message
            self.step3ErrorLabel.isHidden = false
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
            self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
        }
    }

    func provisionFinsihedWithStatus(message: String) {
        okayButton.isEnabled = true
        okayButton.alpha = 1.0
        finalStatusLabel.text = message
        finalStatusLabel.isHidden = false
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
        destinationVC.deviceID = deviceID
        destinationVC.requestID = requestID
        navigationController?.navigationBar.isHidden = false
        navigationController?.popToRootViewController(animated: true)
    }
}
