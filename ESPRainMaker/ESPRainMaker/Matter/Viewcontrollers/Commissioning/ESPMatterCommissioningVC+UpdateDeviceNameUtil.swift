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
//  ESPMatterCommissioningVC+UpdateDeviceNameUtil.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import UIKit
import MatterSupport
import Matter
import Foundation

@available(iOS 16.4, *)
extension ESPMatterCommissioningVC {

    /// Update device name for rainmaker + matter nodes
    /// - Parameter completion: completion handler
    func updateDeviceName(completion: @escaping () -> Void) {
        NetworkManager.shared.getNodes { nodes, _ in
            if let nodes = nodes, nodes.count > 0 {
                User.shared.associatedNodeList = nodes
                for node in nodes {
                    if let nodeId = node.node_id, node.isRainmaker, let deviceName = node.userDefinaedName, let groupId = self.groupId, let savedDeviceName = ESPMatterEcosystemInfo.shared.getDeviceName(), savedDeviceName == deviceName, let devices = node.devices, devices.count > 0 {
                        let device = devices[0]
                        for param in device.params ?? [] {
                            if let type = param.type, type == Constants.deviceNameParam, let properties = param.properties, properties.contains("write"), let name = device.name {
                                let attributeKey = param.name ?? ""
                                DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: [name: [attributeKey: deviceName]], delegate: self) { _ in
                                    completion()
                                }
                                return
                            }
                        }
                    }
                }
                completion()
            } else {
                completion()
            }
        }
    }
}
#endif
