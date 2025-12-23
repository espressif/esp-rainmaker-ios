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
//  ParamGenericCell+RM.swift
//  ESPRainMaker
//
//  Component: Rainmaker-Specific Generic Update Logic
//  Handles: Rainmaker generic parameter updates via DeviceControlHelper

import UIKit

extension ParamGenericCell {
    
    // MARK: - Rainmaker Generic Parameter Update
    // CRITICAL: Always use param.name directly to prevent cell reuse bugs
    func updateParamRM(paramName: String, value: Any, param: Param, device: Device) {
        guard let nodeId = device.node?.node_id else {
            return
        }
        
        // Update via DeviceControlHelper - CRITICAL: Use paramName from param, not stored property
        DeviceControlHelper.shared.updateParam(
            nodeID: nodeId,
            parameter: [device.name ?? "": [paramName: value]],
            delegate: paramDelegate
        )
        
        // Update param value
        param.value = value
    }
    
    // MARK: - Cell Reuse Protection Helpers
    
    /// Helper function to check if cell is still showing the same param
    /// Uses both identity check (same object) and name check (same param name) for robustness
    /// - Parameters:
    ///   - capturedParam: The param object captured at alert creation time
    ///   - capturedParamName: The param name captured at alert creation time
    /// - Returns: true if cell still shows the same param, false otherwise
    private func isSameParam(capturedParam: Param?, capturedParamName: String) -> Bool {
        // Identity check: same object reference (fastest, most reliable if objects aren't replaced)
        if let currentParam = param, capturedParam === currentParam {
            return true
        }
        // Name check: same param name (handles case where param object was replaced but it's the same param)
        if let currentParamName = param?.name, !currentParamName.isEmpty {
            return currentParamName == capturedParamName
        }
        // If current param is nil or has no name, cell was definitely reused
        return false
    }
    
    /// Helper function to find and update the correct cell if it's visible (for cell reuse scenarios)
    /// This provides immediate UI feedback even when the original cell was reused
    /// CRITICAL: Updates param value in BOTH local reference AND global node list
    /// This ensures the optimistic update persists even after table reloads from global data
    /// - Parameters:
    ///   - paramName: The parameter name to search for
    ///   - value: The string value to display
    ///   - capturedParam: The param object captured at alert creation time
    ///   - capturedDataType: The data type captured at alert creation time
    ///   - capturedDevice: The device object captured at alert creation time
    private func updateCorrectCellIfVisible(
        paramName: String,
        value: String,
        capturedParam: Param?,
        capturedDataType: String,
        capturedDevice: Device?
    ) {
        guard let device = capturedDevice else { return }
        
        // 1. Update local param reference (for immediate UI updates)
        var updatedValue: Any?
        if capturedDataType.lowercased() == "int", let intValue = Int(value) {
            updatedValue = intValue
            capturedParam?.value = intValue
        } else if capturedDataType.lowercased() == "float", let floatValue = Float(value) {
            updatedValue = floatValue
            capturedParam?.value = floatValue
        } else if capturedDataType.lowercased() == "bool", let validValue = boolTypeValidValues[value] {
            updatedValue = validValue != 0
            capturedParam?.value = validValue != 0
        } else {
            updatedValue = value as Any
            capturedParam?.value = value as Any
        }
        
        // 2. Update param value in global node list (so table reloads show correct value)
        if let nodeID = device.node?.node_id,
           let nodes = User.shared.associatedNodeList,
           let node = nodes.first(where: { $0.node_id == nodeID }),
           let deviceName = device.name,
           let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
           let paramToUpdate = deviceInNode.params?.first(where: { $0.name == paramName }),
           let finalValue = updatedValue {
            paramToUpdate.value = finalValue
        }
        
        // 3. Try to find the correct cell in the visible cells and update it
        if let parentVC = parentViewController as? DeviceTraitListViewController,
           let tableView = parentVC.tableView {
            // Search through visible cells to find the one showing this param
            for cell in tableView.visibleCells {
                if let genericCell = cell as? ParamGenericCell,
                   genericCell.param?.name == paramName {
                    // Found the correct cell - update both label AND controlValue property (matches old implementation)
                    genericCell.controlValueLabel.text = value
                    genericCell.controlValue = value
                    return
                }
            }
        }
    }
    
    // MARK: - Done Button Action Handler
    // CRITICAL: Uses captured paramName and attributeKey to prevent cell reuse bugs
    // CRITICAL: NEVER uses param.name or self.param - only uses capturedParamName to prevent wrong param updates
    func doneButtonAction(
        capturedAttributeKey: String,
        capturedParamName: String,
        capturedParam: Param?,
        capturedDevice: Device?,
        capturedDataType: String,
        capturedParamDelegate: ParamUpdateProtocol?,
        capturedIsDeviceOffline: Bool,
        value: String
    ) {
        guard let device = capturedDevice else {
            showAlert(message: "Device information is missing. Please try again.")
            return
        }
        
        guard !capturedParamName.isEmpty else {
            showAlert(message: "Parameter name is missing. Please try again.")
            return
        }
        
        // CRITICAL: Check if device is offline before sending update
        // Check both captured offline status AND current device connection status
        var isCurrentlyOffline = capturedIsDeviceOffline
        
        // For Rainmaker devices, also check current connection status
        if let node = device.node {
            let isConnected = node.isConnected || node.localNetwork
            if !isConnected {
                isCurrentlyOffline = true
            }
        }
        
        // For Matter devices, also check current isDeviceOffline flag (if available)
        if let currentDevice = self.device, self.isDeviceOffline {
            isCurrentlyOffline = true
        }
        
        if isCurrentlyOffline {
            showAlert(message: "Device is offline. Cannot update parameter. Please check your connection.")
            return
        }
        
        // CRITICAL: Validate that captured param is still valid
        // This ensures we don't update a param that was removed or changed
        guard let param = capturedParam, param.name == capturedParamName else {
            showAlert(message: "Parameter is no longer available. Please refresh and try again.")
            return
        }
        
        // Use captured paramName as the definitive key - fallback to capturedAttributeKey if empty (matches old implementation)
        let paramKeyToUse = capturedParamName.isEmpty ? capturedAttributeKey : capturedParamName
        
        // Check if cell is still showing the same param (cell reuse protection)
        let sameParam = isSameParam(capturedParam: capturedParam, capturedParamName: capturedParamName)
        
        if capturedDataType.lowercased() == "int" {
            guard let intValue = Int(value) else {
                showAlert(message: "Please enter a valid integer value.")
                return
            }
            
            // Check bounds if available
            if let bounds = capturedParam?.bounds,
               let max = bounds["max"] as? Int,
               let min = bounds["min"] as? Int {
                guard intValue >= min && intValue <= max else {
                    showAlert(message: "Value out of bound.")
                    return
                }
            }
            
            DeviceControlHelper.shared.updateParam(
                nodeID: device.node?.node_id,
                parameter: [device.name ?? "": [paramKeyToUse: intValue]],
                delegate: capturedParamDelegate
            )
            
            // Update param value in global node list (for all data types)
            if let nodeID = device.node?.node_id,
               let nodes = User.shared.associatedNodeList,
               let node = nodes.first(where: { $0.node_id == nodeID }),
               let deviceName = device.name,
               let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
               let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                paramToUpdate.value = intValue
            }
            
            // Update UI: if same cell, update directly; if reused, find correct cell
            if sameParam {
            capturedParam?.value = intValue
                controlValue = value // Set controlValue property (matches old implementation)
            controlValueLabel.text = value
            } else {
                updateCorrectCellIfVisible(
                    paramName: capturedParamName,
                    value: value,
                    capturedParam: capturedParam,
                    capturedDataType: capturedDataType,
                    capturedDevice: capturedDevice
                )
            }
            
        } else if capturedDataType.lowercased() == "float" {
            guard let floatValue = Float(value) else {
                showAlert(message: "Please enter a valid float value.")
                return
            }
            
            // Check bounds if available
            if let bounds = capturedParam?.bounds,
               let max = bounds["max"] as? Float,
               let min = bounds["min"] as? Float {
                guard floatValue >= min && floatValue <= max else {
                    showAlert(message: "Value out of bound.")
                    return
                }
            }
            
            DeviceControlHelper.shared.updateParam(
                nodeID: device.node?.node_id,
                parameter: [device.name ?? "": [paramKeyToUse: floatValue]],
                delegate: capturedParamDelegate
            )
            
            // Update param value in global node list (for all data types)
            if let nodeID = device.node?.node_id,
               let nodes = User.shared.associatedNodeList,
               let node = nodes.first(where: { $0.node_id == nodeID }),
               let deviceName = device.name,
               let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
               let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                paramToUpdate.value = floatValue
            }
            
            // Update UI: if same cell, update directly; if reused, find correct cell
            if sameParam {
            capturedParam?.value = floatValue
                controlValue = value // Set controlValue property (matches old implementation)
            controlValueLabel.text = value
            } else {
                updateCorrectCellIfVisible(
                    paramName: capturedParamName,
                    value: value,
                    capturedParam: capturedParam,
                    capturedDataType: capturedDataType,
                    capturedDevice: capturedDevice
                )
            }
            
        } else if capturedDataType.lowercased() == "bool" {
            guard let validValue = boolTypeValidValues[value] else {
                showAlert(message: "Please enter a valid boolean value.")
                return
            }
            
            let boolValue = validValue != 0
            DeviceControlHelper.shared.updateParam(
                nodeID: device.node?.node_id,
                parameter: [device.name ?? "": [paramKeyToUse: boolValue]],
                delegate: capturedParamDelegate
            )
            
            // Update param value in global node list (for all data types)
            if let nodeID = device.node?.node_id,
               let nodes = User.shared.associatedNodeList,
               let node = nodes.first(where: { $0.node_id == nodeID }),
               let deviceName = device.name,
               let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
               let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                paramToUpdate.value = boolValue
            }
            
            // Update UI: if same cell, update directly; if reused, find correct cell
            if sameParam {
            capturedParam?.value = boolValue
                controlValue = value // Set controlValue property (matches old implementation)
            controlValueLabel.text = value
            } else {
                updateCorrectCellIfVisible(
                    paramName: capturedParamName,
                    value: value,
                    capturedParam: capturedParam,
                    capturedDataType: capturedDataType,
                    capturedDevice: capturedDevice
                )
            }
            
        } else {
            // String type
            if capturedParam?.type == Constants.deviceNameParam {
                guard value.count >= 1 && value.count <= 32 && !value.trimmingCharacters(in: .whitespaces).isEmpty else {
                    showAlert(message: "Please enter a valid device name within a range of 1-32 characters")
                    return
                }
            }
            
            DeviceControlHelper.shared.updateParam(
                nodeID: device.node?.node_id,
                parameter: [device.name ?? "": [paramKeyToUse: value]],
                delegate: capturedParamDelegate
            ) { result in
                // Updates local storage in case parameter update is successful.
                if result == .success {
                    DispatchQueue.main.async {
                        // Only update device name if this is still the same device
                        if device === self.device {
                            device.deviceName = value
                            ESPLocalStorageHandler().saveNodeDetails(nodes: User.shared.associatedNodeList)
                        }
                    }
                }
            }
            
            // Update param value in global node list (for all data types)
            if let nodeID = device.node?.node_id,
               let nodes = User.shared.associatedNodeList,
               let node = nodes.first(where: { $0.node_id == nodeID }),
               let deviceName = device.name,
               let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
               let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                paramToUpdate.value = value as Any
            }
            
            // Update UI: if same cell, update directly; if reused, find correct cell
            if sameParam {
            capturedParam?.value = value as Any
                controlValue = value // Set controlValue property (matches old implementation)
            controlValueLabel.text = value
            } else {
                updateCorrectCellIfVisible(
                    paramName: capturedParamName,
                    value: value,
                    capturedParam: capturedParam,
                    capturedDataType: capturedDataType,
                    capturedDevice: capturedDevice
                )
            }
            
            // Scheduler update for device name changes
            if Configuration.shared.appConfiguration.supportLocalControl {
                ESPScheduler.shared.updateDeviceName(
                    for: device.node?.node_id,
                    name: device.name ?? "",
                    deviceName: value
                )
            }
        }
    }
    
    // MARK: - Backward Compatibility
    /// Backward compatibility: use current cell properties if called without parameters
    /// Matches old GenericParamTableViewCell.doneButtonAction() overload
    @objc func doneButtonAction() {
        doneButtonAction(
            capturedAttributeKey: attributeKey,
            capturedParamName: param?.name ?? attributeKey,
            capturedParam: param,
            capturedDevice: device,
            capturedDataType: dataType,
            capturedParamDelegate: paramDelegate,
            capturedIsDeviceOffline: isDeviceOffline,
            value: controlValue ?? ""
        )
    }
    
    // MARK: - Failure Handling
    /// Notify delegate of parameter update failure
    /// Matches old GenericControlTableViewCell.failureInUpdatingParam()
    func failureInUpdatingParam() {
        paramDelegate?.failureInUpdatingParam()
    }
}

