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
//  ESPNodeSharingAddEvent.swift
//  ESPRainMaker
//

import Foundation

// Class associated with node group sharing add request event.
class ESPNodeGroupSharingAddEvent: ESPNotificationEvent {
    /// Modifies notification content to display message of node group sharing add request event.
    ///
    /// - Returns: Modified notification object.
    override func modifiedContent() -> ESPNotifications? {
        var modifiedNotification = notification
        // Gets primary user email that initiated the sharing request.
        if let primaryUser = eventData[ESPNotificationKeys.sharedFrom] as? String, let groups = eventData[ESPNotificationKeys.groups] as? [[String: Any]], let group = groups.last, let groupName = group[ESPNotificationKeys.groupName] as? String {
            // Gets metadata information from the event data.
            modifiedNotification.body = "\(primaryUser) is trying to share group \(groupName) with you. Tap to accept or decline."
        }
        // Returns modified notification.
        return modifiedNotification
    }
}
