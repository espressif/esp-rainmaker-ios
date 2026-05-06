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
//  ParamGenericCell+Actions.swift
//  ESPRainMaker
//
//  Component: Action Handling
//  Handles: Edit button tap, chart navigation, alert handling

import UIKit

extension ParamGenericCell {
    
    // MARK: - Edit Button Action
    @objc func editButtonTapped(_ sender: Any) {
        guard !isDeviceOfflineForEdit() else {
            showAlert(message: "Device is offline. Please check your connection.")
            return
        }
        
        guard let param = param, let device = device else { return }
        
        // CRITICAL: Use param.name if available, fallback to attributeKey (matches old implementation)
        let capturedParamName = param.name ?? attributeKey
        let capturedAttributeKey = attributeKey.isEmpty ? (param.name ?? "") : attributeKey
        let capturedParam = param
        let capturedDevice = device
        let capturedDataType = dataType
        let capturedParamDelegate = paramDelegate
        let capturedIsDeviceOffline = isDeviceOffline  // Capture offline status at alert creation
        let currentValue = controlValue ?? controlValueLabel.text ?? "" // Use controlValue property first (matches old implementation)
        
        // Create alert controller - use attributeKey for title (matches old implementation)
        let alertTitle = capturedAttributeKey
        let alertMessage: String
        if param.type == Constants.deviceNameParam {
            alertMessage = "Enter device name of length 1-32 characters"
        } else {
            alertMessage = "Enter new value"
        }
        
        let input = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        input.addTextField { textField in
            // CRITICAL: Use controlValue property if available, fallback to label text (matches old implementation)
            textField.text = self.controlValue ?? currentValue
            self.addHeightConstraint(textField: textField)
        }
        
        input.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        input.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak input] _ in
            guard let valueTextField = input?.textFields?.first,
                  let value = valueTextField.text else {
                return
            }
            // Use captured values to prevent cell reuse bugs
            // Done button action is in ParamGenericCell+RM.swift
            self.doneButtonAction(
                capturedAttributeKey: capturedAttributeKey,
                capturedParamName: capturedParamName,
                capturedParam: capturedParam,
                capturedDevice: capturedDevice,
                capturedDataType: capturedDataType,
                capturedParamDelegate: capturedParamDelegate,
                capturedIsDeviceOffline: capturedIsDeviceOffline,
                value: value
            )
        }))
        
        parentViewController?.present(input, animated: true, completion: nil)
    }
    
    // MARK: - Chart Navigation
    @objc func paramTapped(_ sender: Any) {
        guard let param = param, let device = device else { return }
        
        let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
        guard let chartVC = deviceStoryboard.instantiateViewController(withIdentifier: "chartsVC") as? ESPChartsViewController else {
            return
        }
        
        chartVC.param = param
        chartVC.device = device
        if let isSimpleTimeSeries = isSimpleTimeSeries {
            chartVC.isSimpleTimeSeries = isSimpleTimeSeries
        }
        
        parentViewController?.navigationController?.pushViewController(chartVC, animated: true)
    }
    
    // MARK: - Helper Methods
    func addHeightConstraint(textField: UITextField) {
        let heightConstraint = NSLayoutConstraint(
            item: textField,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: 30
        )
        textField.addConstraint(heightConstraint)
        if let font = textField.font {
            textField.font = UIFont(name: font.fontName, size: 18)
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Failure!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        parentViewController?.present(alert, animated: true)
    }
    
    private func isDeviceOfflineForEdit() -> Bool {
        let isMatterDevice = (deviceId != nil) || (nodeGroup != nil)
        
        if isMatterDevice {
            return isDeviceOffline
        }
        
        guard let device = device, let node = device.node else { return false }
        return !(node.isConnected || node.localNetwork)
    }
}

