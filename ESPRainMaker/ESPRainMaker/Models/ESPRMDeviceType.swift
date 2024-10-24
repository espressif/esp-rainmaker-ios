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
//  ESPRMDeviceType.swift
//  ESPRainMaker
//

import Foundation

enum ESPRMDeviceType: String {
    case switchDevice = "esp.device.switch"
    case lightbulb = "esp.device.lightbulb"
    case light = "esp.device.light"
    case fan = "esp.device.fan"
    case temperatureSensor = "esp.device.temperature-sensor"
    case outlet = "esp.device.outlet"
    case plug = "esp.device.plug"
    case socket = "esp.device.socket"
    case lock = "esp.device.lock"
    case internalBlinds = "esp.device.blinds-internal"
    case externalBlinds = "esp.device.blinds-external"
    case garageDoor = "esp.device.garage-door"
    case speaker = "esp.device.speaker"
    case airConditioner = "esp.device.air-conditioner"
    case thermostat = "esp.device.thermostat"
    case tv = "esp.device.tv"
    case washer = "esp.device.washer"
    case contactSensor = "esp.device.contact-sensor"
    case motionSensor = "esp.device.motion-sensor"
    case doorBell = "esp.device.doorbell"
    case securitypanel = "esp.device.security-panel"
    case other = "esp.device.other"
    case sensor = "esp.device.sensor"
    case gateway = "esp.device.gateway"
    case zigbeeGateway = "esp.device.zigbee_gateway"
    case threadBR = "esp.device.thread-br"
}
