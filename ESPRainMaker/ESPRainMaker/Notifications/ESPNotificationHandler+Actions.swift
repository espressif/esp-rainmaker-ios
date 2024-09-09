// Copyright 2021 Espressif Systems
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
//  ESPNotificationHandler+Actions.swift
//  ESPRainMaker
//

import Foundation
import UIKit

// Handles user action for different notification events.
extension ESPNotificationHandler {
    
    // Method to handle notification events based on category.
    func handleEvent(_ category: ESPNotificationCategory?, _ action: String) {
        switch category {
        case .addSharing:
            switch eventType {
            case .groupSharingAdd:
                ESPNodeGroupSharingAddEvent(eventData,notification).handleAction(action)
            default:
                ESPNodeSharingAddEvent(eventData,notification).handleAction(action)
            }
        default:
            var navigationHandler: UserNavigationHandler?
            switch eventType {
            case .groupSharingRemoved, .nodeGroupAdded:
                navigationHandler = .groupSharing
            case .nodeAssociated, .nodeDissassociated, .nodeConnected, .nodeDisconnected:
                navigationHandler = .homeScreen
            case .userNodeOTA:
                navigationHandler = .userNodeOTA(eventData: self.eventData)
            default:
                navigationHandler =  .notificationViewController
            }
            navigationHandler?.navigateToPage()
        }
    }
}
