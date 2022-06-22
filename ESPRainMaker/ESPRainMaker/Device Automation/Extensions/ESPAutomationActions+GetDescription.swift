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
//  ESPAutomationActions+GetDescription.swift
//  ESPRainMaker
//

import Foundation

// Extension defines methods for getting automation related description.
extension ESPAutomationTriggerAction {
    
    /// Method to get description of automation action.
    ///
    /// - Returns: String describing the actions of automation.
    func getActionDescription(nodes: [Node]) -> String {
        var description:[String] = []
        for action in actions ?? [] {
            if let node = nodes.first(where: { $0.node_id == action.nodeID }) {
                for (key, value) in action.params ?? [:] {
                    if let device = node.devices?.first(where: { $0.name == key }) {
                        var params:[String] = []
                        for (key, value) in value {
                            if let param = device.params?.first(where: { $0.name == key }) {
                                if param.dataType?.lowercased() == "bool", let value = value as? Bool {
                                    params.append(key + ":" + "\(value)")
                                } else {
                                    params.append(key + ":" + "\(value)")
                                }
                            }
                        }
                        params.sort(by: >)
                        description.append(device.deviceName + ": " + params.joined(separator: ","))
                    }
                }
            }
        }
        description.sort(by: >)
        return description.joined(separator: ";")
    }
    
    /// Method to get description of automation event.
    ///
    /// - Returns: String describing the event of automation.
    func getEventDescription(nodes: [Node]) -> String {
        var description:[String] = []
        for event in events ?? [] {
            if let paramJSON = event[ESPAutomationConstants.params] as? [String:Any], var check = event[ESPAutomationConstants.check] as? String {
                if let node = nodes.first(where: { $0.node_id == nodeID }) {
                    for (key, value) in paramJSON {
                        if let device = node.devices?.first(where: { $0.name == key }) {
                            var params:[String] = []
                            if let param = value as? [String: Any] {
                                for (key, value) in param {
                                    // Replaced occurence of == string with = for better readability.
                                    if check == "==" {
                                        check = ":"
                                    }
                                    if let param = device.params?.first(where: { $0.name == key }) {
                                        if param.dataType?.lowercased() == "bool", let value = value as? Bool {
                                            params.append(key + check + "\(value)")
                                        } else {
                                            params.append(key + check + "\(value)")
                                        }
                                    }
                                }
                                params.sort(by: >)
                            }
                            description.append(device.deviceName + ": " + params.joined(separator: ","))
                        }
                    }
                }
            }
        }
        description.sort(by: >)
        return description.joined(separator: ";")
    }
}
