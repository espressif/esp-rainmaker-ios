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
                let val = value.intValue
                self.currentLevel = val/100
                self.node?.setMatterOccupiedHeatingSetpoint(ohs: Int16(val), deviceId: deviceId)
                DispatchQueue.main.async {
                    self.slider.setValue(Float(self.currentLevel), animated: true)
                }
            }
        }
    }
    
    func readOCS(groupId: String, deviceId: UInt64) {
        ESPMTRCommissioner.shared.readOccupiedCoolingSetpoint(groupId: groupId, deviceId: deviceId) { value in
            if let value = value {
                let val = value.intValue
                self.currentLevel = val/100
                self.node?.setMatterOccupiedCoolingSetpoint(ocs: Int16(val), deviceId: deviceId)
                DispatchQueue.main.async {
                    self.slider.setValue(Float(self.currentLevel), animated: true)
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
                self.minLabel.text = "16"
                self.maxLabel.text = "32"
                self.slider.minimumValue = 16.0
                self.slider.maximumValue = 32.0
                self.slider.setValue(20.0, animated: true)
            }
            if let val = node.getMatterSystemMode(deviceId: id) {
                status = val
                if val == "Heat" {
                    DispatchQueue.main.async {
                        self.minLabel.text = "7"
                        self.maxLabel.text = "30"
                        self.slider.minimumValue = 7.0
                        self.slider.maximumValue = 30.0
                        self.slider.setValue(20.0, animated: true)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.minLabel.text = "16"
                        self.maxLabel.text = "32"
                        self.slider.minimumValue = 16.0
                        self.slider.maximumValue = 32.0
                        self.slider.setValue(20.0, animated: true)
                    }
                }
            }
            if let status = status {
                if status == "Heat" {
                    if let levelValue = node.getMatterOccupiedHeatingSetpoint(deviceId: id) {
                        self.currentLevel = Int(levelValue)/100
                        DispatchQueue.main.async {
                            self.slider.setValue(Float(self.currentLevel), animated: true)
                        }
                        self.readOHS(groupId: grpId, deviceId: id)
                    } else {
                        self.readOHS(groupId: grpId, deviceId: id)
                    }
                } else if status != "Heat" {
                    if let levelValue = node.getMatterOccupiedCoolingSetpoint(deviceId: id) {
                        self.currentLevel = Int(levelValue)
                        DispatchQueue.main.async {
                            self.slider.setValue(Float(self.currentLevel), animated: true)
                        }
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
                if let value = value {
                    let val = value.intValue/100
                    self.currentLevel = val
                    self.node?.setMatterOccupiedCoolingSetpoint(ocs: Int16(val), deviceId: id)
                    DispatchQueue.main.async {
                        self.slider.setValue(Float(val), animated: true)
                    }
                }
            }
        }
    }
    
    /// Subscribe to occupied heating setpoint
    func subscribeToOccupiedHeatingSetpoint() {
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            ESPMTRCommissioner.shared.subscribeToOccupiedHeatingSetpoint(groupId: grpId, deviceId: id) { value in
                if let value = value {
                    let val = value.intValue/100
                    self.currentLevel = val
                    self.node?.setMatterOccupiedHeatingSetpoint(ohs: Int16(val), deviceId: id)
                    DispatchQueue.main.async {
                        self.slider.setValue(Float(val), animated: true)
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
            if let val = node.getMatterSystemMode(deviceId: id), val == "Heat" {
                ESPMTRCommissioner.shared.setOccupiedHeatingSetpoint(groupId: grpId, deviceId: id, ocs: NSNumber(value: setPoint*100)) { result in
                    self.paramChipDelegate?.matterAPIResponseReceived()
                    if result {
                        node.setMatterOccupiedHeatingSetpoint(ohs: Int16(setPoint*100), deviceId: id)
                        self.currentLevel = Int(setPoint)
                        DispatchQueue.main.async {
                            self.slider.setValue(Float(self.currentLevel), animated: true)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.slider.setValue(Float(self.currentLevel), animated: true)
                        }
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
                        DispatchQueue.main.async {
                            self.slider.setValue(Float(self.currentLevel), animated: true)
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
}
#endif
