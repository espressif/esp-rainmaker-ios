// Copyright 2024 Espressif Systems
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
//  ESPControllerAPIKeys.swift
//  ESPRainmaker
//

import Foundation

class ESPControllerAPIKeys {
    
    static let matterController = "matter-controller"
    static let matterControllerDataVersion = "matter-controller-data-version"
    static let matterControllerData = "matter-controller-data"
    static let data = "data"
    static let enabled = "enabled"
    static let reachable = "reachable"
    static let matterNodes = "matter-nodes"
    static let matterNodeId = "matter-node-id"
    static let endpoints = "endpoints"
    static let endpointId = "endpoint-id"
    static let clusters = "clusters"
    static let clusterId = "cluster-id"
    static let commands = "commands"
    static let commandId = "command-id"
    static let servers = "servers"
    static let clients = "clients"
    static let attributes = "attributes"
    static let events = "events"
    
    static let onOffClusterId = "0x6"
    static let offCommandId = "0x0"
    static let onCommandId = "0x1"
    static let toggleCommandId = "0x2"
    static let onOffAttributeId = "0x0"
    static let levelControlClusterId = "0x8"
    static let colorControlClusterId =  "0x300"
    static let moveToLevelWithOnOffCommandId = "0x0"
    static let brightnessLevelAttributeId = "0x0"
    static let moveToSaturationCommandId = "0x3"
    static let moveToHueCommandId = "0x0"
    static let currentHueAttributeId = "0x0"
    static let currentSaturationAttributeId = "0x1"
    static let thermostatClusterId = "0x201"
    static let localTemperatureAttributeId = "0x0"
    static let systemModeAttributeId = "0x1c"
    static let occupiedCoolingSetpointAttributeId = "0x11"
    static let occupiedHeatingSetpointAttributeId = "0x12"
    static let temperatureMeasurementClusterId = "0x402"
    static let measuredTemperatureAttributeId = "0x0"
}
