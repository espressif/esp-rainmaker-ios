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
    
    @IBOutlet weak var button: PrimaryButton!
    var threadOperationalDataset: Data!
    @IBOutlet weak var availableThreadNetwork: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nextButton.isUserInteractionEnabled = false
        self.getThreadData()
        self.button.setTitle("Next", for: .normal)
    }
    
    func getThreadData() {
        if self.shouldScanThreadNetworks {
            DispatchQueue.main.async {
                Utility.showLoader(message: "Scanning thread networks...", view: self.view)
            }
            self.espDevice.scanThreadList { threadList, threadError in
                guard let threadList = threadList else {
                    DispatchQueue.main.async {
                        Utility.hideLoader(view: self.view)
                        self.alertUser(title: "Failure", message: AppMessages.noThreadScanResult, buttonTitle: "OK") {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                    return
                }
                self.provFetchMultipleThreadNetworks(espDevice: self.espDevice, threadList: threadList) { threadOperationalDataset, networkName in
                    if let data = threadOperationalDataset {
                        DispatchQueue.main.async {
                            let title = "Available Thread Network:"
                            let message = "Do you wish to proceed?"
                            self.availableThreadNetwork.text = "\(title)\n\(networkName)\n\(message)"
                            self.threadOperationalDataset = data
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.alertUser(title: "Failure", message: AppMessages.connectTBRMsg, buttonTitle: "OK") {
                                self.navigationController?.popToRootViewController(animated: true)
                            }
                        }
                    }
                }
            }
        } else {
            self.performActiveThreadNetworkProv(espDevice: self.espDevice) { threadOperationalDataset, networkName in
                if let data = threadOperationalDataset {
                    DispatchQueue.main.async {
                        let title = "Available Thread Network:"
                        let message = "Do you wish to proceed?"
                        self.availableThreadNetwork.text = "\(title)\n\(networkName)\n\(message)"
                        self.threadOperationalDataset = data
                    }
                }
            }
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        DispatchQueue.main.async {
            if let _ = self.threadOperationalDataset {
                self.showSuccessScreenForThread(threadOperationalDataset: self.threadOperationalDataset, device: self.espDevice)
            }
        }
    }
    
    func showSuccessScreenForThread(threadOperationalDataset: Data, device: ESPDevice) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let threadSuccessVC = storyboard.instantiateViewController(withIdentifier: ThreadSuccessViewController.storyboardId) as! ThreadSuccessViewController
        threadSuccessVC.espDevice = device
        threadSuccessVC.threadOperationalDataset = threadOperationalDataset
        navigationController?.pushViewController(threadSuccessVC, animated: true)
    }
}
