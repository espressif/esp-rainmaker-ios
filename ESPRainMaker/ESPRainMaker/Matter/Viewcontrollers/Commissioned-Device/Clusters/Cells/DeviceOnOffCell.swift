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
//  DeviceOnOffCell.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import UIKit

public enum OnOffState {
    case on
    case off
    case toggle
}

protocol OnOffDelegate {
    func actionTaken(dId: UInt64?, endpointId: UInt16?, state: OnOffState)
}

@available(iOS 16.4, *)
class DeviceOnOffCell: UITableViewCell {
    
    static let reuseIdentifier = "DeviceOnOffCell"
    @IBOutlet weak var onOffStatus: UILabel!
    @IBOutlet var toggleSwitch: UISwitch!
    @IBOutlet weak var container: UIView!
    weak var group: ESPNodeGroup?
    var node: ESPNodeDetails?
    var deviceId: UInt64?
    var endpointId: UInt16?
    var delegate: OnOffDelegate?
    var nodeConnectionStatus: NodeConnectionStatus = .local
    
    func setGroup(group: ESPNodeGroup?) {
        self.group = group
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        container.layer.shadowOpacity = 0.18
        container.layer.shadowOffset = CGSize(width: 1, height: 2)
        container.layer.shadowRadius = 2
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.masksToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    /// Toggle button pressed
    /// - Parameter sender: sender
    @IBAction func toggleButtonPressed(sender: UISwitch) {
        self.onOffStatus.text = sender.isOn ? ESPMatterConstants.onTxt : ESPMatterConstants.offTxt
        if self.nodeConnectionStatus == .local {
            if let group = self.group, let groupId = group.groupID, let deviceId = self.deviceId {
                ESPMTRCommissioner.shared.toggleSwitch(groupId: groupId, deviceId: deviceId) { result in
                    if !result {
                        DispatchQueue.main.async {
                            self.onOffStatus.text = !sender.isOn ? ESPMatterConstants.onTxt : ESPMatterConstants.offTxt
                            self.toggleSwitch.setOn(!sender.isOn, animated: true)
                        }
                    } else {
                        if let status = self.node?.isMatterLightOn(deviceId: deviceId) {
                            self.node?.setMatterLightOnStatus(status: !status, deviceId: deviceId)
                        } else {
                            ESPMTRCommissioner.shared.isLightOn(groupId: groupId, deviceId: deviceId) { isLightOn in
                                self.node?.setMatterLightOnStatus(status: isLightOn, deviceId: deviceId)
                            }
                        }
                    }
                }
            }
        } else if self.nodeConnectionStatus == .controller {
            if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let matterDeviceId = matterNodeId.hexToDecimal {
                var endpoint = "0x1"
                if let endpointId = MatterControllerParser.shared.getOnOffEndpointId(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                    endpoint = endpointId
                }
                if let isOn = node.isMatterLightOn(deviceId: matterDeviceId), isOn {
                    ESPControllerAPIManager.shared.callOffAPI(rainmakerNode: rainmakerNode,
                                                                controllerNodeId: controllerNodeId,
                                                                matterNodeId: matterNodeId,
                                                                endpoint: endpoint) { result in
                        self.setToggleUI(node: node, deviceId: matterDeviceId, result: result, currentStatus: false)
                    }
                } else {
                    ESPControllerAPIManager.shared.callOnAPI(rainmakerNode: rainmakerNode,
                                                                controllerNodeId: controllerNodeId,
                                                                matterNodeId: matterNodeId,
                                                                endpoint: endpoint) { result in
                        self.setToggleUI(node: node, deviceId: matterDeviceId, result: result, currentStatus: true)
                    }
                }
            }
        }
    }
    
    /// Set toggle button UI
    /// - Parameters:
    ///   - node: node
    ///   - deviceId: device id
    ///   - result: result
    ///   - currentStatus: current status
    func setToggleUI(node: ESPNodeDetails, deviceId: UInt64, result: Bool, currentStatus: Bool) {
        if result {
            node.setMatterLightOnStatus(status: currentStatus, deviceId: deviceId)
        } else {
            if let val = node.isMatterLightOn(deviceId: deviceId) {
                self.toggleSwitch.setOn(val, animated: true)
            }
        }
    }

    
    /// Setup initial UI
    func setupInitialUI() {
        if self.nodeConnectionStatus == .local {
            if let group = self.group, let groupId = group.groupID, let deviceId = self.deviceId {
                if let node = self.node {
                    if let status = node.isMatterLightOn(deviceId: deviceId) {
                        DispatchQueue.main.async {
                            self.toggleSwitch.setOn(status, animated: true)
                            self.onOffStatus.text = status ? ESPMatterConstants.onTxt : ESPMatterConstants.offTxt
                        }
                    } else {
                        ESPMTRCommissioner.shared.isLightOn(groupId: groupId, deviceId: deviceId) { isLightOn in
                            DispatchQueue.main.async {
                                node.setMatterLightOnStatus(status: isLightOn, deviceId: deviceId)
                                self.toggleSwitch.setOn(isLightOn, animated: true)
                                self.onOffStatus.text = isLightOn ? ESPMatterConstants.onTxt : ESPMatterConstants.offTxt
                            }
                        }
                    }
                }
            }
            self.subscribeToOnOffAttribute()
        } else if self.nodeConnectionStatus == .controller {
            if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = rainmakerNode.matter_node_id, let matterDeviceId = matterNodeId.hexToDecimal {
                if let value = MatterControllerParser.shared.getOnOffValue(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                    node.setMatterLightOnStatus(status: value, deviceId: matterDeviceId)
                    DispatchQueue.main.async {
                        self.toggleSwitch.setOn(value, animated: true)
                        self.onOffStatus.text = value ? ESPMatterConstants.onTxt : ESPMatterConstants.offTxt
                    }
                } else if let value = node.isMatterLightOn(deviceId: matterDeviceId) {
                    DispatchQueue.main.async {
                        self.toggleSwitch.setOn(value, animated: true)
                        self.onOffStatus.text = value ? ESPMatterConstants.onTxt : ESPMatterConstants.offTxt
                    }
                }
            }
        }
    }
    
    /// Setup offline UI
    func setupOfflineUI(deviceId: UInt64) {
        DispatchQueue.main.async {
            if let node = self.node, let status = node.isMatterLightOn(deviceId: deviceId) {
                self.toggleSwitch.setOn(status, animated: true)
                self.onOffStatus.text = status ? ESPMatterConstants.onTxt : ESPMatterConstants.offTxt
            } else {
                self.toggleSwitch.setOn(false, animated: true)
                self.onOffStatus.text = ESPMatterConstants.offTxt
            }
        }
    }
    
    /// Subscribe to on/off attribute value
    func subscribeToOnOffAttribute() {
        if let group = self.group, let groupId = group.groupID, let deviceId = self.deviceId {
            ESPMTRCommissioner.shared.subscribeToOnOffValue(groupId: groupId, deviceId: deviceId) { status in
                DispatchQueue.main.async {
                    self.node?.setMatterLightOnStatus(status: status, deviceId: deviceId)
                    self.onOffStatus.text = status ? ESPMatterConstants.onTxt : ESPMatterConstants.offTxt
                    self.toggleSwitch.setOn(status, animated: true)
                }
            }
        }
    }
}
#endif
