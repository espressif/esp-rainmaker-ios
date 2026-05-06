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
//  ParamSliderCell+MatterOCS.swift
//  ESPRainMaker
//
//  Component: Matter Thermostat Cluster - Occupied Cooling Setpoint
//  Handles: Thermostat cluster OCS subscriptions, updates, initialization

#if ESPRainMakerMatter
import UIKit
import Matter

@available(iOS 16.4, *)
extension ParamSliderCell {
    
    // MARK: - Matter OCS - Initialization
    func setupInitialOCSValue(isDeviceOffline: Bool = false) {
        if let grpId = self.nodeGroup?.groupID, let node = self.node, let id = self.deviceId {
            // Set constraint constants for Matter devices (matches old ESPMTROCSSliderTVC)
            self.backViewTopSpaceConstraint?.constant = 10.0
            self.backViewBottomSpaceConstraint?.constant = -10.0
            
            self.titleLabel.text = "Temperature(°C)"
            self.minImage.image = nil
            self.maxImage.image = nil
            self.minLabel.text = "16"
            self.maxLabel.text = "32"
            self.slider.minimumValue = 16.0
            self.slider.maximumValue = 32.0
            
            if let levelValue = node.getMatterOccupiedCoolingSetpoint(deviceId: id) {
                self.currentLevel = Int(levelValue)
            } else {
                self.currentLevel = 20
            }
            self.setOCSSliderValue(finalValue: Float(self.currentLevel))
            if !isDeviceOffline {
                self.readOCS(groupId: grpId, deviceId: id)
                // Subscription is now handled by view controller to prevent cell reuse issues
            }
        }
    }
    
    func setupInitialControllerOCSValues(isDeviceOffline: Bool = false) {
        self.currentLevel = 20
        DispatchQueue.main.async {
            self.minLabel.text = "16"
            self.maxLabel.text = "32"
            self.slider.minimumValue = 16.0
            self.slider.maximumValue = 32.0
            if let node = self.node, let id = self.deviceId, let levelValue = node.getMatterOccupiedCoolingSetpoint(deviceId: id) {
                self.currentLevel = Int(levelValue)
            }
            self.setOCSSliderValue(finalValue: Float(self.currentLevel))
        }
        if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let deviceId = self.deviceId {
            if let ocs = MatterControllerParser.shared.getCurrentOccupiedCoolingSetpoint(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                node.setMatterOccupiedCoolingSetpoint(ocs: Int16(ocs), deviceId: deviceId)
                self.currentLevel = ocs
                self.setOCSSliderValue(finalValue: Float(self.currentLevel))
            }
        }
    }
    
    // MARK: - Matter OCS - Read Current Value
    func getCurrentOCSValue() {
        self.setupInitialOCSValue(isDeviceOffline: self.isDeviceOffline)
    }
    
    func readOCS(groupId: String, deviceId: UInt64) {
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
        commissioner.readOccupiedCoolingSetpoint(groupId: groupId, deviceId: deviceId) { value in
            if let value = value {
                self.currentLevel = Int(value)
                self.node?.setMatterOccupiedCoolingSetpoint(ocs: value, deviceId: deviceId)
                self.setOCSSliderValue(finalValue: Float(self.currentLevel))
            }
        }
    }
    
    // MARK: - Matter OCS - Subscription
    func subscribeToOCSAttribute() {
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            // CRITICAL: Capture param info at subscription setup time for cell reuse protection
            let capturedParamName = self.param?.name ?? self.paramName
            let capturedParamType = self.sliderParamType
            let capturedDeviceId = id
            let capturedParam = self.param // Capture param object reference
            
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
            commissioner.subscribeToOccupiedCoolingSetpoint(groupId: grpId, deviceId: id) { value in
                // CRITICAL: Verify cell still shows the same param before updating (cell reuse protection)
                let currentParamType = self.sliderParamType
                let currentParamName = self.param?.name ?? self.paramName
                let currentDeviceId = self.deviceId
                let currentParam = self.param
                
                // STRICT CHECK: Must be airConditioner type, same device, and same param
                guard currentParamType == .airConditioner,
                      currentParamType == capturedParamType,
                      currentDeviceId == capturedDeviceId,
                      currentParamName == capturedParamName,
                      currentParam === capturedParam, // Identity check - same object reference
                      self.isSameParam(capturedParam: currentParam, capturedParamName: capturedParamName) else {
                    return
                }
                
                // CRITICAL: Only ignore if user is currently dragging
                // Since continuous updates are disabled for Matter, no cooldown needed
                if self.isUserDragging {
                    return
                }
                
                if let mode = self.node?.getMatterSystemMode(deviceId: id) {
                    if mode == ESPMatterConstants.cool {
                        if let value = value {
                            self.currentLevel = Int(value)
                            self.node?.setMatterOccupiedCoolingSetpoint(ocs: value, deviceId: id)
                            self.setOCSSliderValue(finalValue: Float(value))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Matter OCS - Update
    func changeCoolingSetpoint(value: Float) {
        let setPoint = Int16(value)
        let matterValue = setPoint * 100
        
        if let id = self.deviceId, let grpId = self.nodeGroup?.groupID, let node = self.node {
            self.paramChipDelegate?.matterAPIRequestSent()
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
            commissioner.setOccupiedCoolingSetpoint(groupId: grpId, deviceId: id, ocs: NSNumber(value: matterValue)) { result in
                self.paramChipDelegate?.matterAPIResponseReceived()
                if result {
                    if let node = self.node, let id = self.deviceId {
                        node.setMatterOccupiedCoolingSetpoint(ocs: Int16(setPoint), deviceId: id)
                    }
                    self.currentLevel = Int(setPoint)
                    self.setOCSSliderValue(finalValue: Float(self.currentLevel))
                } else {
                    self.setOCSSliderValue(finalValue: Float(self.currentLevel))
                }
            }
        }
    }
    
    // MARK: - Matter OCS - UI Update
    func setOCSSliderValue(finalValue: Float) {
        // Set value synchronously to avoid race condition with setSliderThumbUI() being called before value is set
        if self.slider.value != finalValue {
            self.slider.setValue(finalValue, animated: false) // Use false for initial setup to avoid animation
            self.setSliderThumbUI()
        }
    }
}

#endif

