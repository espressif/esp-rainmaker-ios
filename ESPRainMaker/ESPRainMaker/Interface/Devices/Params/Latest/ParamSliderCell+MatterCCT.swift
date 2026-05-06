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
//  ParamSliderCell+MatterCCT.swift
//  ESPRainMaker
//
//  Component: Matter Color Control Cluster - CCT (Color Temperature)
//  Handles: Color Control cluster CCT subscriptions, updates, initialization

#if ESPRainMakerMatter
import UIKit
import Matter

@available(iOS 16.4, *)
extension ParamSliderCell {
    
    // MARK: - Matter CCT - Initialization
    func setupInitialCCTValue() {
        // Set constraint constants for Matter devices (matches old ESPMTRCCTSliderTVC)
        self.backViewTopSpaceConstraint?.constant = 10.0
        self.backViewBottomSpaceConstraint?.constant = -10.0
        // Clear images for CCT (matches old ESPMTRCCTSliderTVC)
        self.minImage.image = nil
        self.maxImage.image = nil
        
        self.titleLabel.text = "CCT"
        // CRITICAL: CCT uses 2700-6500 range (matches original ESPMTRCCTSliderTVC line 72-73)
        self.slider.minimumValue = 2700.0
        self.slider.maximumValue = 6500.0
        self.minLabel.text = "2700"
        self.maxLabel.text = "6500"
        
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
        
        if let id = self.deviceId, let node = self.node {
            if let cctValue = node.getMatterCCTValue(deviceId: id) {
                // Stored value exists - use it immediately
                self.currentLevel = cctValue
                setSliderValue(Float(cctValue))
            } else {
                // No stored value - use default (4000, not 2500, since 2500 is below min)
                self.currentLevel = 4000
                setSliderValue(4000.0)
            }
        } else {
            self.currentLevel = 4000
            setSliderValue(4000.0)
        }
    }
    
    // MARK: - Matter CCT - Read Current Value
    func getCurrentCCTValue() {
        // CRITICAL: Setup initial UI with stored value FIRST (like OnOff cell)
        self.setupInitialCCTValue()
        
        // Only read from Matter if no stored value exists (like OnOff cell does)
        if self.nodeConnectionStatus == .local, let groupId = self.nodeGroup?.groupID {
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
            if let _ = commissioner.sController {
                self.getColorCluster() { cluster in
                    if let cluster = cluster {
                        cluster.readAttributeColorTemperatureMireds { val, _ in
                            if let val = val {
                                DispatchQueue.main.async {
                                    // CRITICAL: Verify this is still a CCT cell (cell reuse protection)
                                    guard self.sliderParamType == .cct else {
                                        return
                                    }
                                    
                                    let mireds = val.floatValue
                                    let cct = Int(1000000.0 / mireds)
                                    
                                    // CRITICAL: Only update if Matter value is valid (not 0, within 2700-6500 range)
                                    if mireds > 0 && cct >= 2700 && cct <= 6500 {
                                        if let node = self.node, let id = self.deviceId {
                                            node.setMatterCCTValue(cct: cct, deviceId: id)
                                        }
                                        self.currentLevel = cct
                                        self.setCCTSliderValue(finalValue: Float(self.currentLevel))
                                    }
                                    // If Matter returns invalid value, keep the stored/default value we set in setupInitialCCTValue()
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
                    if currentCCT >= 2700 && currentCCT <= 6500 {
                        self.currentLevel = currentCCT
                        node.setMatterCCTValue(cct: currentCCT, deviceId: matterDeviceId)
                        self.setCCTSliderValue(finalValue: Float(self.currentLevel))
                    }
                }
            }
        }
    }
    
    // MARK: - Matter CCT - Subscription
    func subscribeToCCTAttribute() {
        if let grpId = self.nodeGroup?.groupID, let deviceId = self.deviceId {
            // CRITICAL: Capture param info at subscription setup time for cell reuse protection
            let capturedParamName = self.param?.name ?? self.paramName
            let capturedParamType = self.sliderParamType
            let capturedDeviceId = deviceId
            let capturedParam = self.param // Capture param object reference
            
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
            commissioner.subscribeToCCTValue(groupId: grpId, deviceId: deviceId) { cct in
                // CRITICAL: Verify cell still shows the same param before updating (cell reuse protection)
                let currentParamType = self.sliderParamType
                let currentParamName = self.param?.name ?? self.paramName
                let currentDeviceId = self.deviceId
                let currentParam = self.param
                
                // STRICT CHECK: Must be CCT type, same device, and same param
                guard currentParamType == .cct,
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
                
                if let node = self.node, let id = self.deviceId {
                    node.setMatterCCTValue(cct: cct, deviceId: id)
                }
                self.currentLevel = cct
                self.setCCTSliderValue(finalValue: Float(self.currentLevel))
            }
        }
    }
    
    // MARK: - Matter CCT - Update
    func changeCCT(value: Float) {
        let cctValue = Int(value)
        let mireds = Int(1000000.0 / Float(cctValue))
        
        if let id = self.deviceId, let grpId = self.nodeGroup?.groupID {
            if self.nodeConnectionStatus == .local {
                let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
            if let _ = commissioner.sController {
                self.getColorCluster() { cluster in
                    if let cluster = cluster {
                        let params = MTRColorControlClusterMoveToColorTemperatureParams()
                        params.colorTemperatureMireds = NSNumber(value: mireds)
                        params.transitionTime = NSNumber(value: 0)
                        params.optionsMask = NSNumber(value: 0)
                        params.optionsOverride = NSNumber(value: 0)
                        cluster.moveToColorTemperature(with: params) { error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    self.setCCTSliderValue(finalValue: Float(self.currentLevel))
                                } else {
                                    if let node = self.node, let id = self.deviceId {
                                        node.setMatterCCTValue(cct: cctValue, deviceId: id)
                                    }
                                    self.currentLevel = cctValue
                                    self.setCCTSliderValue(finalValue: Float(self.currentLevel))
                                }
                            }
                            }
                        } else {
                            self.setCCTSliderValue(finalValue: Float(self.currentLevel))
                        }
                    }
                } else {
                    self.setCCTSliderValue(finalValue: Float(self.currentLevel))
                }
            } else if self.nodeConnectionStatus == .controller {
                // Add controller support (matches old ESPMTRCCTSliderTVC)
                if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let _ = matterNodeId.hexToDecimal {
                    var endpoint = "0x1"
                    if let endpointId = MatterControllerParser.shared.getCCTEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                        endpoint = endpointId
                    }
                    let final = Int(1000000.0 / Float(cctValue))
                    ESPControllerAPIManager.shared.callCCTAPI(rainmakerNode: rainmakerNode,
                                                              controllerNodeId: controllerNodeId,
                                                              matterNodeId: matterNodeId,
                                                              endpoint: endpoint,
                                                              cctLevel: "\(final)") { result in
                        if result {
                            if let node = self.node, let id = self.deviceId {
                                node.setMatterCCTValue(cct: cctValue, deviceId: id)
                            }
                            self.currentLevel = cctValue
                        } else {
                            self.setCCTSliderValue(finalValue: Float(self.currentLevel))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Matter CCT - UI Update
    func setCCTSliderValue(finalValue: Float) {
        DispatchQueue.main.async {
            if self.slider.value != finalValue {
                self.slider.setValue(finalValue, animated: true)
                self.setSliderThumbUI()
            }
        }
    }
}

#endif

