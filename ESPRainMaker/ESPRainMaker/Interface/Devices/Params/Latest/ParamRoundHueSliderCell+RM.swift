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
//  ParamRoundHueSliderCell+RM.swift
//  ESPRainMaker
//
//  Component: Rainmaker-Specific Round Hue Update Logic
//  Handles: Rainmaker round hue parameter updates via DeviceControlHelper

import UIKit

extension ParamRoundHueSliderCell {
    
    // MARK: - Cell Reuse Protection
    internal func isSameParam(capturedParam: Param?, capturedParamName: String) -> Bool {
        if let currentParam = param, capturedParam === currentParam {
            return true
        }
        if let currentParamName = param?.name, !currentParamName.isEmpty {
            return currentParamName == capturedParamName
        }
        return false
    }
    
    // MARK: - Rainmaker Round Hue Parameter Update
    // CRITICAL: Always use param.name directly to prevent cell reuse bugs
    func updateParamRM(value: CGFloat, capturedParam: Param? = nil, capturedParamName: String? = nil, capturedDevice: Device? = nil) {
        let paramToUse = capturedParam ?? param
        let deviceToUse = capturedDevice ?? device
        
        guard let param = paramToUse,
              let paramName = capturedParamName ?? param.name,
              let device = deviceToUse,
              let nodeId = device.node?.node_id else {
            return
        }
        
        // Cell reuse protection
        guard isSameParam(capturedParam: paramToUse, capturedParamName: paramName) else {
            return
        }
        
        let intValue = Int(value)
        let previousParamValue = param.value // Capture for revert
        
        // Optimistic update: Update param.value
        param.value = intValue
        
        // Optimistic update: Update global node list
        if let nodes = User.shared.associatedNodeList,
           let node = nodes.first(where: { $0.node_id == nodeId }),
           let deviceName = device.name,
           let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
           let paramToUpdate = deviceInNode.params?.first(where: { $0.name == paramName }) {
            paramToUpdate.value = intValue
        }
        
        // Update via DeviceControlHelper - CRITICAL: Use paramName from param, not stored property
        DeviceControlHelper.shared.updateParam(
            nodeID: nodeId,
            parameter: [device.name ?? "": [paramName: intValue]],
            delegate: paramDelegate
        ) { [weak self] result in
            guard let self = self else { return }
            
            // Cell reuse protection
            guard self.isSameParam(capturedParam: paramToUse, capturedParamName: paramName) else {
                return
            }
            
            if result == .failure {
                DispatchQueue.main.async {
                    // Revert param.value
                    param.value = previousParamValue
                    // Revert global node list
                    if let nodes = User.shared.associatedNodeList,
                       let node = nodes.first(where: { $0.node_id == nodeId }),
                       let deviceName = device.name,
                       let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                       let paramToUpdate = deviceInNode.params?.first(where: { $0.name == paramName }) {
                        paramToUpdate.value = previousParamValue
                    }
                }
            }
        }
    }
}

