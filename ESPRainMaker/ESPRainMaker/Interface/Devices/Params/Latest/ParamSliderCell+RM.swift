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
//  ParamSliderCell+RM.swift
//  ESPRainMaker
//
//  Component: Rainmaker-Specific Update Logic
//  Handles: Rainmaker parameter updates via DeviceControlHelper

import UIKit

extension ParamSliderCell {
    
    // MARK: - Rainmaker Parameter Update
    // CRITICAL: Accepts captured values to prevent cell reuse bugs
    func updateParamRM(value: Float, capturedParamName: String? = nil, capturedParam: Param? = nil, capturedDevice: Device? = nil, skipOptimisticUpdate: Bool = false, completion: ((Bool) -> Void)? = nil) {
        // Use captured values if provided, otherwise fall back to current properties
        let paramToUse = capturedParam ?? param
        let deviceToUse = capturedDevice ?? device
        
        guard let param = paramToUse,
              let device = deviceToUse,
              let nodeId = device.node?.node_id else {
            return
        }
        
        // Use captured param name if provided, otherwise use param.name or paramName (matches old ParamSliderTableViewCell)
        let paramNameToUse = capturedParamName ?? (param.name ?? paramName)
        guard !paramNameToUse.isEmpty else {
            return
        }
        
        // CRITICAL: Verify param name matches (additional cell reuse protection)
        if let paramName = param.name, !paramName.isEmpty, paramName != paramNameToUse {
            // Param name mismatch - cell was likely reused
            return
        }
        
        // CRITICAL: Check if device is offline before sending update
        // For Rainmaker devices, check node connection
        if let node = device.node {
            let isConnected = node.isConnected || node.localNetwork
            if !isConnected {
                // Device offline - call completion with failure
                DispatchQueue.main.async {
                    if let initialValue = self.sliderInitialValue {
                        self.slider.setValue(initialValue, animated: true)
                        self.setSliderThumbUI()
                    }
                }
                completion?(false)
                return
            }
        }
        
        // For Matter devices, check isDeviceOffline flag
        if isDeviceOffline {
            // Device offline - call completion with failure
            DispatchQueue.main.async {
                if let initialValue = self.sliderInitialValue {
                    self.slider.setValue(initialValue, animated: true)
                    self.setSliderThumbUI()
                }
            }
            completion?(false)
            return
        }
        
        // Determine the value to send based on data type (use cached dataType for performance)
        let updateValue: Any
        if dataType == "int" {
            // Match old SliderTableViewCell behavior: send Int(value)
            let intValue = Int(value)
            updateValue = intValue
            sliderValue = paramNameToUse + ": \(intValue)"
        } else {
            updateValue = value
            // Update sliderValue property (matches old ParamSliderTableViewCell)
            sliderValue = paramNameToUse + ": \(value)"
        }
        
        // CRITICAL: Update param.value optimistically BEFORE API call (matches old ParamSliderTableViewCell)
        // This provides immediate UI feedback
        // BUT: Skip if already updated on main thread (for continuous updates)
        if !skipOptimisticUpdate {
            DispatchQueue.main.async {
                param.value = updateValue
                
                // CRITICAL: Update param value in global node list BEFORE API call (optimistic update)
                // This ensures the optimistic update persists even after table reloads from global data
                if let nodes = User.shared.associatedNodeList,
                   let node = nodes.first(where: { $0.node_id == nodeId }),
                   let deviceName = device.name,
                   let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                   let paramToUpdate = deviceInNode.params?.first(where: { $0.name == paramNameToUse }) {
                    paramToUpdate.value = updateValue
                }
            }
        }
        
        // Update via DeviceControlHelper - Use paramNameToUse (matches old ParamSliderTableViewCell which used paramName)
        // CRITICAL: Add completion handler to track success/failure for sequential updates
        // CRITICAL: Capture values for closure to prevent cell reuse bugs
        let capturedUpdateValue = value
        let capturedUpdateValueForParam = updateValue
        let capturedDataTypeForFailure = dataType
        
        DeviceControlHelper.shared.updateParam(
            nodeID: nodeId,
            parameter: [device.name ?? "": [paramNameToUse: updateValue]],
            delegate: paramDelegate
        ) { [weak self] result in
            guard let self = self else {
                completion?(false)
                return
            }
            // CRITICAL: Verify cell still shows the same param before processing (cell reuse protection)
            guard self.isSameParam(capturedParam: paramToUse, capturedParamName: paramNameToUse) else {
                completion?(false)
                return
            }
            
            let success = (result == .success)
            
            // For non-continuous updates, handle immediate revert on failure
            // For continuous updates, defer revert handling until all complete
            if !success {
                DispatchQueue.main.async {
                    // Only revert immediately for non-continuous updates
                    // Continuous updates will be handled after all complete
                    if let initialValue = self.sliderInitialValue {
                        self.slider.setValue(initialValue, animated: true)
                        self.setSliderThumbUI()
                        
                        // Revert param.value
                        if capturedDataTypeForFailure == "int" {
                            param.value = Int(initialValue)
                        } else {
                            param.value = initialValue
                        }
                        
                        // Revert global node list
                        if let nodes = User.shared.associatedNodeList,
                           let node = nodes.first(where: { $0.node_id == nodeId }),
                           let deviceName = device.name,
                           let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                           let paramToUpdate = deviceInNode.params?.first(where: { $0.name == paramNameToUse }) {
                            if capturedDataTypeForFailure == "int" {
                                paramToUpdate.value = Int(initialValue)
                            } else {
                                paramToUpdate.value = initialValue
                            }
                        }
                    }
                }
            }
            
            // Call completion handler with success/failure
            completion?(success)
        }
        
        // CRITICAL: Do NOT update slider or call setSliderThumbUI here when skipOptimisticUpdate is true
        // Those updates were already done on main thread before this method was called
        // Only update slider if this is NOT a continuous update (non-continuous updates don't skip optimistic update)
        if !skipOptimisticUpdate {
            // Update slider if needed (for step sliders)
            if let initialValue = sliderInitialValue, value != initialValue {
                sliderInitialValue = value
            }
            
            DispatchQueue.main.async {
                if self.slider.value != value {
                    self.slider.setValue(value, animated: true)
                    self.setSliderThumbUI()
                }
            }
        }
    }
}

