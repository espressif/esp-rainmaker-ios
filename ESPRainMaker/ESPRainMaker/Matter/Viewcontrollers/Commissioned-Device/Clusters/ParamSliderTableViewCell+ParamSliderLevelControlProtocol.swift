// Copyright 2023 Espressif Systems
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
//  ParamSliderTableViewCell+ParamSliderLevelControlProtocol.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import Foundation
import Matter
import UIKit

@available(iOS 16.4, *)
protocol ParamSliderLevelControlProtocol {
    func setupInitialLevelValues()
    func getLevelController(groupId: String, deviceId: UInt64, controller: MTRDeviceController, completionHandler: @escaping (MTRBaseClusterLevelControl?) -> Void)
    func getMinLevelValue(levelControl: MTRBaseClusterLevelControl, completionHandler: @escaping (NSNumber?, Error?) -> Void)
    func getMaxLevelValue(levelControl: MTRBaseClusterLevelControl, completionHandler: @escaping (NSNumber?, Error?) -> Void)
    func getCurrentLevelValue(levelControl: MTRBaseClusterLevelControl, completionHandler: @escaping (NSNumber?, Error?) -> Void)
    func getCurrentLevelValues(groupId: String, deviceId: UInt64)
    func changeLevel(groupId: String, deviceId: UInt64, toValue _: Float)
}

@available(iOS 16.4, *)
extension ParamSliderTableViewCell: ParamSliderLevelControlProtocol {
    
    /// Setup Offline UI
    func setupOfflineUI() {
        switch sliderParamType {
        case .brightness:
            self.setupInitialLevelValues()
        case .saturation:
            self.setupInitialSaturationValue()
        case .airConditioner:
            self.setupInitialCoolingSetpointValues()
        case .cct:
            self.setupInitialCCTUI()
        }
    }
    
    /// Setup the initial UI for CCT Param
    func setupInitialCCTUI() {
        DispatchQueue.main.async {
            self.backViewTopSpaceConstraint.constant = 10.0
            self.backViewBottomSpaceConstraint.constant = 10.0
            self.minImage.image = nil
            self.maxImage.image = nil
            self.title.text = "CCT"
            self.minLabel.text = "2000"
            self.maxLabel.text = "6536"
            self.slider.minimumValue = 2000.0
            self.slider.maximumValue = 6536.0
            guard let node = self.node, let id = self.deviceId, let levelValue = node.getMatterCCTValue(deviceId: id) else {
                self.setLevelSliderValue(finalValue: 2500.0)
                return
            }
            self.setLevelSliderValue(finalValue: Float(levelValue))
        }
    }
    
    //MARK: Level
    /// Setup initial level values
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
