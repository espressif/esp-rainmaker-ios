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
//  SliderTableViewCell.swift
//  ESPRainMaker
//

import MBProgressHUD
import UIKit

enum SliderType {
    case slider
    case hueSlider
}

protocol StepSliderProtocol {
    func setupParam(_ param: Param, _ type: SliderType)
    func getSliderFinalValue(_ slider: UISlider?, _ gradientSlider: GradientSlider?, _ type: SliderType) -> Float?
    func getSliderValue(value: Float, step: Float, type: SliderType) -> Float
}

class SliderTableViewCell: UITableViewCell {
    // IB outlets
    @IBOutlet var slider: UISlider!
    @IBOutlet var minLabel: UILabel!
    @IBOutlet var maxLabel: UILabel!
    @IBOutlet var backView: UIView!
    @IBOutlet var title: UILabel!
    @IBOutlet var hueSlider: GradientSlider!
    @IBOutlet var checkButton: UIButton!
    @IBOutlet var leadingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet var trailingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet var minImage: UIImageView!
    @IBOutlet var maxImage: UIImageView!

    // Stored properties
    var device: Device!
    var param: Param!
    var scheduleDelegate: ScheduleActionDelegate?
    var indexPath: IndexPath!
    var paramName: String = ""
    var dataType: String!
    var sliderValue = ""
    var paramDelegate: ParamUpdateProtocol?
    var timer = Timer()
    
    var sliderInitialValue: Float?
    var sliderStepValue: Float?
    
    // Properties for handling continuous updates
    let group = DispatchGroup()
    var finalValue:Float = 0.0
    var currentFinalValue:Float = 0.0
    var hueFinalValue: CGFloat = 0.0
    var hueCurrentFinalValue:CGFloat = 0.0
    var currentTimeStamp = Date()
    var hueTimeStamp = Date()
    

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // IB Actions
    @IBAction func sliderValueChanged(_: UISlider) {}
    
    @IBAction func sliderValueDragged(_ sender: UISlider) {}

    @IBAction func hueSliderValueDragged(_: GradientSlider) {}

    @IBAction func hueSliderValueChanged(_: GradientSlider) {}

    @IBAction func checkBoxPressed(_: Any) {}

}

extension SliderTableViewCell: StepSliderProtocol {
    /// Setup slider min/max and step values
    /// - Parameters:
    ///   - param: device param
    ///   - type: slider type
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
                hueSlider.minimumValue = CGFloat(bounds["min"] as? Int ?? 0)
                hueSlider.maximumValue = CGFloat(bounds["max"] as? Int ?? 360)
            }
            if let step = bounds["step"] as? Float {
                sliderStepValue = step
            }
        }
    }
    
    /// Get final slider value after user stops slider movement
    /// - Parameters:
    ///   - slider: default UISlider instance
    ///   - gradientSlider: gradient slider instance
    ///   - type: slider type
    /// - Returns: final slider value
    func getSliderFinalValue(_ slider: UISlider?, _ gradientSlider: GradientSlider?, _ type: SliderType) -> Float? {
        var sliderValue: Float = 0.0
        var value: Float?
        switch type {
            case .slider:
            if let slider = slider {
                sliderValue = slider.value
            }
            case .hueSlider:
            if let gradientSlider = gradientSlider {
                sliderValue = Float(gradientSlider.value)
            }
        }
        if let step = sliderStepValue, step > 0.0, (type == .slider ? (step < self.slider.maximumValue) : (step < Float(self.hueSlider.maximumValue))) {
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
                    if val > Float(self.hueSlider.maximumValue) {
                        value = Float(self.hueSlider.maximumValue)
                    } else if val < Float(self.hueSlider.minimumValue) {
                        value = Float(self.hueSlider.minimumValue)
                    }
                }
            }
        } else {
            value = sliderValue
        }
        return value
    }
    
    /// Get slider value based on initial, current and step values
    /// - Parameters:
    ///   - value: current value
    ///   - step: step value
    ///   - type: slider type
    /// - Returns: slider value
    func getSliderValue(value: Float, step: Float, type: SliderType) -> Float {
        var initialValue: Float = 0.0
        switch type {
        case .slider:
            if value == slider.minimumValue || value == slider.maximumValue {
                return value
            }
            initialValue = slider.minimumValue
        case .hueSlider:
            if value == Float(hueSlider.minimumValue) || value == Float(hueSlider.maximumValue) {
                return value
            }
            initialValue = Float(hueSlider.minimumValue)
        }
        if let _  = self.sliderInitialValue {
            initialValue = self.sliderInitialValue!
        }
        if value < initialValue {
            let diff = initialValue-value
            let factor = ceil(diff/step)
            return initialValue-(factor*step)
        } else if value > initialValue {
            let diff = value-initialValue
            let factor = ceil(diff/step)
            return initialValue+(factor*step)
        }
        return initialValue
    }
}
