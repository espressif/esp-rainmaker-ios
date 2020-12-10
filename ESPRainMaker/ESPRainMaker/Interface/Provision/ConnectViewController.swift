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
//  Created by Vikas Chandra on 10/01/20.
//  Copyright © 2020 Espressif. All rights reserved.
//

import ESPProvision
import UIKit

class ConnectViewController: UIViewController {
    @IBOutlet var popTextField: UITextField!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var nextButton: UIButton!
    var currentDeviceName = ""
    var espDevice: ESPDevice!
    var pop = ""

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
            }
            switch status {
            case .connected:
                DispatchQueue.main.async {
                    self.checkForAssistedClaiming(device: self.espDevice)
                }
            case let .failedToConnect(error):
                DispatchQueue.main.async {
                    var errorDescription = ""
                    switch error {
                    case .securityMismatch, .versionInfoError:
                        errorDescription = error.description
                    default:
                        errorDescription = error.description + "\nCheck if POP is correct."
                    }
                    let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                    self.showAlert(error: errorDescription, action: action)
                }
            default:
                DispatchQueue.main.async {
                    let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                    self.showAlert(error: "Device disconnected", action: action)
                }
            }
        }
    }

    func checkForAssistedClaiming(device: ESPDevice) {
        if let versionInfo = device.versionInfo, let rmaikerInfo = versionInfo["rmaker"] as? NSDictionary, let rmaikerCap = rmaikerInfo["cap"] as? [String], rmaikerCap.contains("claim") {
            if device.transport == .ble {
                goToClaimVC(device: device)
            } else {
                let action = UIAlertAction(title: "Okay", style: .default, handler: nil)
                showAlert(error: "Assisted Claiming not supported for SoftAP. Cannot Proceed.", action: action)
            }
        } else {
            goToProvision()
        }
    }

    func goToProvision() {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
            provisionVC.connectAutomatically = true
            provisionVC.device = self.espDevice
            self.navigationController?.pushViewController(provisionVC, animated: true)
        }
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

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        let destination = segue.destination as! ProvisionViewController
        destination.isScanFlow = false
        destination.pop = popTextField.text ?? ""
    }
}

extension ConnectViewController: ESPDeviceConnectionDelegate {
    func getProofOfPossesion(forDevice _: ESPDevice) -> String? {
        return pop
    }
}
