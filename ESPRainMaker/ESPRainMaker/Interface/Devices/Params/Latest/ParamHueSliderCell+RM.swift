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
//  ParamHueSliderCell+RM.swift
//  ESPRainMaker
//
//  Component: Rainmaker-Specific Hue Update Logic
//  Handles: Rainmaker hue parameter updates via DeviceControlHelper

import UIKit

extension ParamHueSliderCell {
    
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
    
    // MARK: - Rainmaker Hue Parameter Update
    // CRITICAL: Always use param.name directly to prevent cell reuse bugs
    func updateParamRM(value: Int, isContinuous: Bool, capturedParam: Param? = nil, capturedParamName: String? = nil, capturedDevice: Device? = nil, skipOptimisticUpdate: Bool = false, completion: ((Bool) -> Void)? = nil) {
        let paramToUse = capturedParam ?? param
        let deviceToUse = capturedDevice ?? device
        
        guard let param = paramToUse,
              let paramName = capturedParamName ?? param.name,
              let device = deviceToUse,
              let nodeId = device.node?.node_id else {
            completion?(false)
            return
        }
        
        // Cell reuse protection
        guard isSameParam(capturedParam: paramToUse, capturedParamName: paramName) else {
            completion?(false)
            return
        }
        
        let previousParamValue = param.value // Capture for revert
        
        // CRITICAL: Do NOT update param.value or global node list here when skipOptimisticUpdate is true
        // Those updates were already done on main thread before this method was called
        if !skipOptimisticUpdate {
            // Optimistic update: Update param.value
            param.value = value
            
            // Optimistic update: Update global node list
            if let nodes = User.shared.associatedNodeList,
               let node = nodes.first(where: { $0.node_id == nodeId }),
               let deviceName = device.name,
               let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
               let paramToUpdate = deviceInNode.params?.first(where: { $0.name == paramName }) {
                paramToUpdate.value = value
            }
            
            // Update slider initial value
            sliderInitialValue = Float(value)
        }
        
        // Update via DeviceControlHelper - CRITICAL: Use paramName from param, not stored property
        DeviceControlHelper.shared.updateParam(
            nodeID: nodeId,
            parameter: [device.name ?? "": [paramName: value]],
            delegate: paramDelegate
        ) { [weak self] result in
            guard let self = self else {
                completion?(false)
                return
            }
            
            // Cell reuse protection
            guard self.isSameParam(capturedParam: paramToUse, capturedParamName: paramName) else {
                completion?(false)
                return
            }
            
            let success = (result == .success)
            
            // For non-continuous updates, handle immediate revert on failure
            // For continuous updates, defer revert handling until all complete
            if !success {
                DispatchQueue.main.async {
                    // Only revert immediately for non-continuous updates
                    // Continuous updates will be handled after all complete
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
                    
                    // Revert slider if non-continuous
                    if !isContinuous, let initialValue = self.sliderInitialValue {
                        self.hueSlider.setValue(CGFloat(initialValue), animated: true)
                        self.hueSlider.thumbColor = UIColor(hue: CGFloat(initialValue) / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                    }
                }
            }
            
            // Call completion handler with success/failure
            completion?(success)
        }
    }
}

