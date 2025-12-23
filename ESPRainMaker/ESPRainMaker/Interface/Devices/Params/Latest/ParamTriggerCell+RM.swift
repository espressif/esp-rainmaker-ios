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
//  ParamTriggerCell+RM.swift
//  ESPRainMaker
//
//  Component: Rainmaker-Specific Trigger Update Logic
//  Handles: Rainmaker trigger parameter updates via DeviceControlHelper

import UIKit

extension ParamTriggerCell {
    
    // MARK: - Trigger Button Action
    @objc func triggerPressed(_ sender: Any) {
        // CRITICAL: Capture param and paramName at start for cell reuse protection
        guard let capturedParam = param,
              let capturedParamName = capturedParam.name,
              let capturedDevice = device,
              let nodeId = capturedDevice.node?.node_id else {
            return
        }
        
        // CRITICAL: Verify cell still shows the same param (cell reuse protection)
        guard isSameParam(capturedParam: capturedParam, capturedParamName: capturedParamName) else {
            return
        }
        
        // CRITICAL: Check if device is offline before sending update
        // For Rainmaker devices, check node connection
        if let node = capturedDevice.node {
            let isConnected = node.isConnected || node.localNetwork
            if !isConnected {
                // Don't update - device is offline
                return
            }
        }
        
        // CRITICAL: Capture current value before optimistic update (for failure revert)
        let previousParamValue = capturedParam.value
        
        // Animate button to show trigger effect
        triggerButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.39,
            initialSpringVelocity: 0,
            options: .allowUserInteraction,
            animations: {
                self.triggerButton.transform = .identity
            },
            completion: {_ in }  // Matches old implementation: {_ in } instead of nil
        )
        
        // Optimistic update: Update param value (local reference)
        capturedParam.value = true
        
        // Optimistic update: Update param value in global node list
        if let nodes = User.shared.associatedNodeList,
           let node = nodes.first(where: { $0.node_id == nodeId }),
           let deviceName = capturedDevice.name,
           let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
           let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
            paramToUpdate.value = true
        }
        
        // Update via DeviceControlHelper - CRITICAL: Add completion handler for failure handling
        DeviceControlHelper.shared.updateParam(
            nodeID: nodeId,
            parameter: [capturedDevice.name ?? "": [capturedParamName: true]],
            delegate: paramDelegate
        ) { [weak self] result in
            guard let self = self else { return }
            
            // CRITICAL: Verify cell still shows the same param before reverting (cell reuse protection)
            guard self.isSameParam(capturedParam: capturedParam, capturedParamName: capturedParamName) else {
                return
            }
            
            // CRITICAL: Handle failure - revert param value if update failed
            if result == .failure {
                DispatchQueue.main.async {
                    // Revert param.value
                    capturedParam.value = previousParamValue
                    
                    // Revert global node list
                    if let nodes = User.shared.associatedNodeList,
                       let node = nodes.first(where: { $0.node_id == nodeId }),
                       let deviceName = capturedDevice.name,
                       let deviceInNode = node.devices?.first(where: { $0.name == deviceName }),
                       let paramToUpdate = deviceInNode.params?.first(where: { $0.name == capturedParamName }) {
                        paramToUpdate.value = previousParamValue
                    }
                }
            }
        }
    }
    
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
}

