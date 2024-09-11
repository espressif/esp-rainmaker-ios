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
//  ESPNodeGroupSharingAcceptedEvent.swift
//  ESPRainMaker
//

import Foundation

// Class associated with node group sharing request accepted event.
class ESPNodeGroupSharingAcceptedEvent: ESPNotificationEvent {
    /// Modifies notification content to display message of node group sharing request accepted event.
    ///
    /// - Returns: Modified notification object.
    override func modifiedContent() -> ESPNotifications? {
        var modifiedNotification = notification
        // Gets secondary user email that accepted the sharing request.
        if let secondaryUser = eventData[ESPNotificationKeys.sharedTo] as? String, let groups = eventData[ESPNotificationKeys.groups] as? [[String: Any]], let group = groups.last, let groupName = group[ESPNotificationKeys.groupName] as? String {
            modifiedNotification.body = "\(secondaryUser) has accepted the request for group \(groupName)."
        }
        notificationStore.storeESPNotification(notification: modifiedNotification)
        // Returns modified notification.
        return modifiedNotification
    }
}
