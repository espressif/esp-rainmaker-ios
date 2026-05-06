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
//  ParamSliderCell+MatterSaturation.swift
//  ESPRainMaker
//
//  Component: Matter Color Control Cluster - Saturation
//  Handles: Color Control cluster saturation subscriptions, updates, initialization

#if ESPRainMakerMatter
import UIKit
import Matter

@available(iOS 16.4, *)
extension ParamSliderCell {
    
    // MARK: - Matter Saturation - Initialization
    func setupInitialSaturationValue() {
        // Set constraint constants for Matter devices (matches old ESPMTRSaturationSliderTVC)
        self.backViewTopSpaceConstraint?.constant = 10.0
        self.backViewBottomSpaceConstraint?.constant = -10.0
        
        self.titleLabel.text = "Saturation"
        self.slider.minimumValue = 0.0
        self.slider.maximumValue = 100.0
        self.minLabel.text = "0"
        self.maxLabel.text = "100"
        self.minImage.image = UIImage(named: "saturation_low")
        self.maxImage.image = UIImage(named: "saturation_high")
        
        if let id = self.deviceId, let node = self.node, let saturationValue = node.getMatterSaturationValue(deviceId: id) {
            self.setSaturationSliderValue(finalValue: Float(saturationValue))
        } else {
            self.setSaturationSliderValue(finalValue: 50.0)
        }
    }
    
    // MARK: - Matter Saturation - Read Current Value
    func getCurrentSaturationValue() {
        self.setupInitialSaturationValue()
        if self.nodeConnectionStatus == .local, let groupId = self.nodeGroup?.groupID {
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
            if let _ = commissioner.sController {
                self.getColorCluster() { cluster in
                    if let cluster = cluster {
                        cluster.readAttributeCurrentSaturation { val, _ in
                            if let val = val {
                                DispatchQueue.main.async {
                                    // CRITICAL: Convert Matter value (0-254) to UI value (0-100) - matches original ESPMTRSaturationSliderTVC line 328
                                    let saturation = Int(val.floatValue*2.54)
                                    if let node = self.node, let id = self.deviceId {
                                        // CRITICAL: Store UI value (0-100) in node - matches original ESPMTRSaturationSliderTVC line 330
                                        // Note: Original stores UI value here, not Matter value
                                        node.setMatterSaturationValue(saturation: saturation, deviceId: id)
                                    }
                                    // CRITICAL: Store UI value (0-100) in currentLevel - matches original ESPMTRSaturationSliderTVC line 332
                                    self.currentLevel = saturation
                                    self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                                }
                            }
                        }
                    }
                }
            }
            // Note: Subscription is handled by view controller (DeviceViewController+MatterSubscriptions), not here
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
    
    // MARK: - Matter Saturation - Subscription
    func subscribeToSaturationAttribute() {
        if let grpId = self.nodeGroup?.groupID, let deviceId = self.deviceId {
            // CRITICAL: Capture param info at subscription setup time for cell reuse protection
            let capturedParamName = self.param?.name ?? self.paramName
            let capturedParamType = self.sliderParamType
            let capturedDeviceId = deviceId
            let capturedParam = self.param // Capture param object reference
            
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
            commissioner.subscribeToSaturationValue(groupId: grpId, deviceId: deviceId) { saturation in
                // CRITICAL: Verify cell still shows the same param before updating (cell reuse protection)
                let currentParamType = self.sliderParamType
                let currentParamName = self.param?.name ?? self.paramName
                let currentDeviceId = self.deviceId
                let currentParam = self.param
                
                // STRICT CHECK: Must be saturation type, same device, and same param
                guard currentParamType == .saturation,
                      currentParamType == capturedParamType,
                      currentDeviceId == capturedDeviceId,
                      currentParamName == capturedParamName,
                      currentParam === capturedParam, // Identity check - same object reference
                      self.isSameParam(capturedParam: currentParam, capturedParamName: capturedParamName) else {
                    return
                }
                
                let finalSaturationValue = Int(CGFloat(saturation)/2.54)
                
                // CRITICAL: Only ignore if user is currently dragging
                // Since continuous updates are disabled for Matter, no cooldown needed
                if self.isUserDragging {
                    return
                }
                
                DispatchQueue.main.async {
                    // CRITICAL: Convert Matter value (0-254) to UI value (0-100) - matches original ESPMTRSaturationSliderTVC line 441
                    if let node = self.node, let id = self.deviceId {
                        // Store Matter value (0-254) in node - matches original
                        node.setMatterSaturationValue(saturation: saturation, deviceId: id)
                    }
                    // CRITICAL: Store UI value (0-100) in currentLevel - matches original ESPMTRSaturationSliderTVC line 445
                    self.currentLevel = finalSaturationValue
                    self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                }
            }
        }
    }
    
    // MARK: - Matter Saturation - Update
    func changeSaturation(value: Float) {
        var saturation = Int(value*2.54)
        if saturation == 0 {
            saturation = 1
        }
        
        if self.nodeConnectionStatus == .local, let groupId = self.nodeGroup?.groupID {
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
            if let _ = commissioner.sController {
                self.getColorCluster() { cluster in
                    if let cluster = cluster {
                        let params = MTRColorControlClusterMoveToSaturationParams()
                        params.saturation = NSNumber(value: saturation)
                        params.transitionTime = NSNumber(value: 0)
                        params.optionsMask = NSNumber(value: 0)
                        params.optionsOverride = NSNumber(value: 0)
                        cluster.moveToSaturation(with: params) { error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                                } else {
                                    if let node = self.node, let id = self.deviceId {
                                        // Store Matter value (0-254) in node - matches original
                                        node.setMatterSaturationValue(saturation: saturation, deviceId: id)
                                    }
                                    // CRITICAL: Store UI value (0-100) in currentLevel - matches original ESPMTRSaturationSliderTVC line 380
                                    self.currentLevel = Int(value)
                                    self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                                }
                            }
                        }
                    }
                }
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
                        // Store Matter value (0-254) in node - matches original
                        node.setMatterSaturationValue(saturation: saturation, deviceId: matterDeviceId)
                        // CRITICAL: Store UI value (0-100) in currentLevel - matches original ESPMTRSaturationSliderTVC line 405
                        self.currentLevel = Int(value)
                    } else {
                        self.setSaturationSliderValue(finalValue: Float(self.currentLevel))
                    }
                }
            }
        }
    }
    
    // MARK: - Matter Saturation - Cluster Access
    func getColorCluster(completionHandler: @escaping (MTRBaseClusterColorControl?) -> Void) {
        guard let groupId = self.nodeGroup?.groupID, let deviceId = self.deviceId else {
            completionHandler(nil)
            return
        }
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
        let (_, endpoint) = ESPMatterClusterUtil.shared.isColorControlServerSupported(groupId: groupId, deviceId: deviceId)
        if let endpoint = endpoint, let point = UInt16(endpoint), let controller = commissioner.sController {
            controller.getBaseDevice(deviceId, queue: commissioner.matterQueue) { device, _ in
                if let device = device, let colorControl = MTRBaseClusterColorControl(device: device, endpoint: point, queue: commissioner.matterQueue) {
                    completionHandler(colorControl)
                } else {
                    completionHandler(nil)
                }
            }
        } else {
            completionHandler(nil)
        }
    }
    
    // MARK: - Matter Saturation - UI Update
    func setSaturationSliderValue(finalValue: Float) {
        // Set value synchronously to avoid race condition with setSliderThumbUI() being called before value is set
        if self.slider.value != finalValue {
            self.slider.setValue(finalValue, animated: false) // Use false for initial setup to avoid animation
            self.setSliderThumbUI()
        }
    }
}

#endif

