// Copyright 2025 Espressif Systems
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
//  ParamSwitchCell+RM.swift
//  ESPRainMaker
//
//  Component: Rainmaker-Specific Switch Update Logic
//  Handles: Rainmaker switch parameter updates via DeviceControlHelper

import UIKit

extension ParamSwitchCell {
    
    // MARK: - Rainmaker Switch Parameter Update
    // CRITICAL: Use param.name if available, fallback to attributeKey (matches old implementation)
    func updateParamRM(value: Bool) {
        guard let param = param,
              let device = device,
              let nodeId = device.node?.node_id else {
            return
        }
        
        // Use param.name if available, fallback to attributeKey (matches old ParamSwitchTableViewCell)
        let paramName = param.name ?? attributeKey
        guard !paramName.isEmpty else {
            return
        }
        
        // CRITICAL: Check if device is offline before sending update
        // For Rainmaker devices, check node connection
        if let node = device.node {
            let isConnected = node.isConnected || node.localNetwork
            if !isConnected {
                // Revert switch state since update failed
                toggleSwitch.setOn(!value, animated: true)
                controlStateLabel.text = (!value) ? "On" : "Off"
                return
            }
        }
        
        // For Matter devices, check isDeviceOffline flag
        if isDeviceOffline {
            // Revert switch state since update failed
            toggleSwitch.setOn(!value, animated: true)
            controlStateLabel.text = (!value) ? "On" : "Off"
            return
        }
        
        // Update via DeviceControlHelper - Use paramName (matches old ParamSwitchTableViewCell which used attributeKey)
        DeviceControlHelper.shared.updateParam(
            nodeID: nodeId,
            parameter: [device.name ?? "": [paramName: value]],
            delegate: paramDelegate
        )
        
        // Update param value (local reference)
        param.value = value
        
        // Update param value in global node list (so table reloads show correct value)
        if let nodes = User.shared.associatedNodeList,
           let node = nodes.first(where: { $0.node_id == nodeId }),
           let deviceName = device.name,
           let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
           let paramToUpdate = deviceInNode.params?.first(where: { $0.name == paramName }) {
            paramToUpdate.value = value
        }
        
        // Post notification for collection view reload
        NotificationCenter.default.post(Notification(name: Notification.Name(Constants.reloadCollectionView)))
    }
    
    // MARK: - Switch Action Handler
    @objc func switchStateChanged(_ sender: UISwitch) {
        // Update state label
        controlStateLabel.text = sender.isOn ? "On" : "Off"
        
        // Update param - routes to RM or Matter based on isRainmaker flag
        updateParamRM(value: sender.isOn)
    }
}

