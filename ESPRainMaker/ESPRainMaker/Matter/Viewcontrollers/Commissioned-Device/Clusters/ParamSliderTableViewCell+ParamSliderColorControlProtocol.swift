// Copyright 2023 Espressif Systems
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
//  ParamSliderTableViewCell+ParamSliderColorControlProtocol.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import Foundation
import UIKit
import Matter

@available(iOS 16.4, *)
protocol ParamSliderColorControlProtocol {
    func getColorCluster(completionHandler: @escaping (MTRBaseClusterColorControl?) -> Void)
    func setupInitialHueValues()
    func getCurrentHueValue(completionHandler: @escaping (NSNumber?, Error?) -> Void)
    func setCurrentHueValue()
    func changeHue(toValue _: CGFloat)
    func subscribeToHueAttribute()
}

@available(iOS 16.4, *)
extension ParamSliderTableViewCell: ParamSliderColorControlProtocol {
    
    /// Get color cluster
    /// - Parameters:
    ///   - completionHandler: completion
    func getColorCluster(completionHandler: @escaping (MTRBaseClusterColorControl?) -> Void) {
        if let group = nodeGroup, let groupId = group.groupID, let id = deviceId, let controller = ESPMTRCommissioner.shared.sController {
            let (_, endpoint) = ESPMatterClusterUtil.shared.isColorControlServerSupported(groupId: groupId, deviceId: id)
            controller.getBaseDevice(id, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let endpoint = endpoint, let point = UInt16(endpoint), let colorControlCluster = MTRBaseClusterColorControl(device: device, endpoint: UInt16(truncating: NSNumber(value: point)), queue: ESPMTRCommissioner.shared.matterQueue) {
                    completionHandler(colorControlCluster)
                } else {
                    completionHandler(nil)
                }
            }
        } else {
            completionHandler(nil)
        }
    }
    
    /// Set initial hue values
    func setupInitialHueValues() {
        DispatchQueue.main.async {
            self.title.text = "Hue"
            self.hueSlider.minimumValue = 0.0
            self.hueSlider.maximumValue = 360.0
            self.hueSlider.hasRainbow = false
            self.hueSlider.setGradientVaryingHue(saturation: 1.0, brightness: 1.0)
            self.minLabel.text = "0"
            self.maxLabel.text = "360"
            if let node = self.node, let id = self.deviceId, let val = node.getMatterHueValue(deviceId: id) {
                self.hueSlider.value = CGFloat(val)
            } else {
                self.hueSlider.value = 0.0
            }
            self.minImage.image = nil
            self.maxImage.image = nil
        }
        if self.nodeConnectionStatus == .controller {
            if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let matterDeviceId = matterNodeId.hexToDecimal {
                if let currentHue = MatterControllerParser.shared.getCurrentHue(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                    let finalValue = (CGFloat(currentHue)*360.0)/254.0
                    if let node = self.node, let id = self.deviceId {
                        node.setMatterHueValue(hue: Int(finalValue), deviceId: id)
                    }
                    self.currentHueValue = finalValue
                    self.hueSlider.value = self.currentHueValue
                    DispatchQueue.main.async {
                        self.hueSlider.thumbColor = UIColor(hue: self.currentHueValue/360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                    }
                }
            }
        }
    }
    
    /// Get current hue value
    /// - Parameter completionHandler: completion
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
    
    /// Set current hue value
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
    
    /// Subscribe to hue attribute
    func subscribeToHueAttribute() {
        if let grpId = self.nodeGroup?.groupID, let deviceId = self.deviceId {
            ESPMTRCommissioner.shared.subscribeToHueValue(groupId: grpId, deviceId: deviceId) { hue in
                DispatchQueue.main.async {
                    let finalValue = (CGFloat(hue)*360.0)/254.0
                    if let node = self.node, let id = self.deviceId {
                        node.setMatterHueValue(hue: Int(finalValue), deviceId: id)
                    }
                    self.currentHueValue = finalValue
                    self.hueSlider.value = self.currentHueValue
                    self.hueSlider.thumbColor = UIColor(hue: self.currentHueValue/360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                }
            }
        }
    }
    
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
    
    /// Set hue via controller
    /// - Parameters:
    ///   - val: updated hue value
    ///   - finalHue: final hue to be set
    func changeHueViaController(val: CGFloat, finalHue: Int) {
        if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let matterDeviceId = matterNodeId.hexToDecimal {
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
}
#endif
