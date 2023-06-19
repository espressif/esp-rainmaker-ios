// Copyright 2023 Espressif Systems
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
//  RMIntentConstants.swift
//  ESPRainMaker
//

import Foundation

struct RMIntentConstants  {
    static let deviceListKey = "deviceList"
    static let configKey = "config"
    static let devicesKey = "devices"
    static let nameKey = "name"
    static let typeKey = "type"
    static let primaryKey = "primary"
    static let paramsKey = "params"
    static let dataTypeKey = "data_type"
    
    static let onDisplayString = "ON"
    static let offDisplayString = "OFF"
    static let locked = "Locked"
    static let unlocked = "Unlocked"
    static let jammed = "Jammed"
    
    static let powerParamType = "esp.param.power"
    static let lockParamType = "esp.param.lockstate"
    static let nameParamType = "esp.param.name"
    
    static let switchOn = "lightswitch.on.square"
    static let switchOff = "lightswitch.off.square"
    static let lightBulbIcon = "lightbulb.led.wide"
    static let lightBulbIconFilled = "lightbulb.circle"
    static let fanIcon = "fan.ceiling"
    static let fanIconFilled = "fan.ceiling.fill"
    static let thermostatIcon = "thermometer.sun.circle"
    static let thermostatIconFilled = "thermometer.sun.circle.fill"
    static let lockIcon = "lock"
    static let lockIconFilled = "lock.fill"
    static let lockOpenIcon = "lock.open"
    static let lockOpenIconFilled = "lock.open.fill"
    static let lockIconJammed = "lock.trianglebadge.exclamationmark.fill"
    static let outletIcon = "poweroutlet.type.d.fill"
    static let sensorIcon = "sensor"
    static let sensorIconFilled = "sensor.fill"
    static let defaultIcon = "defaultIconActive"
    static let defaultIconInactive = "defaultIconInactive"
    static let tempSensorIcon = "tempSensorActive"
    static let tempSensorInactiveIcon = "tempSensorInactive"
}
