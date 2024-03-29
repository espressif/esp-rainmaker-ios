// Copyright 2021 Espressif Systems
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
//  NodeExtension.swift
//  ESPRainMaker
//

import Foundation

/// Protocol defined for getting scheduling status for node
@objc protocol MaxScheduleProtocol: AnyObject {
    @objc optional var isSchedulingAllowed: Bool { get }
}

/// Protocol defined for getting scene status for node
@objc protocol MaxSceneProtocol: AnyObject {
    @objc optional var isSceneAllowed: Bool { get }
}

extension Node: MaxScheduleProtocol, MaxSceneProtocol {
    /// Returns true if scheuling is allowed
    var isSchedulingAllowed: Bool {
        if isSchedulingSupported {
            if (maxSchedulesCount > 0 && currentSchedulesCount < maxSchedulesCount) || maxSchedulesCount == -1 {
                return true
            }
        }
        return false
    }
    
    var isSceneAllowed: Bool {
        if isSceneSupported {
            if (maxScenesCount > 0 && currentScenesCount < maxScenesCount) || maxScenesCount == -1 {
                return true
            }
        }
        return false
    }
    
    /// Find value of light
    func isPowerOn() -> Bool {
        if let devices = self.devices, let device = devices.first {
            for param in device.params ?? [] {
                if param.uiType == "esp.ui.toggle", param.name == "Power", let dataType = param.dataType, dataType.lowercased() == "bool", let value = param.value as? Bool {
                    return value
                }
            }
        }
        return false
    }
    
    /// Update light param
    func updateLightParam() {
        let val = self.isPowerOn()
        if let devices = self.devices, let device = devices.first {
            for param in device.params ?? [] {
                if param.uiType == "esp.ui.toggle", param.name == "Power", let dataType = param.dataType, dataType.lowercased() == "bool" {
                    param.value = !val
                }
            }
        }
    }
    
    /// Is light supported on the device
    func isLightSupported() -> Bool {
        if let devices = self.devices, let device = devices.first {
            for param in device.params ?? [] {
                if param.uiType == "esp.ui.toggle", param.name == "Power", let dataType = param.dataType, dataType.lowercased() == "bool" {
                    return true
                }
            }
        }
        return false
    }
}


