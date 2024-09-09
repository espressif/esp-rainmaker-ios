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
//  ESPOTAUpdateEvent.swift
//  ESPRainMaker
//

import Foundation

class ESPOTAUpdateEvent: ESPNotificationEvent {
    /// Modifies notification content to display message of  OTA update event
    ///
    /// - Returns: Modified notification object.
    override func modifiedContent() -> ESPNotifications? {
        var modifiedNotification = notification
        // Get the node name
        var body = "A new OTA update is available for some node(s)."
        if let nodeId = eventData[ESPNotificationKeys.nodeIDKey] as? String, let node = ESPLocalStorageNodes(ESPLocalStorageKeys.suiteName).getNode(nodeID: nodeId), let devices = node.devices, let device = devices.first, device.deviceName.count > 0 {
            body = "A new OTA update is available for \(device.deviceName)."
        }
        modifiedNotification.body = body
        notificationStore.storeESPNotification(notification: modifiedNotification)
        // Returns modified notification.
        return modifiedNotification
    }
}
