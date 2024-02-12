// Copyright 2024 Espressif Systems
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
//  ParamSliderTableViewCell+ParamSliderSaturationControlProtocol.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import Foundation
import Matter
import UIKit

@available(iOS 16.4, *)
protocol ParamSliderSaturationControlProtocol {
    func setupInitialSaturationValue()
    func getCurrentSaturationValue(groupId: String, deviceId: UInt64)
    func changeSaturation(value: Float)
    func subscribeToSaturationAttribute()
}

@available(iOS 16.4, *)
extension ParamSliderTableViewCell: ParamSliderSaturationControlProtocol {
    
    //MARK: Saturation
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
                                let saturation = Int(val.floatValue*2.54)
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
        self.subscribeToSaturationAttribute()
    }
    
    /// Change saturation
    /// - Parameters:
    ///   - value: value
    ///   - completion: completion
    func changeSaturation(value: Float) {
        if let controller = ESPMTRCommissioner.shared.sController {
            self.getColorCluster(timeout: 10.0) { cluster in
                if let cluster = cluster {
                    var saturation = Int(value*2.54)
                    if saturation == 0 {
                        saturation = 1
                    }
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
                    let finalSaturationValue = Int(CGFloat(saturation)/2.54)
                    if let node = self.node, let id = self.deviceId {
                        node.setMatterSaturationValue(saturation: saturation, deviceId: id)
                    }
                    self.currentLevel = finalSaturationValue
                    self.slider.setValue(Float(self.currentLevel), animated: true)
                }
            }
        }
    }
}
#endif
