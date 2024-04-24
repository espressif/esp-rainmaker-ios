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
//  DeviceCollectionViewCell.swift
//  ESPRainmaker
//

import UIKit
import Alamofire

#if ESPRainMakerMatter
/// Device collection view cell.
@available(iOS 16.4, *)
class DeviceCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier: String = "DeviceCollectionViewCell"
    @IBOutlet weak var overlay: UIView!
    @IBOutlet weak var container: UIView!
    @IBOutlet var deviceImage: UIImageView!
    @IBOutlet var deviceName: UILabel!
    @IBOutlet var onOffButton: UIImageView!
    @IBOutlet weak var accessibilityButton: UILabel!
    @IBOutlet weak var functionalOnOffButton: UIButton!
    
    var node: ESPNodeDetails?
    var group: ESPNodeGroup?
    var rainmakerNode: Node?
    var bindingEndpointClusterId: [String: Any]?
    var connectionStatus: NodeConnectionStatus = .local
    
    var session: Session!

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        layer.shadowRadius = 0.5
        layer.shadowOpacity = 0.5
        layer.masksToBounds = false
        let onOffTap = UITapGestureRecognizer(target: self, action: #selector(toggle))
        self.functionalOnOffButton.addGestureRecognizer(onOffTap)
    }
    
    /// Toggle button pressed
    @objc func toggle() {
        if let group = self.group, let groupId = group.groupID, let node = self.node, let deviceId = node.deviceId, let nodeId = node.nodeID {
            if self.connectionStatus == .local {
                self.restartController()
                if let status = node.isMatterLightOn(deviceId: deviceId) {
                    self.setToggleButtonUI(isLightOn: !status)
                } else {
                    node.setMatterLightOnStatus(status: true, deviceId: deviceId)
                    self.setToggleButtonUI(isLightOn: false)
                }
                ESPMTRCommissioner.shared.toggleSwitch(groupId: groupId, deviceId: deviceId) { result in
                    if result {
                        if let status = node.isMatterLightOn(deviceId: deviceId) {
                            node.setMatterLightOnStatus(status: !status, deviceId: deviceId)
                        }
                        ESPMTRCommissioner.shared.isLightOn(groupId: groupId, deviceId: deviceId) { result in
                            node.setMatterLightOnStatus(status: result, deviceId: deviceId)
                            self.setToggleButtonUI(isLightOn: result)
                        }
                    } else {
                        if let status = node.isMatterLightOn(deviceId: deviceId) {
                            self.setToggleButtonUI(isLightOn: status)
                        }
                    }
                }
            } else if self.connectionStatus == .remote {
                if let rainmakerNode = self.rainmakerNode, let devices = rainmakerNode.devices, let device = devices.first {
                    DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: [device.name ?? "": ["Power": !rainmakerNode.isPowerOn()]], delegate: self) { status in
                        if status == .success {
                            node.setMatterLightOnStatus(status: !rainmakerNode.isPowerOn(), deviceId: deviceId)
                            self.setToggleButtonUI(isLightOn: !rainmakerNode.isPowerOn())
                            self.rainmakerNode?.updateLightParam()
                        }
                    }
                }
            } else if self.connectionStatus == .controller {
                if let rainmakerNode = self.rainmakerNode, let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id {
                    var endpoint = "0x1"
                    if let endpointId = MatterControllerParser.shared.getOnOffEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                        endpoint = endpointId
                    }
                    if let isOn = node.isMatterLightOn(deviceId: deviceId), isOn {
                        ESPControllerAPIManager.shared.callOffAPI(rainmakerNode: rainmakerNode,
                                                                    controllerNodeId: controllerNodeId,
                                                                    matterNodeId: matterNodeId,
                                                                    endpoint: endpoint) { result in
                            self.setToggleUI(node: node, deviceId: deviceId, result: result, currentStatus: false)
                        }
                    } else {
                        ESPControllerAPIManager.shared.callOnAPI(rainmakerNode: rainmakerNode,
                                                                    controllerNodeId: controllerNodeId,
                                                                    matterNodeId: matterNodeId,
                                                                    endpoint: endpoint) { result in
                            self.setToggleUI(node: node, deviceId: deviceId, result: result, currentStatus: true)
                        }
                    }
                }
            }
        }
    }
    
    /// Set toggle UI
    /// - Parameters:
    ///   - node: node
    ///   - deviceId: matter device id
    ///   - result: result
    ///   - currentStatus: current status
    func setToggleUI(node: ESPNodeDetails, deviceId: UInt64, result: Bool, currentStatus: Bool) {
        if result {
            node.setMatterLightOnStatus(status: currentStatus, deviceId: deviceId)
            self.setToggleButtonUI(isLightOn: currentStatus)
        } else {
            if let val = node.isMatterLightOn(deviceId: deviceId) {
                self.setToggleButtonUI(isLightOn: val)
            }
        }
    }
    
    /// Set UI according to connection status
    /// - Parameter status: status
    func setConnectionStatusUI(status: NodeConnectionStatus) {
        var showLight = false
        self.connectionStatus = status
        self.accessibilityButton.text = status.description + "  "
        if let group = self.group, let groupId = group.groupID, let node = self.node, let deviceId = node.deviceId {
            if ESPMatterClusterUtil.shared.isOnOffServerSupported(groupId: groupId, deviceId: deviceId).0 {
                DispatchQueue.main.async {
                    showLight = true
                    self.onOffButton.isHidden = false
                    if let lightOnOffStatus = node.isMatterLightOn(deviceId: deviceId) {
                        if lightOnOffStatus {
                            self.onOffButton.image = UIImage(named: "switch_on")
                        } else {
                            self.onOffButton.image = UIImage(named: "switch_off")
                        }
                    } else {
                        node.setMatterLightOnStatus(status: true, deviceId: deviceId)
                        self.onOffButton.image = UIImage(named: "switch_on")
                    }
                }
            }
        } else {
            self.onOffButton.isHidden = true
        }
        DispatchQueue.main.async {
            if status == .local || status == .remote || status == .controller {
                self.overlay.isHidden = true
                self.isUserInteractionEnabled = true
                self.container.layer.backgroundColor = UIColor.white.withAlphaComponent(1.0).cgColor
                if status != .remote {
                    self.setToggleStatusFromControllerConfig()
                }
            } else {
                if showLight {
                    self.onOffButton.image = UIImage(named: "switch_disabled")
                }
                self.isUserInteractionEnabled = true
                self.container.layer.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
            }
        }
    }
    
    func setToggleStatusFromControllerConfig() {
        if let node = self.rainmakerNode, let controllerNode = node.matterControllerNode, let controllerNodeId = controllerNode.node_id, let matterNodeId = node.matter_node_id, let onOffStatus = MatterControllerParser.shared.getOnOffValue(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
            if onOffStatus {
                self.onOffButton.image = UIImage(named: "switch_on")
            } else {
                self.onOffButton.image = UIImage(named: "switch_off")
            }
        }
    }
    
    /// display node connection status
    func displayConnectionStatus() {
        self.accessibilityButton.text = self.connectionStatus.description
    }
    
    /// Restart matter controller
    func restartController() {
        if let group = self.group, let groupId = group.groupID, let userNOC = ESPMatterFabricDetails.shared.getUserNOCDetails(groupId: groupId) {
            if let grp = ESPMTRCommissioner.shared.group, let grpId = grp.groupID, grpId != groupId {
                ESPMTRCommissioner.shared.shutDownController()
            }
            if ESPMTRCommissioner.shared.sController == nil {
                ESPMTRCommissioner.shared.group = self.group
                ESPMTRCommissioner.shared.initializeMTRControllerWithUserNOC(matterFabricData: group, userNOCData: userNOC)
            }
        }
    }
    
    /// Toggle button
    /// - Parameter isLightOn: light on/off status
    func setToggleButtonUI(isLightOn: Bool) {
        DispatchQueue.main.async {
            if isLightOn {
                self.onOffButton.image = UIImage(named: "switch_on")
            } else {
                self.onOffButton.image = UIImage(named: "switch_off")
            }
        }
    }
}

@available(iOS 16.4, *)
extension DeviceCollectionViewCell: ParamUpdateProtocol {
    
    /// param update failed
    func failureInUpdatingParam() {}
}
#endif
