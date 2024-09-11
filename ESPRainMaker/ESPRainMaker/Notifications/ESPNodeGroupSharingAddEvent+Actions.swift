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
//  ESPNodeGroupSharingAddEvent+Actions.swift
//  ESPRainMaker
//


import Foundation
import UIKit

extension ESPNodeGroupSharingAddEvent {
    func handleAction(_ actionIdentifier: String) {
        var navigationHandler = UserNavigationHandler.groupSharing
        switch ESPNotificationsAddSharingCategory(rawValue: actionIdentifier) {
        case .accept:
            if let requestID = eventData[ESPNotificationKeys.requestIDKey] as? String {
                NodeGroupSharingManager.shared.actOnSharingRequest(requestId: requestID, accept: true) { _ in
                    DispatchQueue.main.async {
                        NodeGroupManager.shared.listUpdated = true
                        User.shared.updateDeviceList = true
                        navigationHandler = .groupSharing
                        navigationHandler.navigateToPage()
                    }
                }
            }
        case .decline:
            if let requestID = eventData[ESPNotificationKeys.requestIDKey] as? String {
                NodeGroupSharingManager.shared.actOnSharingRequest(requestId: requestID, accept: false) { _ in
                    NodeGroupManager.shared.listUpdated = true
                    User.shared.updateDeviceList = true
                }
            }
        case .none:
            navigationHandler = .groupSharing
            DispatchQueue.main.async {
                navigationHandler.navigateToPage()
            }
        }
    }
}
