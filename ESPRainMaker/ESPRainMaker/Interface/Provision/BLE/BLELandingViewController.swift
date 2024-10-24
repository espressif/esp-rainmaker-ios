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
//  BLELandingViewController.swift
//  ESPRainMaker
//

import CoreBluetooth
import ESPProvision
import Foundation
import MBProgressHUD
import UIKit

protocol BLEStatusProtocol {
    func peripheralDisconnected()
}

class BLELandingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var activityView: UIActivityIndicatorView?
    var grayView: UIView?
    var delegate: BLEStatusProtocol?
    var bleConnectTimer = Timer()
    var bleDeviceConnected = false
    var bleDevices: [ESPDevice]?
    var pop = ""

    @IBOutlet var tableview: UITableView!
    @IBOutlet var prefixTextField: UITextField!
    @IBOutlet var prefixlabel: UILabel!
    @IBOutlet var prefixView: UIView!
    @IBOutlet var textTopConstraint: NSLayoutConstraint!
    
    var espDevice: ESPDevice!
    var provisionCompletionHandler: (() -> Void)?

    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Connect"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Scan for bluetooth devices

        // UI customization
        prefixlabel.layer.masksToBounds = true
        tableview.tableFooterView = UIView()

        // Adding tap gesture to hide keyboard on outside touch
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        // Checking whether filtering by prefix header is allowed
        prefixTextField.text = Utility.deviceNamePrefix
        if Configuration.shared.espProvSetting.allowPrefixSearch {
            prefixView.isHidden = false
        } else {
            textTopConstraint.constant = -10
            view.layoutIfNeeded()
        }

        scanBleDevices()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - IBActions

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func cancelPressed(_: Any) {
        navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func rescanBLEDevices(_: Any) {
        bleDevices?.removeAll()
        tableview.reloadData()
        scanBleDevices()
    }

    func scanBleDevices() {
        Utility.showLoader(message: "Searching for BLE Devices..", view: view)
        ESPProvisionManager.shared.searchESPDevices(devicePrefix: Utility.deviceNamePrefix, transport: .ble, security: Configuration.shared.espProvSetting.securityMode) { bleDevices, _ in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.bleDevices = bleDevices
                self.tableview.reloadData()
            }
        }
    }

    // MARK: - Notifications

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc func keyboardWillDisappear() {
        if let prefix = prefixTextField.text {
            UserDefaults.standard.set(prefix, forKey: "com.espressif.prefix")
            Utility.deviceNamePrefix = prefix
            rescanBLEDevices(self)
        }
    }

    // MARK: - Helper Methods

    func goToConnectVC(device: ESPDevice) {
        let connectVC = storyboard?.instantiateViewController(withIdentifier: Constants.connectVCIdentifier) as! ConnectViewController
        connectVC.espDevice = device
        navigationController?.pushViewController(connectVC, animated: true)
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
                goToClaimVC(device: device)
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
                    self.alertUser(title: Constants.notice, message: AppMessages.upgradeOS15VersionMsg, buttonTitle: "OK") {}
                }
                return
            }
            
            /// Navigate to Wifi provisioning screen
            /// If wifi scan is allowed navigate to provision view controller.
            /// Else navigate user to network selection screen.
            DispatchQueue.main.async {
                device.network = .wifi
                if versionInfo.shouldScanWifiNetwork() {
                    self.goToProvision(device: device)
                } else {
                    self.goToJoinNetworkVC(device: device)
                }
            }
        }
    }
    
    /// Navigate user to provisioning screen
    /// - Parameter device: esp device
    func goToProvision(device: ESPDevice) {
        let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
        provisionVC.device = device
        self.navigationController?.pushViewController(provisionVC, animated: true)
    }
    
    /// Navigate user to network selection screen
    /// - Parameter device: esp device
    func goToJoinNetworkVC(device: ESPDevice) {
        let joinNetworkVC = self.storyboard?.instantiateViewController(withIdentifier: JoinNetworkViewController.storyboardId) as! JoinNetworkViewController
        joinNetworkVC.device = device
        self.navigationController?.pushViewController(joinNetworkVC, animated: true)
    }

    func goToClaimVC(device: ESPDevice) {
        let claimVC = storyboard?.instantiateViewController(withIdentifier: "claimVC") as! ClaimViewController
        claimVC.device = device
        navigationController?.pushViewController(claimVC, animated: true)
    }

    private func showAlert(error: String, action: UIAlertAction) {
        let alertController = UIAlertController(title: "Error!", message: error, preferredStyle: .alert)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }

    private func showBusy(isBusy: Bool, message: String = "") {
        DispatchQueue.main.async {
            if isBusy {
                let loader = MBProgressHUD.showAdded(to: self.view, animated: true)
                loader.mode = MBProgressHUDMode.indeterminate
                loader.label.text = message
            } else {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
    }

    // MARK: - UITableView

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard let peripherals = bleDevices else {
            return 0
        }
        return peripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bleDeviceCell", for: indexPath) as! BLEDeviceListViewCell
        if let peripheral = bleDevices?[indexPath.row] {
            cell.deviceName.text = peripheral.name
        }

        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        Utility.showLoader(message: "Connecting to device", view: view)
        let espDevice = bleDevices![indexPath.row]
        espDevice.connect(delegate: self) { status in
            DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                switch status {
                case .connected:
                        self.checkForAssistedClaiming(device: espDevice)
                case let .failedToConnect(error):
                        var errorDescription = ""
                        switch error {
                        case .securityMismatch, .versionInfoError:
                            errorDescription = error.description
                        default:
                            errorDescription = error.description + "\nCheck if POP is correct."
                        }
                        let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                        self.showAlert(error: errorDescription, action: action)
                default:
                        let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                        self.showAlert(error: "Device disconnected", action: action)
                }
            }
        }
    }
}

extension BLELandingViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}

extension BLELandingViewController: ESPDeviceConnectionDelegate {
    
    func getUsername(forDevice: ESPDevice, completionHandler: @escaping (String?) -> Void) {
        if let caps = forDevice.capabilities, (caps.contains(ESPScanConstants.threadProv) || caps.contains(ESPScanConstants.threadScan)) {
            completionHandler(Configuration.shared.espProvSetting.threadSec2Username)
        } else {
            completionHandler(Configuration.shared.espProvSetting.wifiSec2Username)
        }
    }
    
    func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
        let connectVC = storyboard?.instantiateViewController(withIdentifier: Constants.connectVCIdentifier) as! ConnectViewController
        connectVC.espDevice = forDevice
        connectVC.popHandler = completionHandler
        navigationController?.pushViewController(connectVC, animated: true)
    }
}

extension BLELandingViewController: DeviceAssociationProtocol {
    
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
