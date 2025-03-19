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
    
    /// Get current level value
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    func getCurrentCCTValue(groupId: String, deviceId: UInt64) {
        self.setupInitialCCTUI()
        if self.nodeConnectionStatus == .local {
            if let _ = ESPMTRCommissioner.shared.sController {
                self.getColorCluster() { cluster in
                    if let cluster = cluster {
                        cluster.readAttributeColorTemperatureMireds { val, _ in
                            if let val = val {
                                DispatchQueue.main.async {
                                    let cct = Int(val.intValue)
                                    if let node = self.node, let id = self.deviceId {
                                        node.setMatterCCTValue(cct: cct, deviceId: id)
                                    }
                                    self.currentLevel = cct
                                    self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                                }
                            }
                        }
                    }
                }
            }
            self.subscribeToCCTAttribute()
        } else if self.nodeConnectionStatus == .controller {
            if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let matterDeviceId = matterNodeId.hexToDecimal {
                if let currentCCT = MatterControllerParser.shared.getCurrentCCT(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                    self.currentLevel = currentCCT
                    node.setMatterCCTValue(cct: currentCCT, deviceId: matterDeviceId)
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
    
    /// Change fan speed
    /// - Parameter speed: new speed value
    func changeCCT(cct: Int) {
        if let id = self.deviceId, let grpId = self.nodeGroup?.groupID {
            if self.nodeConnectionStatus == .local {
                if let _ = ESPMTRCommissioner.shared.sController {
                    self.getColorCluster() { cluster in
                        if let cluster = cluster {
                            let cctParams = MTRColorControlClusterMoveToColorTemperatureParams()
                            let final = Int(1000000/cct)
                            cctParams.colorTemperatureMireds = NSNumber(value: final)
                            cctParams.transitionTime = NSNumber(value: 0)
                            cctParams.optionsMask = NSNumber(value: 0)
                            cctParams.optionsOverride = NSNumber(value: 0)
                            cluster.moveToColorTemperature(with: cctParams) { error in
                                if let _ = error {
                                    DispatchQueue.main.async {
                                        self.slider.value = Float(self.currentLevel)
                                    }
                                    return
                                }
                                if let node = self.node, let id = self.deviceId {
                                    node.setMatterCCTValue(cct: cct, deviceId: id)
                                }
                                self.currentLevel = Int(cct)
                                self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                            }
                        }
                    }
                } else {
                    self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                }
            } else if self.nodeConnectionStatus == .controller {
                if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let _ = matterNodeId.hexToDecimal {
                    var endpoint = "0x1"
                    if let endpointId = MatterControllerParser.shared.getCCTEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                        endpoint = endpointId
                    }
                    let final = Int(1000000/cct)
                    ESPControllerAPIManager.shared.callCCTAPI(rainmakerNode: rainmakerNode,
                                                                     controllerNodeId: controllerNodeId,
                                                                     matterNodeId: matterNodeId,
                                                                     endpoint: endpoint,
                                                                     cctLevel: "\(final)") { result in
                        if result {
                            if let node = self.node, let id = self.deviceId {
                                node.setMatterCCTValue(cct: cct, deviceId: id)
                            }
                            self.currentLevel = Int(cct)
                        } else {
                            self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                        }
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
    
    /// Subscribe to saturation attribute
    func subscribeToCCTAttribute() {
        if let grpId = self.nodeGroup?.groupID, let deviceId = self.deviceId {
            ESPMTRCommissioner.shared.subscribeToCCTValue(groupId: grpId, deviceId: deviceId) { cct in
                DispatchQueue.main.async {
                    let finalCCTValue = Int(cct)
                    if let node = self.node, let id = self.deviceId {
                        node.setMatterCCTValue(cct: cct, deviceId: id)
                    }
                    self.currentLevel = finalCCTValue
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
