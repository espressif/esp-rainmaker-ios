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
//  ParamDropDownCell+Matter.swift
//  ESPRainMaker
//
//  Component: Matter-Specific Dropdown Logic
//  Handles: Matter System Mode, Control Sequence of Operation dropdowns

#if ESPRainMakerMatter
import UIKit
import Matter

@available(iOS 16.4, *)
extension ParamDropDownCell {
    
    // MARK: - Matter System Mode - Update
    func updateSystemMode(value: String, capturedParamName: String? = nil) {
        guard let grpId = self.nodeGroup?.groupID, let dId = self.deviceId else { return }
        
        // CRITICAL: Capture current value before optimistic update (for failure revert)
        let previousValue = currentValue
        
        var modeValue = 0
        if value == ESPMatterConstants.off {
            modeValue = 0
        } else if value == ESPMatterConstants.cool {
            modeValue = 3
        } else if value == ESPMatterConstants.heat {
            modeValue = 4
        }
        
        // Optimistic update
        currentValue = value
        controlValueLabel.text = value
        
        self.paramChipDelegate?.matterAPIRequestSent()
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
        commissioner.setSystemMode(groupId: grpId, deviceId: dId, mode: NSNumber(value: modeValue)) { [weak self] result in
            guard let self = self else { return }
            
            // CRITICAL: Verify cell still shows the same param before updating (cell reuse protection)
            if let capturedParamName = capturedParamName {
                guard self.isSameParam(capturedParamName: capturedParamName) else {
                    return
                }
            }
            
            self.paramChipDelegate?.matterAPIResponseReceived()
            if result {
                self.matterNode?.setMatterSystemMode(systemMode: value, deviceId: dId)
                DispatchQueue.main.async {
                    self.controlValueLabel.text = value
                    self.acParamDelegate?.acSystemModeSet()
                }
            } else {
                // CRITICAL: Revert on failure
                DispatchQueue.main.async {
                    self.currentValue = previousValue
                    self.controlValueLabel.text = previousValue
                }
            }
        }
    }
    
    // MARK: - Matter System Mode - Set Initial (matches old ParamDropDownTableViewCell+ParamDropDownCoolingControlProtocol)
    func setInitialSystemMode() {
        // NOTE: Original sets backViewTopSpaceConstraint and backViewBottomSpaceConstraint to 10.0,
        // but new programmatic cell uses fixed constraints in setupUI() that match the XIB layout.
        // No constraint modification needed for the new implementation.
        self.controlValueLabel.text = "_"
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            if let systemMode = self.matterNode?.getMatterSystemMode(deviceId: id) {
                DispatchQueue.main.async {
                    self.controlValueLabel.text = systemMode
                }
            }
            self.readAndSubscribeToSystemMode(groupId: grpId, deviceId: id)
        }
    }
    
    // MARK: - Matter System Mode - Read and Subscribe (matches old implementation)
    func readAndSubscribeToSystemMode(groupId: String, deviceId: UInt64) {
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
        commissioner.readSystemMode(groupId: groupId, deviceId: deviceId) { value in
            if let value = value {
                let val = value.intValue
                var systemMode = ESPMatterConstants.off
                if val == 0 {
                    systemMode = ESPMatterConstants.off
                } else if val == 3 {
                    systemMode = ESPMatterConstants.cool
                } else if val == 4 {
                    systemMode = ESPMatterConstants.heat
                }
                self.matterNode?.setMatterSystemMode(systemMode: systemMode, deviceId: deviceId)
                DispatchQueue.main.async {
                    self.controlValueLabel.text = systemMode
                }
                self.acParamDelegate?.acSystemModeSet()
            }
        }
    }
    
    // MARK: - Matter System Mode - Subscribe (matches old implementation)
    func subscribeSystemMode() {
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
            commissioner.subscribeSystemMode(groupId: grpId, deviceId: id) { value in
                if let value = value {
                    let mode = value.intValue
                    var systemMode = ESPMatterConstants.off
                    switch mode {
                    case 3:
                        systemMode = ESPMatterConstants.cool
                    case 4:
                        systemMode = ESPMatterConstants.heat
                    default:
                        break
                    }
                    self.matterNode?.setMatterSystemMode(systemMode: systemMode, deviceId: id)
                    DispatchQueue.main.async {
                        self.controlValueLabel.text = systemMode
                    }
                    self.acParamDelegate?.acSystemModeSet()
                }
            }
        }
    }
    
    // MARK: - Matter Control Sequence of Operation - Update
    func updateControlSequenceOfOperation(value: String, capturedParamName: String? = nil) {
        guard let grpId = self.nodeGroup?.groupID, let dId = self.deviceId else { return }
        
        // CRITICAL: Capture current value before optimistic update (for failure revert)
        let previousValue = currentValue
        
        var csoValue = 0
        if value == ESPMatterConstants.cool {
            csoValue = 4
        }
        
        // Optimistic update
        currentValue = value
        controlValueLabel.text = value
        
        self.paramChipDelegate?.matterAPIRequestSent()
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
        commissioner.setControlSequenceOfOperation(groupId: grpId, deviceId: dId, cos: NSNumber(value: csoValue)) { [weak self] result in
            guard let self = self else { return }
            
            // CRITICAL: Verify cell still shows the same param before updating (cell reuse protection)
            if let capturedParamName = capturedParamName {
                guard self.isSameParam(capturedParamName: capturedParamName) else {
                    return
                }
            }
            
            self.paramChipDelegate?.matterAPIResponseReceived()
            if result {
                self.matterNode?.setMatterControlledSequenceOfOperation(cso: value, deviceId: dId)
                DispatchQueue.main.async {
                    self.controlValueLabel.text = value
                }
            } else {
                // CRITICAL: Revert on failure
                DispatchQueue.main.async {
                    self.currentValue = previousValue
                    self.controlValueLabel.text = previousValue
                }
            }
        }
    }
    
    // MARK: - Cell Reuse Protection Helper
    /// Check if cell still shows the same param (prevents cell reuse bugs)
    /// - Parameter capturedParamName: The param name captured at dropdown open
    /// - Returns: true if cell still shows the same param, false otherwise
    func isSameParam(capturedParamName: String) -> Bool {
        // Name check: same param name
        if let currentParamName = param?.name, !currentParamName.isEmpty {
            return currentParamName == capturedParamName
        }
        // If current param is nil or has no name, cell was definitely reused
        return false
    }
    
    // MARK: - Matter Control Sequence of Operation - Set Initial (matches old ParamDropDownTableViewCell+ParamDropDownCoolingControlProtocol)
    func setInitialControlSequenceOfOperation() {
        DispatchQueue.main.async {
            self.controlValueLabel.text = "_"
        }
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            if let cso = self.matterNode?.getMatterControlledSequenceOfOperation(deviceId: id) {
                DispatchQueue.main.async {
                    self.controlValueLabel.text = cso
                }
                self.matterNode?.setMatterControlledSequenceOfOperation(cso: cso, deviceId: id)
            } else {
                let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
                commissioner.readControlSequenceOfOperation(groupId: grpId, deviceId: id) { value in
                    if let value = value {
                        let val = value.intValue
                        var cso = ESPMatterConstants.off
                        if val == 4 {
                            cso = ESPMatterConstants.cool
                        }
                        self.matterNode?.setMatterControlledSequenceOfOperation(cso: cso, deviceId: id)
                        DispatchQueue.main.async {
                            self.controlValueLabel.text = cso
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Matter Control Sequence of Operation - Subscribe (matches old implementation)
    func subscribeControlSequenceOfOperation() {
        if let grpId = self.nodeGroup?.groupID, let id = self.deviceId {
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
            commissioner.subscribeControlSequenceOfOperation(groupId: grpId, deviceId: id) { value in
                if let value = value {
                    let val = value.intValue
                    var cso = ESPMatterConstants.off
                    if val == 4 {
                        cso = ESPMatterConstants.cool
                    }
                    self.matterNode?.setMatterControlledSequenceOfOperation(cso: cso, deviceId: id)
                    DispatchQueue.main.async {
                        self.controlValueLabel.text = cso
                    }
                }
            }
        }
    }
}

#endif

