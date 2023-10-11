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
            if [ESPMatterConstants.deviceName, ESPMatterConstants.onOff, ESPMatterConstants.rainmakerController].contains(value) {
                return 100.0
            } else if value == ESPMatterConstants.delete {
                return 75.0
            } else if [ESPMatterConstants.levelControl, ESPMatterConstants.colorControl, ESPMatterConstants.saturationControl].contains(value) {
                return 126.0
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
                return cell
            }
        }
        if let group = group, let groupId = group.groupID, let matterNodeId = matterNodeId, let _ = matterNodeId.hexToDecimal, let deviceId = matterNodeId.hexToDecimal, indexPath.row < cellInfo.count {
            let value = cellInfo[indexPath.row]
            if value == ESPMatterConstants.deviceName {
                if let cell = tableView.dequeueReusableCell(withIdentifier: DeviceNameCell.reuseIdentifier, for: indexPath) as? DeviceNameCell {
                    cell.delegate = self
                    cell.rainmakerNode = self.rainmakerNode
                    if let node = self.rainmakerNode, let name = node.rainmakerDeviceName {
                        cell.deviceName.text = name
                    }
                    return cell
                }
            } else if value == ESPMatterConstants.onOff {
                if let cell = tableView.dequeueReusableCell(withIdentifier: DeviceOnOffCell.reuseIdentifier, for: indexPath) as? DeviceOnOffCell {
                    cell.node = self.node
                    cell.deviceId = deviceId
                    cell.delegate = self
                    cell.group = self.group
                    self.setAutoresizingMask(cell)
                    if self.isDeviceOffline {
                        cell.setupOfflineUI(deviceId: deviceId)
                    } else {
                        cell.setupInitialUI()
                        cell.subscribeToOnOffAttribute()
                    }
                    return cell
                }
            } else if value == ESPMatterConstants.levelControl {
                let sliderCell = tableView.dequeueReusableCell(withIdentifier: SliderTableViewCell.reuseIdentifier, for: indexPath) as! SliderTableViewCell
                object_setClass(sliderCell, ParamSliderTableViewCell.self)
                let cell = sliderCell as! ParamSliderTableViewCell
                cell.node = self.node
                cell.isRainmaker = false
                cell.isSaturation = false
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
                    cell.subscribeToLevelAttribute()
                }
                return cell
            } else if value == ESPMatterConstants.colorControl {
                let sliderCell = tableView.dequeueReusableCell(withIdentifier: SliderTableViewCell.reuseIdentifier, for: indexPath) as! SliderTableViewCell
                object_setClass(sliderCell, ParamSliderTableViewCell.self)
                let cell = sliderCell as! ParamSliderTableViewCell
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
                cell.subscribeToHueAttribute()
                return cell
            } else if value == ESPMatterConstants.saturationControl {
                let sliderCell = tableView.dequeueReusableCell(withIdentifier: SliderTableViewCell.reuseIdentifier, for: indexPath) as! SliderTableViewCell
                object_setClass(sliderCell, ParamSliderTableViewCell.self)
                let cell = sliderCell as! ParamSliderTableViewCell
                cell.node = self.node
                cell.isRainmaker = false
                cell.isSaturation = true
                cell.nodeGroup = self.group
                cell.deviceId = deviceId
                cell.hueSlider.isHidden = true
                cell.slider.isHidden = false
                cell.paramChipDelegate = self
                self.setAutoresizingMask(cell)
                cell.setupInitialSaturationValue()
                cell.subscribeToSaturationAttribute()
                return cell
            } else if value == ESPMatterConstants.delete {
                if let cell = tableView.dequeueReusableCell(withIdentifier: RemoveDeviceCell.reuseIdentifier, for: indexPath) as? RemoveDeviceCell {
                    cell.delegate = self
                    self.setAutoresizingMask(cell)
                    return cell
                }
            } else if value == ESPMatterConstants.openCW {
                if let cell = tableView.dequeueReusableCell(withIdentifier: OpenCommissioningWindowCell.reuseIdentifier, for: indexPath) as? OpenCommissioningWindowCell {
                    cell.delegate = self
                    self.setAutoresizingMask(cell)
                    return cell
                }
            } else if value == ESPMatterConstants.rainmakerController {
                if let cell = tableView.dequeueReusableCell(withIdentifier: LaunchControllerCell.reuseIdentifier, for: indexPath) as? LaunchControllerCell {
                    cell.delegate = self
                    self.setAutoresizingMask(cell)
                    return cell
                }
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
}
#endif
