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
//  ScannerViewController+WifiProvManagerProtocol.swift
//  ESPRainMaker
//

import ESPProvision
import UIKit

protocol WifiProvManagerProtocol {
    
    func goToProvision(device: ESPDevice)
    func goToJoinNetworkVC(device: ESPDevice)
    func performWifiNetworkActions(device: ESPDevice, rainmakerCaps: [String])
}

extension ScannerViewController: WifiProvManagerProtocol {
    
    /// Go to provisioning screen
    /// - Parameter device: esp device
    func goToProvision(device: ESPDevice) {
        let provisionVC = storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
        provisionVC.device = device
        navigationController?.pushViewController(provisionVC, animated: true)
    }
    
    /// Go to join wifi network screen
    /// - Parameter device: esp device
    func goToJoinNetworkVC(device: ESPDevice) {
        let joinNetworkVC = storyboard?.instantiateViewController(withIdentifier: JoinNetworkViewController.storyboardId) as! JoinNetworkViewController
        joinNetworkVC.device = device
        navigationController?.pushViewController(joinNetworkVC, animated: true)
    }
    
    /// Perform Wifi network actions
    /// - Parameters:
    ///   - device: esp device
    ///   - rainmakerCaps: rainmaker capabilities
    func performWifiNetworkActions(device: ESPDevice, rainmakerCaps: [String]) {
        if rainmakerCaps.contains(ESPScanConstants.wiFiScan) {
            DispatchQueue.main.async {
                self.goToProvision(device: device)
            }
        } else {
            DispatchQueue.main.async {
                self.goToJoinNetworkVC(device: device)
            }
        }
    }
}
