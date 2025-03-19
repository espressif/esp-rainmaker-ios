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
//  ESPMTRSaturationSliderTVC.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import MBProgressHUD
import UIKit
import Matter

@available(iOS 16.4, *)
class ESPMTRSaturationSliderTVC: UITableViewCell {
    static let reuseIdentifier: String = "ESPMTRSaturationSliderTVC"
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
            self.changeSaturation(value: val)
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
extension ESPMTRSaturationSliderTVC: StepSliderProtocol {
    
    /// Get color cluster
    /// - Parameters:
    ///   - completionHandler: completion
    func getColorCluster(completionHandler: @escaping (MTRBaseClusterColorControl?) -> Void) {
        if let group = nodeGroup, let groupId = group.groupID, let id = deviceId, let controller = ESPMTRCommissioner.shared.sController {
            let (_, endpoint) = ESPMatterClusterUtil.shared.isColorControlServerSupported(groupId: groupId, deviceId: id)
            controller.getBaseDevice(id, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let endpoint = endpoint, let point = UInt16(endpoint), let colorControlCluster = MTRBaseClusterColorControl(device: device, endpoint: UInt16(truncating: NSNumber(value: point)), queue: ESPMTRCommissioner.shared.matterQueue) {
                    completionHandler(colorControlCluster)
                } else {
                    completionHandler(nil)
                }
            }
        } else {
            completionHandler(nil)
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
    
    //MARK: Saturation
    /// Setup initial saturation values
    func setupInitialSaturationValue() {
        DispatchQueue.main.async {
            self.backViewTopSpaceConstraint.constant = 10.0
            self.backViewBottomSpaceConstraint.constant = 10.0
            self.title.text = "Saturation"
            self.slider.minimumValue = 0.0
            self.slider.maximumValue = 100.0
            self.minLabel.text = "0"
            self.maxLabel.text = "100"
            if let id = self.deviceId, let node = self.node, let saturationValue = node.getMatterSaturationValue(deviceId: id) {
                self.setSaturationSliderValue(finalValue: Float(saturationValue))
            } else {
                self.setSaturationSliderValue(finalValue: 50.0)
            }
        }
        self.minImage.image = UIImage(named: "saturation_low")
        self.maxImage.image = UIImage(named: "saturation_high")
    }
    
    /// Get current level value
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    func getCurrentSaturationValue(groupId: String, deviceId: UInt64) {
        self.setupInitialSaturationValue()
        if self.nodeConnectionStatus == .local {
            if let _ = ESPMTRCommissioner.shared.sController {
                self.getColorCluster() { cluster in
                    if let cluster = cluster {
                        cluster.readAttributeCurrentSaturation { val, _ in
                            if let val = val {
                                DispatchQueue.main.async {
                                    let saturation = Int(val.floatValue*2.54)
                                    if let node = self.node, let id = self.deviceId {
                                        node.setMatterSaturationValue(saturation: saturation, deviceId: id)
                                    }
                                    self.currentLevel = saturation
                                    self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                                }
                            }
                        }
                    }
                }
            }
            self.subscribeToSaturationAttribute()
        } else if self.nodeConnectionStatus == .controller {
            if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let matterDeviceId = matterNodeId.hexToDecimal {
                if let currentSaturation = MatterControllerParser.shared.getCurrentSaturation(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                    self.currentLevel = Int(Float(currentSaturation)/2.54)
                    node.setMatterSaturationValue(saturation: currentSaturation, deviceId: matterDeviceId)
                    self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                }
            }
        }
    }

    /// Change saturation
    /// - Parameters:
    ///   - value: value
    ///   - completion: completion
    func changeSaturation(value: Float) {
        var saturation = Int(value*2.54)
        if saturation == 0 {
            saturation = 1
        }
        if self.nodeConnectionStatus == .local {
            if let _ = ESPMTRCommissioner.shared.sController {
                self.getColorCluster() { cluster in
                    if let cluster = cluster {
                        let params = MTRColorControlClusterMoveToSaturationParams()
                        params.saturation = NSNumber(value: saturation)
                        params.transitionTime = NSNumber(value: 0)
                        params.optionsMask = NSNumber(value: 0)
                        params.optionsOverride = NSNumber(value: 0)
                        cluster.moveToSaturation(with: params) { error in
                            if let _ = error {
                                DispatchQueue.main.async {
                                    self.slider.value = Float(self.currentLevel)
                                }
                                return
                            }
                            if let node = self.node, let id = self.deviceId {
                                node.setMatterSaturationValue(saturation: saturation, deviceId: id)
                            }
                            self.currentLevel = Int(value)
                            self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                        }
                    } else {
                        self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                    }
                }
            } else {
                self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
            }
        } else if self.nodeConnectionStatus == .controller {
            if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let matterDeviceId = matterNodeId.hexToDecimal {
                var endpoint = "0x1"
                if let endpointId = MatterControllerParser.shared.getSaturationLevelEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                    endpoint = endpointId
                }
                ESPControllerAPIManager.shared.callSaturationAPI(rainmakerNode: rainmakerNode,
                                                                 controllerNodeId: controllerNodeId,
                                                                 matterNodeId: matterNodeId,
                                                                 endpoint: endpoint,
                                                                 saturationLevel: "\(saturation)") { result in
                    if result {
                        if let node = self.node, let id = self.deviceId {
                            node.setMatterSaturationValue(saturation: saturation, deviceId: id)
                        }
                        self.currentLevel = Int(value)
                    } else {
                        self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                    }
                }
            }
        }
    }
    
    /// Subscribe to saturation attribute
    func subscribeToSaturationAttribute() {
        if let grpId = self.nodeGroup?.groupID, let deviceId = self.deviceId {
            ESPMTRCommissioner.shared.subscribeToSaturationValue(groupId: grpId, deviceId: deviceId) { saturation in
                DispatchQueue.main.async {
                    let finalSaturationValue = Int(CGFloat(saturation)/2.54)
                    if let node = self.node, let id = self.deviceId {
                        node.setMatterSaturationValue(saturation: saturation, deviceId: id)
                    }
                    self.currentLevel = finalSaturationValue
                    self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                }
            }
        }
    }
    
    /// Set saturation slider final value
    /// - Parameter finalValue: slider final value
    func setSaturationSliderValue(finalValue: Float) {
        if self.slider.value != finalValue {
            DispatchQueue.main.async {
                self.slider.setValue(finalValue, animated: true)
                self.setSliderThumbUI()
            }
        }
    }
}
#endif
