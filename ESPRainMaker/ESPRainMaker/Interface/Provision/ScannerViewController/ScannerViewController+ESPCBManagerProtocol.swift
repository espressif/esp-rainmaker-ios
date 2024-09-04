// Copyright 2024 Espressif Systems
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
//  ScannerViewController+ESPCBManagerProtocol.swift
//  ESPRainMaker
//

import CoreBluetooth
import UIKit

protocol ESPCBManagerProtocol {
    
    func isBluetoothRequired() -> Bool
    func checkBluetoothOnStatus(_ completion: @escaping (CBManagerState) -> Void)
    func authorizeCBAlert(title: String, message: String, buttonTitle: String, completion: @escaping (Bool) -> Void)
    func checkCBAndProceed(_ completion: @escaping () -> Void)
    func handleCBPermissionError(cbStatus: CBManagerState)
    func openSettingsApp()
    func dismissDisplayedAlert()
}

extension ScannerViewController: ESPCBManagerProtocol {
    
    //MARK: BLE permission APIs
    
    
    /// Check if bluetooth is required for commissioning or provisioning
    /// - Returns: is bluetooth allowed
    func isBluetoothRequired() -> Bool {
        #if ESPRainMakerMatter
        return true
        #endif
        switch Configuration.shared.espProvSetting.transport {
        case .ble, .both:
            return true
        default:
            return false
        }
    }
    
    /// Check and ask for bluetooth permission
    /// - Parameter completion: completion
    func checkBluetoothOnStatus(_ completion: @escaping (CBManagerState) -> Void) {
        self.bluetoothOnStatusCompletion = completion
        self.bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// UI to alert user of the Bluetooth status
    /// - Parameters:
    ///   - title: alert title
    ///   - message: message
    ///   - buttonTitle: button title
    ///   - cancelCallback: cancel callback
    func authorizeCBAlert(title: String, message: String, buttonTitle: String, completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        let goToSettingsAction = UIAlertAction(title: buttonTitle, style: .default, handler: {_ in
            completion(true)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in
            completion(false)
        })
        alertController.addAction(cancelAction)
        alertController.addAction(goToSettingsAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// Check CB status and proceed
    /// - Parameter completion: completion
    func checkCBAndProceed(_ completion: @escaping () -> Void) {
        self.checkBluetoothOnStatus { cbStatus in
            switch cbStatus {
            case .poweredOff, .unauthorized:
                self.handleCBPermissionError(cbStatus: cbStatus)
            default:
                completion()
            }
        }
    }
    
    /// Handle BLE persmission status workflow
    /// - Parameter cbStatus: BLE status
    func handleCBPermissionError(cbStatus: CBManagerState) {
        switch cbStatus {
        case .poweredOff:
            DispatchQueue.main.async {
                self.alertUser(title: Constants.settings, message: AppMessages.turnBLEOnMsg, buttonTitle: "OK") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        case .unauthorized:
            DispatchQueue.main.async {
                self.authorizeCBAlert(title: "", message: AppMessages.blePermissionReqdMsg, buttonTitle: Constants.settings) { shouldGoToSettings in
                    if shouldGoToSettings {
                        self.openSettingsApp()
                    } else {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        default:
            break
        }
    }
    
    /// Code to dismiss UIAlertController from screen if displayed
    func dismissDisplayedAlert() {
        if let top = UIApplication.shared.keyWindow?.rootViewController {
            if let alert = top.presentedViewController as? UIAlertController {
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    /// Navigate to Settings in order to provide Bluetooth permission
    func openSettingsApp() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL) { _ in }
        }
    }
}

extension ScannerViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.bluetoothOnStatusCompletion?(central.state)
    }
}
