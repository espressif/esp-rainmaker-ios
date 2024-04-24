// Copyright 2023 Espressif Systems
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
//  DeviceViewController+BindingDelegate.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import UIKit

protocol BindingDelegate {
    func bindingInvoked(endpointClusterId: [String: UInt]?)
}

@available(iOS 16.4, *)
extension DeviceViewController: BindingDelegate {
    
    /// Binding invoked
    func bindingInvoked(endpointClusterId: [String: UInt]?) {
        if let node = self.node {
            let storyboard = UIStoryboard(name: ESPMatterConstants.matterStoryboardId, bundle: nil)
            let devicesBindingVC = storyboard.instantiateViewController(withIdentifier: DevicesBindingViewController.storyboardId) as! DevicesBindingViewController
            devicesBindingVC.group = self.group
            devicesBindingVC.nodes = self.allNodes
            devicesBindingVC.sourceNode = node
            devicesBindingVC.bindingEndpointClusterId = endpointClusterId
            devicesBindingVC.switchIndex = self.switchIndex
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(devicesBindingVC, animated: true)
            }
        }
    }
}
#endif
