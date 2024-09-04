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
//  ConnectViewController.swift
//  ESPRainMaker
//

import ESPProvision
import UIKit

class ConnectViewController: UIViewController {
    @IBOutlet var popTextField: UITextField!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var nextButton: UIButton!
    var popHandler: ((String) -> Void)?
    var currentDeviceName = ""
    var espDevice: ESPDevice!
    var pop = ""
    var provisionCompletionHandler: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        if espDevice == nil {
            ESPProvisionManager.shared.createESPDevice(deviceName: currentDeviceName, transport: .softap, completionHandler: { device, error in
                if device != nil {
                    self.espDevice = device
                    DispatchQueue.main.async {
                        self.nextButton.isHidden = false
                    }

                } else {
                    DispatchQueue.main.async {
                        let action = UIAlertAction(title: "Retry", style: .default) { _ in
                            self.navigationController?.popToRootViewController(animated: false)
                        }
                        self.showAlert(error: error!.description, action: action)
                    }
                }
            })
        } else {
            nextButton.isHidden = false
            currentDeviceName = espDevice.name
        }

        headerLabel.text = "Enter your proof of possession PIN for \n" + currentDeviceName
    }

    @IBAction func cancelClicked(_: Any) {
        navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func nextBtnClicked(_: Any) {
        pop = popTextField.text ?? ""
        Utility.showLoader(message: "Connecting to device", view: view)
        espDevice.connect(delegate: self) { status in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                switch status {
                case .connected:
                    DispatchQueue.main.async {
                        self.checkForAssistedClaiming(device: self.espDevice)
                    }
                case let .failedToConnect(error):
                    switch error {
                    case .sessionInitError:
                        self.showStatusScreen(step1Failed: true, message: error.description + ".Please check if POP is correct.")
                    default:
                        self.showStatusScreen(step1Failed: true, message: error.description)
                    }
                default:
                    let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                    self.showAlert(error: "Device disconnected", action: action)
                }
            }
        }
    }

    /// Check device for assisted claiming.
    /// If the version info contains the "rmaker" : ["claim"] capability,
    /// then we take the user to the assisted claiming screen.
    /// If the claim flag is absent start the provisioning process for either
    /// Wifi or Thread based on the capabilities defined under the "prov" key.
    /// - Parameter device: ESPDevice
    func checkForAssistedClaiming(device: ESPDevice) {
        
        if let versionInfo = device.versionInfo {
            
            //Check the "rmaker"/"cap" to see if assisted claiming is supported.
            //If yes navigagte user to assisted claiming screen.
            //Else show error.
            if versionInfo.isAssistedClaimingSupported() {
                if device.transport == .ble {
                    DispatchQueue.main.async {
                        self.goToClaimVC(device: device)
                    }
                } else {
                    self.showErrorAlert(title: "", message: "Assisted Claiming not supported for SoftAP. Cannot Proceed.", buttonTitle: "OK") {}
                }
                return
            }
            
            //Check the "prov"/"cap" to see if wifi/thread is supported.
            //If Thread is supported navigate to thread network selection screen.
            //Else navigate user to wifi provisioning screen.
            let threadCapabilities = versionInfo.checkThreadCapabilities()
            if threadCapabilities.canProvisionOverThread {
                if #available(iOS 15.0, *) {
                    self.espDevice = device
                    self.espDevice.network = .thread
                    self.provisionDeviceWithThreadNetwork(device: self.espDevice) {
                        DispatchQueue.main.async {
                            self.showThreadNetworkSelectionVC(shouldScanThreadNetworks: threadCapabilities.shouldScanThreadNetworks, device: self.espDevice)
                        }
                    }
                } else {
                    self.alertUser(title: "Notice", message: Constants.upgradeOS15VersionMsg, buttonTitle: "OK") {}
                }
                return
            }
            
            /// Navigate to Wifi provisioning screen
            /// If device can scan wifi networks navigate to provisioning screen
            /// else navigate to network selection screen
            DispatchQueue.main.async {
                self.espDevice.network = .wifi
                if versionInfo.shouldScanWifiNetwork() {
                    self.goToProvisionVC()
                } else {
                    self.goToJoinNetworkVC()
                }
            }
        }
    }

    // Show status screen, called when device connection fails.
    func showStatusScreen(step1Failed: Bool = false, message: String) {
        Utility.hideLoader(view: view)
        let successVC = storyboard?.instantiateViewController(withIdentifier: "successViewController") as! SuccessViewController
        successVC.step1Failed = step1Failed
        successVC.espDevice = espDevice
        successVC.failureMessage = message
        navigationController?.pushViewController(successVC, animated: true)
    }

    func goToProvisionVC() {
        let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
        provisionVC.device = self.espDevice
        self.navigationController?.pushViewController(provisionVC, animated: true)
    }
    
    func goToJoinNetworkVC() {
        let joinNetworkVC = self.storyboard?.instantiateViewController(withIdentifier: JoinNetworkViewController.storyboardId) as! JoinNetworkViewController
        joinNetworkVC.device = self.espDevice
        self.navigationController?.pushViewController(joinNetworkVC, animated: true)
    }

    func goToClaimVC(device: ESPDevice) {
        let claimVC = storyboard?.instantiateViewController(withIdentifier: "claimVC") as! ClaimViewController
        claimVC.device = device
        navigationController?.pushViewController(claimVC, animated: true)
    }

    func showAlert(error: String, action: UIAlertAction) {
        let alertController = UIAlertController(title: "Error!", message: error, preferredStyle: .alert)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
}

extension ConnectViewController: ESPDeviceConnectionDelegate {
    
    func getUsername(forDevice: ESPDevice, completionHandler: @escaping (String?) -> Void) {
        if let caps = forDevice.capabilities, (caps.contains(ESPScanConstants.threadProv) || caps.contains(ESPScanConstants.threadScan)) {
            completionHandler(Configuration.shared.espProvSetting.threadSec2Username)
        } else {
            completionHandler(Configuration.shared.espProvSetting.wifiSec2Username)
        }
    }
    
    func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
        completionHandler(pop)
    }
}

extension ConnectViewController: DeviceAssociationProtocol {
    
    @available(iOS 15.0, *)
    func provisionDeviceWithThreadNetwork(device: ESPDevice, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            Utility.showLoader(message: "Sending association data", view: self.view)
        }
        self.provisionCompletionHandler = completion
        User.shared.associateNodeWithUser(device: device, delegate: self)
    }
    
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
                    self.showThreadNetworkSelectionVC(device: self.espDevice)
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
