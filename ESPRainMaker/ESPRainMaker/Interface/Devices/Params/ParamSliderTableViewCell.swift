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

    @IBAction override func sliderValueChanged(_ sender: UISlider) {
        guard let value = getSliderFinalValue(sender, nil, .slider) else {
            return
        }
        var val: Float = 0.0
        if dataType.lowercased() == "int" {
            sliderValue = paramName + ": \(Int(value))"
            DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: Int(value)]], delegate: paramDelegate)
            param.value = Int(value)
            val = Float(Int(value))
        } else {
            sliderValue = paramName + ": \(value)"
            DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: value]], delegate: paramDelegate)
            param.value = value
            val = value
        }
        sliderInitialValue = val
        sender.setValue(val, animated: true)
    }

    @IBAction override func hueSliderValueDragged(_ sender: GradientSlider) {
        hueSlider.thumbColor = UIColor(hue: CGFloat(sender.value / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }

    @IBAction override func hueSliderValueChanged(_ sender: GradientSlider) {
        guard let value = getSliderFinalValue(nil, sender, .hueSlider) else {
            return
        }
        hueSlider.thumbColor = UIColor(hue: CGFloat(value / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        DeviceControlHelper.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: Int(value)]], delegate: paramDelegate)
        param.value = Int(value)
        sliderInitialValue = Float(Int(value))
        sender.setValue(CGFloat(value))
    }
}
