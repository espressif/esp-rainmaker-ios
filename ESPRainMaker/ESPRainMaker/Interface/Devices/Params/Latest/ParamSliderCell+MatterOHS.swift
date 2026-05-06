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
//  ParamSliderCell+MatterOHS.swift
//  ESPRainMaker
//
//  Component: Matter Thermostat Cluster - Occupied Heating Setpoint
//  Handles: Thermostat cluster OHS subscriptions, updates, initialization

#if ESPRainMakerMatter
import UIKit
import Matter

@available(iOS 16.4, *)
extension ParamSliderCell {
    
    // MARK: - Matter OHS - Initialization
    func setupInitialOHSValue(isDeviceOffline: Bool = false) {
        if let grpId = self.nodeGroup?.groupID, let node = self.node, let id = self.deviceId {
            // Set constraint constants for Matter devices (matches old ESPMTROHSSliderTVC)
            self.backViewTopSpaceConstraint?.constant = 10.0
            self.backViewBottomSpaceConstraint?.constant = -10.0
            
            self.titleLabel.text = "Temperature(°C)"
            self.minImage.image = nil
            self.maxImage.image = nil
            self.currentLevel = 20
            self.minLabel.text = "7"
            self.maxLabel.text = "30"
            self.slider.minimumValue = 7.0
            self.slider.maximumValue = 30.0
            
            if let levelValue = node.getMatterOccupiedHeatingSetpoint(deviceId: id) {
                self.currentLevel = Int(levelValue)
            }
            self.setOHSSliderValue(finalValue: Float(self.currentLevel))
            if !isDeviceOffline {
                self.readOHS(groupId: grpId, deviceId: id)
                // Subscription is now handled by view controller to prevent cell reuse issues
            }
        }
    }
    
    func setupInitialControllerOHSValues(isDeviceOffline: Bool = false) {
        if let node = self.node, let deviceId = self.deviceId {
            self.currentLevel = 20
            DispatchQueue.main.async {
                self.minLabel.text = "7"
                self.maxLabel.text = "30"
                self.slider.minimumValue = 7.0
                self.slider.maximumValue = 30.0
                // CRITICAL: Bug fix - should use getMatterOccupiedHeatingSetpoint, not getMatterOccupiedCoolingSetpoint
                if let ohs = node.getMatterOccupiedHeatingSetpoint(deviceId: deviceId) {
                    self.currentLevel = Int(ohs)
                }
                self.setOHSSliderValue(finalValue: Float(self.currentLevel))
            }
            if let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let ohs = MatterControllerParser.shared.getCurrentOccupiedHeatingSetpoint(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                node.setMatterOccupiedHeatingSetpoint(ohs: Int16(ohs), deviceId: deviceId)
                self.currentLevel = ohs
            }
            self.setOHSSliderValue(finalValue: Float(self.currentLevel))
        }
    }
    
    // MARK: - Matter OHS - Read Current Value
    func getCurrentOHSValue() {
        self.setupInitialOHSValue(isDeviceOffline: self.isDeviceOffline)
    }
    
    func readOHS(groupId: String, deviceId: UInt64) {
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
        commissioner.readOccupiedHeatingSetpoint(groupId: groupId, deviceId: deviceId) { value in
            if let value = value {
                self.currentLevel = Int(value)
                self.node?.setMatterOccupiedHeatingSetpoint(ohs: value, deviceId: deviceId)
                self.setOHSSliderValue(finalValue: Float(self.currentLevel))
            }
        }
    }
    
    // MARK: - Matter OHS - Subscription
    func subscribeToOHSAttribute() {
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            // CRITICAL: Capture param info at subscription setup time for cell reuse protection
            let capturedParamName = self.param?.name ?? self.paramName
            let capturedParamType = self.sliderParamType
            let capturedDeviceId = id
            let capturedParam = self.param // Capture param object reference
            
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
            commissioner.subscribeToOccupiedHeatingSetpoint(groupId: grpId, deviceId: id) { value in
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
                    if mode == ESPMatterConstants.heat {
                        if let value = value {
                            self.currentLevel = Int(value)
                            self.node?.setMatterOccupiedHeatingSetpoint(ohs: value, deviceId: id)
                            self.setOHSSliderValue(finalValue: Float(value))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Matter OHS - Update
    func changeHeatingSetpoint(value: Float) {
        let setPoint = Int16(value)
        let matterValue = setPoint * 100
        
        if let id = self.deviceId, let grpId = self.nodeGroup?.groupID, let node = self.node {
            self.paramChipDelegate?.matterAPIRequestSent()
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
            commissioner.setOccupiedHeatingSetpoint(groupId: grpId, deviceId: id, ocs: NSNumber(value: matterValue)) { result in
                self.paramChipDelegate?.matterAPIResponseReceived()
                if result {
                    node.setMatterOccupiedHeatingSetpoint(ohs: Int16(setPoint), deviceId: id)
                    self.currentLevel = Int(setPoint)
                    self.setOHSSliderValue(finalValue: Float(self.currentLevel))
                } else {
                    self.setOHSSliderValue(finalValue: Float(self.currentLevel))
                }
            }
        }
    }
    
    // MARK: - Matter OHS - UI Update
    func setOHSSliderValue(finalValue: Float) {
        // Set value synchronously to avoid race condition with setSliderThumbUI() being called before value is set
        if self.slider.value != finalValue {
            self.slider.setValue(finalValue, animated: false) // Use false for initial setup to avoid animation
            self.setSliderThumbUI()
        }
    }
}

#endif

