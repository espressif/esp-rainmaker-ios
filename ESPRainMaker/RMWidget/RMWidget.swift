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
//  RMWidget.swift
//  ESPRainMaker
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    var device: UserDevice?
    
    init(date: Date, configuration: ConfigurationIntent) {
        self.date = date
        self.configuration = configuration
        if self.configuration.UserDevice == nil {
            // Get details of all devices stored in the local storage
            if let nodes = ESPLocalStorageNodes(ESPLocalStorageKeys.suiteName).fetchNodeDetails() {
                if let node = nodes.first {
                    if let device = node.devices?.first {
                        self.device = getUserDeviceWithID((node.node_id ?? "")+(device.name  ?? ""))
                    }
                }
            }
        } else {
            self.device = getUserDeviceWithID(self.configuration.UserDevice!.identifier!)
        }
    }
    
    /// Create Device object that contains information like name, primary parameter, primary value and connection status.
    /// - Parameter id: ID provided at the time of creating device list.
    /// - Returns: UserDevice object containing device information.
    func getUserDeviceWithID(_ id: String) -> UserDevice? {
        if let nodes = ESPLocalStorageNodes(ESPLocalStorageKeys.suiteName).fetchNodeDetails() {
            for node in nodes {
                for device in node.devices ?? [] {
                    // Check for device using identifier
                    if id == (node.node_id ?? "")+(device.name  ?? "") {
                        // Initialise user device object
                        let userDevice = UserDevice(identifier: (device.name ?? "")+(node.node_id ?? ""), display: device.getDeviceName() ?? "")
                        userDevice.name = device.getDeviceName() ?? device.name
                        userDevice.type = device.type
                        userDevice.connected = node.isConnected ? 1:0
                        userDevice.timestamp = NSNumber(value: node.timestamp)
                        
                        // Store primary parameter information.
                        if let primaryParam = device.params?.first(where: { $0.name == device.primary }) {
                            userDevice.primary_param = device.primary
                            userDevice.primary_type = primaryParam.type
                            switch primaryParam.dataType?.lowercased() {
                            case "bool":
                                if let param_value = primaryParam.value as? Bool {
                                    userDevice.param_value = param_value ? RMIntentConstants.onDisplayString:RMIntentConstants.offDisplayString
                                }
                            case "float":
                                if let param_value = primaryParam.value as? Float {
                                    userDevice.param_value = String(format: "%.2f", param_value)
                                }
                            case "int":
                                // Check if device is lock type
                                if let param_value = primaryParam.value as? Int {
                                    if primaryParam.type == RMIntentConstants.lockParamType {
                                        // Convert lock state to user readable description
                                        switch param_value {
                                        case 0:
                                            userDevice.param_value = RMIntentConstants.unlocked
                                        case 1:
                                            userDevice.param_value = RMIntentConstants.locked
                                        default:
                                            userDevice.param_value = RMIntentConstants.jammed
                                        }
                                    } else {
                                        userDevice.param_value = "\(param_value)"
                                    }
                                }
                            default:
                                if let param_value = primaryParam.value as? String {
                                    userDevice.param_value = param_value
                                }
                            }
                            }
                        return userDevice
                    }
                }
            }
        }
    return nil
    }
}

struct RMWidget: Widget {
    let kind: String = "RMWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            RMWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("RainMaker Widget")
        .description("Choose any device to quickly view its information.")
        .supportedFamilies([.systemSmall,.systemMedium])
    }
}
