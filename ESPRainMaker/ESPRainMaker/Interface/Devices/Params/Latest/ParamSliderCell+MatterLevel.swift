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
//  ParamSliderCell+MatterLevel.swift
//  ESPRainMaker
//
//  Component: Matter Level Control Cluster
//  Handles: Level Control cluster subscriptions, updates, initialization

#if ESPRainMakerMatter
import UIKit
import Matter

@available(iOS 16.4, *)
extension ParamSliderCell {
    
    // MARK: - Matter Level Control - Initialization
    func setupInitialLevelValues() {
        // Set constraint constants for Matter devices (matches old ESPMTRLevelSliderTVC)
        self.backViewTopSpaceConstraint?.constant = 10.0
        self.backViewBottomSpaceConstraint?.constant = -10.0
        
        self.titleLabel.text = "Brightness"
        self.slider.minimumValue = 0.0
        self.slider.maximumValue = 100.0
        self.minLabel.text = "0"
        self.maxLabel.text = "100"
        self.minImage.image = UIImage(named: "brightness_low")
        self.maxImage.image = UIImage(named: "brightness_high")
        
        // CRITICAL: Use stored value FIRST (like OnOff cell does)
        // Only use default if no stored value exists
        // Ensure UI updates happen on main thread
        let setSliderValue: (Float) -> Void = { value in
            if Thread.isMainThread {
                self.slider.setValue(value, animated: false)
                self.setSliderThumbUI()
            } else {
                DispatchQueue.main.sync {
                    self.slider.setValue(value, animated: false)
                    self.setSliderThumbUI()
                }
            }
        }
        
        if let node = self.node, let id = self.deviceId {
            if let levelValue = node.getMatterLevelValue(deviceId: id) {
                // Stored value exists - use it immediately
                let final = Float(levelValue)/2.54
                let uiValue = Int(final)
                self.currentLevel = uiValue
                setSliderValue(final)
            } else {
                // No stored value - use default
                self.currentLevel = 50
                setSliderValue(50.0)
            }
        } else {
            self.currentLevel = 50
            setSliderValue(50.0)
        }
    }
    
    // MARK: - Matter Level Control - Read Current Value
    func getCurrentLevelValues() {
        guard let groupId = self.nodeGroup?.groupID, let deviceId = self.deviceId else { return }
        
        // CRITICAL: Setup initial UI with stored value FIRST (like OnOff cell)
        self.setupInitialLevelValues()
        
        // Only read from Matter if no stored value exists (like OnOff cell does)
        if self.nodeConnectionStatus == .local {
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
            if let controller = commissioner.sController {
                self.getLevelController(controller: controller) { levelControl in
                    if let levelControl = levelControl {
                        self.getMinLevelValue(levelControl: levelControl) { min, _ in
                            self.getCurrentLevelValue(levelControl: levelControl) { current, _ in
                                DispatchQueue.main.async {
                                    // CRITICAL: Verify this is still a Level cell (cell reuse protection)
                                    guard self.sliderParamType == .brightness else {
                                        return
                                    }
                                    
                                    // Only update if Matter returns a valid value (not 0, within range)
                                    if let current = current {
                                        let matterValue = current.intValue
                                        let uiValue = Int(current.floatValue/2.54)
                                        
                                        // CRITICAL: Only update if Matter value is valid (not 0, within 0-100 range)
                                        if matterValue > 0 && uiValue >= 0 && uiValue <= 100 {
                                            if let node = self.node, let id = self.deviceId {
                                                node.setMatterLevelValue(level: matterValue, deviceId: id)
                                            }
                                            self.currentLevel = uiValue
                                            self.setLevelSliderValue(finalValue: Float(self.currentLevel))
                                        }
                                        // If Matter returns invalid value, keep the stored/default value we set in setupInitialLevelValues()
                                    }
                                    Utility.hideLoader(view: self)
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
                    let uiValue = Int(finalValue)
                    if uiValue >= 0 && uiValue <= 100 {
                        self.currentLevel = uiValue
                        node.setMatterLevelValue(level: currentLevel, deviceId: matterDeviceId)
                        self.setLevelSliderValue(finalValue: Float(self.currentLevel))
                    }
                }
            }
        }
    }
    
    // MARK: - Matter Level Control - Subscription
    func subscribeToLevelAttribute() {
        if let grpId = self.nodeGroup?.groupID, let deviceId = self.deviceId {
            // CRITICAL: Capture param info at subscription setup time for cell reuse protection
            let capturedParamName = self.param?.name ?? self.paramName
            let capturedParamType = self.sliderParamType
            let capturedDeviceId = deviceId
            let capturedParam = self.param // Capture param object reference
            
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
            commissioner.subscribeToLevelValue(groupId: grpId, deviceId: deviceId) { level in
                // CRITICAL: Verify cell still shows the same param before updating (cell reuse protection)
                let currentParamType = self.sliderParamType
                let currentParamName = self.param?.name ?? self.paramName
                let currentDeviceId = self.deviceId
                let currentParam = self.param
                
                // STRICT CHECK: Must be brightness/level type, same device, and same param
                guard currentParamType == .brightness,
                      currentParamType == capturedParamType,
                      currentDeviceId == capturedDeviceId,
                      currentParamName == capturedParamName,
                      currentParam === capturedParam, // Identity check - same object reference
                      self.isSameParam(capturedParam: currentParam, capturedParamName: capturedParamName) else {
                    return
                }
                
                let finalLevelValue = Float(CGFloat(level)/2.54)
                let uiValue = Int(finalLevelValue)
                
                // CRITICAL: Only ignore if user is currently dragging
                // Since continuous updates are disabled for Matter, user only sets value once on touch up
                // Subscription should fire with the new value after user sets it, so no cooldown needed
                if self.isUserDragging {
                    return
                }
                
                if let node = self.node, let id = self.deviceId {
                    node.setMatterLevelValue(level: level, deviceId: id)
                }
                self.currentLevel = uiValue
                self.setLevelSliderValue(finalValue: finalLevelValue)
            }
        }
    }
    
    // MARK: - Matter Level Control - Update
    func changeLevel(toValue val: Float) {
        guard let groupId = self.nodeGroup?.groupID, let deviceId = self.deviceId else { return }
        let finalValue = Int(val*2.54)
        
        if nodeConnectionStatus == .local {
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
            if let cont = commissioner.sController {
                self.getLevelController(controller: cont) { controller in
                    if let controller = controller {
                        let levelParams = MTRLevelControlClusterMoveToLevelWithOnOffParams()
                        levelParams.level = NSNumber(value: finalValue)
                        controller.moveToLevelWithOnOff(with: levelParams) { error in
                            DispatchQueue.main.async {
                                if let error = error {
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
    
    // MARK: - Matter Level Control - Cluster Access
    func getLevelController(controller: MTRDeviceController, completionHandler: @escaping (MTRBaseClusterLevelControl?) -> Void) {
        guard let groupId = self.nodeGroup?.groupID, let deviceId = self.deviceId else {
            completionHandler(nil)
            return
        }
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
        let (_, endpoint) = ESPMatterClusterUtil.shared.isLevelControlServerSupported(groupId: groupId, deviceId: deviceId)
        if let endpoint = endpoint, let point = UInt16(endpoint) {
            controller.getBaseDevice(deviceId, queue: commissioner.matterQueue) { device, _ in
                if let device = device, let levelControl = MTRBaseClusterLevelControl(device: device, endpoint: point, queue: commissioner.matterQueue) {
                    completionHandler(levelControl)
                } else {
                    completionHandler(nil)
                }
            }
        }
    }
    
    func getMinLevelValue(levelControl: MTRBaseClusterLevelControl, completionHandler: @escaping (NSNumber?, Error?) -> Void) {
        levelControl.readAttributeMinLevel() { min, error in
            completionHandler(min, error)
        }
    }
    
    func getCurrentLevelValue(levelControl: MTRBaseClusterLevelControl, completionHandler: @escaping (NSNumber?, Error?) -> Void) {
        levelControl.readAttributeCurrentLevel() { current, error in
            completionHandler(current, error)
        }
    }
    
    func getMaxLevelValue(levelControl: MTRBaseClusterLevelControl, completionHandler: @escaping (NSNumber?, Error?) -> Void) {
        levelControl.readAttributeMaxLevel() { max, error in
            completionHandler(max, error)
        }
    }
    
    // MARK: - Matter Level Control - UI Update
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

