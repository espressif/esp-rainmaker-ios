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
//  ESPSystemService.swift
//  ESPRainMaker
//

import Foundation

enum ESPSystemService: String {
    case reboot = "esp.param.reboot"
    case factoryReset = "esp.param.factory-reset"
    case wifiReset = "esp.param.wifi-reset"
    
    var alertDescription: String {
        switch self {
        case .factoryReset:
            return "Doing a factory reset on your device will erase all the data including Wi-Fi credentials from your device. You will no longer be able to control the device from the app. You need to provision the device again in order to control it. Do you wish to proceed?"
        case .reboot:
            return "Device will be rebooted. Please wait sometime after reset. Do you wish to proceed?"
        case .wifiReset:
            return "Doing a Wi-Fi reset on your device will erase the Wi-Fi credentials from your device. You will no longer be able to control the device from the app. You need to provision the device again in order to control it. Do you wish to proceed?"
        }
    }
}
