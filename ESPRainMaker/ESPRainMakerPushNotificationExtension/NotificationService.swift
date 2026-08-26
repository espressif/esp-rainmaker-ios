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
//  NotificationService.swift
//  ESPRainMakerPushNotificationExtension
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        guard let bestAttemptContent = bestAttemptContent else {
            return contentHandler(request.content)
        }
        
        // Handle modified content from notification handler
        if let userInfo = bestAttemptContent.userInfo as? [String:Any], let modifiedPayload = ESPNotificationHandler(userInfo).modifiedContent() {
            bestAttemptContent.body = modifiedPayload.body
            bestAttemptContent.title = modifiedPayload.title
        } else {
            var body = ""
            var title = ""
            if let userInfo = bestAttemptContent.userInfo as? [String:Any], let aps = userInfo["aps"] as? [String:Any], let alert = aps["alert"] as? [String: Any] {
                if let alertBody = alert["body"] as? String {
                    body = alertBody
                }
                if let alertTitle = alert["title"] as? String {
                    title = alertTitle
                }
            }
            // Save notification for non-event types (like advertisements)
            let notificationStore = ESPNotificationsStore(ESPLocalStorageKeys.suiteName)
            let notifs = ESPNotifications(body: body, title: title, timestamp: Date().timeIntervalSince1970 * 1000)
            notificationStore.storeESPNotification(notification: notifs)
        }
        
        // Check if notification has image in additional_info
        if let userInfo = bestAttemptContent.userInfo as? [String:Any],
           let aps = userInfo["aps"] as? [String:Any],
           let alert = aps["alert"] as? [String:Any],
           let additionalInfo = alert["additional_info"] as? [String:Any],
           let imageUrlString = additionalInfo["image"] as? String,
           let imageUrl = URL(string: imageUrlString) {
            // Download and attach image
            downloadImageAndAttach(from: imageUrl, content: bestAttemptContent, handler: contentHandler)
            return
        }
        contentHandler(bestAttemptContent)
    }
    
    private func downloadImageAndAttach(
        from url: URL,
        content: UNMutableNotificationContent,
        handler: @escaping (UNNotificationContent) -> Void
    ) {
        URLSession.shared.downloadTask(with: url) { localURL, _, error in
            guard let localURL = localURL, error == nil else {
                return handler(content)
            }
            
            let fileExtension = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
            let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("image.\(fileExtension)")
            
            do {
                try FileManager.default.moveItem(at: localURL, to: tmpURL)
                let attachment = try UNNotificationAttachment(identifier: "img", url: tmpURL)
                content.attachments = [attachment]
            } catch {
                // Ignore failures and return content without attachment
            }
            
            handler(content)
        }.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
