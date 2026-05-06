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
//  ParamDropDownCell+RM.swift
//  ESPRainMaker
//
//  Component: Rainmaker-Specific Dropdown Update Logic
//  Handles: Rainmaker dropdown parameter updates via DeviceControlHelper

import UIKit

extension ParamDropDownCell {
    
    // MARK: - Rainmaker Dropdown Parameter Update
    // CRITICAL: Accepts captured values to prevent cell reuse bugs
    func updateParamRM(selectedValue: String, capturedParamName: String? = nil, capturedParam: Param? = nil, capturedDevice: Device? = nil) {
        // Use captured values if provided, otherwise fall back to current properties
        let paramToUse = capturedParam ?? param
        let deviceToUse = capturedDevice ?? device
        
        guard let param = paramToUse,
              let paramName = capturedParamName ?? param.name,  // Use captured param name if provided
              let device = deviceToUse,
              let nodeId = device.node?.node_id else {
            return
        }
        
        // CRITICAL: Verify param name matches (additional cell reuse protection)
        if let currentParamName = param.name, !currentParamName.isEmpty, currentParamName != paramName {
            // Param name mismatch - cell was likely reused
            return
        }
        
        // CRITICAL: Check if device is offline before sending update
        // For Rainmaker devices, check node connection
        if let node = device.node {
            let isConnected = node.isConnected || node.localNetwork
            if !isConnected {
                // Revert dropdown selection since update failed
                controlValueLabel.text = currentValue
                return
            }
        }
        
        // For Matter devices, check isDeviceOffline flag
        if isDeviceOffline {
            // Revert dropdown selection since update failed
            controlValueLabel.text = currentValue
            return
        }
        
        // CRITICAL: Capture current value before update (for failure revert)
        let previousValue = currentValue
        let previousParamValue = param.value
        
        // Determine the value to send based on data type
        let updateValue: Any
        if let dataType = param.dataType?.lowercased() {
            if dataType == "int", let intValue = Int(selectedValue) {
                updateValue = intValue
            } else {
                updateValue = selectedValue
            }
        } else {
            updateValue = selectedValue
        }
        
        // CRITICAL: Match old implementation order exactly
        // 1. API call first (async)
        // 2. param.value update immediately after API call starts
        // 3. currentValue update immediately
        // 4. controlValueLabel.text update in DispatchQueue.main.async
        
        // Update via DeviceControlHelper - CRITICAL: Add completion handler for failure handling
        DeviceControlHelper.shared.updateParam(
            nodeID: nodeId,
            parameter: [device.name ?? "": [paramName: updateValue]],
            delegate: paramDelegate
        ) { [weak self] result in
            guard let self = self else { return }
            
            // CRITICAL: Verify cell still shows the same param before reverting (cell reuse protection)
            guard self.isSameParam(capturedParam: paramToUse, capturedParamName: paramName) else {
                return
            }
            
            // CRITICAL: Update param value in global node list on success (improvement over old implementation)
            if result == .success {
                if let nodes = User.shared.associatedNodeList,
                   let node = nodes.first(where: { $0.node_id == nodeId }),
                   let deviceName = device.name,
                   let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                   let paramToUpdate = deviceInNode.params?.first(where: { $0.name == paramName }) {
                    paramToUpdate.value = updateValue
                }
            }
            
            // CRITICAL: Handle failure - revert dropdown selection and param value if update failed
            if result == .failure {
                DispatchQueue.main.async {
                    // Revert UI
                    self.currentValue = previousValue
                    self.controlValueLabel.text = previousValue
                    
                    // Revert param.value
                    param.value = previousParamValue
                    
                    // Revert global node list
                    if let nodes = User.shared.associatedNodeList,
                       let node = nodes.first(where: { $0.node_id == nodeId }),
                       let deviceName = device.name,
                       let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                       let paramToUpdate = deviceInNode.params?.first(where: { $0.name == paramName }) {
                        paramToUpdate.value = previousParamValue
                    }
                }
            }
        }
        
        // Update param.value immediately after API call starts (matches old implementation order)
        // Since API is async, this is effectively optimistic
        if let dataType = param.dataType?.lowercased() {
            if dataType == "int", let intValue = Int(selectedValue) {
                param.value = intValue
            } else {
                param.value = selectedValue
            }
        } else {
            param.value = selectedValue
        }
        
        // Update current value (matches old implementation - happens immediately after API call starts)
        currentValue = selectedValue
        // Matches old implementation: Update label in DispatchQueue.main.async
        DispatchQueue.main.async {
            self.controlValueLabel.text = selectedValue
        }
    }
}

