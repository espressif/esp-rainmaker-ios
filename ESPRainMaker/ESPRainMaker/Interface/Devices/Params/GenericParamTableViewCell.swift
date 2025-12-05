// Copyright 2020 Espressif Systems
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
//  GenericParamTableViewCell.swift
//  ESPRainMaker
//

import UIKit

class GenericParamTableViewCell: GenericControlTableViewCell {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset cell state to prevent cell reuse bugs
        // Note: attributeKey will be set again in getTableViewGenericCell, but we reset it here for safety
        attributeKey = ""
        controlValue = nil
        // Don't reset param, device, dataType, paramDelegate as they're set during cell configuration
    }
    
    override func layoutSubviews() {
        // Customise switch element for param screen
        // Hide row selection button
        super.layoutSubviews()
        checkButton.isHidden = true
        leadingSpaceConstraint.constant = 15.0
        trailingSpaceConstraint.constant = 15.0

        backgroundColor = UIColor.clear

        backView.layer.borderWidth = 1
        backView.layer.cornerRadius = 10
        backView.layer.borderColor = UIColor.clear.cgColor
        backView.layer.masksToBounds = true

        layer.shadowOpacity = 0.18
        layer.shadowOffset = CGSize(width: 1, height: 2)
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.black.cgColor
        layer.masksToBounds = false
    }

    @IBAction override func editButtonTapped(_: Any) {
        // CRITICAL FIX: Capture attributeKey and param.name at alert creation time to prevent cell reuse issues
        // When the cell is reused while alert is showing, these captured values ensure correct param is updated
        let capturedAttributeKey = attributeKey
        let capturedParamName = param?.name ?? attributeKey
        let capturedParam = param
        let capturedDevice = device
        let capturedDataType = dataType
        let capturedParamDelegate = paramDelegate
        
        // Create alert controller safely without force unwrap
        let alertTitle = capturedAttributeKey
        let alertMessage: String
        if param?.type == Constants.deviceNameParam {
            alertMessage = "Enter device name of length 1-32 characters"
        } else {
            alertMessage = "Enter new value"
        }
        let input = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        input.addTextField { textField in
            textField.text = self.controlValue ?? ""
            self.addHeightConstraint(textField: textField)
        }

        input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
        }))
        input.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak input] _ in
            guard let valueTextField = input?.textFields?.first,
                  let value = valueTextField.text else {
                return
            }
            // Use captured values instead of self properties to prevent cell reuse bugs
            self.doneButtonAction(capturedAttributeKey: capturedAttributeKey,
                                 capturedParamName: capturedParamName,
                                 capturedParam: capturedParam,
                                 capturedDevice: capturedDevice,
                                 capturedDataType: capturedDataType,
                                 capturedParamDelegate: capturedParamDelegate,
                                 value: value)
        }))
        parentViewController?.present(input, animated: true, completion: nil)
    }

    @objc override func doneButtonAction() {
        // Backward compatibility: use current cell properties if called without parameters
        doneButtonAction(capturedAttributeKey: attributeKey,
                        capturedParamName: param?.name ?? attributeKey,
                        capturedParam: param,
                        capturedDevice: device,
                        capturedDataType: dataType,
                        capturedParamDelegate: paramDelegate,
                        value: controlValue)
    }
    
    /// Internal method that uses captured values to prevent cell reuse bugs
    /// - Parameters:
    ///   - capturedAttributeKey: The attributeKey captured at alert creation time
    ///   - capturedParamName: The param.name captured at alert creation time
    ///   - capturedParam: The param object captured at alert creation time
    ///   - capturedDevice: The device object captured at alert creation time
    ///   - capturedDataType: The dataType captured at alert creation time
    ///   - capturedParamDelegate: The paramDelegate captured at alert creation time
    ///   - value: The value to update
    private func doneButtonAction(capturedAttributeKey: String,
                                  capturedParamName: String,
                                  capturedParam: Param?,
                                  capturedDevice: Device?,
                                  capturedDataType: String,
                                  capturedParamDelegate: ParamUpdateProtocol?,
                                  value: String?) {
        guard let value = value else { return }
        
        // Validate essential values before proceeding
        guard let device = capturedDevice else {
            showAlert(message: "Device information is missing. Please try again.")
            return
        }
        
        // Use captured paramName as the definitive key (most reliable)
        let paramKeyToUse = capturedParamName.isEmpty ? capturedAttributeKey : capturedParamName
        
        // Ensure we have a valid param key
        guard !paramKeyToUse.isEmpty else {
            showAlert(message: "Parameter name is missing. Please try again.")
            return
        }
        
        // Helper function to check if cell is still showing the same param
        // Uses both identity check (same object) and name check (same param name) for robustness
        func isSameParam() -> Bool {
            // Identity check: same object reference (fastest, most reliable if objects aren't replaced)
            if capturedParam === param {
                return true
            }
            // Name check: same param name (handles case where param object was replaced but it's the same param)
            if let currentParamName = param?.name, !currentParamName.isEmpty {
                return currentParamName == capturedParamName
            }
            // Fallback: check attributeKey
            return attributeKey == capturedAttributeKey
        }
        
        // Helper function to find and update the correct cell if it's visible (for cell reuse scenarios)
        // This provides immediate UI feedback even when the original cell was reused
        func updateCorrectCellIfVisible(paramName: String, value: String) {
            // CRITICAL: Update param value in BOTH local reference AND global node list
            // This ensures the optimistic update persists even after table reloads from global data
            
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
            
            // Try to find the correct cell in the visible cells and update it
            if let parentVC = parentViewController as? DeviceTraitListViewController,
               let tableView = parentVC.tableView {
                // Search through visible cells to find the one showing this param
                for cell in tableView.visibleCells {
                    if let genericCell = cell as? GenericParamTableViewCell,
                       genericCell.param?.name == paramName {
                        // Found the correct cell - update its label
                        genericCell.controlValueLabel.text = value
                        genericCell.controlValue = value
                        return
                    }
                }
            }
        }
        
        if capturedDataType.lowercased() == "int" {
            if let intValue = Int(value) {
                if let bounds = capturedParam?.bounds, let max = bounds["max"] as? Int, let min = bounds["min"] as? Int {
                    if intValue >= min, intValue <= max {
                        DeviceControlHelper.shared.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramKeyToUse: intValue]], delegate: capturedParamDelegate)
                        // Update UI: if same cell, update directly; if reused, find correct cell
                        if isSameParam() {
                            controlValueLabel.text = value
                            param?.value = intValue
                        } else {
                            updateCorrectCellIfVisible(paramName: capturedParamName, value: value)
                        }
                    } else {
                        showAlert(message: "Value out of bound.")
                    }
                } else {
                    DeviceControlHelper.shared.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramKeyToUse: intValue]], delegate: capturedParamDelegate)
                    // Update UI: if same cell, update directly; if reused, find correct cell
                    if isSameParam() {
                        controlValueLabel.text = value
                        param?.value = intValue
                    } else {
                        updateCorrectCellIfVisible(paramName: capturedParamName, value: value)
                    }
                }
            } else {
                showAlert(message: "Please enter a valid integer value.")
            }
        } else if capturedDataType.lowercased() == "float" {
            if let floatValue = Float(value) {
                if let bounds = capturedParam?.bounds, let max = bounds["max"] as? Float, let min = bounds["min"] as? Float {
                    if floatValue >= min, floatValue <= max {
                        DeviceControlHelper.shared.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramKeyToUse: floatValue]], delegate: capturedParamDelegate)
                        // Update UI: if same cell, update directly; if reused, find correct cell
                        if isSameParam() {
                            controlValueLabel.text = value
                            param?.value = floatValue
                        } else {
                            updateCorrectCellIfVisible(paramName: capturedParamName, value: value)
                        }
                    } else {
                        showAlert(message: "Value out of bound.")
                    }
                } else {
                    DeviceControlHelper.shared.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramKeyToUse: floatValue]], delegate: capturedParamDelegate)
                    // Update UI: if same cell, update directly; if reused, find correct cell
                    if isSameParam() {
                        controlValueLabel.text = value
                        param?.value = floatValue
                    } else {
                        updateCorrectCellIfVisible(paramName: capturedParamName, value: value)
                    }
                }
            } else {
                showAlert(message: "Please enter a valid float value.")
            }
        } else if capturedDataType.lowercased() == "bool" {
            if let validValue = boolTypeValidValues[value] {
                let boolValue = validValue != 0
                DeviceControlHelper.shared.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramKeyToUse: boolValue]], delegate: capturedParamDelegate)
                // Update UI: if same cell, update directly; if reused, find correct cell
                if isSameParam() {
                    controlValueLabel.text = value
                    param?.value = boolValue
                } else {
                    updateCorrectCellIfVisible(paramName: capturedParamName, value: value)
                }
            } else {
                showAlert(message: "Please enter a valid boolean value.")
            }
        } else {
            if capturedParam?.type == Constants.deviceNameParam {
                if value.count < 1 || value.count > 32 || value.isEmpty || value.trimmingCharacters(in: .whitespaces).isEmpty {
                    showAlert(message: "Please enter a valid device name within a range of 1-32 characters")
                    return
                }
            }
            DeviceControlHelper.shared.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramKeyToUse: value]], delegate: capturedParamDelegate) { result in
                // Updates local storage in case parameter update is successful.
                if result == .success {
                    DispatchQueue.main.async {
                        // Only update device name if this is still the same device
                        if device === self.device {
                            self.device.deviceName = value
                            ESPLocalStorageHandler().saveNodeDetails(nodes: User.shared.associatedNodeList)
                        }
                    }
                }
            }
            // Update UI: if same cell, update directly; if reused, find correct cell
            if isSameParam() {
                controlValueLabel.text = value
                param?.value = value as Any
            } else {
                updateCorrectCellIfVisible(paramName: capturedParamName, value: value)
            }

            if Configuration.shared.appConfiguration.supportLocalControl {
                ESPScheduler.shared.updateDeviceName(for: device.node?.node_id, name: device.name ?? "", deviceName: value)
            }
        }
    }
    
    override func paramTapped(_ sender: Any) {
        let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
        // Safe cast: use optional cast instead of force cast to prevent crashes
        guard let chartVC = deviceStoryboard.instantiateViewController(withIdentifier: "chartsVC") as? ESPChartsViewController else {
            return
        }
        chartVC.param = param
        chartVC.device = device
        if let isSimpleTimeSeries = self.isSimpleTimeSeries {
            chartVC.isSimpleTimeSeries = isSimpleTimeSeries
        }
        parentViewController?.navigationController?.pushViewController(chartVC, animated: true)
    }
}
