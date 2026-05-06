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
//  ParamSliderCell+Matter.swift
//  ESPRainMaker
//
//  Component: Matter-Specific Slider Logic
//  Handles: Matter Level, Saturation, CCT, Cooling Setpoint, Heating Setpoint
//  Subscriptions, Updates, Initialization

#if ESPRainMakerMatter
import UIKit
import Matter

@available(iOS 16.4, *)
extension ParamSliderCell {
    
    // MARK: - Matter Parameter Update Router
    // Routes Matter updates to appropriate cluster-specific methods
    // Cluster-specific implementations are in separate files:
    // - ParamSliderCell+MatterLevel.swift (Level Control cluster)
    // - ParamSliderCell+MatterSaturation.swift (Color Control cluster - Saturation)
    // - ParamSliderCell+MatterCCT.swift (Color Control cluster - CCT)
    // - ParamSliderCell+MatterOCS.swift (Thermostat cluster - Occupied Cooling Setpoint)
    // - ParamSliderCell+MatterOHS.swift (Thermostat cluster - Occupied Heating Setpoint)
    func updateParamMatter(value: Float, isContinuous: Bool) {
        switch configuration {
        case .matterLevel:
            changeLevel(toValue: value)
        case .matterSaturation:
            changeSaturation(value: value)
        case .matterCCT:
            self.changeCCT(value: value)
        case .matterCoolingSetpoint:
            changeCoolingSetpoint(value: value)
        case .matterHeatingSetpoint:
            changeHeatingSetpoint(value: value)
        default:
            break
        }
        
        if isContinuous {
            group.leave()
        }
    }
    
    // MARK: - Setup Offline UI
    /// Setup Offline UI (matches old ParamSliderTableViewCell+ParamSliderLevelControlProtocol)
    /// Routes to appropriate setup method based on configuration
    func setupOfflineUI() {
        switch configuration {
        case .matterLevel:
            self.setupInitialLevelValues()
        case .matterSaturation:
            self.setupInitialSaturationValue()
        case .matterCCT:
            self.setupInitialCCTValue()
        case .matterCoolingSetpoint:
            self.setupInitialOCSValue(isDeviceOffline: true)
        case .matterHeatingSetpoint:
            self.setupInitialOHSValue(isDeviceOffline: true)
        default:
            // For standard/Rainmaker sliders, just update UI normally
            updateUI()
        }
    }
    
    // MARK: - Legacy Method Wrappers (for backward compatibility with sliderParamType)
    /// Wrapper method for changeOccupiedSetpoint (matches old ParamSliderTableViewCell signature)
    /// Determines whether to call cooling or heating setpoint based on device mode
    func changeOccupiedSetpoint(setPoint: Int16) {
        if let id = self.deviceId, let node = self.node {
            if let mode = node.getMatterSystemMode(deviceId: id), mode.lowercased() == "heat" {
                // Heating mode - use heating setpoint
                changeHeatingSetpoint(value: Float(setPoint))
            } else {
                // Cooling mode (default) - use cooling setpoint
                changeCoolingSetpoint(value: Float(setPoint))
            }
        } else {
            // Default to cooling if we can't determine mode
            changeCoolingSetpoint(value: Float(setPoint))
        }
    }
    
    /// Wrapper method for changeCCT with Int parameter (matches old ParamSliderTableViewCell signature)
    func changeCCT(cct: Int) {
        self.changeCCT(value: Float(cct))
    }
}

#endif

