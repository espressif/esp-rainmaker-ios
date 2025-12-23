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
//  ParamHueSliderCell+Updates.swift
//  ESPRainMaker
//
//  Component: Continuous Update Throttling Logic
//  Handles: Hue slider drag updates, value change handling, step slider logic

import UIKit

extension ParamHueSliderCell {
    
    // MARK: - Hue Slider Actions
    @objc func hueSliderValueDragged(_ sender: GradientSlider) {
        // CRITICAL: Mark that user is actively dragging
        isUserDragging = true
        dragEndTimestamp = nil
        shouldIgnorePendingUpdates = false // Reset flag when user starts dragging again
        
        // Update thumb color immediately (matches original implementation)
        hueSlider.thumbColor = UIColor(hue: CGFloat(sender.value / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        
        // Skip param update if app does not support continuous updates
        if !Configuration.shared.appConfiguration.supportContinuousUpdate || !isRainmaker {
            return
        }
        
        // Check time elapsed since last slider update
        if currentTimeStamp.milliSeconds(from: Date()) > Configuration.shared.appConfiguration.continuousUpdateInterval {
            currentTimeStamp = Date()
            
            // Check for slider final value in case of step slider
            guard let value = getHueSliderFinalValue(sender) else {
                return
            }
            
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
            
            group.enter()
            hueSlider.thumbColor = UIColor(hue: CGFloat(value / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
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
            sliderInitialValue = Float(intValue)
            sender.setValue(CGFloat(intValue))
            
            // NOTE: We intentionally do NOT schedule a delayed final update here.
            // The throttling logic above already ensures we send updates at a controlled rate,
            // and the final value will be sent when user releases the slider (touchUp).
        }
    }
    
    @objc func hueSliderValueChanged(_ sender: GradientSlider) {
        // CRITICAL: Mark that user has finished dragging (touch ended)
        // Set timestamp for notification update cooldown
        if isUserDragging {
            isUserDragging = false
            dragEndTimestamp = Date()
        }
        
        // CRITICAL: Matter updates are handled in hueSliderTouchUp (only fires when user interaction ends)
        // hueSliderValueChanged fires for both user and programmatic updates, so we don't use it for Matter
        if isRainmaker {
            guard let value = getHueSliderFinalValue(sender) else {
                return
            }
            self.hueFinalValue = CGFloat(value)
            // Update param if continuous update is disabled
            if !Configuration.shared.appConfiguration.supportContinuousUpdate {
                updateHueSliderParam(sender: sender)
                return
            }
            if self.hueCurrentFinalValue == self.hueFinalValue {
                return
            }
            // For continuous updates, we don't send a delayed final update here
            // Updates are sent during drag (throttled), and final value is sent on touchUp
            // This prevents queued updates after user releases the slider
        }
    }
    
    // MARK: - Touch Up Callback (only fires when user interaction ends)
    @objc func hueSliderTouchUp(_ sender: GradientSlider) {
        // Cancel any pending delayed update work item
        pendingDelayedUpdateWorkItem?.cancel()
        pendingDelayedUpdateWorkItem = nil
        
        // Mark that user interaction has ended
        isUserDragging = false
        dragEndTimestamp = Date()
        
        // For Rainmaker with continuous updates, wait for slider to settle then send final value
        if isRainmaker && Configuration.shared.appConfiguration.supportContinuousUpdate {
            shouldIgnorePendingUpdates = true
            
            // Capture references for delayed callback
            guard let capturedParam = param,
                  let capturedParamName = capturedParam.name,
                  let capturedDevice = device else {
                return
            }
            
            // Wait for slider to settle (after any bounce/elasticity) before sending final value
            // This ensures we send the actual final position, not where user released
            pendingDelayedUpdateWorkItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                
                // Verify cell still shows the same param (cell reuse protection)
                guard self.isSameParam(capturedParam: capturedParam, capturedParamName: capturedParamName) else {
                    return
                }
                
                // Get the actual settled slider value (after any animation/bounce)
                guard let finalValue = self.getHueSliderFinalValue(sender) else {
                    return
                }
                
                // Send final value update with the settled position
                let intValue = Int(finalValue)
                DeviceControlHelper.shared.updateParam(nodeID: capturedDevice.node?.node_id, parameter: [capturedDevice.name ?? "": [capturedParamName: intValue]], delegate: self.paramDelegate) { result in
                }
                capturedParam.value = intValue
                self.sliderInitialValue = Float(intValue)
                sender.setValue(CGFloat(intValue))
                self.hueSlider.thumbColor = UIColor(hue: CGFloat(finalValue / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
            }
            
            // Schedule the delayed check after slider settles (0.15 seconds should be enough for any bounce)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: pendingDelayedUpdateWorkItem!)
            return
        }
        
        // This is called ONLY when user lifts finger (touchUpInside or touchUpOutside)
        // CRITICAL: This is the perfect place for Matter API calls - it never fires for programmatic updates
        if #available(iOS 16.4, *) {
            #if ESPRainMakerMatter
            guard !isRainmaker else {
                return
            }
            
            let hueValue = sender.value
            // Match original Matter hue slider structure - call changeHue directly
            // No debouncing needed - touchUp only fires once when user lifts finger
            self.changeHue(toValue: hueValue)
            #endif
        }
    }
    
    // MARK: - Parameter Update Router
    func updateParam(value: Int, isContinuous: Bool, capturedParam: Param? = nil, capturedParamName: String? = nil, capturedDevice: Device? = nil, skipOptimisticUpdate: Bool = false, completion: ((Bool) -> Void)? = nil) {
        if isRainmaker {
            updateParamRM(value: value, isContinuous: isContinuous, capturedParam: capturedParam, capturedParamName: capturedParamName, capturedDevice: capturedDevice, skipOptimisticUpdate: skipOptimisticUpdate, completion: completion)
        } else {
            #if ESPRainMakerMatter
            if #available(iOS 16.4, *) {
            // Matter update handled in ParamHueSliderCell+Matter.swift
            updateParamMatter(value: value, isContinuous: isContinuous)
            completion?(true) // Matter updates don't have completion, assume success
            }
            #endif
        }
    }
    
    // MARK: - Helper method for updating hue slider param (matches original implementation)
    // NOTE: This method is kept for non-continuous updates, but for continuous updates,
    // the final value is sent directly in hueSliderTouchUp to avoid queued updates.
    func updateHueSliderParam(sender: GradientSlider) {
        guard let param = self.param,
              let paramName = param.name,
              let device = self.device,
              self.isSameParam(capturedParam: param, capturedParamName: paramName) else {
            return
        }
        self.hueSlider.thumbColor = UIColor(hue: CGFloat(self.hueFinalValue / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        DeviceControlHelper.shared.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: Int(self.hueFinalValue)]], delegate: self.paramDelegate)
        param.value = Int(self.hueFinalValue)
        self.sliderInitialValue = Float(Int(self.hueFinalValue))
        sender.setValue(CGFloat(self.hueFinalValue))
    }
    
    // MARK: - Helper Methods
    func getHueSliderFinalValue(_ slider: GradientSlider) -> Float? {
        let sliderValue = Float(slider.value)
        
        // Handle step sliders
        if let step = sliderStepValue, step > 0.0, step < Float(slider.maximumValue) {
            if let initialValue = sliderInitialValue, sliderValue == initialValue {
                return nil
            }
            
            var value = getHueSliderValue(value: sliderValue, step: step)
            
            // Clamp to bounds
            if value > Float(slider.maximumValue) {
                value = Float(slider.maximumValue)
            } else if value < Float(slider.minimumValue) {
                value = Float(slider.minimumValue)
            }
            
            return value
        }
        
        return sliderValue
    }
    
    func getHueSliderValue(value: Float, step: Float) -> Float {
        if value == Float(hueSlider.minimumValue) || value == Float(hueSlider.maximumValue) {
            return value
        }
        
        let initialValue = sliderInitialValue ?? Float(hueSlider.minimumValue)
        
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

