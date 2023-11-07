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
    func getLevelController(timeout: Float, groupId: String, deviceId: UInt64, controller: MTRDeviceController, completionHandler: @escaping (MTRBaseClusterLevelControl?) -> Void)
    func getMinLevelValue(levelControl: MTRBaseClusterLevelControl, completionHandler: @escaping (NSNumber?, Error?) -> Void)
    func getMaxLevelValue(levelControl: MTRBaseClusterLevelControl, completionHandler: @escaping (NSNumber?, Error?) -> Void)
    func getCurrentLevelValue(levelControl: MTRBaseClusterLevelControl, completionHandler: @escaping (NSNumber?, Error?) -> Void)
    func getCurrentLevelValues(groupId: String, deviceId: UInt64)
    func setupInitialLevelValues()
    func changeLevel(groupId: String, deviceId: UInt64, toValue _: Float)
}

@available(iOS 16.4, *)
extension ParamSliderTableViewCell: ParamSliderLevelControlProtocol {
    
    /// Setup initial level values
    func setupInitialLevelValues() {
        DispatchQueue.main.async {
            self.title.text = "Brightness"
            self.slider.minimumValue = 0.0
            self.slider.maximumValue = 100.0
            self.minLabel.text = "0"
            self.maxLabel.text = "100"
            self.minImage.image = UIImage(named: "brightness_low")
            self.maxImage.image = UIImage(named: "brightness_high")
            guard let node = self.node, let id = self.deviceId, let levelValue = node.getMatterLevelValue(deviceId: id) as? Int else {
                self.slider.setValue(50.0, animated: true)
                return
            }
            self.slider.setValue(Float(levelValue), animated: true)
        }
    }
    
    /// Subscribe to level attribute
    func subscribeToLevelAttribute() {
        if let grpId = self.nodeGroup?.groupID, let deviceId = self.deviceId {
            ESPMTRCommissioner.shared.subscribeToLevelValue(groupId: grpId, deviceId: deviceId) { level in
                let finalLevelValue = Float(CGFloat(level)/2.55)
                if let node = self.node, let id = self.deviceId {
                    node.setMatterLevelValue(level: level, deviceId: id)
                }
                self.currentLevel = Int(finalLevelValue)
                DispatchQueue.main.async {
                    self.slider.setValue(finalLevelValue, animated: true)
                }
            }
        }
    }
    
    /// Get current level value
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    func getCurrentLevelValues(groupId: String, deviceId: UInt64) {
        self.setupInitialLevelValues()
        if let controller = ESPMTRCommissioner.shared.sController {
            self.getLevelController(timeout: 10.0, groupId: groupId, deviceId: deviceId, controller: controller) { levelControl in
                if let levelControl = levelControl {
                    self.getMinLevelValue(levelControl: levelControl) { min, _ in
                        self.getCurrentLevelValue(levelControl: levelControl) { current, _ in
                            DispatchQueue.main.async {
                                if let current = current {
                                    if let node = self.node, let id = self.deviceId {
                                        node.setMatterLevelValue(level: current.intValue, deviceId: id)
                                    }
                                    self.currentLevel = current.intValue
                                }
                                Utility.hideLoader(view: self)
                                self.slider.setValue(Float(self.currentLevel), animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Setup initial saturation values
    func setupInitialSaturationValue() {
        DispatchQueue.main.async {
            self.title.text = "Saturation"
            self.slider.minimumValue = 0.0
            self.slider.maximumValue = 100.0
            self.minLabel.text = "0"
            self.maxLabel.text = "100"
            if let id = self.deviceId, let node = self.node, let saturationValue = node.getMatterSaturationValue(deviceId: id) {
                self.slider.setValue(Float(saturationValue), animated: true)
            } else {
                self.slider.setValue(50.0, animated: true)
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
        if let _ = ESPMTRCommissioner.shared.sController {
            self.getColorCluster(timeout: 10.0) { cluster in
                if let cluster = cluster {
                    cluster.readAttributeCurrentSaturation { val, _ in
                        if let val = val {
                            DispatchQueue.main.async {
                                let saturation = Int(val.floatValue*2.55)
                                if let node = self.node, let id = self.deviceId {
                                    node.setMatterSaturationValue(saturation: saturation, deviceId: id)
                                }
                                self.currentLevel = saturation
                                self.slider.setValue(Float(self.currentLevel), animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Change saturation
    /// - Parameters:
    ///   - value: value
    ///   - completion: completion
    func changeSaturation(value: Float) {
        if let controller = ESPMTRCommissioner.shared.sController {
            self.getColorCluster(timeout: 10.0) { cluster in
                if let cluster = cluster {
                    let saturation = Int(value*2.55)
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
                        DispatchQueue.main.async {
                            if let node = self.node, let id = self.deviceId {
                                node.setMatterSaturationValue(saturation: saturation, deviceId: id)
                            }
                            self.currentLevel = Int(value)
                            self.slider.setValue(Float(self.currentLevel), animated: true)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.slider.setValue(Float(self.currentLevel), animated: true)
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.slider.setValue(Float(self.currentLevel), animated: true)
            }
        }
    }
    
    /// Subscribe to saturation attribute
    func subscribeToSaturationAttribute() {
        if let grpId = self.nodeGroup?.groupID, let deviceId = self.deviceId {
            ESPMTRCommissioner.shared.subscribeToSaturationValue(groupId: grpId, deviceId: deviceId) { saturation in
                DispatchQueue.main.async {
                    let finalSaturationValue = Int(CGFloat(saturation)/2.55)
                    if let node = self.node, let id = self.deviceId {
                        node.setMatterSaturationValue(saturation: saturation, deviceId: id)
                    }
                    self.currentLevel = finalSaturationValue
                    self.slider.setValue(Float(self.currentLevel), animated: true)
                }
            }
        }
    }
    
    /// Setup Offline UI
    func setupOfflineUI() {
        if self.isSaturation {
            self.setupInitialLevelValues()
        } else {
            self.setupInitialSaturationValue()
        }
    }
    
    /// Get level controller
    /// - Parameters:
    ///   - timeout: time out
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - controller: controller
    ///   - completionHandler: completion handler
    func getLevelController(timeout: Float, groupId: String, deviceId: UInt64, controller: MTRDeviceController, completionHandler: @escaping (MTRBaseClusterLevelControl?) -> Void) {
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
        if let cont = ESPMTRCommissioner.shared.sController {
            self.getLevelController(timeout: 10.0, groupId: groupId, deviceId: deviceId, controller: cont) { controller in
                if let controller = controller {
                    let finalValue = Int(val*2.55)
                    let levelParams = MTRLevelControlClusterMoveToLevelWithOnOffParams()
                    levelParams.level = NSNumber(value: finalValue)
                    controller.moveToLevelWithOnOff(with: levelParams) { error in
                        DispatchQueue.main.async {
                            if let _ = error {
                                self.slider.setValue(Float(self.currentLevel), animated: true)
                            } else {
                                if let node = self.node, let id = self.deviceId {
                                    node.setMatterLevelValue(level: finalValue, deviceId: id)
                                    if let flag = node.isMatterLightOn(deviceId: id), !flag {
                                        node.setMatterLightOnStatus(status: true, deviceId: id)
                                        self.paramChipDelegate?.levelSet()
                                    }
                                }
                                self.currentLevel = finalValue
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.slider.setValue(Float(self.currentLevel), animated: true)
                    }
                }
            }
        }
    }
}
#endif
