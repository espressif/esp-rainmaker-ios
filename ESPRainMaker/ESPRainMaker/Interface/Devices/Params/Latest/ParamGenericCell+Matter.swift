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
//  ParamGenericCell+Matter.swift
//  ESPRainMaker
//
//  Component: Matter-Specific Functionality
//  Handles: Matter temperature subscription and display
//  Matches: GenericControlTableViewCell Matter methods

import UIKit
#if ESPRainMakerMatter
import Matter
#endif

extension ParamGenericCell {
    
    // MARK: - Matter Temperature Methods
    // Matches old GenericControlTableViewCell Matter methods
    
    /// Setup locally stored UI
    /// Matches old GenericControlTableViewCell.setupLocallyStoredUI()
    func setupLocallyStoredUI() {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *), let deviceId = self.deviceId {
            if let localTemperature = self.node?.getMatterLocalTemperatureValue(deviceId: deviceId) {
                DispatchQueue.main.async {
                    self.controlValueLabel.text = "\(localTemperature) °C"
                }
            }
        }
        #endif
    }
    
    /// Subscribe to temperature measurement
    /// Matches old GenericControlTableViewCell.subscribeToLocalTemperature()
    func subscribeToLocalTemperature() {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *), let group = self.nodeGroup, let groupId = group.groupID, let deviceId = self.deviceId {
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
            commissioner.subscribeLocalTemperature(groupId: groupId, deviceId: deviceId) { localTemperature in
                if let localTemperature = localTemperature {
                    self.node?.setMatterLocalTemperatureValue(temperature: localTemperature, deviceId: deviceId)
                    DispatchQueue.main.async {
                        self.controlValueLabel.text = "\(localTemperature) °C"
                    }
                }
            }
        }
        #endif
    }
    
    /// Setup offline indoor temperature UI
    /// Matches old GenericControlTableViewCell.setupOfflineLocalTemperatureUI()
    func setupOfflineLocalTemperatureUI() {
        self.setupLocallyStoredUI()
    }
    
    /// Set initial indoor temperature UI
    /// First set stored value as UI
    /// Subscribe to local temperature
    /// Matches old GenericControlTableViewCell.setupLocalTemperatureUI()
    func setupLocalTemperatureUI() {
        self.setupLocallyStoredUI()
        self.subscribeToLocalTemperature()
    }
}

