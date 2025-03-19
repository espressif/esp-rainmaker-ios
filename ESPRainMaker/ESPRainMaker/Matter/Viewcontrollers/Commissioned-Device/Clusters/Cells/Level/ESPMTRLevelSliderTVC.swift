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
//  ESPMTRLevelSliderTVC.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import MBProgressHUD
import UIKit
import Matter

@available(iOS 16.4, *)
class ESPMTRLevelSliderTVC: UITableViewCell {
    static let reuseIdentifier: String = "ESPMTRLevelSliderTVC"
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
        if let grouoId = nodeGroup?.groupID, let deviceId = deviceId {
            let val = sender.value
            self.changeLevel(groupId: grouoId, deviceId: deviceId, toValue: val)
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
extension ESPMTRLevelSliderTVC: StepSliderProtocol {
    
    /// Subscribe to level attribute
    func subscribeToLevelAttribute() {
        if let grpId = self.nodeGroup?.groupID, let deviceId = self.deviceId {
            ESPMTRCommissioner.shared.subscribeToLevelValue(groupId: grpId, deviceId: deviceId) { level in
                let finalLevelValue = Float(CGFloat(level)/2.54)
                if let node = self.node, let id = self.deviceId {
                    node.setMatterLevelValue(level: level, deviceId: id)
                }
                self.currentLevel = Int(finalLevelValue)
                self.setLevelSliderValue(finalValue: finalLevelValue)
            }
        }
    }
    
    /// Change level
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - val: value
    func changeLevel(groupId: String, deviceId: UInt64, toValue val: Float) {
        let finalValue = Int(val*2.54)
        if nodeConnectionStatus == .local {
            if let cont = ESPMTRCommissioner.shared.sController {
                self.getLevelController(groupId: groupId, deviceId: deviceId, controller: cont) { controller in
                    if let controller = controller {
                        let levelParams = MTRLevelControlClusterMoveToLevelWithOnOffParams()
                        levelParams.level = NSNumber(value: finalValue)
                        controller.moveToLevelWithOnOff(with: levelParams) { error in
                            DispatchQueue.main.async {
                                if let _ = error {
                                    self.setLevelSliderValue(finalValue: Float(self.currentLevel))
                                } else {
                                    if let node = self.node, let id = self.deviceId {
                                        node.setMatterLevelValue(level: finalValue, deviceId: id)
                                        if let flag = node.isMatterLightOn(deviceId: id), !flag {
                                            node.setMatterLightOnStatus(status: true, deviceId: id)
                                            self.paramChipDelegate?.levelSet()
                                        }
                                    }
                                    self.currentLevel = Int(val)
                                }
                            }
                        }
                    } else {
                        self.setLevelSliderValue(finalValue: Float(self.currentLevel))
                    }
                }
            }
        } else if nodeConnectionStatus == .controller {
            if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let matterDeviceId = matterNodeId.hexToDecimal {
                var endpoint = "0x1"
                if let endpointId = MatterControllerParser.shared.getBrightnessLevelEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                    endpoint = endpointId
                }
                ESPControllerAPIManager.shared.callBrightnessAPI(rainmakerNode: rainmakerNode,
                                                                 controllerNodeId: controllerNodeId,
                                                                 matterNodeId: matterNodeId,
                                                                 endpoint: endpoint,
                                                                 brightnessLevel: "\(finalValue)") { result in
                    if result {
                        node.setMatterLevelValue(level: finalValue, deviceId: matterDeviceId)
                        self.currentLevel = Int(val)
                        node.setMatterLightOnStatus(status: true, deviceId: matterDeviceId)
                        self.paramChipDelegate?.levelSet()
                    } else {
                        self.setLevelSliderValue(finalValue: Float(self.currentLevel))
                    }
                }
            }
        }
    }
    
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
    
    func setupInitialLevelValues() {
        DispatchQueue.main.async {
            self.backViewTopSpaceConstraint.constant = 10.0
            self.backViewBottomSpaceConstraint.constant = 10.0
            self.title.text = "Brightness"
            self.slider.minimumValue = 0.0
            self.slider.maximumValue = 100.0
            self.minLabel.text = "0"
            self.maxLabel.text = "100"
            self.minImage.image = UIImage(named: "brightness_low")
            self.maxImage.image = UIImage(named: "brightness_high")
            guard let node = self.node, let id = self.deviceId, let levelValue = node.getMatterLevelValue(deviceId: id) else {
                self.setLevelSliderValue(finalValue: 50.0)
                return
            }
            let final = Float(levelValue)/2.54
            self.setLevelSliderValue(finalValue: Float(final))
        }
    }
    
    /// Get current level value
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    func getCurrentLevelValues(groupId: String, deviceId: UInt64) {
        self.setupInitialLevelValues()
        if self.nodeConnectionStatus == .local {
            if let controller = ESPMTRCommissioner.shared.sController {
                self.getLevelController(groupId: groupId, deviceId: deviceId, controller: controller) { levelControl in
                    if let levelControl = levelControl {
                        self.getMinLevelValue(levelControl: levelControl) { min, _ in
                            self.getCurrentLevelValue(levelControl: levelControl) { current, _ in
                                DispatchQueue.main.async {
                                    if let current = current {
                                        if let node = self.node, let id = self.deviceId {
                                            node.setMatterLevelValue(level: current.intValue, deviceId: id)
                                        }
                                        self.currentLevel = Int(current.floatValue/2.54)
                                    }
                                    Utility.hideLoader(view: self)
                                    self.setLevelSliderValue(finalValue: Float(self.currentLevel))
                                }
                            }
                        }
                    }
                }
            }
            self.subscribeToLevelAttribute()
        } else if self.nodeConnectionStatus == .controller {
            if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let matterDeviceId = matterNodeId.hexToDecimal {
                if let currentLevel = MatterControllerParser.shared.getBrightnessLevel(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                    let finalValue = Float(currentLevel)/2.54
                    self.currentLevel = Int(finalValue)
                    node.setMatterLevelValue(level: currentLevel, deviceId: matterDeviceId)
                    self.setLevelSliderValue(finalValue: Float(self.currentLevel))
                }
            }
        }
    }
    
    /// Get level controller
    /// - Parameters:
    ///   - timeout: time out
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - controller: controller
    ///   - completionHandler: completion handler
    func getLevelController(groupId: String, deviceId: UInt64, controller: MTRDeviceController, completionHandler: @escaping (MTRBaseClusterLevelControl?) -> Void) {
        let (_, endpoint) = ESPMatterClusterUtil.shared.isLevelControlServerSupported(groupId: groupId, deviceId: deviceId)
        if let endpoint = endpoint, let point = UInt16(endpoint) {
            controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let levelControl = MTRBaseClusterLevelControl(device: device, endpoint: point, queue: ESPMTRCommissioner.shared.matterQueue) {
                    completionHandler(levelControl)
                } else {
                    completionHandler(nil)
                }
            }
        }
    }
    
    /// Get minimum level value
    /// - Parameters:
    ///   - levelControl: level control
    ///   - completionHandler: completion handler
    func getMinLevelValue(levelControl: MTRBaseClusterLevelControl, completionHandler: @escaping (NSNumber?, Error?) -> Void) {
        levelControl.readAttributeMinLevel() { min, error in
            completionHandler(min, error)
        }
    }
    
    /// Get mac level value
    /// - Parameters:
    ///   - levelControl: level control
    ///   - completionHandler: completion
    func getMaxLevelValue(levelControl: MTRBaseClusterLevelControl, completionHandler: @escaping (NSNumber?, Error?) -> Void) {
        levelControl.readAttributeMaxLevel() { min, error in
            completionHandler(min, error)
        }
    }
    
    /// get current level
    /// - Parameters:
    ///   - levelControl: level control
    ///   - completionHandler: completion
    func getCurrentLevelValue(levelControl: MTRBaseClusterLevelControl, completionHandler: @escaping (NSNumber?, Error?) -> Void) {
        levelControl.readAttributeCurrentLevel() { min, error in
            completionHandler(min, error)
        }
    }
    
    /// Set level slider final value
    /// - Parameter finalValue: slider finalk value
    func setLevelSliderValue(finalValue: Float) {
        DispatchQueue.main.async {
            if self.slider.value != finalValue {
                self.slider.setValue(finalValue, animated: true)
                self.setSliderThumbUI()
            }
        }
    }
}
#endif
