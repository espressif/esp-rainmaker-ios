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
//  ESPNotificationHandler.swift
//  ESPRainMaker
//

import Foundation

// Enum consisting of all notification events.
enum ESPNotificationEvents: String {
    case nodeAssociated = "rmaker.event.user_node_added"
    case nodeDissassociated = "rmaker.event.user_node_removed"
    case nodeConnected = "rmaker.event.node_connected"
    case nodeDisconnected = "rmaker.event.node_disconnected"
    case nodeSharingAdd = "rmaker.event.user_node_sharing_add"
    case nodeAlert = "rmaker.event.alert"
    case automationTrigger = "rmaker.event.node_automation_trigger"
    case groupSharingAdd = "rmaker.event.user_node_group_sharing_add"
    case groupSharingRemoved = "rmaker.event.user_node_group_removed"
    case nodeGroupAdded = "rmaker.event.user_node_group_added"
    case userNodeOTA = "rmaker.event.user_node_ota"
}

// Struct to handle all type of notification events.
struct ESPNotificationHandler: ESPNotificationProtocol {
    
    var eventData: [String : Any]
    var notification =  ESPNotifications(body: "", title: "", timestamp: Date().timeIntervalSince1970)
    let eventType: ESPNotificationEvents?
    
    
    init(_ userInfo: [String: Any]) {
        eventData = [:]
        var eventTypeStr = ""
        if let aps = userInfo[ESPNotificationKeys.apsKey] as? [String:Any], let alert = aps[ESPNotificationKeys.alertkey] as? [String: Any] {
            
            notification.title = alert[ESPNotificationKeys.titleKey] as? String ?? ""
            notification.body = alert[ESPNotificationKeys.bodyKey] as? String ?? ""
            
            if let event_data_payload = alert[ESPNotificationKeys.eventDataPayloadKey] as? [String: Any] {
                
                if let event_data = event_data_payload[ESPNotificationKeys.eventDataKey] as? [String:Any] {
                    eventData = event_data
                }
                if let event = event_data_payload[ESPNotificationKeys.eventTypeKey] as? String {
                    eventTypeStr = event
                }
                if let timestamp = event_data_payload[ESPNotificationKeys.timestampKey] as? Double {
                    notification.timestamp = timestamp
                }
            }
        }
        eventType = ESPNotificationEvents(rawValue: eventTypeStr)
    }
    
    func modifiedContent() -> ESPNotifications? {
        var modifiedNotification: ESPNotifications?
        switch eventType {
        case .nodeConnected:
            modifiedNotification = ESPNodeConnectedEvent(eventData, notification).modifiedContent()
        case .nodeDisconnected:
            modifiedNotification = ESPNodeDisconnectedEvent(eventData, notification).modifiedContent()
        case .groupSharingAdd:
            if let accept = eventData[ESPNotificationKeys.acceptKey] as? Bool {
                if accept {
                    modifiedNotification = ESPNodeGroupSharingAcceptedEvent(eventData, notification).modifiedContent()
                    break
                } else {
                    modifiedNotification = ESPNodeGroupSharingDeclinedEvent(eventData, notification).modifiedContent()
                    break
                }
            }
            modifiedNotification = ESPNodeGroupSharingAddEvent(eventData, notification).modifiedContent()
        case .nodeSharingAdd:
            if let accept = eventData[ESPNotificationKeys.acceptKey] as? Bool {
                if accept {
                    modifiedNotification = ESPNodeSharingAcceptedEvent(eventData, notification).modifiedContent()
                    break
                } else {
                    modifiedNotification = ESPNodeSharingDeclinedEvent(eventData, notification).modifiedContent()
                    break
                }
            }
            modifiedNotification = ESPNodeSharingAddEvent(eventData, notification).modifiedContent()
        case .nodeAlert:
            modifiedNotification = ESPNodeAlertEvent(eventData, notification).modifiedContent()
        case .nodeAssociated:
            modifiedNotification = ESPNodeAssociatedEvent(eventData, notification).modifiedContent()
        case .nodeDissassociated:
            modifiedNotification = ESPNodeDisassociatedEvent(eventData, notification).modifiedContent()
        case .automationTrigger:
            modifiedNotification = ESPAutomationTriggerEvent(eventData, notification).modifiedContent()
        case .groupSharingRemoved:
            modifiedNotification = ESPNodeGroupSharingRemovedEvent(eventData, notification).modifiedContent()
        case .nodeGroupAdded:
            modifiedNotification = ESPNodeGroupAddedEvent(eventData, notification).modifiedContent()
        case .userNodeOTA:
            modifiedNotification = ESPOTAUpdateEvent(eventData, notification).modifiedContent()
        default:
            return nil
        }
        return modifiedNotification
    }
}
