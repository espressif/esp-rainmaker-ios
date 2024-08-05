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
//  UIViewController+ThreadProvManagerProtocol.swift
//  ESPRainMaker
//

import ESPProvision
import ThreadNetwork
import UIKit

protocol ThreadProvManagerProtocol {
    
    @available(iOS 16.4, *)
    func provFetchMultipleThreadNetworks(espDevice: ESPDevice, threadList: [ESPThreadNetwork], _ completion: @escaping (Data?, String) -> Void)
    
    @available(iOS 16.4, *)
    func provisionMatchingBorderAgentId(espDevice: ESPDevice, threadList: [ESPThreadNetwork], _ completion: @escaping (Data?) -> Void)
    
    @available(iOS 16.4, *)
    func performActiveThreadNetworkProv(espDevice: ESPDevice, _ completion: @escaping (Data?, String) -> Void)
    
    @available(iOS 16.4, *)
    func getThreadOpeartionalDatasetFromTHCredentials(threadNetwork: THCredentials, networkKey: String) -> String
    
    func getThreadOpeartionalDataset(threadNetwork: ESPThreadNetwork, networkKey: String) -> String
    
    @available(iOS 16.4, *)
    func showThreadNetworkSelectionVC(shouldScanThreadNetworks: Bool, device: ESPDevice)
    
    @available(iOS 16.4, *)
    func showStatusScreenForThread(shouldScanThreadNetworks: Bool, device: ESPDevice)
    
    func goToProvision(device: ESPDevice, withThreadNetworks threadNetworks: [ESPThreadNetwork])
}

extension UIViewController: ThreadProvManagerProtocol {
    
    /// Fetch multiple thread networks from iOS.
    /// Iterate and match with scanned list from ESPDevice.
    /// - Parameter threadList: ESPDevice scanned thread list
    @available(iOS 16.4, *)
    func provFetchMultipleThreadNetworks(espDevice: ESPDevice, threadList: [ESPThreadNetwork], _ completion: @escaping (Data?, String) -> Void) {
        ThreadCredentialsManager.shared.fetchMultipleThreadCredentials { creds in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
            }
            guard let creds = creds else {
                DispatchQueue.main.async {
                    self.showErrorAlert(title: "Error", message: ESPMatterConstants.noThreadBRDescription, buttonTitle: "OK") {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
                return
            }
            for cred in creds {
                var shouldBreak = false
                for thread in threadList {
                    if let networkName = cred.networkName, thread.networkName == networkName, let networkKey = cred.networkKey?.hexadecimalString {
                        shouldBreak = true
                        let dataset = self.getThreadOpeartionalDataset(threadNetwork: thread, networkKey: networkKey)
                        let threadOperationalDataset = Data(hex: dataset)
                        completion(threadOperationalDataset, networkName)
                        break
                    }
                }
                if shouldBreak {
                    return
                }
            }
            DispatchQueue.main.async {
                self.showErrorAlert(title: "Error", message: ESPMatterConstants.noMatchingThreadDescription, buttonTitle: "OK") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    /// Provision using THCredentials fetched using border agent id of scanned thread networks
    /// - Parameter threadList: scanned thread list
    @available(iOS 16.4, *)
    func provisionMatchingBorderAgentId(espDevice: ESPDevice, threadList: [ESPThreadNetwork], _ completion: @escaping (Data?) -> Void) {
        ThreadCredentialsManager.shared.checkThreadNetwork(threadList: threadList) { creds in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
            }
            guard let creds = creds, let nKey = creds.networkKey else {
                DispatchQueue.main.async {
                    self.showErrorAlert(title: "Error", message: ESPMatterConstants.noThreadBRDescription, buttonTitle: "OK") {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
                return
            }
            let nKeyStr = nKey.hexadecimalString
            let dataset = self.getThreadOpeartionalDatasetFromTHCredentials(threadNetwork: creds, networkKey: nKeyStr)
            let threadOperationalDataset = Data(hex: dataset)
            completion(threadOperationalDataset)
        }
    }
    
    /// Perform thread provisioning using the active store operational datraset of iOS
    @available(iOS 16.4, *)
    func performActiveThreadNetworkProv(espDevice: ESPDevice, _ completion: @escaping (Data?, String) -> Void) {
        ThreadCredentialsManager.shared.fetchThreadCredentials { cred in
            if let cred = cred, let networkKey = cred.networkKey, let networkName = cred.networkName {
                let dataset = self.getThreadOpeartionalDatasetFromTHCredentials(threadNetwork: cred, networkKey: networkKey.hexadecimalString)
                let threadOperationalDataset = Data(hex: dataset)
                completion(threadOperationalDataset, networkName)
            } else {
                DispatchQueue.main.async {
                    self.showErrorAlert(title: "Error", message: ESPMatterConstants.noThreadBRDescription, buttonTitle: "OK") {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }
    }
    
    
    /// Get thread operational dataset from ESPThrad network and network key
    /// - Parameters:
    ///   - threadNetwork: thread network
    ///   - networkKey: network key
    /// - Returns: thread operational dataset to be sent to the device.
    func getThreadOpeartionalDataset(threadNetwork: ESPThreadNetwork, networkKey: String) -> String {
        var threadOperationalDatasetHexString = "00030000"
        threadOperationalDatasetHexString += String(format: "%02x", threadNetwork.channel)
        threadOperationalDatasetHexString += "0208"
        threadOperationalDatasetHexString +=  threadNetwork.extPanID.hexadecimalString
        threadOperationalDatasetHexString += "0510"
        threadOperationalDatasetHexString += networkKey
        threadOperationalDatasetHexString += "0102"
        threadOperationalDatasetHexString += String(format: "%04x", threadNetwork.panID)
        return threadOperationalDatasetHexString
    }
    
    /// Get thread operational dataset to be sent from iOS app to ESP device
    /// - Parameters:
    ///   - threadNetwork: thread network
    ///   - networkKey: network key
    /// - Returns: operational dataset
    @available(iOS 16.4, *)
    func getThreadOpeartionalDatasetFromTHCredentials(threadNetwork: THCredentials, networkKey: String) -> String {
        if let extendedPANId = threadNetwork.extendedPANID, let panId = threadNetwork.panID {
            var threadOperationalDatasetHexString = "00030000"
            threadOperationalDatasetHexString += String(format: "%02x", threadNetwork.channel)
            threadOperationalDatasetHexString += "0208"
            threadOperationalDatasetHexString +=  extendedPANId.hexadecimalString
            threadOperationalDatasetHexString += "0510"
            threadOperationalDatasetHexString += networkKey
            threadOperationalDatasetHexString += "0102"
            threadOperationalDatasetHexString += panId.hexadecimalString
            return threadOperationalDatasetHexString
        }
        return ""
    }
    
    /// Show thread network selection screen
    /// - Parameters:
    ///   - shouldScanThreadNetworks: should scan thread networks
    ///   - device: esp device
    func showThreadNetworkSelectionVC(shouldScanThreadNetworks: Bool = true, device: ESPDevice) {
        if #available(iOS 16.4, *) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let threadNetworkSelectionVC = storyboard.instantiateViewController(withIdentifier: ThreadNetworkSelectionVC.storyboardId) as! ThreadNetworkSelectionVC
            threadNetworkSelectionVC.espDevice = device
            threadNetworkSelectionVC.shouldScanThreadNetworks = shouldScanThreadNetworks
            navigationController?.pushViewController(threadNetworkSelectionVC, animated: true)
        } else {
            self.alertUser(title: "Error", message: Constants.upgradeOSVersionMsg, buttonTitle: "OK") {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    /// Show success view controller for thread commissioning
    /// - Parameters:
    ///   - step1Failed: step1Failed
    ///   - device: esp device
    ///   - threadOperationalDataset: thread operaitonal dataset
    @available(iOS 16.4, *)
    func showStatusScreenForThread(shouldScanThreadNetworks: Bool = true, device: ESPDevice) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let threadSuccessVC = storyboard.instantiateViewController(withIdentifier: ThreadSuccessViewController.storyboardId) as! ThreadSuccessViewController
        threadSuccessVC.espDevice = device
        threadSuccessVC.shouldScanThreadNetworks = shouldScanThreadNetworks
        navigationController?.pushViewController(threadSuccessVC, animated: true)
    }
    
    /// Go to provision screen with scanned thread networks
    /// - Parameters:
    ///   - device: device
    ///   - threadNetworks: thread networks
    func goToProvision(device: ESPDevice, withThreadNetworks threadNetworks: [ESPThreadNetwork]) {
        DispatchQueue.main.async {
            let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
            provisionVC.device = device
            provisionVC.threadDetailList = threadNetworks
            self.navigationController?.pushViewController(provisionVC, animated: true)
        }
    }
}
