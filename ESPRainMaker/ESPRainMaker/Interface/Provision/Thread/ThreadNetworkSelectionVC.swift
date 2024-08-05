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
//  ThreadNetworkSelectionVC.swift
//  ESPRainMaker
//

import UIKit
import ThreadNetwork
import ESPProvision

@available(iOS 15.0, *)
class ThreadNetworkSelectionVC: UIViewController {
    
    var shouldScanThreadNetworks: Bool = true
    static let storyboardId = "ThreadNetworkSelectionVC"
    var espDevice: ESPDevice!
    @IBOutlet var nextButton: PrimaryButton!
    var threadOperationalDataset: Data!
    @IBOutlet weak var availableThreadNetwork: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nextButton.isUserInteractionEnabled = false
        if #available(iOS 16.4, *) {
            self.getThreadData()
        } else {
            self.alertUser(title: "Error", message: Constants.upgradeOSVersionMsg, buttonTitle: "OK") {}
        }
    }
    
    @available(iOS 16.4, *)
    func getThreadData() {
        if self.shouldScanThreadNetworks {
            DispatchQueue.main.async {
                Utility.showLoader(message: "Scanning thread networks...", view: self.view)
            }
            self.espDevice.scanThreadList { threadList, threadError in
                guard let threadList = threadList else {
                    DispatchQueue.main.async {
                        Utility.hideLoader(view: self.view)
                    }
                    if let threadError = threadError {
                        let failureMessage = threadError.localizedDescription
                        self.alertUser(title: "Failure", message: failureMessage, buttonTitle: "OK") {}
                    }
                    return
                }
                self.provFetchMultipleThreadNetworks(espDevice: self.espDevice, threadList: threadList) { threadOperationalDataset, networkName in
                    if let data = threadOperationalDataset {
                        DispatchQueue.main.async {
                            self.availableThreadNetwork.text = "Available Thread Network:\n\(networkName)\nDo you wish to proceed?"
                            self.threadOperationalDataset = data
                            self.nextButton.alpha = 1.0
                        }
                    }
                }
            }
        } else {
            self.performActiveThreadNetworkProv(espDevice: self.espDevice) { threadOperationalDataset, networkName in
                if let data = threadOperationalDataset {
                    DispatchQueue.main.async {
                        self.availableThreadNetwork.text = "Available Thread Network:\n\(networkName)\nDo you wish to proceed?"
                        self.threadOperationalDataset = data
                        self.nextButton.alpha = 1.0
                    }
                }
            }
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        if #available(iOS 16.4, *) {
            if let tOD = self.threadOperationalDataset {
                self.showSuccessScreenForThread(threadOperationalDataset: self.threadOperationalDataset, device: self.espDevice)
            }
        } else {
            // Fallback on earlier versions
            self.alertUser(title: "Error", message: Constants.upgradeOSVersionMsg, buttonTitle: "OK") {
                DispatchQueue.main.async {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    @available(iOS 16.4, *)
    func showSuccessScreenForThread(threadOperationalDataset: Data, device: ESPDevice) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let threadSuccessVC = storyboard.instantiateViewController(withIdentifier: ThreadSuccessViewController.storyboardId) as! ThreadSuccessViewController
        threadSuccessVC.espDevice = device
        threadSuccessVC.threadOperationalDataset = threadOperationalDataset
        navigationController?.pushViewController(threadSuccessVC, animated: true)
    }
}
