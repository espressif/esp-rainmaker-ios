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
//  ESPRMDeviceType+GetImage.swift
//  ESPRainMaker
//

import Foundation
import UIKit

extension ESPRMDeviceType {
    func getImageFromDeviceType() -> UIImage? {
        switch self {
        case .switchDevice:
            return UIImage(named: "switch")
        case .lightbulb, .light:
            return UIImage(named: "light")
        case .fan:
            return UIImage(named: "fan")
        case .temperatureSensor:
            return UIImage(named: "temperature_sensor")
        case .outlet:
            return UIImage(named: "outlet")
        case .plug:
            return UIImage(named: "plug")
        case .socket:
            return UIImage(named: "socket")
        case .lock:
            return UIImage(named: "lock")
        case .internalBlinds:
            return UIImage(named: "internal_blinds")
        case .externalBlinds:
            return UIImage(named: "external_blinds")
        case .garageDoor:
            return UIImage(named: "garage_door")
        case .speaker:
            return UIImage(named: "speaker")
        case .airConditioner:
            return UIImage(named: "air_conditioner")
        case .thermostat:
            return UIImage(named: "thermostat")
        case .tv:
            return UIImage(named: "tv")
        case .washer:
            return UIImage(named: "washer")
        case .contactSensor:
            return UIImage(named: "contact_sensor")
        case .motionSensor:
            return UIImage(named: "motion_sensor")
        case .doorBell:
            return UIImage(named: "door_bell")
        case .securitypanel:
            return UIImage(named: "security_panel")
        case .other:
            return UIImage(named: "other")
        case .sensor:
            return UIImage(named: "sensor_icon")
        case .gateway, .zigbeeGateway:
            return UIImage(named: "gateway")
        }
    }
}
