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
//  ParamSliderCell+Updates.swift
//  ESPRainMaker
//
//  Component: Continuous Update Throttling Logic
//  Handles: Slider drag updates, value change handling, step slider logic

import UIKit

extension ParamSliderCell {

    // MARK: - Slider Actions
    @objc func sliderValueDragged(_ sender: UISlider) {
        // Update thumb UI (matches original implementation)
        setSliderThumbUI()
        
        // For Matter devices, just update UI - no API calls during drag (matches original)
        if !isRainmaker {
            isUserDragging = true
            dragEndTimestamp = nil
            return
        }
        
        // Mark that user is actively dragging (for Rainmaker notification cooldown)
        if !isUserDragging {
            // First drag event - capture the starting value for step calculation reference
            dragStartValue = sender.value
        }
        isUserDragging = true
        dragEndTimestamp = nil
        shouldIgnorePendingUpdates = false // Reset flag when user starts dragging again
        
        // Skip param update if app does not support continuous updates
        if !Configuration.shared.appConfiguration.supportContinuousUpdate {
            return
        }
        
        // Check time elapsed since last slider update
        if currentTimeStamp.milliSeconds(from: Date()) > Configuration.shared.appConfiguration.continuousUpdateInterval {
            // Update timestamp
            currentTimeStamp = Date()
            
            // Check for slider final value in case of step slider
            let currentSliderValue = sender.value
            guard let value = getSliderFinalValue(sender) else {
                return
            }
            
            // CRITICAL: Capture values for cell reuse protection
            guard let capturedParam = param,
                  let capturedParamName = capturedParam.name ?? (paramName.isEmpty ? nil : paramName),
                  let capturedDevice = device else {
                return
            }
            let capturedDataType = dataType
            
            // CRITICAL: Verify cell still shows the same param before updating (cell reuse protection)
            guard isSameParam(capturedParam: capturedParam, capturedParamName: capturedParamName) else {
                return
            }
            
            // Send throttled update during drag
            // NOTE: These updates may complete after user releases slider - their completion handlers will be ignored
            group.enter()
            var val: Float = 0.0
            if capturedDataType.lowercased() == "int" {
                // Match old SliderTableViewCell behavior: send Int(value)
                let intValue = Int(value)
                sliderValue = capturedParamName + ": \(intValue)"
                // Call updateParam directly (matches original - no queuing for performance)
                DeviceControlHelper.shared.updateParam(nodeID: capturedDevice.node?.node_id, parameter: [capturedDevice.name ?? "": [capturedParamName: intValue]], delegate: self.paramDelegate) { [weak self] result in
                    guard let self = self else { return }
                    // Ignore completion if user has already released slider
                    if self.shouldIgnorePendingUpdates {
                        self.group.leave()
                        return
                    }
                    // CRITICAL: Do NOT update sliderInitialValue during drag - only update on touchUp
                    // This ensures dragStartValue remains the reference point for step calculations
                    // Leave group after request is processed
                    self.group.leave()
                }
                capturedParam.value = intValue
                val = Float(intValue)
            } else {
                sliderValue = capturedParamName + ": \(value)"
                // Call updateParam directly (matches original - no queuing for performance)
                DeviceControlHelper.shared.updateParam(nodeID: capturedDevice.node?.node_id, parameter: [capturedDevice.name ?? "": [capturedParamName: value]], delegate: self.paramDelegate) { [weak self] result in
                    guard let self = self else { return }
                    // Ignore completion if user has already released slider
                    if self.shouldIgnorePendingUpdates {
                        self.group.leave()
                        return
                    }
                    // CRITICAL: Do NOT update sliderInitialValue during drag - only update on touchUp
                    // This ensures dragStartValue remains the reference point for step calculations
                    // Leave group after request is processed
                    self.group.leave()
                }
                capturedParam.value = value
                val = value
            }
            if sender.value != val {
                sender.setValue(val, animated: true) // Match old SliderTableViewCell: use animated: true
            }
            // CRITICAL: Do NOT update sliderInitialValue here - only update on API success
            // This ensures dragStartValue remains the reference point for step calculations during the drag
            // Always update thumb UI to show current value
            setSliderThumbUI()
            
            // Update global node list optimistically
            if let nodeId = capturedDevice.node?.node_id,
               let nodes = User.shared.associatedNodeList,
               let node = nodes.first(where: { $0.node_id == nodeId }),
               let deviceName = capturedDevice.name,
               let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
               let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                if capturedDataType.lowercased() == "int" {
                    paramToUpdate.value = Int(value)
                } else {
                    paramToUpdate.value = value
                }
            }
            
            // NOTE: We intentionally do NOT schedule an extra delayed "final" update here.
            // The throttling logic above already ensures we send updates at a controlled rate,
            // and each throttled update uses the latest value at that moment. Adding another
            // delayed update would make requests feel queued and can cause redundant writes.
        }
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        // Update thumb UI (matches original implementation)
        setSliderThumbUI()
        
        // Mark that user has finished dragging (for Rainmaker notification cooldown)
        if isUserDragging {
            isUserDragging = false
            dragEndTimestamp = Date()
        }
        
        // CRITICAL: Matter updates are handled in sliderTouchUp (only fires when user interaction ends)
        // sliderValueChanged fires for both user and programmatic updates, so we don't use it for Matter
        if isRainmaker {
            // Rainmaker logic - unchanged
            guard let value = getSliderFinalValue(sender) else {
                return
            }
            self.finalValue = value
            if !Configuration.shared.appConfiguration.supportContinuousUpdate {
                // Update param if continuous update is disabled
                updateSliderParam(sender: sender)
                return
            }
            // For continuous updates, we don't send a delayed final update here
            // Updates are sent during drag (throttled), and final value is sent on touchUp
            // This prevents queued updates after user releases the slider
        }
    }
    
    // MARK: - Touch Up Callback (only fires when user interaction ends)
    @objc func sliderTouchUp(_ sender: UISlider) {
        // Cancel any pending delayed update work item
        pendingDelayedUpdateWorkItem?.cancel()
        pendingDelayedUpdateWorkItem = nil
        
        // Mark that user interaction has ended
        isUserDragging = false
        dragEndTimestamp = Date()
        // CRITICAL: Clear dragStartValue on touchUp - it will be recaptured on next drag
        dragStartValue = nil
        
        // For Rainmaker with continuous updates, wait for slider to settle then send final value
        if isRainmaker && Configuration.shared.appConfiguration.supportContinuousUpdate {
            shouldIgnorePendingUpdates = true
            
            // Capture references for delayed callback
            guard let capturedParam = param,
                  let capturedParamName = capturedParam.name ?? (paramName.isEmpty ? nil : paramName),
                  let capturedDevice = device else {
                return
            }
            
            let capturedDataType = dataType
            
            // Wait for slider to settle (after any bounce/elasticity) before sending final value
            // This ensures we send the actual final position, not where user released
            pendingDelayedUpdateWorkItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }

                // If user started dragging again, don't act on this stale touchUp callback.
                // This prevents late failures from reverting a new user interaction.
                if self.isUserDragging {
                    return
                }
                
                // Verify cell still shows the same param (cell reuse protection)
                guard self.isSameParam(capturedParam: capturedParam, capturedParamName: capturedParamName) else {
                    return
                }
                
                // Get the actual settled slider value (after any animation/bounce)
                let settledValue = sender.value
                guard let finalValue = self.getSliderFinalValue(sender) else {
                    return
                }
                
                // Capture previous value so we can revert UI/model if the update fails.
                let previousParamValue = capturedParam.value
                let previousSliderValueForUI: Float = {
                    if let prevInt = previousParamValue as? Int { return Float(prevInt) }
                    if let prevFloat = previousParamValue as? Float { return prevFloat }
                    if let prevDouble = previousParamValue as? Double { return Float(prevDouble) }
                    return settledValue
                }()
                
                // Send final value update with the settled position
                var val: Float = 0.0
                if capturedDataType.lowercased() == "int" {
                    // Match old SliderTableViewCell behavior: send Int(value)
                    let intValue = Int(finalValue)
                    val = Float(intValue)
                    
                    // Optimistically update UI/model to match what we're sending.
                    DispatchQueue.main.async {
                        capturedParam.value = intValue
                        self.sliderInitialValue = val
                        if sender.value != val {
                            sender.setValue(val, animated: false)
                        }
                        self.setSliderThumbUI()
                        
                        // Keep global node list consistent with optimistic UI
                        if let nodeId = capturedDevice.node?.node_id,
                           let nodes = User.shared.associatedNodeList,
                           let node = nodes.first(where: { $0.node_id == nodeId }),
                           let deviceName = capturedDevice.name,
                           let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                           let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                            paramToUpdate.value = intValue
                        }
                    }
                    
                    DeviceControlHelper.shared.updateParam(
                        nodeID: capturedDevice.node?.node_id,
                        parameter: [capturedDevice.name ?? "": [capturedParamName: intValue]],
                        delegate: self.paramDelegate
                    ) { [weak self] result in
                        guard let self = self else { return }
                        // Verify cell still shows the same param before reverting (cell reuse protection)
                        guard self.isSameParam(capturedParam: capturedParam, capturedParamName: capturedParamName) else {
                            return
                        }
                        if result == .success {
                            // CRITICAL: Only update sliderInitialValue on success at touchUp
                            DispatchQueue.main.async {
                                self.sliderInitialValue = val
                            }
                        } else {
                            DispatchQueue.main.async {
                                // Revert model
                                capturedParam.value = previousParamValue
                                
                                // Revert global node list
                                if let nodeId = capturedDevice.node?.node_id,
                                   let nodes = User.shared.associatedNodeList,
                                   let node = nodes.first(where: { $0.node_id == nodeId }),
                                   let deviceName = capturedDevice.name,
                                   let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                                   let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                                    paramToUpdate.value = previousParamValue
                                }
                                
                                // Revert UI to last known value
                                self.sliderInitialValue = previousSliderValueForUI
                                sender.setValue(previousSliderValueForUI, animated: false)
                                self.setSliderThumbUI()
                            }
                        }
                    }
                } else {
                    val = finalValue
                    
                    // Optimistically update UI/model to match what we're sending.
                    DispatchQueue.main.async {
                        capturedParam.value = finalValue
                        self.sliderInitialValue = val
                        if sender.value != val {
                            sender.setValue(val, animated: false)
                        }
                        self.setSliderThumbUI()
                        
                        // Keep global node list consistent with optimistic UI
                        if let nodeId = capturedDevice.node?.node_id,
                           let nodes = User.shared.associatedNodeList,
                           let node = nodes.first(where: { $0.node_id == nodeId }),
                           let deviceName = capturedDevice.name,
                           let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                           let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                            paramToUpdate.value = finalValue
                        }
                    }
                    
                    DeviceControlHelper.shared.updateParam(
                        nodeID: capturedDevice.node?.node_id,
                        parameter: [capturedDevice.name ?? "": [capturedParamName: finalValue]],
                        delegate: self.paramDelegate
                    ) { [weak self] result in
                        guard let self = self else { return }
                        // Verify cell still shows the same param before reverting (cell reuse protection)
                        guard self.isSameParam(capturedParam: capturedParam, capturedParamName: capturedParamName) else {
                            return
                        }
                        if result == .success {
                            // CRITICAL: Only update sliderInitialValue on success at touchUp
                            DispatchQueue.main.async {
                                self.sliderInitialValue = val
                            }
                        } else {
                            DispatchQueue.main.async {
                                // Revert model
                                capturedParam.value = previousParamValue
                                
                                // Revert global node list
                                if let nodeId = capturedDevice.node?.node_id,
                                   let nodes = User.shared.associatedNodeList,
                                   let node = nodes.first(where: { $0.node_id == nodeId }),
                                   let deviceName = capturedDevice.name,
                                   let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                                   let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                                    paramToUpdate.value = previousParamValue
                                }
                                
                                // Revert UI to last known value
                                self.sliderInitialValue = previousSliderValueForUI
                                sender.setValue(previousSliderValueForUI, animated: false)
                                self.setSliderThumbUI()
                            }
                        }
                    }
                }
            }
            
            // Schedule the delayed check after slider settles (0.15 seconds should be enough for any bounce)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: pendingDelayedUpdateWorkItem!)
            return
        }
        
        // This is called ONLY when user lifts finger (touchUpInside or touchUpOutside)
        // CRITICAL: This is the perfect place for Matter API calls - it never fires for programmatic updates
        if #available(iOS 16.4, *) {
            #if ESPRainMakerMatter
            guard !isRainmaker, let groupId = nodeGroup?.groupID, let deviceId = deviceId else {
                return
            }
            
            let val = sender.value
            
            // Match original Matter slider structure - call change methods directly
            // No debouncing needed - touchUp only fires once when user lifts finger
            switch self.sliderParamType {
            case .brightness:
                self.changeLevel(toValue: val)
            case .saturation:
                self.changeSaturation(value: val)
            case .airConditioner:
                self.changeOccupiedSetpoint(setPoint: Int16(val))
            case .cct:
                self.changeCCT(cct: Int(val))
            }
            #endif
        }
    }
    
    // MARK: - Helper method for updating slider param (matches original implementation)
    func updateSliderParam(sender: UISlider) {
        guard let capturedParam = param,
              let capturedParamName = capturedParam.name ?? (paramName.isEmpty ? nil : paramName),
              let capturedDevice = device else {
            return
        }
        let capturedDataType = dataType
        
        // CRITICAL: Verify cell still shows the same param before updating (cell reuse protection)
        guard isSameParam(capturedParam: capturedParam, capturedParamName: capturedParamName) else {
            return
        }

        // Capture previous value so we can revert UI/model if the update fails.
        let previousParamValue = capturedParam.value
        let previousSliderValueForUI: Float = {
            if let prevInt = previousParamValue as? Int { return Float(prevInt) }
            if let prevFloat = previousParamValue as? Float { return prevFloat }
            if let prevDouble = previousParamValue as? Double { return Float(prevDouble) }
            return sender.value
        }()
        
        let currentSliderValue = sender.value
        
        var val: Float = 0.0
        if capturedDataType.lowercased() == "int" {
            // Match old SliderTableViewCell behavior: send Int(value)
            let intFinalValue = Int(finalValue)
            sliderValue = capturedParamName + ": \(intFinalValue)"
            val = Float(intFinalValue)
            
            // Optimistically update UI/model to match what we're sending.
            DispatchQueue.main.async {
                capturedParam.value = intFinalValue
                // Do NOT update sliderInitialValue here - only update on API success
                if sender.value != val {
                    sender.setValue(val, animated: false)
                }
                self.setSliderThumbUI()
                
                // Keep global node list consistent with optimistic UI
                if let nodeId = capturedDevice.node?.node_id,
                   let nodes = User.shared.associatedNodeList,
                   let node = nodes.first(where: { $0.node_id == nodeId }),
                   let deviceName = capturedDevice.name,
                   let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                   let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                    paramToUpdate.value = intFinalValue
                }
            }
            
            DeviceControlHelper.shared.updateParam(
                nodeID: capturedDevice.node?.node_id,
                parameter: [capturedDevice.name ?? "": [capturedParamName: intFinalValue]],
                delegate: paramDelegate
            ) { [weak self] result in
                guard let self = self else { return }
                guard self.isSameParam(capturedParam: capturedParam, capturedParamName: capturedParamName) else {
                    return
                }
                if result == .success {
                    // CRITICAL: Only update sliderInitialValue on success
                    DispatchQueue.main.async {
                        self.sliderInitialValue = val
                    }
                } else {
                    DispatchQueue.main.async {
                        capturedParam.value = previousParamValue
                        
                        // Revert global node list
                        if let nodeId = capturedDevice.node?.node_id,
                           let nodes = User.shared.associatedNodeList,
                           let node = nodes.first(where: { $0.node_id == nodeId }),
                           let deviceName = capturedDevice.name,
                           let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                           let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                            paramToUpdate.value = previousParamValue
                        }
                        
                        self.sliderInitialValue = previousSliderValueForUI
                        sender.setValue(previousSliderValueForUI, animated: false)
                        self.setSliderThumbUI()
                    }
                }
            }
        } else {
            let finalValueToSend = finalValue
            sliderValue = capturedParamName + ": \(finalValueToSend)"
            val = finalValueToSend
            
            // Optimistically update UI/model to match what we're sending.
            DispatchQueue.main.async {
                capturedParam.value = finalValueToSend
                // Do NOT update sliderInitialValue here - only update on API success
                if sender.value != val {
                    sender.setValue(val, animated: false)
                }
                self.setSliderThumbUI()
                
                // Keep global node list consistent with optimistic UI
                if let nodeId = capturedDevice.node?.node_id,
                   let nodes = User.shared.associatedNodeList,
                   let node = nodes.first(where: { $0.node_id == nodeId }),
                   let deviceName = capturedDevice.name,
                   let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                   let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                    paramToUpdate.value = finalValueToSend
                }
            }
            
            DeviceControlHelper.shared.updateParam(
                nodeID: capturedDevice.node?.node_id,
                parameter: [capturedDevice.name ?? "": [capturedParamName: finalValueToSend]],
                delegate: paramDelegate
            ) { [weak self] result in
                guard let self = self else { return }
                guard self.isSameParam(capturedParam: capturedParam, capturedParamName: capturedParamName) else {
                    return
                }
                if result == .success {
                    // CRITICAL: Only update sliderInitialValue on success
                    DispatchQueue.main.async {
                        self.sliderInitialValue = val
                    }
                } else {
                    DispatchQueue.main.async {
                        capturedParam.value = previousParamValue
                        
                        // Revert global node list
                        if let nodeId = capturedDevice.node?.node_id,
                           let nodes = User.shared.associatedNodeList,
                           let node = nodes.first(where: { $0.node_id == nodeId }),
                           let deviceName = capturedDevice.name,
                           let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                           let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                            paramToUpdate.value = previousParamValue
                        }
                        
                        self.sliderInitialValue = previousSliderValueForUI
                        sender.setValue(previousSliderValueForUI, animated: false)
                        self.setSliderThumbUI()
                    }
                }
            }
        }
    }
    
    // MARK: - Parameter Update Router
    // Routes to appropriate update method based on device type
    // CRITICAL: Accepts captured values to prevent cell reuse bugs
    func updateParam(value: Float, isContinuous: Bool, capturedParamName: String? = nil, capturedParam: Param? = nil, capturedDevice: Device? = nil, skipOptimisticUpdate: Bool = false, completion: ((Bool) -> Void)? = nil) {
        // Use captured values if provided, otherwise fall back to current properties
        let paramNameToUse = capturedParamName ?? (param?.name ?? paramName)
        let paramToUse = capturedParam ?? param
        let deviceToUse = capturedDevice ?? device
        
        if isRainmaker {
            updateParamRM(value: value, capturedParamName: paramNameToUse, capturedParam: paramToUse, capturedDevice: deviceToUse, skipOptimisticUpdate: skipOptimisticUpdate, completion: completion)
            if isContinuous {
                // Don't call group.leave() here - it's handled in the completion handler
            }
        } else {
            #if ESPRainMakerMatter
            if #available(iOS 16.4, *) {
            // Matter update handled in ParamSliderCell+Matter.swift
            // Matter devices should NOT use continuous updates
            updateParamMatter(value: value, isContinuous: false)
            completion?(true)
            }
            #endif
        }
    }
    
    // MARK: - Cell Reuse Protection
    /// Check if cell still shows the same param (prevents cell reuse bugs)
    /// - Parameters:
    ///   - capturedParam: The param object captured at interaction start
    ///   - capturedParamName: The param name captured at interaction start
    /// - Returns: true if cell still shows the same param, false otherwise
    func isSameParam(capturedParam: Param?, capturedParamName: String) -> Bool {
        // Identity check: same object reference (fastest, most reliable if objects aren't replaced)
        if let currentParam = param, capturedParam === currentParam {
            return true
        }
        // Name check: same param name (handles case where param object was replaced but it's the same param)
        if let currentParamName = param?.name, !currentParamName.isEmpty {
            return currentParamName == capturedParamName
        }
        // Fallback to stored paramName
        if !paramName.isEmpty {
            return paramName == capturedParamName
        }
        // If current param is nil or has no name, cell was definitely reused
        return false
    }
    
    // MARK: - Helper Methods
    /// Convenience method for UISlider (1 parameter)
    /// Step-snapping consistent with the original `SliderTableViewCell` implementation.
    func getSliderFinalValue(_ slider: UISlider) -> Float? {
        var sliderValue: Float = slider.value
        var value: Float?
        
        // Check for step slider logic (matches SliderTableViewCell.getSliderFinalValue)
        if let step = sliderStepValue, step > 0.0, step < slider.maximumValue {
            if let initialValue = sliderInitialValue, sliderValue == initialValue {
                return nil
            }
            value = getSliderValue(value: sliderValue, step: step, type: .slider)
            if let val = value {
                if val > slider.maximumValue {
                    value = slider.maximumValue
                } else if val < slider.minimumValue {
                    value = slider.minimumValue
                }
            }
        } else {
            value = sliderValue
        }
        return value
    }
}

// MARK: - StepSliderProtocol Conformance
extension ParamSliderCell: StepSliderProtocol {
    /// Setup slider min/max and step values (matches old SliderTableViewCell)
    func setupParam(_ param: Param, _ type: SliderType) {
        self.param = param
        if let initialValue = param.value as? Float {
            sliderInitialValue = initialValue
        }
        if let bounds = param.bounds {
            switch type {
            case .slider:
                slider.minimumValue = bounds["min"] as? Float ?? 0
                slider.maximumValue = bounds["max"] as? Float ?? 100
            case .hueSlider:
                // Hue slider is handled in ParamHueSliderCell, but we need to conform to protocol
                // This case should not be called for ParamSliderCell
                break
            }
            if let step = bounds["step"] as? Float {
                sliderStepValue = step
            }
        }
    }
    
    /// Get final slider value after user stops slider movement (matches old SliderTableViewCell)
    func getSliderFinalValue(_ slider: UISlider?, _ gradientSlider: GradientSlider?, _ type: SliderType) -> Float? {
        var sliderValue: Float = 0.0
        var value: Float?
        switch type {
        case .slider:
            if let slider = slider {
                sliderValue = slider.value
            }
        case .hueSlider:
            // Hue slider is handled in ParamHueSliderCell, but we need to conform to protocol
            if let gradientSlider = gradientSlider {
                sliderValue = Float(gradientSlider.value)
            }
        }
        if let step = sliderStepValue, step > 0.0, (type == .slider ? (step < self.slider.maximumValue) : false) {
            if let initialValue = sliderInitialValue, sliderValue == initialValue {
                return nil
            }
            value = getSliderValue(value: sliderValue, step: step, type: type)
            if let val = value {
                switch type {
                case .slider:
                    if val > self.slider.maximumValue {
                        value = self.slider.maximumValue
                    } else if val < self.slider.minimumValue {
                        value = self.slider.minimumValue
                    }
                case .hueSlider:
                    // Hue slider bounds checking would go here if needed
                    break
                }
            }
        } else {
            value = sliderValue
        }
        return value
    }
    
    /// Get slider value based on initial, current and step values
    /// CRITICAL: Uses dragStartValue (value when user started dragging) as reference point for direction
    /// This ensures we correctly determine if user is moving up or down, even if slider was snapped to a different value
    func getSliderValue(value: Float, step: Float, type: SliderType) -> Float {
        var initialValue: Float = 0.0
        switch type {
        case .slider:
            if value == slider.minimumValue || value == slider.maximumValue {
                return value
            }
            initialValue = slider.minimumValue
        case .hueSlider:
            // Hue slider is handled in ParamHueSliderCell, but we need to conform to protocol
            // This case should not be called for ParamSliderCell
            return value
        }
        
        // CRITICAL: Use dragStartValue as reference if available (when user is actively dragging)
        // This ensures we use the value when interaction began, not the last snapped value
        if let dragStart = dragStartValue {
            initialValue = dragStart
        } else if let _ = self.sliderInitialValue {
            initialValue = self.sliderInitialValue!
        }
        
        // Simple direction check: if value moved from reference, snap to nearest step
        if value < initialValue {
            let diff = initialValue - value
            let factor = ceil(diff / step)
            return initialValue - (factor * step)
        } else if value > initialValue {
            let diff = value - initialValue
            let factor = ceil(diff / step)
            return initialValue + (factor * step)
        }
        return initialValue
    }
}

