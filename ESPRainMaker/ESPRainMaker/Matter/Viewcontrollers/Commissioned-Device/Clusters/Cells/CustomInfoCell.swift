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
//  CustomInfoCell.swift
//  ESPRainmaker
//

import UIKit

enum InfoType {
    case indoorTemperature
    case outdoorTemperature
}

protocol CustomInfoDelegate: AnyObject {
    func infoFetched()
}

class CustomInfoCell: UITableViewCell {
    
    static let reuseIdentifier = "CustomInfoCell"
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var value: UILabel!
    var deviceId: UInt64?
    weak var nodeGroup: ESPNodeGroup?
    var node: ESPNodeDetails?
    var infoType: InfoType = .indoorTemperature
    weak var customInfoDelegate: CustomInfoDelegate?
    @IBOutlet weak var container: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.container.layer.shadowOpacity = 0.18
        self.container.layer.shadowOffset = CGSize(width: 1, height: 2)
        self.container.layer.shadowRadius = 2
        self.container.layer.shadowColor = UIColor.black.cgColor
        self.container.layer.masksToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    /// Set initial indoor temperature
    func setupLocalTemperatureUI() {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *), let group = self.nodeGroup, let groupId = group.groupID, let deviceId = self.deviceId {
            if let localTemp = self.node?.getMatterLocalTemperatureValue(deviceId: deviceId) {
                DispatchQueue.main.async {
                    self.value.text = "\(localTemp) °C"
                }
            }
            self.subscribeToLocalTemperature()
        }
        #endif
    }
    
    /// Subscribe to temperature measurement
    func subscribeToLocalTemperature() {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *), let group = self.nodeGroup, let groupId = group.groupID, let deviceId = self.deviceId {
            ESPMTRCommissioner.shared.subscribeLocalTemperature(groupId: groupId, deviceId: deviceId) { localTemperature in
                if let localTemperature = localTemperature {
                    self.node?.setMatterLocalTemperatureValue(temperature: localTemperature, deviceId: deviceId)
                    DispatchQueue.main.async {
                        self.value.text = "\(localTemperature) °C"
                    }
                }
            }
        }
        #endif
    }
    
    /// Set initial indoor temperature
    func setupInitialControllerLocalTempUI() {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *) {
            if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = node.matterNodeID, let deviceId = self.deviceId {
                if let localTemp = MatterControllerParser.shared.getCurrentLocalTemperature(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                    node.setMatterLocalTemperatureValue(temperature: Int16(localTemp), deviceId: deviceId)
                    DispatchQueue.main.async {
                        self.value.text = "\(localTemp) °C"
                    }
                }
            }
        }
        #endif
    }
    
    /// Setup offline indoor temperature UI
    func setupOfflineLocalTemperatureUI() {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *), let deviceId = self.deviceId {
            if let localTemperature = self.node?.getMatterLocalTemperatureValue(deviceId: deviceId) {
                DispatchQueue.main.async {
                    self.value.text = "\(localTemperature) °C"
                }
            }
        }
        #endif
    }
    
    /// Set initial measured temperature
    func setupMeasuredTemperatureUI() {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *), let group = self.nodeGroup, let groupId = group.groupID, let deviceId = self.deviceId {
            if let measuredTemperature = self.node?.getMeasuredTemperatureValue(deviceId: deviceId) {
                DispatchQueue.main.async {
                    self.value.text = "\(measuredTemperature) °C"
                }
            }
            ESPMTRCommissioner.shared.readMeasuredTemperatureValue(groupId: groupId, deviceId: deviceId) { measuredTemperature in
                if let measuredTemperature = measuredTemperature {
                    self.node?.setMeasuredTemperatureValue(temperature: measuredTemperature, deviceId: deviceId)
                    DispatchQueue.main.async {
                        self.value.text = "\(measuredTemperature) °C"
                    }
                    self.subscribeToTemperatureMeasurement()
                }
            }
        }
        #endif
    }
    
    /// Subscribe to temperature measurement
    func subscribeToTemperatureMeasurement() {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *), let group = self.nodeGroup, let groupId = group.groupID, let deviceId = self.deviceId {
            ESPMTRCommissioner.shared.subscribeMeasuredTemperatureValue(groupId: groupId, deviceId: deviceId) { measuredTemperature in
                if let measuredTemperature = measuredTemperature {
                    self.node?.setMeasuredTemperatureValue(temperature: measuredTemperature, deviceId: deviceId)
                    DispatchQueue.main.async {
                        self.value.text = "\(measuredTemperature) °C"
                    }
                }
            }
        }
        #endif
    }
    
    /// Setup offline measured temperature UI
    func setupOfflineMeasuredTemperatureUI() {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *), let deviceId = self.deviceId {
            if let measuredTemperature = self.node?.getMeasuredTemperatureValue(deviceId: deviceId) {
                self.node?.setMeasuredTemperatureValue(temperature: measuredTemperature, deviceId: deviceId)
                DispatchQueue.main.async {
                    self.value.text = "\(measuredTemperature) °C"
                }
            }
        }
        #endif
    }
    
    /// Set initial indoor temperature
    func setupInitialControllerMeasuredTempUI() {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *) {
            if let node = self.node, let rainmakerNode = node.getRainmakerNode(), let controller = rainmakerNode.matterControllerNode, let controllerNodeId = controller.node_id, let matterNodeId = node.matterNodeID, let deviceId = self.deviceId {
                if let measuredTemp = MatterControllerParser.shared.getCurrentMeasuredTemperature(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
                    node.setMeasuredTemperatureValue(temperature: Int16(measuredTemp), deviceId: deviceId)
                    DispatchQueue.main.async {
                        self.value.text = "\(measuredTemp) °C"
                    }
                }
            }
        }
        #endif
    }
}
