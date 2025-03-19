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
//  ESPMTROCSSliderTVC.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import Matter
import MBProgressHUD
import UIKit

@available(iOS 16.4, *)
class ESPMTROCSSliderTVC: UITableViewCell {
    static let reuseIdentifier: String = "ESPMTROCSSliderTVC"
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
    
    @IBOutlet weak var backViewTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var backViewBottomSpaceConstraint: NSLayoutConstraint!
    
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
    var currentHueValue: CGFloat = 0
    
    // Properties for handling continuous updates
    let group = DispatchGroup()
    var finalValue:Float = 0.0
    var currentFinalValue:Float = 0.0
    var hueFinalValue: CGFloat = 0.0
    var hueCurrentFinalValue:CGFloat = 0.0
    var currentTimeStamp = Date()
    var hueTimeStamp = Date()
    
    // Matter properties
    var deviceId: UInt64?
    weak var nodeGroup: ESPNodeGroup?
    var isRainmaker: Bool = true
    
    //Matter Level Control
    var minLevel: Int = 0
    var maxLevel: Int = 100
    var currentLevel: Int = 0
    
    //Matter Hue Control
    var minHue: Int = 0
    var maxHue: Int = 100
    weak var paramChipDelegate: ParamCHIPDelegate?
    var sliderParamType: SliderParamType = .brightness
    var isWindowCovering: Bool = false
    var nodeConnectionStatus: NodeConnectionStatus = .local
    var node: ESPNodeDetails?
    
    var thumbLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Disable layout debugging visualization
        slider.layer.shouldRasterize = true
        slider.layer.rasterizationScale = UIScreen.main.scale
        
        // Configure slider thumb to resize based on text
        setSliderThumbUI()
        
        // Additional options if needed:
        slider.layer.masksToBounds = true
        backView.layer.masksToBounds = true
    }
    
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

    func setSliderThumbUI(backgroundColor: UIColor = UIColor(hexString: Constants.customColor)) {
        slider.setThumbImage(nil, for: .normal)

        if thumbLabel == nil {
            thumbLabel = UILabel()
            thumbLabel?.font = UIFont.systemFont(ofSize: 14)
            thumbLabel?.textAlignment = .center
            thumbLabel?.textColor = .white
        }
        
        guard let thumbLabel = thumbLabel else { return }

        thumbLabel.text = String(format: "%.0f", slider.value)

        let padding: CGFloat = 16
        let textSize = thumbLabel.intrinsicContentSize
        let minWidth: CGFloat = 32
        let thumbWidth = max(textSize.width + padding, minWidth)
        let thumbSize = CGSize(width: thumbWidth, height: textSize.height + padding)
        let thumbView = UIView(frame: CGRect(origin: .zero, size: thumbSize))
        thumbView.backgroundColor = backgroundColor
        thumbView.layer.cornerRadius = thumbSize.height / 2
        thumbView.clipsToBounds = true  // Prevents UI overlap

        thumbView.subviews.forEach { $0.removeFromSuperview() }
        thumbLabel.frame = thumbView.bounds
        thumbView.addSubview(thumbLabel)

        let thumbImage = thumbView.asImage()

        slider.setThumbImage(thumbImage, for: .normal)
        
        thumbLabel.isHidden = true
    }

    // IB Actions
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        setSliderThumbUI()
        if let grouoId = nodeGroup?.groupID, let deviceId = deviceId, let val = Int16(sender.value) as? Int16 {
            self.changeOccupiedCoolingSetpoint(setPoint: val)
        }
    }
    
    @IBAction func sliderValueDragged(_ sender: UISlider) {
        setSliderThumbUI()
    }

    @IBAction func hueSliderValueDragged(_: GradientSlider) {}

    @IBAction func hueSliderValueChanged(_: GradientSlider) {}

    @IBAction func checkBoxPressed(_: Any) {}

}

@available(iOS 16.4, *)
extension ESPMTROCSSliderTVC: StepSliderProtocol {
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
    
    //MARK: Occupied cooling/heating setpoint
    /// Setup initial level values
    func setupInitialCoolingSetpointValues(isDeviceOffline: Bool) {
        if let grpId = self.nodeGroup?.groupID, let node = self.node, let id = self.deviceId {
            DispatchQueue.main.async {
                self.title.text = "Temperature(°C)"
                self.minImage.image = nil
                self.maxImage.image = nil
                self.backViewTopSpaceConstraint.constant = 10.0
                self.backViewBottomSpaceConstraint.constant = 10.0
                self.minLabel.text = "16"
                self.maxLabel.text = "32"
                self.slider.minimumValue = 16.0
                self.slider.maximumValue = 32.0
                if let levelValue = node.getMatterOccupiedCoolingSetpoint(deviceId: id) {
                    self.currentLevel = Int(levelValue)
                } else {
                    self.currentLevel = 20
                }
                self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
                if !isDeviceOffline {
                    self.readOCS(groupId: grpId, deviceId: id)
                    self.subscribeToOccupiedCoolingSetpoint()
                }
            }
        }
    }
    
    func setupInitialControllerOCSValues(isDeviceOffline: Bool) {
        self.currentLevel = 20
        DispatchQueue.main.async {
            self.minLabel.text = "16"
            self.maxLabel.text = "32"
            self.slider.minimumValue = 16.0
            self.slider.maximumValue = 32.0
            if let node = self.node, let id = self.deviceId,  let levelValue = node.getMatterOccupiedCoolingSetpoint(deviceId: id) {
                self.currentLevel = Int(levelValue)
            }
            self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
        }
        if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let deviceId = self.deviceId {
            if let ocs = MatterControllerParser.shared.getCurrentOccupiedCoolingSetpoint(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                node.setMatterOccupiedCoolingSetpoint(ocs: Int16(ocs), deviceId: deviceId)
                self.currentLevel = ocs
                self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
            }
        }
    }
    
    func readOCS(groupId: String, deviceId: UInt64) {
        ESPMTRCommissioner.shared.readOccupiedCoolingSetpoint(groupId: groupId, deviceId: deviceId) { value in
            if let value = value {
                self.currentLevel = Int(value)
                self.node?.setMatterOccupiedCoolingSetpoint(ocs: value, deviceId: deviceId)
                self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
            }
        }
    }
    
    /// Subscribe to occupied cooling setpoint
    func subscribeToOccupiedCoolingSetpoint() {
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            ESPMTRCommissioner.shared.subscribeToOccupiedCoolingSetpoint(groupId: grpId, deviceId: id) { value in
                if let mode = self.node?.getMatterSystemMode(deviceId: id) {
                    if mode == ESPMatterConstants.cool {
                        if let value = value {
                            self.currentLevel = Int(value)
                            self.node?.setMatterOccupiedCoolingSetpoint(ocs: value, deviceId: id)
                            self.setOccupiedSetpointSliderValue(finalValue: Float(value))
                        }
                    }
                }
            }
        }
    }
    
    /// Change occupied cooling/heating set point
    /// - Parameter setPoint: cooling/heating set point
    func changeOccupiedCoolingSetpoint(setPoint: Int16) {
        if let id = self.deviceId, let grpId = self.nodeGroup?.groupID, let node = self.node {
            self.paramChipDelegate?.matterAPIRequestSent()
            ESPMTRCommissioner.shared.setOccupiedCoolingSetpoint(groupId: grpId, deviceId: id, ocs: NSNumber(value: setPoint*100)) { result in
                self.paramChipDelegate?.matterAPIResponseReceived()
                if result {
                    if let node = self.node, let id = self.deviceId {
                        node.setMatterOccupiedCoolingSetpoint(ocs: Int16(setPoint), deviceId: id)
                    }
                    self.currentLevel = Int(setPoint)
                    self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
                } else {
                    self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
                }
            }
        }
    }
    
    /// Set setpoint slider final value
    /// - Parameter finalValue: slider final value
    func setOccupiedSetpointSliderValue(finalValue: Float) {
        DispatchQueue.main.async {
            if self.slider.value != finalValue {
                self.slider.setValue(finalValue, animated: true)
                self.setSliderThumbUI()
            }
        }
    }
}
#endif
