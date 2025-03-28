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
//  ParamSliderTableViewCell+CoolingControl.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import Foundation
import UIKit
import Matter

@available(iOS 16.4, *)
extension ParamSliderTableViewCell {
    
    func readOHS(groupId: String, deviceId: UInt64) {
        ESPMTRCommissioner.shared.readOccupiedHeatingSetpoint(groupId: groupId, deviceId: deviceId) { value in
            if let value = value {
                self.currentLevel = Int(value)
                self.node?.setMatterOccupiedHeatingSetpoint(ohs: value, deviceId: deviceId)
                self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
            }
        }
    }
    
    func readOCS(groupId: String, deviceId: UInt64) {
        ESPMTRCommissioner.shared.readOccupiedCoolingSetpoint(groupId: groupId, deviceId: deviceId) { value in
            if let value = value {
                self.currentLevel = Int(value)
                self.node?.setMatterOccupiedCoolingSetpoint(ocs: value, deviceId: deviceId)
                self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
            }
        }
    }
    
    func setupInitialControllerOCSValues(isDeviceOffline: Bool) {
        DispatchQueue.main.async {
            self.minLabel.text = "7"
            self.maxLabel.text = "30"
            self.slider.minimumValue = 7.0
            self.slider.maximumValue = 30.0
            self.setOccupiedSetpointSliderValue(finalValue: 20.0)
        }
        if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let deviceId = self.deviceId {
            if let status = node.getMatterSystemMode(deviceId: deviceId) {
                if status == ESPMatterConstants.cool {
                    if let ocs = MatterControllerParser.shared.getCurrentOccupiedCoolingSetpoint(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                        node.setMatterOccupiedCoolingSetpoint(ocs: Int16(ocs), deviceId: deviceId)
                        self.currentLevel = ocs
                        self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
                    }
                } else {
                    self.currentLevel = 20
                    if let ohs = MatterControllerParser.shared.getCurrentOccupiedHeatingSetpoint(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                        node.setMatterOccupiedHeatingSetpoint(ohs: Int16(ohs), deviceId: deviceId)
                        self.currentLevel = ohs
                    }
                    DispatchQueue.main.async {
                        self.minLabel.text = "16"
                        self.maxLabel.text = "32"
                        self.slider.minimumValue = 16.0
                        self.slider.maximumValue = 32.0
                        self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
                    }
                }
            }
        }
    }
    
    //MARK: Occupied cooling/heating setpoint
    /// Setup initial level values
    func setupInitialCoolingSetpointValues2(isDeviceOffline: Bool) {
        DispatchQueue.main.async {
            self.minLabel.text = "7"
            self.maxLabel.text = "30"
            self.slider.minimumValue = 7.0
            self.slider.maximumValue = 30.0
            self.setOccupiedSetpointSliderValue(finalValue: 20.0)
        }
        if let grpId = self.nodeGroup?.groupID, let node = self.node, let id = self.deviceId {
            if let status = node.getMatterSystemMode(deviceId: id) {
                if status == "Heat" {
                    if let levelValue = node.getMatterOccupiedHeatingSetpoint(deviceId: id) {
                        self.currentLevel = Int(levelValue)
                        self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
                    }
                    if !isDeviceOffline {
                        self.subscribeToOccupiedHeatingSetpoint()
                    }
                } else if status != "Heat" {
                    DispatchQueue.main.async {
                        self.minLabel.text = "16"
                        self.maxLabel.text = "32"
                        self.slider.minimumValue = 16.0
                        self.slider.maximumValue = 32.0
                        self.setOccupiedSetpointSliderValue(finalValue: 20.0)
                    }
                    if let levelValue = node.getMatterOccupiedCoolingSetpoint(deviceId: id) {
                        self.currentLevel = Int(levelValue)
                        self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
                    }
                    if !isDeviceOffline {
                        self.subscribeToOccupiedCoolingSetpoint()
                    }
                }
            }
        }
    }
    
    //MARK: Occupied cooling/heating setpoint
    /// Setup initial level values
    func setupInitialCoolingSetpointValues() {
        if let grpId = self.nodeGroup?.groupID, let node = self.node, let id = self.deviceId {
            var status: String?
            self.title.text = "Temperature(°C)"
            self.minImage.image = nil
            self.maxImage.image = nil
            self.currentLevel = 20
            DispatchQueue.main.async {
                self.backViewTopSpaceConstraint.constant = 10.0
                self.backViewBottomSpaceConstraint.constant = 10.0
                self.minLabel.text = "16"
                self.maxLabel.text = "32"
                self.slider.minimumValue = 16.0
                self.slider.maximumValue = 32.0
                self.setOccupiedSetpointSliderValue(finalValue: 20.0)
            }
            if let val = node.getMatterSystemMode(deviceId: id) {
                status = val
                if val.lowercased() == "heat" {
                    DispatchQueue.main.async {
                        self.backViewTopSpaceConstraint.constant = 10.0
                        self.backViewBottomSpaceConstraint.constant = 10.0
                        self.minLabel.text = "7"
                        self.maxLabel.text = "30"
                        self.slider.minimumValue = 7.0
                        self.slider.maximumValue = 30.0
                        self.setOccupiedSetpointSliderValue(finalValue: 20.0)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.backViewTopSpaceConstraint.constant = 10.0
                        self.backViewBottomSpaceConstraint.constant = 10.0
                        self.minLabel.text = "16"
                        self.maxLabel.text = "32"
                        self.slider.minimumValue = 16.0
                        self.slider.maximumValue = 32.0
                        self.setOccupiedSetpointSliderValue(finalValue: 20.0)
                    }
                }
            }
            if let status = status {
                if status.lowercased() == "heat" {
                    if let levelValue = node.getMatterOccupiedHeatingSetpoint(deviceId: id) {
                        self.currentLevel = Int(levelValue)
                        self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
                        self.readOHS(groupId: grpId, deviceId: id)
                    } else {
                        self.readOHS(groupId: grpId, deviceId: id)
                    }
                } else if status.lowercased() != "heat" {
                    if let levelValue = node.getMatterOccupiedCoolingSetpoint(deviceId: id) {
                        self.currentLevel = Int(levelValue)
                        self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
                        self.readOCS(groupId: grpId, deviceId: id)
                    } else {
                        self.readOCS(groupId: grpId, deviceId: id)
                    }
                }
            }
        }
    }
    
    /// Subscribe to occupied cooling setpoint
    func subscribeToOccupiedCoolingSetpoint() {
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            ESPMTRCommissioner.shared.subscribeToOccupiedCoolingSetpoint(groupId: grpId, deviceId: id) { value in
                if let mode = self.node?.getMatterSystemMode(deviceId: id) {
                    if mode == ESPMatterConstants.cool {
                        if let value = value {
                            self.currentLevel = Int(value)
                            self.node?.setMatterOccupiedCoolingSetpoint(ocs: value, deviceId: id)
                            self.setOccupiedSetpointSliderValue(finalValue: Float(value))
                        }
                    }
                }
            }
        }
    }
    
    /// Subscribe to occupied heating setpoint
    func subscribeToOccupiedHeatingSetpoint() {
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            ESPMTRCommissioner.shared.subscribeToOccupiedHeatingSetpoint(groupId: grpId, deviceId: id) { value in
                if let mode = self.node?.getMatterSystemMode(deviceId: id) {
                    if mode == ESPMatterConstants.heat {
                        if let value = value {
                            self.currentLevel = Int(value)
                            self.node?.setMatterOccupiedHeatingSetpoint(ohs: value, deviceId: id)
                            self.setOccupiedSetpointSliderValue(finalValue: Float(value))
                        }
                    }
                }
            }
        }
    }
    
    /// Change occupied cooling/heating set point
    /// - Parameter setPoint: cooling/heating set point
    func changeOccupiedSetpoint(setPoint: Int16) {
        if let id = self.deviceId, let grpId = self.nodeGroup?.groupID, let node = self.node {
            self.paramChipDelegate?.matterAPIRequestSent()
            if let val = node.getMatterSystemMode(deviceId: id), val.lowercased() == "heat" {
                ESPMTRCommissioner.shared.setOccupiedHeatingSetpoint(groupId: grpId, deviceId: id, ocs: NSNumber(value: setPoint*100)) { result in
                    self.paramChipDelegate?.matterAPIResponseReceived()
                    if result {
                        node.setMatterOccupiedHeatingSetpoint(ohs: Int16(setPoint*100), deviceId: id)
                        self.currentLevel = Int(setPoint)
                        self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
                    } else {
                        self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
                    }
                }
            } else {
                ESPMTRCommissioner.shared.setOccupiedCoolingSetpoint(groupId: grpId, deviceId: id, ocs: NSNumber(value: setPoint*100)) { result in
                    self.paramChipDelegate?.matterAPIResponseReceived()
                    if result {
                        if let node = self.node, let id = self.deviceId {
                            node.setMatterOccupiedCoolingSetpoint(ocs: Int16(setPoint*100), deviceId: id)
                        }
                        self.currentLevel = Int(setPoint)
                        self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
                    } else {
                        self.setOccupiedSetpointSliderValue(finalValue: Float(self.currentLevel))
                    }
                }
            }
        }
    }
    
    /// Set setpoint slider final value
    /// - Parameter finalValue: slider final value
    func setOccupiedSetpointSliderValue(finalValue: Float) {
        if self.slider.value != finalValue {
            DispatchQueue.main.async {
                self.slider.setValue(finalValue, animated: true)
                self.setSliderThumbUI()
            }
        }
    }
}
#endif
