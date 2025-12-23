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
//  ParamRoundHueSliderCell+Updates.swift
//  ESPRainMaker
//
//  Component: Continuous Update Throttling Logic
//  Handles: Round hue slider value changes, continuous update handling

import FlexColorPicker
import UIKit

extension ParamRoundHueSliderCell {
    
    // MARK: - Actions
    @objc func valueChanged(_ sender: RadialHueControl) {
        // Update simple UIView background color to reflect slider thumb position
        let hsbColor = sender.selectedHSBColor.withSaturation(1.0)
        selectedColor.backgroundColor = UIColor(hue: hsbColor.hue, saturation: hsbColor.saturation, brightness: hsbColor.brightness, alpha: 1.0)
    }
}

// MARK: - RadialHueControlDelegate
extension ParamRoundHueSliderCell: RadialHueControlDelegate {
    
    /// Callback to get final selected color
    /// - Parameter value: final value of Hue
    func finalSelectedColor(value: CGFloat) {
        // Cancel any pending delayed update work item
        pendingDelayedUpdateWorkItem?.cancel()
        pendingDelayedUpdateWorkItem = nil
        
        // CRITICAL: Mark that user has finished dragging (touch ended)
        // Set timestamp for notification update cooldown
        isUserDragging = false
        dragEndTimestamp = Date()
        
        // Capture values for cell reuse protection
        guard let capturedParam = param,
              let capturedParamName = capturedParam.name,
              let capturedDevice = device else {
            return
        }
        
        finalValue = value
        
        if isRainmaker {
            // Update param if continuous update is disabled
            if !Configuration.shared.appConfiguration.supportContinuousUpdate {
                updateParamRM(value: value, capturedParam: capturedParam, capturedParamName: capturedParamName, capturedDevice: capturedDevice)
                return
            }
            
            // For continuous updates, send final value immediately and ignore pending updates
            shouldIgnorePendingUpdates = true
            
            let intValue = Int(value)
            DeviceControlHelper.shared.updateParam(nodeID: capturedDevice.node?.node_id, parameter: [capturedDevice.name ?? "": [capturedParamName: intValue]], delegate: self.paramDelegate) { result in
            }
            capturedParam.value = intValue
            hueInitialValue = value
            currentFinalValue = finalValue
        } else if #available(iOS 16.4, *) {
            #if ESPRainMakerMatter
            // Matter update handled in ParamRoundHueSliderCell+Matter.swift (if exists)
            #endif
        }
    }
    
    /// Callback that receives value for currently selected color
    /// - Parameter value: current value of Hue
    func selectedColor(value: CGFloat) {
        // CRITICAL: Mark that user is actively dragging
        isUserDragging = true
        dragEndTimestamp = nil
        shouldIgnorePendingUpdates = false // Reset flag when user starts dragging again
        
        // Update color indicator immediately (matches original implementation)
        // Convert value (0-360) to hue (0-1) for UIColor
        let hue = value / 360.0
        selectedColor.backgroundColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        
        // Skip param update if app does not support continuous updates or not Rainmaker
        if !Configuration.shared.appConfiguration.supportContinuousUpdate || !isRainmaker {
            return
        }
        
        // Check time elapsed since last slider update
        if currentTimeStamp.milliSeconds(from: Date()) > Configuration.shared.appConfiguration.continuousUpdateInterval {
            // CRITICAL: Capture values for cell reuse protection
            guard let capturedParam = param,
                  let capturedParamName = capturedParam.name,
                  let capturedDevice = device else {
                return
            }
            
            // CRITICAL: Verify cell still shows the same param before updating (cell reuse protection)
            guard isSameParam(capturedParam: capturedParam, capturedParamName: capturedParamName) else {
                return
            }
            
            currentTimeStamp = Date()
            group.enter()
            let intValue = Int(value)
            
            // Call updateParam directly (matches original - no queuing for performance)
            DeviceControlHelper.shared.updateParam(nodeID: capturedDevice.node?.node_id, parameter: [capturedDevice.name ?? "": [capturedParamName: intValue]], delegate: self.paramDelegate) { [weak self] result in
                guard let self = self else { return }
                // Ignore completion if user has already released slider
                if self.shouldIgnorePendingUpdates {
                    self.group.leave()
                    return
                }
                // Leave group after request is processed
                self.group.leave()
            }
            capturedParam.value = intValue
            hueInitialValue = value
            
            // Update global node list optimistically
            if let nodeId = capturedDevice.node?.node_id,
               let nodes = User.shared.associatedNodeList,
               let node = nodes.first(where: { $0.node_id == nodeId }),
               let deviceName = capturedDevice.name,
               let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
               let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                paramToUpdate.value = intValue
            }
            
            // NOTE: We intentionally do NOT schedule a delayed final update here.
            // The throttling logic above already ensures we send updates at a controlled rate,
            // and the final value will be sent when user releases the slider (finalSelectedColor).
        }
    }
}

