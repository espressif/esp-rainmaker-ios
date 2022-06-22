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
//  ESPAutomationTriggerEvent.swift
//  ESPRainMaker
//

import Foundation

class ESPAutomationTriggerEvent: ESPNotificationEvent {
    // Static keys
    let automationNameKey = "automation_name"
    let eventsKey = "events"
    let paramsKey = "params"
    let checkKey = "check"
    let actionsKey = "actions"
    let statusKey = "status"
    let success = "success"
    
    
    override func modifiedContent() -> ESPNotifications? {
        var modifiedNotification = notification
        modifiedNotification.title = "Automation"
        if let name = eventData[automationNameKey] as? String {
            modifiedNotification.title.append(contentsOf: ": " + name)
        }
        // Get description of devices action status
        if let nodes = ESPLocalStorageNodes(ESPLocalStorageKeys.suiteName).fetchNodeDetails() {
            modifiedNotification.body = getActionDescription(nodes: nodes)
        }
        notificationStore.storeESPNotification(notification: modifiedNotification)
        return modifiedNotification
    }
    
    // Method to get event description but not used in actual notifications.
    private func getEventDescription(devices:[Device]) -> String {
        var description:[String] = []
        if let events = eventData[eventsKey] as? [[String:Any]]{
            for event in events {
                if let paramJSON = event[paramsKey] as? [String:Any], var check = event[checkKey] as? String {
                    for (key, value) in paramJSON {
                        var params:[String] = []
                        if let param = value as? [String: Any] {
                            for (key, value) in param {
                                // Replaced occurence of == string with = for better readability.
                                if check == "==" {
                                    check = ":"
                                }
                                params.append(key + " " + check + " \(value)")
                            }
                        }
                        if let device = devices.first(where: { $0.name == key}) {
                            description.append(device.deviceName + ": " + params.joined(separator: ","))
                        } else {
                            description.append(key + ": " + params.joined(separator: ","))
                        }
                    }
                }
            }
        }
        return description.joined(separator: ";")
    }
    
    private func getActionDescription(nodes:[Node]) -> String {
        var failedDevices:[String] = []
        var successDevices:[String] = []
        var description: [String] = []
        if let actions = eventData[actionsKey] as? [[String:Any]] {
            for action in actions {
                if let nodeID = action[ESPNotificationKeys.nodeIDKey] as? String, let params = action[paramsKey] as? [String:[String:Any]] {
                    for (key, _) in params {
                        if let node = nodes.first(where: { $0.node_id == nodeID}), let device = node.devices?.first(where: { $0.name == key}) {
                            getStatus(nodeID: nodeID) == true ? successDevices.append(device.deviceName) : failedDevices.append(device.deviceName)
                        } else {
                            getStatus(nodeID: nodeID) == true ? successDevices.append(key) : failedDevices.append(key)
                        }
                    }
                }
            }
        }
        if successDevices.count > 0 {
            description.append("Successfully executed action for device\(successDevices.count == 1 ? "":"s"): \(successDevices.joined(separator: ", "))")
        }
        if failedDevices.count > 0 {
            description.append("Failed to execute action for device\(failedDevices.count == 1 ? "":"s"): \(failedDevices.joined(separator: ", "))")
        }
        return description.joined(separator: "; ") + "."
    }
    
    private func getStatus(nodeID: String) -> Bool {
        if let status = eventData[statusKey] as? [[String:String]] {
            for status in status {
                if status[ESPNotificationKeys.nodeIDKey] == nodeID {
                    if status[statusKey] == success {
                        return true
                    } else {
                        return false
                    }
                }
            }
        }
        return false
    }
}
