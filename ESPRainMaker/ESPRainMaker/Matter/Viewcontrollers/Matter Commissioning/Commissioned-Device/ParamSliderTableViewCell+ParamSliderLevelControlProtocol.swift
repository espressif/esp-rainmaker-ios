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
    
    func setupInitialLevelValues() {
        DispatchQueue.main.async {
            self.title.text = "Brightness"
            self.slider.minimumValue = 0.0
            self.slider.maximumValue = 254.0
            self.minLabel.text = "0"
            self.maxLabel.text = "254"
            self.slider.setValue(50.0, animated: true)
        }
    }
    
    func getCurrentLevelValues(groupId: String, deviceId: UInt64) {
        self.setupInitialLevelValues()
        if let controller = ESPMTRCommissioner.shared.sController {
            self.getLevelController(timeout: 10.0, groupId: groupId, deviceId: deviceId, controller: controller) { levelControl in
                if let levelControl = levelControl {
                    self.getMinLevelValue(levelControl: levelControl) { min, _ in
                        DispatchQueue.main.async {
                            if let min = min {
                                self.minLevel = min.intValue
                                self.minLabel.text = "\(min.intValue)"
                            }
                        }
                        self.getMaxLevelValue(levelControl: levelControl) { max, _ in
                            DispatchQueue.main.async {
                                if let max = max {
                                    self.maxLevel = max.intValue
                                }
                            }
                            self.getCurrentLevelValue(levelControl: levelControl) { current, _ in
                                DispatchQueue.main.async {
                                    if let current = current {
                                        self.currentLevel = current.intValue
                                    }
                                    Utility.hideLoader(view: self)
                                    self.slider.minimumValue = Float(self.minLevel)
                                    self.slider.maximumValue = Float(self.maxLevel)
                                    self.slider.value = Float(self.currentLevel)
                                }
                            }
                        }
                    }
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
                    let levelParams = MTRLevelControlClusterMoveToLevelParams()
                    levelParams.level = NSNumber(value: UInt(val))
                    controller.moveToLevel(with: levelParams) { error in
                        DispatchQueue.main.async {
                            if let _ = error {
                                self.slider.value = Float(self.currentLevel)
                            } else {
                                self.currentLevel = Int(self.slider.value)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.slider.value = Float(self.currentLevel)
                    }
                }
            }
        }
    }
}
#endif
