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
//  DeviceViewController+TableView.swift
//  ESPRainmaker
//

import Foundation
import UIKit

#if ESPRainMakerMatter
@available(iOS 16.4, *)
extension DeviceViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < cellInfo.count {
            let value = cellInfo[indexPath.row]
            if [ESPMatterConstants.rainmakerController,
                ESPMatterConstants.borderRouter,
                ESPMatterConstants.measuredTemperature,
                ESPMatterConstants.updateMetadata].contains(value) {
                
                return 100.0
            } else if [ESPMatterConstants.levelControl,
                       ESPMatterConstants.colorControl,
                       ESPMatterConstants.saturationControl,
                       ESPMatterConstants.occupiedCoolingSetpoint,
                       ESPMatterConstants.occupiedHeatingSetpoint,
                       ESPMatterConstants.cctControl].contains(value) {
                
                if let node = self.node, let matterNodeId = matterNodeId, let deviceId = matterNodeId.hexToDecimal, let systemMode = node.getMatterSystemMode(deviceId: deviceId) {
                    
                    self.hideOCS = (systemMode == ESPMatterConstants.off || systemMode == ESPMatterConstants.heat)
                    self.hideOHS = (systemMode == ESPMatterConstants.off || systemMode == ESPMatterConstants.cool)
                    if (value == ESPMatterConstants.occupiedCoolingSetpoint && self.hideOCS) ||
                       (value == ESPMatterConstants.occupiedHeatingSetpoint && self.hideOHS) {
                        return 0.0
                    }
                }
                return 136.0
            } else if value == ESPMatterConstants.participantData {
                
                return 278.0
            } else if [ESPMatterConstants.matterDeviceName,
                       ESPMatterConstants.onOff,
                       ESPMatterConstants.controlSequenceOfOperation,
                       ESPMatterConstants.systemMode,
                       ESPMatterConstants.localTemperature].contains(value) {
                
                return 90.0
            }
        }
        return 0.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellInfo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let group = group, let groupId = group.groupID, let matterNodeId = matterNodeId, let _ = matterNodeId.hexToDecimal, let deviceId = matterNodeId.hexToDecimal, indexPath.row < cellInfo.count {
            let value = cellInfo[indexPath.row]
            if value == ESPMatterConstants.cctControl, let cctCell = getCCTControlCell(tableView, indexPath: indexPath, groupId: groupId, deviceId: deviceId) {
                return cctCell
            } else if value == ESPMatterConstants.deviceName || value == ESPMatterConstants.matterDeviceName {
                if let deviceNameCell = getDeviceNameCell(tableView, indexPath: indexPath, groupId: groupId, deviceId: deviceId) {
                    return deviceNameCell
                }
            } else if value == ESPMatterConstants.onOff {
                if let onOffCell = getOnOffCell(tableView, indexPath: indexPath, deviceId: deviceId) {
                    return onOffCell
                }
            } else if value == ESPMatterConstants.levelControl, let levelCell = getLevelControlCell(tableView, indexPath: indexPath, groupId: groupId, deviceId: deviceId) {
                return levelCell
            } else if value == ESPMatterConstants.colorControl {
                return getColorControlCell(tableView, indexPath: indexPath, deviceId: deviceId)
            } else if value == ESPMatterConstants.saturationControl, let saturationCell = getSaturationControlCell(tableView, indexPath: indexPath, groupId: groupId, deviceId: deviceId) {
                return saturationCell
            } else if value == ESPMatterConstants.rainmakerController {
                if let controllerCell = getControllerCell(tableView, indexPath: indexPath) {
                    return controllerCell
                }
            } else if value == ESPMatterConstants.borderRouter {
                if let borderRouterCell = getBorderRouterCell(tableView, indexPath: indexPath) {
                    return borderRouterCell
                }
            } else if value == ESPMatterConstants.participantData {
                if let participantCell = getParticipantDataCell(tableView, indexPath: indexPath, groupId: groupId, deviceId: deviceId) {
                    return participantCell
                }
            } else if value == ESPMatterConstants.localTemperature || value == ESPMatterConstants.measuredTemperature {
                if let temperatureCell = getTemperatureCell(tableView, indexPath: indexPath, value: value, deviceId: deviceId) {
                    return temperatureCell
                }
            } else if value == ESPMatterConstants.controlSequenceOfOperation {
                return getControlSequenceOpfOperationCell(tableView, indexPath: indexPath, deviceId: deviceId)
            } else if value == ESPMatterConstants.systemMode {
                return getSystemModeCell(tableView, indexPath: indexPath, deviceId: deviceId)
            } else if value == ESPMatterConstants.occupiedCoolingSetpoint, let ocsCell = getOccupiedCoolingSetpointCell(tableView, indexPath: indexPath, deviceId: deviceId) {
                return ocsCell
            } else if value == ESPMatterConstants.occupiedHeatingSetpoint, let ohsCell = getOccupiedHeatingSetpointCell(tableView, indexPath: indexPath, deviceId: deviceId) {
                return ohsCell
            }
        }
        return UITableViewCell()
    }
}

@available(iOS 16.4, *)
extension DeviceViewController: DeviceNameDelegate {
    
    // Adding height constraint for popup textfield
    func addHeightConstraint(textField: UITextField) {
        let heightConstraint = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        textField.addConstraint(heightConstraint)
        textField.font = UIFont(name: textField.font!.fontName, size: 18)
    }
    
    /// Get name param if present
    /// - Parameter node: node
    /// - Returns: name param
    func getNameParam(node: Node?) -> Param? {
        if let node = node, let devices = node.devices, devices.count > 0 {
            let device = devices[0]
            if let params = device.params {
                for param in params {
                    if let type = param.type, type == Constants.deviceNameParam {
                        return param
                    }
                }
            }
        }
        return nil
    }
    
    /// Edit name option pressed
    /// - Parameter rainmakerNode: rainmaker node
    /// - Parameter completion: completion handler
    func editNamePressed(rainmakerNode: Node?, completion: @escaping (String?) -> Void) {
        var input: UIAlertController!
        if let param = self.getNameParam(node: rainmakerNode), let attributeKey = param.name, let value = param.value as? String {
            input = UIAlertController(title: attributeKey, message: ESPMatterConstants.enterDeviceNameMsg, preferredStyle: .alert)
            input.addTextField { textField in
                textField.text = value
                self.addHeightConstraint(textField: textField)
            }
            input.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak input] _ in
                let valueTextField = input?.textFields![0]
                if let text = valueTextField?.text, text.count > 0, text.count <= 32 {
                    self.deviceName = valueTextField?.text
                    self.doneButtonAction(rainmakerNode: rainmakerNode, param: param, completion: completion)
                } else {
                    self.alertUser(title: ESPMatterConstants.failureTxt,
                                   message: ESPMatterConstants.enterValidDeviceNameMsg,
                                   buttonTitle: ESPMatterConstants.okTxt,
                                   callback: {})
                }
            }))
            input.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(input, animated: true, completion: nil)
        }
    }
    
    /// Done action button pressed
    /// - Parameters:
    ///   - rainmakerNode: rainmaker node
    ///   - param: name param
    func doneButtonAction(rainmakerNode: Node?, param: Param, completion: @escaping (String?) -> Void) {
        if let node = rainmakerNode, let nodeId = node.node_id, let devices = node.devices, devices.count > 0, let attributeKey = param.name, let name = self.deviceName {
            let device = devices[0]
            Utility.showLoader(message: "", view: self.view)
            DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: [device.name ?? "" : [attributeKey: name]], delegate: nil) { responseStatus in
                Utility.hideLoader(view: self.view)
                switch responseStatus {
                case .failure, .unknown:
                    Utility.hideLoader(view: self.view)
                    self.showErrorAlert(title: ESPMatterConstants.failureTxt, message: "Failed to update device name. Please try later.", buttonTitle: ESPMatterConstants.okTxt, callback: {})
                    return
                default:
                    break
                }
                param.value = name
                DispatchQueue.main.async {
                    self.topBarTitle.text = name
                    completion(name)
                }
            }
        }
    }
    
    /// Edit node label called
    /// - Parameters:
    ///   - rainmakerNode: rainmaker node
    ///   - nodeLabel: node label
    ///   - completion: completion handler
    func editNodeLabelPressed(rainmakerNode: Node?, nodeLabel: String, completion: @escaping (String?) -> Void) {
        if let node = self.rainmakerNode, let groupId = node.groupId, let deviceId = node.matter_node_id?.hexToDecimal {
            let input = UIAlertController(title: "Name", message: ESPMatterConstants.enterDeviceNameMsg, preferredStyle: .alert)
            input.addTextField { textField in
                textField.placeholder = "Enter device name"
                textField.text = node.matterDeviceName
                self.addHeightConstraint(textField: textField)
            }
            input.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak input] _ in
                let valueTextField = input?.textFields![0]
                if let text = valueTextField?.text, text.replacingOccurrences(of: " ", with: "").count > 0, text.count <= 32 {
                    let finalTxt = text.replacingOccurrences(of: " ", with: "")
                    if finalTxt.count > 0 {
                        self.deviceName = valueTextField?.text
                        self.updateMatterNodeLabel(nodeLabel: text, node: node, groupId: groupId, deviceId: deviceId) { matterDeviceName in
                            if let param = self.getNameParam(node: rainmakerNode) {
                                self.updateMTRRainmakerParamName(rainmakerNode: rainmakerNode, param: param) { _, _ in
                                    completion(matterDeviceName)
                                }
                            } else {
                                completion(matterDeviceName)
                            }
                        }
                        return
                    }
                }
                self.alertUser(title: ESPMatterConstants.failureTxt,
                               message: ESPMatterConstants.enterValidDeviceNameMsg,
                               buttonTitle: ESPMatterConstants.okTxt,
                               callback: {})
            }))
            input.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(input, animated: true, completion: nil)
        }
    }
    
    /// Update
    /// - Parameters:
    ///   - nodeLabel: node label
    ///   - node: node
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion handler
    func updateMatterNodeLabel(nodeLabel: String, node: Node, groupId: String, deviceId: UInt64, completion: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
        ESPNodeMetadataService.shared.setMatterDeviceName(node: node, deviceName: nodeLabel) { result, _ in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
            }
            if result {
                DispatchQueue.main.async {
                    self.topBarTitle.text = nodeLabel
                }
                completion(nodeLabel)
            } else {
                completion(nil)
            }
        }
    }
    
    /// Edit node label called
    /// - Parameters:
    ///   - rainmakerNode: rainmaker node
    ///   - nodeLabel: node label
    ///   - completion: completion handler
    func editMTRDeviceNamePressed(rainmakerNode: Node?, deviceName: String, completion: @escaping (String?) -> Void) {
        if let node = self.rainmakerNode, let groupId = node.groupId, let deviceId = node.matter_node_id?.hexToDecimal {
            let input = UIAlertController(title: "Name", message: ESPMatterConstants.enterDeviceNameMsg, preferredStyle: .alert)
            input.addTextField { textField in
                textField.placeholder = "Enter device name"
                textField.text = node.matterDeviceName
                self.addHeightConstraint(textField: textField)
            }
            input.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak input] _ in
                let valueTextField = input?.textFields![0]
                if let text = valueTextField?.text, text.replacingOccurrences(of: " ", with: "").count > 0, text.count <= 32 {
                    let finalTxt = text.replacingOccurrences(of: " ", with: "")
                    if finalTxt.count > 0 {
                        self.deviceName = valueTextField?.text
                        self.updateMatterNodeLabel(nodeLabel: text, node: node, groupId: groupId, deviceId: deviceId) { matterDeviceName in
                            if let param = self.getNameParam(node: rainmakerNode) {
                                self.updateMTRRainmakerParamName(rainmakerNode: rainmakerNode, param: param) { _, _ in
                                    completion(matterDeviceName)
                                }
                            } else {
                                completion(matterDeviceName)
                            }
                        }
                        return
                    }
                }
                self.alertUser(title: ESPMatterConstants.failureTxt,
                               message: ESPMatterConstants.enterValidDeviceNameMsg,
                               buttonTitle: ESPMatterConstants.okTxt,
                               callback: {})
            }))
            input.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(input, animated: true, completion: nil)
        }
    }
    
    /// Update the rainmaker param name for the matter+rainmaker device
    /// - Parameters:
    ///   - rainmakerNode: rainmkaer node
    ///   - param: rainmaker name param
    ///   - completion: completion
    func updateMTRRainmakerParamName(rainmakerNode: Node?, param: Param, completion: @escaping (ESPCloudResponseStatus?, String?) -> Void) {
        if let node = rainmakerNode, let nodeId = node.node_id, let devices = node.devices, devices.count > 0, let attributeKey = param.name, let name = self.deviceName {
            var device = devices[0]
            for dv in devices {
                if let name = param.value as? String, let deviceName = dv.name, name == deviceName {
                    device = dv
                    break
                }
            }
            DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: [device.name ?? "" : [attributeKey: name]], delegate: nil) { responseStatus in
                completion(responseStatus, name)
            }
        } else {
            completion(nil, self.deviceName)
        }
    }
}
#endif
