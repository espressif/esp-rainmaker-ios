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
//  ParamCentralSwitchCell+RM.swift
//  ESPRainMaker
//
//  Component: Rainmaker-Specific Central Switch Update Logic
//  Handles: Rainmaker central switch parameter updates via DeviceControlHelper

import UIKit

extension ParamCentralSwitchCell {
    
    // MARK: - Power Button Action
    @objc func powerButtonPressed(_ sender: Any) {
        guard let param = param,
              let paramName = param.name,  // Use param.name directly, not stored property
              let device = device,
              let nodeId = device.node?.node_id else {
            return
        }
        
        // CRITICAL: Check if device is offline before sending update
        // For Rainmaker devices, check node connection
        if let node = device.node {
            let isConnected = node.isConnected || node.localNetwork
            if !isConnected {
                // Don't update - device is offline
                return
            }
        }
        
        let currentValue = param.value as? Bool ?? false
        let newValue = !currentValue
        
        // Update via DeviceControlHelper - CRITICAL: Use paramName from param, not stored property
        DeviceControlHelper.shared.updateParam(
            nodeID: nodeId,
            parameter: [device.name ?? "": [paramName: newValue]],
            delegate: paramDelegate
        )
        
        // Update param value (local reference)
        param.value = newValue
        
        // Update param value in global node list (so table reloads show correct value)
        if let nodes = User.shared.associatedNodeList,
           let node = nodes.first(where: { $0.node_id == nodeId }),
           let deviceName = device.name,
           let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
           let paramToUpdate = deviceInNode.params?.first(where: { $0.name == paramName }) {
            paramToUpdate.value = newValue
        }
        
        // Update UI
        if newValue {
            powerButton.setBackgroundImage(UIImage(named: "central_switch_on"), for: .normal)
        } else {
            powerButton.setBackgroundImage(UIImage(named: "central_switch_off"), for: .normal)
        }
        
        // Post notification for collection view reload
        NotificationCenter.default.post(Notification(name: Notification.Name(Constants.reloadCollectionView)))
    }
}

