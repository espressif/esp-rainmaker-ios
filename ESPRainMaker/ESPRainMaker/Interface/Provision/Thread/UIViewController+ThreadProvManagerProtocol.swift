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
    
    @available(iOS 15.0, *)
    func provFetchMultipleThreadNetworks(espDevice: ESPDevice, threadList: [ESPThreadNetwork], _ completion: @escaping (Data?, String) -> Void)
    
    @available(iOS 15.0, *)
    func performActiveThreadNetworkProv(espDevice: ESPDevice, _ completion: @escaping (Data?, String) -> Void)
    
    func performActiveESPThreadNetworkProv(_ completion: @escaping (Data?, String) -> Void, failureCompletionHandler: @escaping () -> Void)
    
    @available(iOS 15.0, *)
    func getThreadOperationalDatasetFromTHCredentials(threadNetwork: THCredentials, networkKey: String) -> String
    
    func getThreadOperationalDataset(threadNetwork: ESPThreadNetwork, networkKey: String) -> String
    
    @available(iOS 15.0, *)
    func showThreadNetworkSelectionVC(shouldScanThreadNetworks: Bool, device: ESPDevice)
    
    @available(iOS 15.0, *)
    func showStatusScreenForThread(shouldScanThreadNetworks: Bool, device: ESPDevice)
    
    func goToProvision(device: ESPDevice, withThreadNetworks threadNetworks: [ESPThreadNetwork])
}

extension UIViewController: ThreadProvManagerProtocol {
    
    /// Fetch multiple thread networks from iOS.
    /// Iterate and match with scanned list from ESPDevice.
    /// - Parameter threadList: ESPDevice scanned thread list
    @available(iOS 15.0, *)
    func provFetchMultipleThreadNetworks(espDevice: ESPDevice, threadList: [ESPThreadNetwork], _ completion: @escaping (Data?, String) -> Void) {
        ThreadCredentialsManager.shared.fetchMultipleThreadCredentials { creds in
            guard let creds = creds else {
                self.checkAssociatedNodeListForTBR(threadList: threadList, completion: completion)
                return
            }
            for cred in creds {
                var shouldBreak = false
                for thread in threadList {
                    if let networkName = cred.networkName, thread.networkName == networkName, let networkKey = cred.networkKey?.hexadecimalString {
                        shouldBreak = true
                        let dataset = self.getThreadOperationalDataset(threadNetwork: thread, networkKey: networkKey)
                        let threadOperationalDataset = Data(hex: dataset)
                        completion(threadOperationalDataset, networkName)
                        DispatchQueue.main.async {
                            Utility.hideLoader(view: self.view)
                        }
                        break
                    }
                }
                if shouldBreak {
                    return
                }
            }
            self.checkAssociatedNodeListForTBR(threadList: threadList, completion: completion)
        }
    }
    
    /// We check the associated node list of the user to determine if we have a TBR provisioned.
    /// If present if it is currently running. If is running and reachable over mDNS we use it's active operational
    /// dataset in order to provision the thread end device.
    /// - Parameter threadList: scanned thread list from ESP device.
    func checkAssociatedNodeListForTBR(threadList: [ESPThreadNetwork], completion: @escaping (Data?, String) -> Void) {
        User.shared.scanThreadBorderRouters { scannedTBRs, scannedNetworks, _ in
            User.shared.stopThreadBRSearch()
            for threadNetwork in threadList {
                guard scannedTBRs.count > 0 else {
                    DispatchQueue.main.async {
                        Utility.hideLoader(view: self.view)
                        self.showErrorAlert(title: "Error", message: AppMessages.connectTBRMsg, buttonTitle: "OK") {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                    return
                }
                for scannedTBR in scannedTBRs {
                    if let tBRNode = User.shared.getNode(id: scannedTBR),  tBRNode.isThreadBorderRouter, let associatedNodeId = tBRNode.node_id, let activeDataset = (tBRNode.getServiceParam(forServiceType: Constants.threadBRService, andParamType: Constants.threadActiveDataset)?.value as? String)?.hexadecimal as? Data, let networkName = scannedNetworks[associatedNodeId], threadNetwork.networkName == networkName {
                        DispatchQueue.main.async {
                            Utility.hideLoader(view: self.view)
                        }
                        completion(activeDataset, networkName)
                        return
                    }
                }
            }
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                completion(nil, "")
            }
        }
    }
    
    /// Perform thread provisioning using the active store operational datraset of iOS
    @available(iOS 15.0, *)
    func performActiveThreadNetworkProv(espDevice: ESPDevice, _ completion: @escaping (Data?, String) -> Void) {
        ThreadCredentialsManager.shared.fetchThreadCredentials { cred, _ in
            if let cred = cred, let networkKey = cred.networkKey, let networkName = cred.networkName {
                User.shared.scanThreadBorderRouters() { tBRs, scannedNetworks, _ in
                    User.shared.stopThreadBRSearch()
                    for tBR in tBRs {
                        if let scannedNetworkName = scannedNetworks[tBR], scannedNetworkName == networkName {
                            DispatchQueue.main.async {
                                Utility.hideLoader(view: self.view)
                            }
                            let dataset = self.getThreadOperationalDatasetFromTHCredentials(threadNetwork: cred, networkKey: networkKey.hexadecimalString)
                            let threadOperationalDataset = Data(hex: dataset)
                            completion(threadOperationalDataset, networkName)
                            return
                        }
                    }
                    self.performThreadProvWithESPTBR(completion)
                }
            } else {
                self.performThreadProvWithESPTBR(completion)
            }
        }
    }
    
    /// Perform Thread provisioning with ESP Thread Border Router
    /// Scan for Thread Border Routers
    /// If one from the list is an ESP node, use that as the TBR for provisioning
    /// - Parameter completion: A completion handler
    func performThreadProvWithESPTBR(_ completion: @escaping (Data?, String) -> Void) {
        self.performActiveESPThreadNetworkProv(completion) {
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.showErrorAlert(title: "Error", message: AppMessages.connectTBRMsg, buttonTitle: "OK") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    /// Perform thread network provisioning using ESP thread network.
    /// That is the thread network of an ESP thread border router..
    /// - Parameters:
    ///   - completion: completion
    ///   - failureCompletionHandler: invoked if there is no active ESP thread border router
    func performActiveESPThreadNetworkProv(_ completion: @escaping (Data?, String) -> Void, failureCompletionHandler: @escaping () -> Void) {
        User.shared.scanThreadBorderRouters() { tBRs, scannedNetworks, _ in
            User.shared.stopThreadBRSearch()
            if tBRs.count > 0 {
                for associatedNode in User.shared.associatedNodeList ?? [] {
                    if let associatedNodeId = associatedNode.node_id, associatedNode.isThreadBorderRouter, tBRs.contains(associatedNodeId), let networkName = scannedNetworks[associatedNodeId] {
                        /// If the device is a thread border router
                        /// Check for if has an active operational dataset.
                        if let tADParam = associatedNode.getServiceParam(forServiceType: Constants.threadBRService, andParamType: Constants.threadActiveDataset), let tADParamValue = tADParam.value as? String, let tAD_Data = tADParamValue.hexadecimal {
                            DispatchQueue.main.async {
                                Utility.hideLoader(view: self.view)
                            }
                            completion(tAD_Data, networkName)
                            return
                        }
                    }
                }
            }
            failureCompletionHandler()
        }
    }
    
    /// Get thread operational dataset from ESPThrad network and network key
    /// - Parameters:
    ///   - threadNetwork: thread network
    ///   - networkKey: network key
    /// - Returns: thread operational dataset to be sent to the device.
    func getThreadOperationalDataset(threadNetwork: ESPThreadNetwork, networkKey: String) -> String {
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
    @available(iOS 15.0, *)
    func getThreadOperationalDatasetFromTHCredentials(threadNetwork: THCredentials, networkKey: String) -> String {
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
        if #available(iOS 15.0, *) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let threadNetworkSelectionVC = storyboard.instantiateViewController(withIdentifier: ThreadNetworkSelectionVC.storyboardId) as! ThreadNetworkSelectionVC
            threadNetworkSelectionVC.espDevice = device
            threadNetworkSelectionVC.shouldScanThreadNetworks = shouldScanThreadNetworks
            navigationController?.pushViewController(threadNetworkSelectionVC, animated: true)
        } else {
            self.alertUser(title: "Error", message: AppMessages.upgradeOS15VersionMsg, buttonTitle: "OK") {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    /// Show success view controller for thread commissioning
    /// - Parameters:
    ///   - step1Failed: step1Failed
    ///   - device: esp device
    ///   - threadOperationalDataset: thread operational dataset
    @available(iOS 15.0, *)
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
