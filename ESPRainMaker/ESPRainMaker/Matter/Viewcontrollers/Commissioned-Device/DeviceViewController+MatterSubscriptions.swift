// Copyright 2025 Espressif Systems
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
//  DeviceViewController+MatterSubscriptions.swift
//  ESPRainMaker
//
//  Handles Matter attribute subscriptions at view controller level

#if ESPRainMakerMatter
import UIKit
import Matter

@available(iOS 16.4, *)
extension DeviceViewController {
    
    // MARK: - Matter Level Subscription
    func subscribeToLevelAttribute(deviceId: UInt64) {
        guard let grpId = self.group?.groupID else { return }
        
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
        commissioner.subscribeToLevelValue(groupId: grpId, deviceId: deviceId) { [weak self] level in
            guard let self = self else { return }
            
            // Look up indexPath from cellInfo array (data source) - this is safe on any thread
            guard let cellIndex = self.cellInfo.firstIndex(of: ESPMatterConstants.levelControl) else {
                return
            }
            let indexPath = IndexPath(row: cellIndex, section: 0)
            
            let finalLevelValue = Float(CGFloat(level)/2.54)
            let uiValue = Int(finalLevelValue)
            
            // CRITICAL: cellForRow(at:) is a UI API and MUST be called on main thread
            DispatchQueue.main.async {
                // Get cell at that indexPath (works even if not visible)
                guard let cell = self.deviceTableView.cellForRow(at: indexPath) as? ParamSliderCell else {
                    return
                }
                
                // Verify it's the correct cell type
                guard cell.sliderParamType == .brightness else {
                    return
                }
                
                if cell.isUserDragging {
                    return
                }
                
                if let node = cell.node, let id = cell.deviceId {
                    node.setMatterLevelValue(level: level, deviceId: id)
                }
                cell.currentLevel = uiValue
                cell.setLevelSliderValue(finalValue: finalLevelValue)
            }
        }
    }
    
    // MARK: - Matter Saturation Subscription
    func subscribeToSaturationAttribute(deviceId: UInt64) {
        guard let grpId = self.group?.groupID else { return }
        
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
        commissioner.subscribeToSaturationValue(groupId: grpId, deviceId: deviceId) { [weak self] saturation in
            guard let self = self else { return }
            
            // Look up indexPath from cellInfo array (data source) - this is safe on any thread
            guard let cellIndex = self.cellInfo.firstIndex(of: ESPMatterConstants.saturationControl) else {
                return
            }
            let indexPath = IndexPath(row: cellIndex, section: 0)
            
            let finalSaturationValue = Int(CGFloat(saturation)/2.54)
            
            // CRITICAL: cellForRow(at:) is a UI API and MUST be called on main thread
            DispatchQueue.main.async {
                // Get cell at that indexPath (works even if not visible)
                guard let cell = self.deviceTableView.cellForRow(at: indexPath) as? ParamSliderCell else {
                    return
                }
                
                // Verify it's the correct cell type
                guard cell.sliderParamType == .saturation else {
                    return
                }
                
                if cell.isUserDragging {
                    return
                }
                
                if let node = cell.node, let id = cell.deviceId {
                    node.setMatterSaturationValue(saturation: saturation, deviceId: id)
                }
                cell.currentLevel = finalSaturationValue
                cell.setSaturationSliderValue(finalValue: Float(cell.currentLevel))
            }
        }
    }
    
    // MARK: - Matter CCT Subscription
    func subscribeToCCTAttribute(deviceId: UInt64) {
        guard let grpId = self.group?.groupID else { return }
        
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
        commissioner.subscribeToCCTValue(groupId: grpId, deviceId: deviceId) { [weak self] cct in
            guard let self = self else { return }
            
            // Look up indexPath from cellInfo array (data source) - this is safe on any thread
            guard let cellIndex = self.cellInfo.firstIndex(of: ESPMatterConstants.cctControl) else {
                return
            }
            let indexPath = IndexPath(row: cellIndex, section: 0)
            
            // CRITICAL: cellForRow(at:) is a UI API and MUST be called on main thread
            DispatchQueue.main.async {
                // Get cell at that indexPath (works even if not visible)
                guard let cell = self.deviceTableView.cellForRow(at: indexPath) as? ParamSliderCell else {
                    return
                }
                
                // Verify it's the correct cell type
                guard cell.sliderParamType == .cct else {
                    return
                }
                
                if cell.isUserDragging {
                    return
                }
                
                if let node = cell.node, let id = cell.deviceId {
                    node.setMatterCCTValue(cct: cct, deviceId: id)
                }
                cell.currentLevel = cct
                cell.setCCTSliderValue(finalValue: Float(cell.currentLevel))
            }
        }
    }
    
    // MARK: - Matter Hue Subscription
    func subscribeToHueAttribute(deviceId: UInt64) {
        guard let grpId = self.group?.groupID else { return }
        
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
        commissioner.subscribeToHueValue(groupId: grpId, deviceId: deviceId) { [weak self] hue in
            guard let self = self else { return }
            
            // Look up indexPath from cellInfo array (data source) - this is safe on any thread
            guard let cellIndex = self.cellInfo.firstIndex(of: ESPMatterConstants.colorControl) else {
                return
            }
            let indexPath = IndexPath(row: cellIndex, section: 0)
            
            let finalValue = (CGFloat(hue)*360.0)/254.0
            
            // CRITICAL: cellForRow(at:) is a UI API and MUST be called on main thread
            DispatchQueue.main.async {
                // Get cell at that indexPath (works even if not visible)
                guard let cell = self.deviceTableView.cellForRow(at: indexPath) as? ParamHueSliderCell else {
                    return
                }
                
                if cell.isUserDragging {
                    return
                }
                
                if let node = cell.node, let id = cell.deviceId {
                    node.setMatterHueValue(hue: Int(finalValue), deviceId: id)
                }
                cell.currentHueValue = finalValue
                cell.hueSlider.value = cell.currentHueValue
                cell.hueSlider.thumbColor = UIColor(hue: cell.currentHueValue/360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            }
        }
    }
    
    // MARK: - Matter OCS Subscription
    func subscribeToOCSAttribute(deviceId: UInt64) {
        guard let grpId = self.group?.groupID else { return }
        
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
        commissioner.subscribeToOccupiedCoolingSetpoint(groupId: grpId, deviceId: deviceId) { [weak self] value in
            guard let self = self else { return }
            
            // Look up indexPath from cellInfo array (data source) - this is safe on any thread
            guard let cellIndex = self.cellInfo.firstIndex(of: ESPMatterConstants.occupiedCoolingSetpoint) else {
                return
            }
            let indexPath = IndexPath(row: cellIndex, section: 0)
            
            // CRITICAL: cellForRow(at:) is a UI API and MUST be called on main thread
            DispatchQueue.main.async {
                // Get cell at that indexPath (works even if not visible)
                guard let cell = self.deviceTableView.cellForRow(at: indexPath) as? ParamSliderCell else {
                    return
                }
                
                // Verify it's the correct cell type
                guard cell.sliderParamType == .airConditioner, cell.configuration == .matterCoolingSetpoint else {
                    return
                }
                
                if cell.isUserDragging {
                    return
                }
                
                if let mode = cell.node?.getMatterSystemMode(deviceId: deviceId) {
                    if mode == ESPMatterConstants.cool {
                        if let value = value {
                            cell.currentLevel = Int(value)
                            cell.node?.setMatterOccupiedCoolingSetpoint(ocs: value, deviceId: deviceId)
                            cell.setOCSSliderValue(finalValue: Float(value))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Matter OHS Subscription
    func subscribeToOHSAttribute(deviceId: UInt64) {
        guard let grpId = self.group?.groupID else { return }
        
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
        commissioner.subscribeToOccupiedHeatingSetpoint(groupId: grpId, deviceId: deviceId) { [weak self] value in
            guard let self = self else { return }
            
            // Look up indexPath from cellInfo array (data source) - this is safe on any thread
            guard let cellIndex = self.cellInfo.firstIndex(of: ESPMatterConstants.occupiedHeatingSetpoint) else {
                return
            }
            let indexPath = IndexPath(row: cellIndex, section: 0)
            
            // CRITICAL: cellForRow(at:) is a UI API and MUST be called on main thread
            DispatchQueue.main.async {
                // Get cell at that indexPath (works even if not visible)
                guard let cell = self.deviceTableView.cellForRow(at: indexPath) as? ParamSliderCell else {
                    return
                }
                
                // Verify it's the correct cell type
                guard cell.sliderParamType == .airConditioner, cell.configuration == .matterHeatingSetpoint else {
                    return
                }
                
                if cell.isUserDragging {
                    return
                }
                
                if let mode = cell.node?.getMatterSystemMode(deviceId: deviceId) {
                    if mode == ESPMatterConstants.heat {
                        if let value = value {
                            cell.currentLevel = Int(value)
                            cell.node?.setMatterOccupiedHeatingSetpoint(ohs: value, deviceId: deviceId)
                            cell.setOHSSliderValue(finalValue: Float(value))
                        }
                    }
                }
            }
        }
    }
}

#endif

