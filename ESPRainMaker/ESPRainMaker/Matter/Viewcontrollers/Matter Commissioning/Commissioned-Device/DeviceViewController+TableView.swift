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
            if [ESPMatterConstants.deviceName, ESPMatterConstants.onOff, ESPMatterConstants.rainmakerController, ESPMatterConstants.nodeLabel, ESPMatterConstants.localTemperature, ESPMatterConstants.borderRouter, ESPMatterConstants.measuredTemperature].contains(value) {
                return 100.0
            } else if [ESPMatterConstants.delete].contains(value) {
                return 75.0
            } else if [ESPMatterConstants.levelControl, ESPMatterConstants.colorControl, ESPMatterConstants.saturationControl, ESPMatterConstants.occupiedCoolingSetpoint].contains(value) {
                return 126.0
            } else if value == ESPMatterConstants.participantData {
                return 278.0
            } else if [ESPMatterConstants.controlSequenceOfOperation, ESPMatterConstants.systemMode].contains(value) {
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
        if cellInfo.count == 1, indexPath.row < cellInfo.count {
            let value = cellInfo[indexPath.row]
            if value == ESPMatterConstants.delete, let cell = tableView.dequeueReusableCell(withIdentifier: RemoveDeviceCell.reuseIdentifier, for: indexPath) as? RemoveDeviceCell {
                cell.delegate = self
                self.setAutoresizingMask(cell)
                cell.isUserInteractionEnabled = !self.isDeviceOffline
                return cell
            }
        }
        if let group = group, let groupId = group.groupID, let matterNodeId = matterNodeId, let _ = matterNodeId.hexToDecimal, let deviceId = matterNodeId.hexToDecimal, indexPath.row < cellInfo.count {
            let value = cellInfo[indexPath.row]
            if value == ESPMatterConstants.deviceName || value == ESPMatterConstants.nodeLabel {
                if let cell = tableView.dequeueReusableCell(withIdentifier: DeviceInfoCell.reuseIdentifier, for: indexPath) as? DeviceInfoCell {
                    cell.delegate = self
                    cell.rainmakerNode = self.rainmakerNode
                    if let node = self.rainmakerNode, node.isRainmaker, let name = node.rainmakerDeviceName {
                        cell.deviceInfo = .deviceName
                        cell.deviceName.text = name
                    } else {
                        cell.deviceInfo = .nodeLabel
                        cell.propertyName.text = "Name"
                        if let name = self.fabricDetails.getNodeLabel(groupId: groupId, deviceId: deviceId) {
                            cell.deviceName.text = name
                        }
                    }
                    cell.isUserInteractionEnabled = !self.isDeviceOffline
                    return cell
                }
            } else if value == ESPMatterConstants.onOff {
                if let cell = tableView.dequeueReusableCell(withIdentifier: DeviceOnOffCell.reuseIdentifier, for: indexPath) as? DeviceOnOffCell {
                    cell.nodeConnectionStatus = self.nodeConnectionStatus
                    cell.node = self.node
                    cell.deviceId = deviceId
                    cell.delegate = self
                    cell.group = self.group
                    self.setAutoresizingMask(cell)
                    if self.isDeviceOffline {
                        cell.setupOfflineUI(deviceId: deviceId)
                    } else {
                        cell.setupInitialUI()
                    }
                    cell.isUserInteractionEnabled = !self.isDeviceOffline
                    return cell
                }
            } else if value == ESPMatterConstants.levelControl {
                let sliderCell = tableView.dequeueReusableCell(withIdentifier: SliderTableViewCell.reuseIdentifier, for: indexPath) as! SliderTableViewCell
                object_setClass(sliderCell, ParamSliderTableViewCell.self)
                let cell = sliderCell as! ParamSliderTableViewCell
                cell.nodeConnectionStatus = self.nodeConnectionStatus
                cell.node = self.node
                cell.isRainmaker = false
                cell.sliderParamType = .brightness
                cell.nodeGroup = self.group
                cell.deviceId = deviceId
                cell.hueSlider.isHidden = true
                cell.slider.isHidden = false
                cell.paramChipDelegate = self
                self.setAutoresizingMask(cell)
                if self.isDeviceOffline {
                    cell.setupOfflineUI()
                } else {
                    cell.getCurrentLevelValues(groupId: groupId, deviceId: deviceId)
                }
                cell.isUserInteractionEnabled = !self.isDeviceOffline
                return cell
            } else if value == ESPMatterConstants.colorControl {
                let sliderCell = tableView.dequeueReusableCell(withIdentifier: SliderTableViewCell.reuseIdentifier, for: indexPath) as! SliderTableViewCell
                object_setClass(sliderCell, ParamSliderTableViewCell.self)
                let cell = sliderCell as! ParamSliderTableViewCell
                cell.nodeConnectionStatus = self.nodeConnectionStatus
                cell.node = self.node
                cell.isRainmaker = false
                cell.nodeGroup = self.group
                cell.deviceId = deviceId
                cell.slider.isHidden = true
                cell.hueSlider.isHidden = false
                cell.hueSlider.thumbColor = UIColor(hue: 0.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                cell.paramChipDelegate = self
                self.setAutoresizingMask(cell)
                cell.setupInitialHueValues()
                if !self.isDeviceOffline {
                    cell.subscribeToHueAttribute()
                }
                cell.isUserInteractionEnabled = !self.isDeviceOffline
                return cell
            } else if value == ESPMatterConstants.saturationControl {
                let sliderCell = tableView.dequeueReusableCell(withIdentifier: SliderTableViewCell.reuseIdentifier, for: indexPath) as! SliderTableViewCell
                object_setClass(sliderCell, ParamSliderTableViewCell.self)
                let cell = sliderCell as! ParamSliderTableViewCell
                cell.nodeConnectionStatus = self.nodeConnectionStatus
                cell.node = self.node
                cell.isRainmaker = false
                cell.sliderParamType = .saturation
                cell.nodeGroup = self.group
                cell.deviceId = deviceId
                cell.hueSlider.isHidden = true
                cell.slider.isHidden = false
                cell.paramChipDelegate = self
                self.setAutoresizingMask(cell)
                if self.isDeviceOffline {
                    cell.setupOfflineUI()
                } else {
                    cell.getCurrentSaturationValue(groupId: groupId, deviceId: deviceId)
                }
                cell.isUserInteractionEnabled = !self.isDeviceOffline
                return cell
            } else if value == ESPMatterConstants.delete {
                if let cell = tableView.dequeueReusableCell(withIdentifier: RemoveDeviceCell.reuseIdentifier, for: indexPath) as? RemoveDeviceCell {
                    cell.delegate = self
                    self.setAutoresizingMask(cell)
                    cell.isUserInteractionEnabled = !self.isDeviceOffline
                    return cell
                }
            } else if value == ESPMatterConstants.openCW {
                if let cell = tableView.dequeueReusableCell(withIdentifier: OpenCommissioningWindowCell.reuseIdentifier, for: indexPath) as? OpenCommissioningWindowCell {
                    cell.delegate = self
                    self.setAutoresizingMask(cell)
                    cell.isUserInteractionEnabled = !self.isDeviceOffline
                    return cell
                }
            } else if value == ESPMatterConstants.rainmakerController {
                if let cell = tableView.dequeueReusableCell(withIdentifier: CustomActionCell.reuseIdentifier, for: indexPath) as? CustomActionCell {
                    cell.delegate = self
                    cell.setupWorkflow(workflow: .launchController)
                    self.setAutoresizingMask(cell)
                    cell.isUserInteractionEnabled = !self.isDeviceOffline
                    return cell
                }
            } else if value == ESPMatterConstants.borderRouter {
                if let cell = tableView.dequeueReusableCell(withIdentifier: CustomActionCell.reuseIdentifier, for: indexPath) as? CustomActionCell {
                    cell.delegate = self
                    cell.setupWorkflow(workflow: .updateThreadDataset)
                    self.setAutoresizingMask(cell)
                    cell.isUserInteractionEnabled = !self.isDeviceOffline
                    return cell
                }
            } else if value == ESPMatterConstants.participantData {
                if let cell = tableView.dequeueReusableCell(withIdentifier: ParticipantDataCell.reuseIdentifier, for: indexPath) as? ParticipantDataCell {
                    cell.delegate = self
                    if let data = self.fabricDetails.fetchParticipantData(groupId: groupId, deviceId: deviceId) {
                        cell.setupUI(data: data)
                    }
                    self.setAutoresizingMask(cell)
                    cell.isUserInteractionEnabled = !self.isDeviceOffline
                    return cell
                }
            } else if value == ESPMatterConstants.localTemperature || value == ESPMatterConstants.measuredTemperature {
                if let cell = tableView.dequeueReusableCell(withIdentifier: CustomInfoCell.reuseIdentifier, for: indexPath) as? CustomInfoCell {
                    cell.node = self.node
                    cell.deviceId = deviceId
                    cell.nodeGroup = self.group
                    if value == ESPMatterConstants.localTemperature {
                        cell.type.text = "Local Temperature"
                        if self.isDeviceOffline {
                            cell.setupOfflineLocalTemperatureUI()
                        } else {
                            if self.nodeConnectionStatus == .controller {
                                cell.setupInitialControllerLocalTempUI()
                            } else {
                                cell.setupLocalTemperatureUI()
                            }
                        }
                    } else {
                        cell.type.text = "Measured Temperature"
                        if self.isDeviceOffline {
                            cell.setupOfflineMeasuredTemperatureUI()
                        } else {
                            if self.nodeConnectionStatus == .controller {
                                cell.setupInitialControllerMeasuredTempUI()
                            } else {
                                cell.setupMeasuredTemperatureUI()
                            }
                        }
                    }
                    self.setAutoresizingMask(cell)
                    cell.isUserInteractionEnabled = !self.isDeviceOffline
                    return cell
                }
            } else if value == ESPMatterConstants.occupiedCoolingSetpoint {
                let sliderCell = tableView.dequeueReusableCell(withIdentifier: SliderTableViewCell.reuseIdentifier, for: indexPath) as! SliderTableViewCell
                object_setClass(sliderCell, ParamSliderTableViewCell.self)
                let cell = sliderCell as! ParamSliderTableViewCell
                cell.title.text = "Occupied Cooling Setpoint"
                cell.node = self.node
                cell.isRainmaker = false
                cell.sliderParamType = .airConditioner
                cell.nodeGroup = self.group
                cell.deviceId = deviceId
                cell.hueSlider.isHidden = true
                cell.slider.isHidden = false
                cell.paramChipDelegate = self
                self.setAutoresizingMask(cell)
                if self.nodeConnectionStatus == .controller {
                    cell.setupInitialControllerOCSValues(isDeviceOffline: self.isDeviceOffline)
                } else {
                    cell.setupInitialCoolingSetpointValues2(isDeviceOffline: self.isDeviceOffline)
                }
                cell.isUserInteractionEnabled = !self.isDeviceOffline
                return cell
            } else if value == ESPMatterConstants.controlSequenceOfOperation {
                let dropDownCell = tableView.dequeueReusableCell(withIdentifier: DropDownTableViewCell.reuseIdentifier, for: indexPath) as! DropDownTableViewCell
                object_setClass(dropDownCell, ParamDropDownTableViewCell.self)
                let cell = dropDownCell as! ParamDropDownTableViewCell
                cell.topViewHeightConstraint.constant = 30.0
                cell.matterNode = self.node
                cell.datasource = [ESPMatterConstants.cool]
                cell.type = .controlSequenceOfOperation
                cell.isRainmaker = false
                cell.deviceId = deviceId
                cell.nodeGroup = self.group
                cell.paramChipDelegate = self
                cell.controlName.text = ESPMatterConstants.controlSequence
                cell.setInitialControlSequenceOfOperation()
                cell.acParamDelegate = self
                cell.isUserInteractionEnabled = !self.isDeviceOffline
                return cell
            } else if value == ESPMatterConstants.systemMode {
                let dropDownCell = tableView.dequeueReusableCell(withIdentifier: DropDownTableViewCell.reuseIdentifier, for: indexPath) as! DropDownTableViewCell
                object_setClass(dropDownCell, ParamDropDownTableViewCell.self)
                let cell = dropDownCell as! ParamDropDownTableViewCell
                cell.topViewHeightConstraint.constant = 30.0
                cell.matterNode = self.node
                cell.datasource = [ESPMatterConstants.off, 
                                   ESPMatterConstants.cool,
                                   ESPMatterConstants.heat]
                cell.type = .systemMode
                cell.isRainmaker = false
                cell.deviceId = deviceId
                cell.nodeGroup = self.group
                cell.controlName.text = ESPMatterConstants.systemModeTxt
                cell.paramChipDelegate = self
                cell.acParamDelegate = self
                cell.setInitialSystemMode()
                if !self.isDeviceOffline {
                    if self.nodeConnectionStatus == .controller {
                        cell.readControllerMode()
                    } else {
                        cell.readMode()
                    }
                }
                cell.isUserInteractionEnabled = !self.isDeviceOffline
                return cell
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
                self.addHeightConstraint(textField: textField)
            }
            input.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak input] _ in
                let valueTextField = input?.textFields![0]
                if let text = valueTextField?.text, text.replacingOccurrences(of: " ", with: "").count > 0, text.count <= 32 {
                    let finalTxt = text.replacingOccurrences(of: " ", with: "")
                    if finalTxt.count > 0 {
                        self.deviceName = valueTextField?.text
                        self.updateMatterNodeLabel(nodeLabel: text, node: node, groupId: groupId, deviceId: deviceId, completion: completion)
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
        ESPMTRCommissioner.shared.setNodeLabel(deviceId: deviceId, nodeLabel: nodeLabel) { result in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
            }
            if result {
                DispatchQueue.main.async {
                    self.topBarTitle.text = nodeLabel
                }
                self.fabricDetails.removeNodeLabel(groupId: groupId, deviceId: deviceId)
                self.fabricDetails.saveNodeLabel(groupId: groupId, deviceId: deviceId, nodeLabel: nodeLabel)
                completion(nodeLabel)
            } else {
                completion(nil)
            }
        }
    }
}
#endif
