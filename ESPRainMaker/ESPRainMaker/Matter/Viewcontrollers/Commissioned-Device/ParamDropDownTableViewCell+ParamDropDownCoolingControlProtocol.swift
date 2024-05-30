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
//  ParamDropDownTableViewCell+ParamDropDownCoolingControlProtocol.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import Foundation
import UIKit
import Matter

@available(iOS 16.4, *)
protocol ParamDropDownCoolingControlProtocol {
    func setInitialControlSequenceOfOperation()
    func subscribeControlSequenceOfOperation()
    func setInitialSystemMode()
    func subscribeSystemMode()
}

@available(iOS 16.4, *)
extension ParamDropDownTableViewCell: ParamDropDownCoolingControlProtocol {
    
    /// Set initial control sequence of operation
    func setInitialControlSequenceOfOperation() {
        DispatchQueue.main.async {
            self.controlValueLabel.text = "_"
        }
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            if let cso = self.matterNode?.getMatterControlledSequenceOfOperation(deviceId: id) {
                self.controlValueLabel.text = cso
                self.matterNode?.setMatterControlledSequenceOfOperation(cso: cso, deviceId: id)
            } else {
                ESPMTRCommissioner.shared.readControlSequenceOfOperation(groupId: grpId, deviceId: id) { value in
                    if let value = value {
                        let val = value.intValue
                        var cso = ESPMatterConstants.off
                        if val == 4 {
                            cso = ESPMatterConstants.cool
                        }
                        self.matterNode?.setMatterControlledSequenceOfOperation(cso: cso, deviceId: id)
                        DispatchQueue.main.async {
                            self.controlValueLabel.text = cso
                        }
                    }
                }
            }
        }
    }
    
    /// Subscribe to control sequence of operation
    func subscribeControlSequenceOfOperation() {
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            ESPMTRCommissioner.shared.subscribeControlSequenceOfOperation(groupId: grpId, deviceId: id) { value in
                if let value = value {
                    let val = value.intValue
                    var cso = ESPMatterConstants.off
                    if val == 4 {
                        cso = ESPMatterConstants.cool
                    }
                    self.matterNode?.setMatterControlledSequenceOfOperation(cso: cso, deviceId: id)
                    DispatchQueue.main.async {
                        self.controlValueLabel.text = cso
                    }
                }
            }
        }
    }
    
    /// Set initial system mode
    func setInitialSystemMode() {
        self.controlValueLabel.text = "_"
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            if let systemMode = self.matterNode?.getMatterSystemMode(deviceId: id) {
                DispatchQueue.main.async {
                    self.controlValueLabel.text = systemMode
                }
            }
            self.readAndSubscribeToSystemMode(groupId: grpId, deviceId: id)
        }
    }
    
    func readAndSubscribeToSystemMode(groupId: String, deviceId: UInt64) {
        ESPMTRCommissioner.shared.readSystemMode(groupId: groupId, deviceId: deviceId) { value in
            if let value = value {
                let val = value.intValue
                var systemMode = ESPMatterConstants.off
                if val == 0 {
                    systemMode = ESPMatterConstants.off
                } else if val == 3 {
                    systemMode = ESPMatterConstants.cool
                } else if val == 4 {
                    systemMode = ESPMatterConstants.heat
                }
                self.matterNode?.setMatterSystemMode(systemMode: systemMode, deviceId: deviceId)
                DispatchQueue.main.async {
                    self.controlValueLabel.text = systemMode
                }
                self.acParamDelegate?.acSystemModeSet()
            }
        }
    }
    
    func readControllerMode() {
        if let node = self.node, let controller = node.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = node.matter_node_id, let deviceId = self.deviceId {
            if let mode = MatterControllerParser.shared.getCurrentSystemMode(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                var systemMode = ESPMatterConstants.off
                switch mode {
                case 3:
                    systemMode = ESPMatterConstants.cool
                case 4:
                    systemMode = ESPMatterConstants.heat
                default:
                    break
                }
                self.matterNode?.setMatterSystemMode(systemMode: systemMode, deviceId: deviceId)
                DispatchQueue.main.async {
                    self.controlValueLabel.text = systemMode
                }
                self.acParamDelegate?.acSystemModeSet()
            }
        }
    }
    
    func readMode() {
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            ESPMTRCommissioner.shared.readSystemMode(groupId: grpId, deviceId: id) { value in
                if let value = value {
                    let mode = value.intValue
                    var systemMode = ESPMatterConstants.off
                    switch mode {
                    case 3:
                        systemMode = ESPMatterConstants.cool
                    case 4:
                        systemMode = ESPMatterConstants.heat
                    default:
                        break
                    }
                    self.matterNode?.setMatterSystemMode(systemMode: systemMode, deviceId: id)
                    DispatchQueue.main.async {
                        self.controlValueLabel.text = systemMode
                    }
                    self.acParamDelegate?.acSystemModeSet()
                }
            }
        }
    }
    
    /// Subscribe to system mode
    func subscribeSystemMode() {
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            ESPMTRCommissioner.shared.subscribeSystemMode(groupId: grpId, deviceId: id) { value in
                if let value = value {
                    let mode = value.intValue
                    var systemMode = ESPMatterConstants.off
                    switch mode {
                    case 3:
                        systemMode = ESPMatterConstants.cool
                    case 4:
                        systemMode = ESPMatterConstants.heat
                    default:
                        break
                    }
                    self.matterNode?.setMatterSystemMode(systemMode: systemMode, deviceId: id)
                    DispatchQueue.main.async {
                        self.controlValueLabel.text = systemMode
                    }
                    self.acParamDelegate?.acSystemModeSet()
                }
            }
        }
    }
}
#endif
