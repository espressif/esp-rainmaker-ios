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
//  ParamHueSliderCell+Matter.swift
//  ESPRainMaker
//
//  Component: Matter Color Control Cluster - Hue
//  Handles: Matter hue subscriptions, updates, initialization

#if ESPRainMakerMatter
import UIKit
import Matter

@available(iOS 16.4, *)
extension ParamHueSliderCell {
    
    // MARK: - Matter Hue - Constraint Setup
    /// Set constraint constants for Matter devices (10pt top, -10pt bottom)
    func setupMatterConstraints() {
        DispatchQueue.main.async {
            self.backViewTopSpaceConstraint?.constant = 10.0
            self.backViewBottomSpaceConstraint?.constant = -10.0
        }
    }
    
    // MARK: - Matter Hue - Update
    func updateParamMatter(value: Int, isContinuous: Bool) {
        // Matter hue update is handled via changeHue() method which is called from hueSliderTouchUp
        // This method is kept for compatibility but the actual implementation is in changeHue()
        if isContinuous {
            group.leave()
        }
    }
    
    // MARK: - Matter Hue - Change Hue (matches original implementation)
    /// Change hue
    /// - Parameter val: hue value
    func changeHue(toValue val: CGFloat) {
        var finalHue = Int(val*(254.0/360.0))
        if finalHue == 0 {
            finalHue = 1
        }
        if self.nodeConnectionStatus == .controller {
            self.changeHueViaController(val: val, finalHue: finalHue)
            return
        }
        self.changeHueViaMatter(val: val, finalHue: finalHue)
    }
    
    // MARK: - Matter Hue - Change Hue Via Matter
    /// Change hue via matter
    /// - Parameters:
    ///   - val: new hue
    ///   - finalHue: final hue value
    func changeHueViaMatter(val: CGFloat, finalHue: Int) {
        self.getColorCluster() { cluster in
            if let cluster = cluster {
                let params = MTRColorControlClusterMoveToHueParams()
                params.hue = NSNumber(value: finalHue)
                if CGFloat(finalHue) < self.currentHueValue {
                    params.direction = NSNumber(value: 0)
                } else {
                    params.direction = NSNumber(value: 1)
                }
                params.optionsMask = NSNumber(value: 0)
                params.optionsOverride = NSNumber(value: 0)
                params.transitionTime = NSNumber(value: 1)
                cluster.moveToHue(with: params) { error in
                    if let _ = error {
                        DispatchQueue.main.async {
                            self.hueSlider.value = self.currentHueValue
                            self.paramChipDelegate?.alertUserError(message: "Failed to update hue!")
                            self.hueSlider.thumbColor = UIColor(hue: self.currentHueValue/360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                        }
                    } else {
                        if let node = self.node, let id = self.deviceId {
                            node.setMatterHueValue(hue: Int(val), deviceId: id)
                        }
                        self.currentHueValue = val
                        DispatchQueue.main.async {
                            self.hueSlider.thumbColor = UIColor(hue: self.currentHueValue/360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Matter Hue - Change Hue Via Controller
    /// Set hue via controller
    /// - Parameters:
    ///   - val: updated hue value
    ///   - finalHue: final hue to be set
    func changeHueViaController(val: CGFloat, finalHue: Int) {
        if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id {
            var endpoint = "0x1"
            if let endpointId = MatterControllerParser.shared.getHueEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                endpoint = endpointId
            }
            ESPControllerAPIManager.shared.callHueAPI(rainmakerNode: rainmakerNode,
                                                      controllerNodeId: controllerNodeId,
                                                      matterNodeId: matterNodeId,
                                                      endpoint: endpoint,
                                                      hue: "\(finalHue)") { result in
                if result {
                    if let node = self.node, let id = self.deviceId {
                        node.setMatterHueValue(hue: Int(val), deviceId: id)
                    }
                    self.currentHueValue = val
                    DispatchQueue.main.async {
                        self.hueSlider.thumbColor = UIColor(hue: self.currentHueValue/360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.hueSlider.value = self.currentHueValue
                        self.paramChipDelegate?.alertUserError(message: "Failed to update hue!")
                        self.hueSlider.thumbColor = UIColor(hue: self.currentHueValue/360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                    }
                }
            }
        }
    }
    
    // MARK: - Matter Hue - Subscription
    // NOTE: This method is kept for backward compatibility but subscriptions are now handled by view controller
    func subscribeToHueAttribute() {
        // Subscriptions are now handled by DeviceViewController+MatterSubscriptions.swift
        // This method is kept to avoid breaking existing code but does nothing
    }
    
    // MARK: - Matter Hue - Read Current Value
    func getCurrentHueValue(completionHandler: @escaping (NSNumber?, Error?) -> Void) {
        self.getColorCluster() { controller in
            if let controller = controller {
                controller.readAttributeCurrentHue() { hue, error in
                    completionHandler(hue, error)
                }
            } else {
                completionHandler(nil, nil)
            }
        }
    }
    
    // MARK: - Matter Hue - Set Current Value (reads from Matter and updates UI)
    func setCurrentHueValue() {
        self.getCurrentHueValue() { hue, error in
            DispatchQueue.main.async {
                if let hue = hue {
                    if let node = self.node, let id = self.deviceId {
                        node.setMatterHueValue(hue: Int((hue.floatValue*360.0)/255.0), deviceId: id)
                    }
                    self.currentHueValue = CGFloat((hue.floatValue*360.0)/255.0)
                    self.hueSlider.value = self.currentHueValue
                    self.hueSlider.thumbColor = UIColor(hue: self.currentHueValue/360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                }
            }
        }
    }
    
    // MARK: - Matter Hue - Get Color Cluster
    func getColorCluster(completionHandler: @escaping (MTRBaseClusterColorControl?) -> Void) {
        if let group = nodeGroup, let groupId = group.groupID, let id = deviceId {
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
            if let controller = commissioner.sController {
                let (_, endpoint) = ESPMatterClusterUtil.shared.isColorControlServerSupported(groupId: groupId, deviceId: id)
                controller.getBaseDevice(id, queue: commissioner.matterQueue) { device, _ in
                    if let device = device, let endpoint = endpoint, let point = UInt16(endpoint), let colorControlCluster = MTRBaseClusterColorControl(device: device, endpoint: UInt16(truncating: NSNumber(value: point)), queue: commissioner.matterQueue) {
                        completionHandler(colorControlCluster)
                    } else {
                        completionHandler(nil)
                    }
                }
            } else {
                completionHandler(nil)
            }
        } else {
            completionHandler(nil)
        }
    }
}

#endif

