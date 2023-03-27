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
//  ParamSlider.swift
//  ESPRainMaker
//

import UIKit

class ParamSliderTableViewCell: SliderTableViewCell {
    
    
    override func layoutSubviews() {
        // Customise slider element for param screen
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

    @IBAction override func sliderValueDragged(_ sender: UISlider) {
        // Skip param update if app does not support continuous updates
        if !Configuration.shared.appConfiguration.supportContinuousUpdate {
            return
        }
        // Check time elapsed since last slider update
        if currentTimeStamp.milliSeconds(from: Date()) > Configuration.shared.appConfiguration.continuousUpdateInterval {
            // Update timestamp
            currentTimeStamp = Date()
            // Check for slider final value in case of step slider
            guard let value = getSliderFinalValue(sender, nil, .slider) else {
                return
            }
            // Add request in queue
            group.enter()
            var val: Float = 0.0
            if dataType.lowercased() == "int" {
                sliderValue = paramName + ": \(Int(value))"
                DeviceControlHelper.shared.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: Int(value)]], delegate: paramDelegate) { _ in
                    // Leave group after request is processed
                    self.group.leave()
                }
                param.value = Int(value)
                val = Float(Int(value))
            } else {
                sliderValue = paramName + ": \(value)"
                DeviceControlHelper.shared.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: value]], delegate: paramDelegate) { _ in
                    // Leave group after request is processed
                    self.group.leave()
                }
                param.value = value
                val = value
            }
            sliderInitialValue = val
            sender.setValue(val, animated: true)
            group.notify(queue: .main) {
                // Check if final value is already updated
                if self.finalValue == self.currentFinalValue {
                    return
                }
                self.currentFinalValue = self.finalValue
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        var val: Float = 0.0
                        if self.dataType.lowercased() == "int" {
                            self.sliderValue = self.paramName + ": \(Int(self.finalValue))"
                            DeviceControlHelper.shared.updateParam(nodeID: self.device.node?.node_id, parameter: [self.device.name ?? "": [self.paramName: Int(self.finalValue)]], delegate: self.paramDelegate)
                            self.param.value = Int(self.finalValue)
                            val = Float(Int(self.finalValue))
                        } else {
                            self.sliderValue = self.paramName + ": \(self.finalValue)"
                            DeviceControlHelper.shared.updateParam(nodeID: self.device.node?.node_id, parameter: [self.device.name ?? "": [self.paramName: self.finalValue]], delegate: self.paramDelegate)
                            self.param.value = self.finalValue
                            val = self.finalValue
                        }
                        self.sliderInitialValue = val
                        sender.setValue(val, animated: true)
                    }
            }
        }
    }
    
    @IBAction override func sliderValueChanged(_ sender: UISlider) {
        guard let value = getSliderFinalValue(sender, nil, .slider) else {
            return
        }
        self.finalValue = value
        if !Configuration.shared.appConfiguration.supportContinuousUpdate {
            // Update param if continuous update is disabled
            updateSliderParam(sender: sender)
            return
        }
        if self.currentFinalValue == self.finalValue {
            return
        }
        self.currentFinalValue = self.finalValue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateSliderParam(sender: sender)
        }
    }

    @IBAction override func hueSliderValueDragged(_ sender: GradientSlider) {
        hueSlider.thumbColor = UIColor(hue: CGFloat(sender.value / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        // Skip param update if app does not support continuous updates
        if !Configuration.shared.appConfiguration.supportContinuousUpdate {
            return
        }
        // Check time elapsed since last slider update
        if currentTimeStamp.milliSeconds(from: Date()) > Configuration.shared.appConfiguration.continuousUpdateInterval {
            currentTimeStamp = Date()
            // Check for slider final value in case of step slider
            guard let value = getSliderFinalValue(nil, sender, .hueSlider) else {
                return
            }
            group.enter()
            hueSlider.thumbColor = UIColor(hue: CGFloat(value / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
            DeviceControlHelper.shared.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: Int(value)]], delegate: paramDelegate) { _ in
                // Leave group after request is processed
                self.group.leave()
            }
            param.value = Int(value)
            sliderInitialValue = Float(Int(value))
            sender.setValue(CGFloat(value))
            group.notify(queue: .main) {
                if self.hueFinalValue == self.hueCurrentFinalValue {
                    return
                }
                self.hueCurrentFinalValue = self.hueFinalValue
                self.updateHueSliderParam(sender: sender)
            }
        }
    }
    
    @IBAction override func hueSliderValueChanged(_ sender: GradientSlider) {
        guard let value = getSliderFinalValue(nil, sender, .hueSlider) else {
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
        self.hueCurrentFinalValue = self.hueFinalValue
        updateHueSliderParam(sender: sender)
    }
    
    
    /// Call update param API with final value.
    /// - Parameter sender: Slider object.
    private func updateSliderParam(sender: UISlider) {
        var val: Float = 0.0
        if self.dataType.lowercased() == "int" {
            self.sliderValue = self.paramName + ": \(Int(self.finalValue))"
            DeviceControlHelper.shared.updateParam(nodeID: self.device.node?.node_id, parameter: [self.device.name ?? "": [self.paramName: Int(self.finalValue)]], delegate: self.paramDelegate)
            self.param.value = Int(self.finalValue)
            val = Float(Int(self.finalValue))
        } else {
            self.sliderValue = self.paramName + ": \(self.finalValue)"
            DeviceControlHelper.shared.updateParam(nodeID: self.device.node?.node_id, parameter: [self.device.name ?? "": [self.paramName: self.finalValue]], delegate: self.paramDelegate)
            self.param.value = self.finalValue
            val = self.finalValue
        }
        self.sliderInitialValue = val
        sender.setValue(val, animated: true)
    }
    
    
    /// Call update param API with final value.
    /// - Parameter sender: Gradient slider object
    private func updateHueSliderParam(sender: GradientSlider) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.hueSlider.thumbColor = UIColor(hue: CGFloat(self.hueFinalValue / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
            DeviceControlHelper.shared.updateParam(nodeID: self.device.node?.node_id, parameter: [self.device.name ?? "": [self.paramName: Int(self.hueFinalValue)]], delegate: self.paramDelegate)
            self.param.value = Int(self.hueFinalValue)
            self.sliderInitialValue = Float(Int(self.hueFinalValue))
            sender.setValue(CGFloat(self.hueFinalValue))
        }
    }
}

