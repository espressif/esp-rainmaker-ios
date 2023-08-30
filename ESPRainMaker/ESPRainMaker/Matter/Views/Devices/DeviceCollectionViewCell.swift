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
    var node: ESPNodeDetails?
    var group: ESPNodeGroup?
    var rainmakerNode: Node?
    var endpointClusterId: [String: Any]?
    var connectionStatus: NodeConnectionStatus = .local

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        layer.shadowRadius = 0.5
        layer.shadowOpacity = 0.5
        layer.masksToBounds = false
        let onOffTap = UITapGestureRecognizer(target: self, action: #selector(toggle))
        self.onOffButton.addGestureRecognizer(onOffTap)
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
                    let deviceName = device.deviceName
                    DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: [deviceName: ["Power": !rainmakerNode.isPowerOn()]], delegate: self) { status in
                        if status == .success {
                            node.setMatterLightOnStatus(status: !rainmakerNode.isPowerOn(), deviceId: deviceId)
                            self.setToggleButtonUI(isLightOn: !rainmakerNode.isPowerOn())
                            self.rainmakerNode?.updateLightParam()
                        }
                    }
                }
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
                    if let status = node.isMatterLightOn(deviceId: deviceId) {
                        if status {
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
            if status == .local {
                self.overlay.isHidden = true
                self.isUserInteractionEnabled = true
                self.container.layer.backgroundColor = UIColor.white.withAlphaComponent(1.0).cgColor
            } else if status == .remote {
                self.overlay.isHidden = true
                self.isUserInteractionEnabled = true
                self.container.layer.backgroundColor = UIColor.white.withAlphaComponent(1.0).cgColor
            } else {
                if showLight {
                    self.onOffButton.image = UIImage(named: "switch_disabled")
                }
                self.isUserInteractionEnabled = true
                self.container.layer.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
            }
        }
    }
    
    /// display node connection status
    func displayConnectionStatus() {
        self.accessibilityButton.text = self.connectionStatus.description
    }
    
    /// Restart matter controller
    func restartController() {
        ESPMTRCommissioner.shared.shutDownController()
        ESPMTRCommissioner.shared.group = self.group
        if let group = self.group, let groupId = group.groupID, let userNOC = ESPMatterFabricDetails.shared.getUserNOCDetails(groupId: groupId) {
            ESPMTRCommissioner.shared.initializeMTRControllerWithUserNOC(matterFabricData: group, userNOCData: userNOC)
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
