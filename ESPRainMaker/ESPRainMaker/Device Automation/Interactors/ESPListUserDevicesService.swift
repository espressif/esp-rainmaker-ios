// Copyright 2022 Espressif Systems
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
//  ESPListUserDeviceService.swift
//  ESPRainMaker
//

import Foundation

protocol ESPListUserDeviceLogic {
    func getListOfDevicesForEvent(nodes:[Node]?)
    func getListOfDevicesForActions(nodes:[Node]?)
}

class ESPListUserDeviceService: ESPListUserDeviceLogic {
    
    var presenter: ESPListUserDevicePresentationLogic?
    
    init(presenter: ESPListUserDevicePresentationLogic? = nil) {
        self.presenter = presenter
    }
    
    /// Method to get list of devices with params for which event can be added.
    ///
    /// - Parameters:
    ///   - nodes: User associated nodes.
    func getListOfDevicesForEvent(nodes: [Node]?) {
        var devices:[Device] = []
        for node in nodes ?? [] {
            for device in node.devices ?? [] {
                // Make copy of devices.
                let copyDevice = Device(device: device)
                let params = device.params?.filter({ $0.uiType != Constants.hidden })
                copyDevice.params = []
                for param in params ?? [] {
                    copyDevice.params?.append(Param(param: param))
                }
                if copyDevice.params?.count ?? 0 > 0 {
                    devices.append(copyDevice)
                }
            }
        }
        self.presenter?.listOfDevicesForAutomationEvent(devices: devices)
    }
    
    /// Method to get list of devices with params for which actions are added.
    ///
    /// - Parameters:
    ///   - nodes: User associated nodes.
    func getListOfDevicesForActions(nodes: [Node]?) {
        var devices:[Device] = []
        for node in nodes ?? [] {
            for device in node.devices ?? [] {
                let copyDevice = Device(device: device)
                // Remove parameter with hidden type.
                var params = device.params?.filter({ $0.uiType != Constants.hidden })
                // Remove parameter of device name.
                params = params?.filter({ $0.type != Constants.deviceNameParam})
                // Remove parameter with read-only property.
                params = params?.filter({ $0.properties?.contains("write") ?? false})
                copyDevice.params = []
                for param in params ?? [] {
                    copyDevice.params?.append(Param(param: param))
                }
                if copyDevice.params?.count ?? 0 > 0 {
                    devices.append(copyDevice)
                }
            }
        }
        self.presenter?.listOfDevicesForAutomationAction(devices: devices)
    }
}
