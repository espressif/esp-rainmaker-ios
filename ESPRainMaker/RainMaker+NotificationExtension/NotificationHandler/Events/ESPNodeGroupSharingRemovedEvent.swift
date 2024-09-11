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
//  ESPNodeGroupSharingRemovedEvent.swift
//  ESPRainMaker
//

import Foundation

// Class associated with node group sharing removed event.
class ESPNodeGroupSharingRemovedEvent: ESPNotificationEvent {
    /// Modifies notification content to display message of node group sharing removed
    ///
    /// - Returns: Modified notification object.
    override func modifiedContent() -> ESPNotifications? {
        var modifiedNotification = notification
        // Get the group name
        if let groups = eventData[ESPNotificationKeys.groups] as? [[String: Any]], let group = groups.last, let groupName = group[ESPNotificationKeys.groupName] as? String {
            // Get the self_removal key value
            if let selfRemoval = eventData[ESPNotificationKeys.selfRemoval] as? Bool, selfRemoval {
                modifiedNotification.body = "You have left group \(groupName)."
            } else if let sharedFrom = eventData[ESPNotificationKeys.sharedFrom] as? String {
                modifiedNotification.body = "\(sharedFrom) has removed \(groupName) group access from you."
            }
        }
        notificationStore.storeESPNotification(notification: modifiedNotification)
        // Returns modified notification.
        return modifiedNotification
    }
}
