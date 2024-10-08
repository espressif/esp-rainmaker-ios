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
//  ESPNodeGroupSharingDeclinedEvent.swift
//  ESPRainMaker
//

import Foundation

// Class associated with node group sharing request declined event.
class ESPNodeGroupSharingDeclinedEvent: ESPNotificationEvent {
    /// Modifies notification content to display message of node group sharing request declined.
    ///
    /// - Returns: Modified notification object.
    override func modifiedContent() -> ESPNotifications? {
        var modifiedNotification = notification
        // Gets secondary user email that declined the sharing request.
        if let secondaryUser = eventData[ESPNotificationKeys.sharedTo] as? String, let groups = eventData[ESPNotificationKeys.groups] as? [[String: Any]], let group = groups.last, let groupName = group[ESPNotificationKeys.groupName] as? String {
            modifiedNotification.body = "\(secondaryUser) has declined the request for group \(groupName)."
        }
        // Saves notification in local storage.
        notificationStore.storeESPNotification(notification: modifiedNotification)
        // Returns modified notification.
        return modifiedNotification
    }
}
