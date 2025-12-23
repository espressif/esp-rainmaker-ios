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
            cell.selectionStyle = .none
            cell.delegate = self
            cell.rainmakerNode = self.rainmakerNode
            if let node = self.rainmakerNode {
                if node.isRainmakerMatter, let name = node.rainmakerDeviceName {
                    cell.deviceInfo = .deviceName
                    cell.deviceName.text = name
                } else {
                    cell.deviceInfo = .matterDeviceName
                    cell.propertyName.text = "Name"
                    if let name = node.matterDeviceName {
                        cell.deviceName.text = name
                    }
                }
            }
            cell.isUserInteractionEnabled = !self.isDeviceOffline
            cell.editButton.isEnabled = !self.isDeviceOffline
            // Set alpha when device is offline
            let alpha: CGFloat = self.isDeviceOffline ? 0.5 : 1.0
            cell.alpha = alpha
            cell.deviceName.alpha = alpha
            cell.propertyName.alpha = alpha
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
            cell.selectionStyle = .none
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
                if !self.isDeviceOffline, !self.showDefaultUI {
                    cell.subscribeToOnOffAttribute()
                }
            }
            cell.toggleSwitch.isEnabled = !self.isDeviceOffline
            cell.isUserInteractionEnabled = !self.isDeviceOffline
            // Set alpha when device is offline
            let alpha: CGFloat = self.isDeviceOffline ? 0.5 : 1.0
            cell.alpha = alpha
            cell.onOffStatus.alpha = alpha
            cell.toggleSwitch.alpha = alpha
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
    func getLevelControlCell(_ tableView: UITableView, indexPath: IndexPath, groupId: String, deviceId: UInt64) -> ParamSliderCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamSliderCell.reuseIdentifier, for: indexPath) as? ParamSliderCell else { return nil }
        cell.selectionStyle = .none
        cell.nodeConnectionStatus = self.nodeConnectionStatus
        cell.node = self.node
        cell.isRainmaker = false
        cell.sliderParamType = .brightness
        cell.nodeGroup = self.group
        cell.deviceId = deviceId
        cell.configuration = .matterLevel
        cell.paramChipDelegate = self
        cell.isDeviceOffline = self.isDeviceOffline
        cell.showDefaultUI = self.showDefaultUI
        if self.isDeviceOffline || self.showDefaultUI {
            cell.setupInitialLevelValues()
        } else {
            cell.getCurrentLevelValues()
            if !self.isDeviceOffline, !self.showDefaultUI {
                self.subscribeToLevelAttribute(deviceId: deviceId)
            }
        }
        self.setAutoresizingMask(cell)
        cell.updateConnectionState()
        return cell
    }
    
    /// Get color control cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: indexpath
    ///   - deviceId: device id
    /// - Returns: color control cell
    func getColorControlCell(_ tableView: UITableView, indexPath: IndexPath, deviceId: UInt64) -> ParamHueSliderCell {
        // Use new programmatic ParamHueSliderCell - no runtime class swizzling
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamHueSliderCell.reuseIdentifier, for: indexPath) as? ParamHueSliderCell else {
            return ParamHueSliderCell() // Fallback - should not happen if cells are registered
        }
        cell.selectionStyle = .none
        cell.nodeConnectionStatus = self.nodeConnectionStatus
        cell.node = self.node
        cell.isRainmaker = false
        cell.nodeGroup = self.group
        cell.deviceId = deviceId
        cell.paramChipDelegate = self
        cell.isDeviceOffline = self.isDeviceOffline
        cell.showDefaultUI = self.showDefaultUI
        self.setAutoresizingMask(cell)
        
        // Set Matter-specific constraints (10pt top, -10pt bottom)
        cell.setupMatterConstraints()
        
        // Bind a param so title/min/max render (mirror DeviceTraitListViewController)
        if cell.param == nil {
            var hueParam: Param?
            if let devices = self.rainmakerNode?.devices {
                for dev in devices {
                    if let params = dev.params {
                        hueParam = params.first(where: {
                            let name = $0.name?.lowercased() ?? ""
                            let ui = $0.uiType?.lowercased() ?? ""
                            return name == "hue" || ui == Constants.hue
                        })
                        if hueParam != nil { break }
                    }
                }
            }
            if hueParam == nil {
                let p = Param()
                p.name = "Hue"
                p.dataType = "int"
                p.properties = ["write"]
                p.bounds = ["min": 0, "max": 360, "step": 1]
                hueParam = p
            }
            cell.param = hueParam
        }
        
        // Matter-specific hue setup
        if self.isDeviceOffline || self.showDefaultUI {
            // For offline/default UI, use stored value
            if let node = self.node, let storedHue = node.getMatterHueValue(deviceId: deviceId) {
                cell.currentHueValue = CGFloat(storedHue)
                cell.hueSlider.value = CGFloat(storedHue)
                cell.hueSlider.thumbColor = UIColor(hue: CGFloat(storedHue)/360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            }
        } else {
            // For online, read current value and subscribe
            cell.setCurrentHueValue()
            self.subscribeToHueAttribute(deviceId: deviceId)
        }
        cell.updateConnectionState()
        
        return cell
    }
    
    /// Get saturation control cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: inde xpath
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: saturation control cell
    func getSaturationControlCell(_ tableView: UITableView, indexPath: IndexPath, groupId: String, deviceId: UInt64) -> ParamSliderCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamSliderCell.reuseIdentifier, for: indexPath) as? ParamSliderCell else { return nil }
        cell.selectionStyle = .none
        cell.nodeConnectionStatus = self.nodeConnectionStatus
        cell.node = self.node
        cell.isRainmaker = false
        cell.sliderParamType = .saturation
        cell.nodeGroup = self.group
        cell.deviceId = deviceId
        cell.configuration = .matterSaturation
        cell.paramChipDelegate = self
        cell.isDeviceOffline = self.isDeviceOffline
        cell.showDefaultUI = self.showDefaultUI
        if self.isDeviceOffline || self.showDefaultUI {
            cell.setupInitialSaturationValue()
        } else {
            cell.getCurrentSaturationValue()
            if !self.isDeviceOffline, !self.showDefaultUI {
                self.subscribeToSaturationAttribute(deviceId: deviceId)
            }
        }
        self.setAutoresizingMask(cell)
        cell.updateConnectionState()
        return cell
    }
    
    /// Get controller cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    /// - Returns: controller cell
    func getControllerCell(_ tableView: UITableView, indexPath: IndexPath) -> ParamCustomActionCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamCustomActionCell.reuseIdentifier, for: indexPath) as? ParamCustomActionCell else { return nil }
        // Set Matter-specific constraints (10pt top, -10pt bottom)
        cell.selectionStyle = .none
        cell.topSpaceConstraint?.constant = 10.0
        cell.bottomSpaceConstraint?.constant = -10.0
        cell.delegate = self
        cell.setupWorkflow(workflow: CustomAction.launchController)
        if let node = self.rainmakerNode, node.isMatterControllerDevice, !node.isRainmakerMatter {
            cell.setLaunchButtonConnectedStatus(isDeviceOffline: true)
            cell.setControllerUnauthorizedStatus()
        } else {
            cell.setLaunchButtonConnectedStatus(isDeviceOffline: self.isDeviceOffline)
        }
        return cell
    }
    
    /// Get TBR cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    /// - Returns: TBR cell
    func getBorderRouterCell(_ tableView: UITableView, indexPath: IndexPath) -> ParamCustomActionCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamCustomActionCell.reuseIdentifier, for: indexPath) as? ParamCustomActionCell else { return nil }
        // Set Matter-specific constraints (10pt top, -10pt bottom)
        cell.selectionStyle = .none
        cell.topSpaceConstraint?.constant = 10.0
        cell.bottomSpaceConstraint?.constant = -10.0
        cell.delegate = self
        cell.setupWorkflow(workflow: CustomAction.updateThreadDataset)
        cell.isUserInteractionEnabled = !self.isDeviceOffline
        return cell
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
            cell.selectionStyle = .none
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
    /// Get temperature cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: inde xpath
    ///   - value: va;lue
    ///   - deviceId: device id
    /// - Returns: temp cell
    func getTemperatureCell(_ tableView: UITableView, indexPath: IndexPath, value: String, deviceId: UInt64) -> ParamGenericCell? {
        // Use new programmatic ParamGenericCell - no runtime class swizzling
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamGenericCell.reuseIdentifier, for: indexPath) as? ParamGenericCell else { return nil }
        cell.selectionStyle = .none
        cell.node = self.node
        cell.deviceId = deviceId
        cell.nodeGroup = self.group
        
        // Find and set param
        if let node = self.rainmakerNode, let devices = node.devices, let device = devices.first {
            cell.device = device
            for param in device.params ?? [] {
                if let paramName = param.name, paramName.lowercased() == ESPMatterConstants.localTemperatureTxt.lowercased() {
                    cell.param = param
                }
            }
        }
        
        // Set control name
        if value == ESPMatterConstants.localTemperature || value == ESPMatterConstants.measuredTemperature {
            // Control name is set in ParamGenericCell.updateUI() from param.name
        }
        
        // TODO: Matter-specific temperature subscription - need to integrate into ParamGenericCell
        // For now, basic setup
        cell.isDeviceOffline = self.isDeviceOffline
        cell.showDefaultUI = self.showDefaultUI
        self.setAutoresizingMask(cell)
        cell.updateConnectionState()
        
        return cell
    }
    
    // REMOVED: getOccupiedSetpointCell - Dead code that used object_setClass
    // Replaced by getOccupiedCoolingSetpointCell and getOccupiedHeatingSetpointCell
    
    /// Get occupied cooling setpoint cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    ///   - deviceId: device id
    /// - Returns: occupied  setpoint cell
    func getOccupiedCoolingSetpointCell(_ tableView: UITableView, indexPath: IndexPath, deviceId: UInt64) -> ParamSliderCell? {
        return getOccupiedSetpointCell(tableView: tableView, indexPath: indexPath, deviceId: deviceId, isCooling: true)
    }
    
    /// Get occupied heating setpoint cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    ///   - deviceId: device id
    /// - Returns: occupied  setpoint cell
    func getOccupiedHeatingSetpointCell(_ tableView: UITableView, indexPath: IndexPath, deviceId: UInt64) -> ParamSliderCell? {
        return getOccupiedSetpointCell(tableView: tableView, indexPath: indexPath, deviceId: deviceId, isCooling: false)
    }
    
    /// Get occupied setpoint cell (cooling or heating)
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    ///   - deviceId: device id
    ///   - isCooling: true for cooling, false for heating
    /// - Returns: occupied setpoint cell
    private func getOccupiedSetpointCell(tableView: UITableView, indexPath: IndexPath, deviceId: UInt64, isCooling: Bool) -> ParamSliderCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamSliderCell.reuseIdentifier, for: indexPath) as? ParamSliderCell else { return nil }
        cell.selectionStyle = .none
        cell.node = node
        cell.isRainmaker = false
        cell.sliderParamType = .airConditioner
        cell.nodeGroup = group
        cell.deviceId = deviceId
        cell.configuration = isCooling ? .matterCoolingSetpoint : .matterHeatingSetpoint
        cell.paramChipDelegate = self
        cell.isDeviceOffline = isDeviceOffline
        cell.showDefaultUI = showDefaultUI
        cell.nodeConnectionStatus = nodeConnectionStatus
        // CRITICAL: Use controller setup methods for controller devices, regular setup for local devices
        if nodeConnectionStatus == .controller {
            if isCooling {
                cell.setupInitialControllerOCSValues(isDeviceOffline: isDeviceOffline)
            } else {
                cell.setupInitialControllerOHSValues(isDeviceOffline: isDeviceOffline)
            }
        } else {
            if isCooling {
                cell.setupInitialOCSValue(isDeviceOffline: isDeviceOffline)
                if !isDeviceOffline, !showDefaultUI {
                    self.subscribeToOCSAttribute(deviceId: deviceId)
                }
            } else {
                cell.setupInitialOHSValue(isDeviceOffline: isDeviceOffline)
                if !isDeviceOffline, !showDefaultUI {
                    self.subscribeToOHSAttribute(deviceId: deviceId)
                }
            }
        }
        setAutoresizingMask(cell)
        cell.updateConnectionState()
        return cell
    }
    
    /// Get control sequence of operation cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    ///   - deviceId: device id
    /// - Returns: CSO cell
    func getControlSequenceOpfOperationCell(_ tableView: UITableView, indexPath: IndexPath, deviceId: UInt64) -> ParamDropDownCell {
        // Use new programmatic ParamDropDownCell - no runtime class swizzling
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamDropDownCell.reuseIdentifier, for: indexPath) as? ParamDropDownCell else {
            return ParamDropDownCell() // Fallback - should not happen if cells are registered
        }
        // Set Matter-specific constraints (10pt top, -10pt bottom) - find and update constraints
        for constraint in cell.contentView.constraints {
            if (constraint.firstItem === cell.backView && constraint.secondItem === cell.contentView) ||
               (constraint.firstItem === cell.contentView && constraint.secondItem === cell.backView) {
                if constraint.firstAttribute == .top || constraint.secondAttribute == .top {
                    constraint.constant = 10.0
                } else if constraint.firstAttribute == .bottom || constraint.secondAttribute == .bottom {
                    constraint.constant = -10.0
                }
            }
        }
        cell.selectionStyle = .none
        cell.matterNode = self.node
        cell.datasource = [ESPMatterConstants.cool]
        cell.type = .controlSequenceOfOperation
        cell.isRainmaker = false
        cell.deviceId = deviceId
        cell.nodeGroup = self.group
        cell.paramChipDelegate = self
        cell.acParamDelegate = self
        
        // TODO: setInitialControlSequenceOfOperation() - need to integrate Matter-specific logic into ParamDropDownCell
        // For now, basic setup
        cell.isDeviceOffline = self.isDeviceOffline
        cell.showDefaultUI = self.showDefaultUI
        self.setAutoresizingMask(cell)
        cell.updateConnectionState()
        
        return cell
    }
    
    /// Get system mode cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path
    ///   - deviceId: device id
    /// - Returns: system mode cell
    func getSystemModeCell(_ tableView: UITableView, indexPath: IndexPath, deviceId: UInt64) -> ParamDropDownCell {
        // Use new programmatic ParamDropDownCell - no runtime class swizzling
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamDropDownCell.reuseIdentifier, for: indexPath) as? ParamDropDownCell else {
            return ParamDropDownCell() // Fallback - should not happen if cells are registered
        }
        // Set Matter-specific constraints (10pt top, -10pt bottom) - find and update constraints
        for constraint in cell.contentView.constraints {
            if (constraint.firstItem === cell.backView && constraint.secondItem === cell.contentView) ||
               (constraint.firstItem === cell.contentView && constraint.secondItem === cell.backView) {
                if constraint.firstAttribute == .top || constraint.secondAttribute == .top {
                    constraint.constant = 10.0
                } else if constraint.firstAttribute == .bottom || constraint.secondAttribute == .bottom {
                    constraint.constant = -10.0
                }
            }
        }
        cell.selectionStyle = .none
        cell.matterNode = self.node
        cell.datasource = [ESPMatterConstants.off,
                           ESPMatterConstants.cool,
                           ESPMatterConstants.heat]
        cell.type = .systemMode
        cell.isRainmaker = false
        cell.deviceId = deviceId
        cell.nodeGroup = self.group
        cell.paramChipDelegate = self
        cell.acParamDelegate = self
        
        // TODO: Matter-specific system mode methods - need to integrate into ParamDropDownCell
        // setInitialSystemMode(), readControllerMode(), readMode()
        // For now, basic setup
        cell.isDeviceOffline = self.isDeviceOffline
        cell.showDefaultUI = self.showDefaultUI
        if !self.isDeviceOffline, !self.showDefaultUI {
            // cell.readControllerMode() or cell.readMode() - to be implemented
        }
        self.setAutoresizingMask(cell)
        cell.updateConnectionState()
        
        return cell
    }
    
    /// Get saturation control cell
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: inde xpath
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: saturation control cell
    func getCCTControlCell(_ tableView: UITableView, indexPath: IndexPath, groupId: String, deviceId: UInt64) -> ParamSliderCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamSliderCell.reuseIdentifier, for: indexPath) as? ParamSliderCell else { return nil }
        cell.selectionStyle = .none
        cell.nodeConnectionStatus = self.nodeConnectionStatus
        cell.node = self.node
        cell.isRainmaker = false
        cell.sliderParamType = .cct
        cell.nodeGroup = self.group
        cell.deviceId = deviceId
        cell.configuration = .matterCCT
        cell.paramChipDelegate = self
        cell.isDeviceOffline = self.isDeviceOffline
        cell.showDefaultUI = self.showDefaultUI
        if self.isDeviceOffline || self.showDefaultUI {
            cell.setupInitialCCTValue()
            // setSliderThumbUI() is called inside setCCTSliderValue()
        } else {
            cell.getCurrentCCTValue()
            // setSliderThumbUI() is called inside setCCTSliderValue()
            if !self.isDeviceOffline, !self.showDefaultUI {
                self.subscribeToCCTAttribute(deviceId: deviceId)
            }
        }
        self.setAutoresizingMask(cell)
        cell.updateConnectionState()
        return cell
    }
}
#endif
