// Copyright 2021 Espressif Systems
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
//  HueSliderTableViewCell.swift
//  ESPRainMaker
//

import FlexColorPicker
import UIKit

class RoundHueSliderTableViewCell: UITableViewCell {
    @IBOutlet var hueSlider: RadialHueControl!
    @IBOutlet var backView: UIView!
    @IBOutlet var selectedColor: ColorPreviewWithHex!

    var param: Param!
    var device: Device!
    var paramDelegate: ParamUpdateProtocol?
    var hueInitialValue: CGFloat?
    // Properties for handling continuous updates
    let group = DispatchGroup()
    var finalValue:CGFloat = 0.0
    var currentFinalValue:CGFloat = 0.0
    var currentTimeStamp = Date()

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
        hueSlider.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    @IBAction func valueChanged(_ sender: RadialHueControl) {
        selectedColor.setSelectedHSBColor(sender.selectedHSBColor.withSaturation(1.0), isInteractive: true)
    }
    
    
    /// Call update param API with value.
    /// - Parameter value: value of param
    private func updateSliderParam(value: CGFloat) {
        DeviceControlHelper.shared.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [param.name ?? "": Int(value)]], delegate: paramDelegate)
        param.value = Int(value)
    }
}

extension RoundHueSliderTableViewCell: RadialHueControlDelegate {
    
    /// Callback to get final selected color
    /// - Parameter value: final value of Hue
    func finalSelectedColor(value: CGFloat) {
        finalValue = value
        // Update param if continuous update is disabled
        if !Configuration.shared.appConfiguration.supportContinuousUpdate {
            updateSliderParam(value: value)
            return
        }
        if self.currentFinalValue == self.finalValue {
            return
        }
        self.currentFinalValue = self.finalValue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateSliderParam(value: value)
        }
    }
    
    /// Callback that recieves value for currently selected color
    /// - Parameter value: current value of Hue
    func selectedColor(value: CGFloat) {
        // Skip param update if app does not support continuous updates
        if !Configuration.shared.appConfiguration.supportContinuousUpdate {
            return
        }
        // Check time elapsed since last value update
        if currentTimeStamp.milliSeconds(from: Date()) > Configuration.shared.appConfiguration.continuousUpdateInterval {
            currentTimeStamp = Date()
            group.enter()
            var val: CGFloat = 0.0
            DeviceControlHelper.shared.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [param.name ?? "": Int(value)]], delegate: paramDelegate) { _ in
                // Leave group after request is processed
                self.group.leave()
            }
            param.value = Int(value)
            val = value
            hueInitialValue = val
            group.notify(queue: .main) {
                if self.finalValue == self.currentFinalValue {
                    return
                }
                self.currentFinalValue = self.finalValue
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    var val: CGFloat = 0.0
                    self.param.value = Int(self.finalValue)
                    DeviceControlHelper.shared.updateParam(nodeID: self.device.node?.node_id, parameter: [self.device.name ?? "": [self.param.name ?? "": Int(self.finalValue)]], delegate: self.paramDelegate)
                        self.param.value = self.finalValue
                        val = self.finalValue
                        self.hueInitialValue = val
                }
            }
        }
        
    }
}
