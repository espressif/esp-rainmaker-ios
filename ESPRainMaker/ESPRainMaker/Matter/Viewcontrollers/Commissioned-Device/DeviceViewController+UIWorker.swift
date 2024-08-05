// Copyright 2024 Espressif Systems
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
//  DeviceViewController+UIWorker.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import UIKit

@available(iOS 16.4, *)
extension DeviceViewController {
    
    /// Get device name cell
    /// - Parameters:
    ///   - tableView: tableview
    ///   - indexPath: indexpath
    ///   - groupId: groupid
    ///   - deviceId: deviceId
    /// - Returns: device name cell
    func getDeviceNameCell(_ tableView: UITableView, indexPath: IndexPath, groupId: String, deviceId: UInt64) -> DeviceInfoCell? {
        if let cell = tableView.dequeueReusableCell(withIdentifier: DeviceInfoCell.reuseIdentifier, for: indexPath) as? DeviceInfoCell {
            cell.delegate = self
            cell.rainmakerNode = self.rainmakerNode
            if let node = self.rainmakerNode {
                if node.isRainmaker, let name = node.rainmakerDeviceName {
                    cell.deviceInfo = .deviceName
                    cell.deviceName.text = name
                } else {
                    cell.deviceInfo = .nodeLabel
                    cell.propertyName.text = "Name"
                    if let name = node.matterDeviceName {
                        cell.deviceName.text = name
                    }
                }
            }
            cell.isUserInteractionEnabled = !self.isDeviceOffline
            return cell
        }
        return nil
    }
    
    /// Get on off cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: indexpath
    ///   - deviceId: device id
    /// - Returns: on off cell
    func getOnOffCell(_ tableView: UITableView, indexPath: IndexPath, deviceId: UInt64) -> DeviceOnOffCell? {
        if let cell = tableView.dequeueReusableCell(withIdentifier: DeviceOnOffCell.reuseIdentifier, for: indexPath) as? DeviceOnOffCell {
            cell.nodeConnectionStatus = self.nodeConnectionStatus
            cell.node = self.node
            cell.deviceId = deviceId
            cell.delegate = self
            cell.group = self.group
            self.setAutoresizingMask(cell)
            if self.showDefaultUI || self.isDeviceOffline {
                cell.setupOfflineUI(deviceId: deviceId)
            } else {
                cell.setupInitialUI()
            }
            cell.isUserInteractionEnabled = !self.isDeviceOffline
            return cell
        }
        return nil
    }
    
    /// Get level control cell
    /// - Parameters:
    ///   - tableView: tableView
    ///   - indexPath: indexpath
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: level control cell
    func getLevelControlCell(_ tableView: UITableView, indexPath: IndexPath, groupId: String, deviceId: UInt64) -> ParamSliderTableViewCell {
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
        if self.isDeviceOffline || self.showDefaultUI {
            cell.setupOfflineUI()
        } else {
            cell.getCurrentLevelValues(groupId: groupId, deviceId: deviceId)
        }
        cell.isUserInteractionEnabled = !self.isDeviceOffline
        return cell
    }
    
    /// Get color control cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: indexpath
    ///   - deviceId: device id
    /// - Returns: color control cell
    func getColorControlCell(_ tableView: UITableView, indexPath: IndexPath, deviceId: UInt64) -> ParamSliderTableViewCell {
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
        if !self.isDeviceOffline, !self.showDefaultUI {
            cell.subscribeToHueAttribute()
        }
        cell.isUserInteractionEnabled = !self.isDeviceOffline
        return cell
    }
    
    /// Get saturation control cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: inde xpath
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: saturation control cell
    func getSaturationControlCell(_ tableView: UITableView, indexPath: IndexPath, groupId: String, deviceId: UInt64) -> ParamSliderTableViewCell {
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
        if self.isDeviceOffline || self.showDefaultUI {
            cell.setupOfflineUI()
        } else {
            cell.getCurrentSaturationValue(groupId: groupId, deviceId: deviceId)
        }
        cell.isUserInteractionEnabled = !self.isDeviceOffline
        return cell
    }
    
    /// Get controller cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    /// - Returns: controller cell
    func getControllerCell(_ tableView: UITableView, indexPath: IndexPath) -> CustomActionCell? {
        if let cell = tableView.dequeueReusableCell(withIdentifier: CustomActionCell.reuseIdentifier, for: indexPath) as? CustomActionCell {
            cell.delegate = self
            cell.setupWorkflow(workflow: .launchController)
            self.setAutoresizingMask(cell)
            cell.isUserInteractionEnabled = !self.isDeviceOffline
            return cell
        }
        return nil
    }
    
    /// Get TBR cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    /// - Returns: TBR cell
    func getBorderRouterCell(_ tableView: UITableView, indexPath: IndexPath) -> CustomActionCell? {
        if let cell = tableView.dequeueReusableCell(withIdentifier: CustomActionCell.reuseIdentifier, for: indexPath) as? CustomActionCell {
            cell.delegate = self
            cell.setupWorkflow(workflow: .updateThreadDataset)
            self.setAutoresizingMask(cell)
            cell.isUserInteractionEnabled = !self.isDeviceOffline
            return cell
        }
        return nil
    }
    
    /// Get participant darta cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: indexpath
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: participant data cell
    func getParticipantDataCell(_ tableView: UITableView, indexPath: IndexPath, groupId: String, deviceId: UInt64) -> ParticipantDataCell? {
        if let cell = tableView.dequeueReusableCell(withIdentifier: ParticipantDataCell.reuseIdentifier, for: indexPath) as? ParticipantDataCell {
            cell.delegate = self
            if let data = self.fabricDetails.fetchParticipantData(groupId: groupId, deviceId: deviceId) {
                cell.setupUI(data: data)
            }
            self.setAutoresizingMask(cell)
            cell.isUserInteractionEnabled = !self.isDeviceOffline
            return cell
        }
        return nil
    }
    
    /// Get temperature cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: inde xpath
    ///   - value: va;lue
    ///   - deviceId: device id
    /// - Returns: temp cell
    func getTemperatureCell(_ tableView: UITableView, indexPath: IndexPath, value: String, deviceId: UInt64) -> CustomInfoCell? {
        if let cell = tableView.dequeueReusableCell(withIdentifier: CustomInfoCell.reuseIdentifier, for: indexPath) as? CustomInfoCell {
            cell.node = self.node
            cell.deviceId = deviceId
            cell.nodeGroup = self.group
            if value == ESPMatterConstants.localTemperature {
                cell.type.text = ESPMatterConstants.localTemperatureTxt
                if self.isDeviceOffline || self.showDefaultUI {
                    cell.setupOfflineLocalTemperatureUI()
                } else {
                    if self.nodeConnectionStatus == .controller {
                        cell.setupInitialControllerLocalTempUI()
                    } else {
                        cell.setupLocalTemperatureUI()
                    }
                }
            } else {
                cell.type.text = ESPMatterConstants.measuredTemperatureTxt
                if self.isDeviceOffline || self.showDefaultUI {
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
        return nil
    }
    
    /// Get occupied setpoint cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    ///   - deviceId: device id
    /// - Returns: occupied  setpoint cell
    func getOccupiedSetpointCell(_ tableView: UITableView, indexPath: IndexPath, deviceId: UInt64) -> ParamSliderTableViewCell {
        let sliderCell = tableView.dequeueReusableCell(withIdentifier: SliderTableViewCell.reuseIdentifier, for: indexPath) as! SliderTableViewCell
        object_setClass(sliderCell, ParamSliderTableViewCell.self)
        let cell = sliderCell as! ParamSliderTableViewCell
        cell.title.text = ESPMatterConstants.occupiedCoolingSetpointTxt
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
    }
    
    /// Get control sequence of operation cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    ///   - deviceId: device id
    /// - Returns: CSO cell
    func getControlSequenceOpfOperationCell(_ tableView: UITableView, indexPath: IndexPath, deviceId: UInt64) -> ParamDropDownTableViewCell {
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
    }
    
    /// Get system mode cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    ///   - deviceId: device id
    /// - Returns: system mode cell
    func getSystemModeCell(_ tableView: UITableView, indexPath: IndexPath, deviceId: UInt64) -> ParamDropDownTableViewCell {
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
        if !self.isDeviceOffline, !self.showDefaultUI {
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
#endif
