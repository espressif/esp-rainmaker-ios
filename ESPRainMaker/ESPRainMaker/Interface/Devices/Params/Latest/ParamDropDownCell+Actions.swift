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
//  ParamDropDownCell+Actions.swift
//  ESPRainMaker
//
//  Component: Dropdown Action Handling
//  Handles: Dropdown button tap, selection handling, routing to RM/Matter updates

import UIKit
import DropDown

extension ParamDropDownCell {
    
    // MARK: - Dropdown Button Action
    @objc func dropDownButtonPressed(_ sender: Any) {
        // CRITICAL: Capture param and paramName at dropdown open to prevent cell reuse bugs
        guard let capturedParam = param,
              let capturedParamName = capturedParam.name else {
            return
        }
        let capturedDevice = device
        let capturedIsRainmaker = isRainmaker
        let capturedType = type
        let capturedCurrentValue = currentValue
        
        // Configure dropdown appearance
        DropDown.appearance().backgroundColor = UIColor.white
        DropDown.appearance().selectionBackgroundColor = #colorLiteral(red: 0.04705882353, green: 0.4392156863, blue: 0.9098039216, alpha: 1)
        
        let dropDown = DropDown()
        dropDown.dataSource = datasource
        dropDown.width = UIScreen.main.bounds.size.width - 100
        dropDown.anchorView = self
        
        // Select current value in dropdown
        if let index = datasource.firstIndex(where: { $0 == capturedCurrentValue }) {
            dropDown.selectRow(at: index)
        }
        
        dropDown.show()
        
        // Handle selection - CRITICAL: Use captured values to prevent cell reuse bugs
        dropDown.selectionAction = { [unowned self] (_: Int, item: String) in
            // CRITICAL: Verify cell still shows the same param before updating (cell reuse protection)
            guard self.isSameParam(capturedParam: capturedParam, capturedParamName: capturedParamName) else {
                return
            }
            
            if capturedIsRainmaker {
                self.updateParamRM(selectedValue: item, capturedParamName: capturedParamName, capturedParam: capturedParam, capturedDevice: capturedDevice)
            } else {
                #if ESPRainMakerMatter
                if #available(iOS 16.4, *) {
                    self.updateParamMatter(selectedValue: item, capturedParamName: capturedParamName, capturedType: capturedType)
                }
                #endif
            }
        }
    }
    
    // MARK: - Cell Reuse Protection
    /// Check if cell still shows the same param (prevents cell reuse bugs)
    /// - Parameters:
    ///   - capturedParam: The param object captured at dropdown open
    ///   - capturedParamName: The param name captured at dropdown open
    /// - Returns: true if cell still shows the same param, false otherwise
    func isSameParam(capturedParam: Param?, capturedParamName: String) -> Bool {
        // Identity check: same object reference (fastest, most reliable if objects aren't replaced)
        if let currentParam = param, capturedParam === currentParam {
            return true
        }
        // Name check: same param name (handles case where param object was replaced but it's the same param)
        if let currentParamName = param?.name, !currentParamName.isEmpty {
            return currentParamName == capturedParamName
        }
        // If current param is nil or has no name, cell was definitely reused
        return false
    }
    
    // MARK: - Matter Dropdown Update Router
    #if ESPRainMakerMatter
    @available(iOS 16.4, *)
    func updateParamMatter(selectedValue: String, capturedParamName: String? = nil, capturedType: DropDownType? = nil) {
        guard let grpId = self.nodeGroup?.groupID, let dId = self.deviceId else { return }
        
        // Use captured type if provided, otherwise use current type
        let typeToUse = capturedType ?? self.type
        
        switch typeToUse {
        case .controlSequenceOfOperation:
            self.updateControlSequenceOfOperation(value: selectedValue, capturedParamName: capturedParamName)
        case .systemMode:
            self.updateSystemMode(value: selectedValue, capturedParamName: capturedParamName)
        default:
            break
        }
    }
    #endif
}

