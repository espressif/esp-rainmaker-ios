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
//  AppDelegate+Notifications.swift
//  ESPRainMaker
//

import Foundation
import UIKit
import WidgetKit

extension AppDelegate {
    
    // MARK: - Notifications Configuration
    
    func configureRemoteNotifications() {
        registerForAddSharingEventActions()
        requestNotificationAuthorization()
    }
    
    /// Setup JPUSHService for receiving remote notifications
    /// - Parameter launchOptions: launchOptions
    func setupJPushService(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let entity = JPUSHRegisterEntity()
        entity.types = Int(JPAuthorizationOptions.alert.rawValue |
                           JPAuthorizationOptions.badge.rawValue |
                           JPAuthorizationOptions.sound.rawValue |
                           JPAuthorizationOptions.providesAppNotificationSettings.rawValue)
        JPUSHService.register(forRemoteNotificationConfig: entity, delegate: self)
        JPUSHService.setup(withOption: launchOptions,
                           appKey: Configuration.shared.jPushServiceConfiguration.appKey,
                           channel: nil,
                           apsForProduction: Configuration.shared.jPushServiceConfiguration.apsForProduction)
    }
    
    // Method to request notification authorization for type .alert, .badge and .sound.
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            guard granted else { return }
            self?.getNotificationSettings()
        }
    }
    
    // Method to check current notification authorization status of the app
    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                /// We call the JPushService setup code if region is set to China Mainland
                /// and JPUSHService app key is configured under JPushService Configuration
                /// in the Configuration.plist file
                /// Else we call the default registerForRemoteNotifications API.
                if ESPLocaleManager.shared.isLocaleChinaWithAuroraConfigured {
                    self.setupJPushService(launchOptions: self.launchOptions)
                } else {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // Adds notification category for add sharing event type.
    private func registerForAddSharingEventActions() {
        ESPNotificationsAddSharingCategory.addCategory()
    }
    
    // Method to delete endpoints for current user on logout.
    func disablePlatformApplicationARN(_ completionHandler: @escaping () -> Void) {
        if let deviceToken = self.deviceToken {
            self.espNotificationsAPIWorker.deletePlatformEndpoint(deviceToken: deviceToken) {
                completionHandler()
            }
        } else {
            completionHandler()
        }
    }

    // MARK: - Callbacks
    
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Retreive device token from deviceToken data.
        var token: String?
        if ESPLocaleManager.shared.isLocaleChinaWithAuroraConfigured {
            JPUSHService.registerDeviceToken(deviceToken)
            token = JPUSHService.registrationID()
            if !self.isJPUSHRegistrationIdCreated(registrationId: token) {
                self.startJPUSHTimer()
                return
            }
        } else {
            let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
            token = tokenParts.joined()
        }
        if let token = token {
            self.espNotificationsAPIWorker.createNewPlatformEndpoint(deviceToken: token) { result in
                if result {
                    self.deviceToken = token
                }
            }
        }
    }
    
    // To display message even when app is in foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Parsed the notification payload to get event type information.
        let userInfo:[String:Any] = notification.request.content.userInfo as? [String:Any] ?? [:]
        var notificationHandler = ESPNotificationHandler(userInfo)
        // Update data if event is related with node connection.
        notificationHandler.updateData()
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        completionHandler([.alert, .badge, .sound])
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Parsed the notification payload to get event type information.
        let userInfo:[String:Any] = response.notification.request.content.userInfo as? [String:Any] ?? [:]
        let notificationHandler = ESPNotificationHandler(userInfo)
        // Handled event related with other using notification handler.
        notificationHandler.handleEvent(ESPNotificationCategory(rawValue: response.notification.request.content.categoryIdentifier), response.actionIdentifier)
        completionHandler()
    }

    func application(_: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Silent notifications are used to update device params in real time in the app.
        ESPSilentNotificationHandler().handleSilentNotification(userInfo)
        fetchCompletionHandler(.newData)
    }
}


extension AppDelegate: JPUSHRegisterDelegate {
    
    func jpushNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (Int) -> Void) {
        // Parsed the notification payload to get event type information.
        let userInfo:[String:Any] = notification.request.content.userInfo as? [String:Any] ?? [:]
        var notificationHandler = ESPNotificationHandler(userInfo)
        // Update data if event is related with node connection.
        notificationHandler.updateData()
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        completionHandler(Int(JPAuthorizationOptions.alert.rawValue | JPAuthorizationOptions.sound.rawValue | JPAuthorizationOptions.badge.rawValue | JPAuthorizationOptions.providesAppNotificationSettings.rawValue))
    }
    
    func jpushNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo:[String:Any] = response.notification.request.content.userInfo as? [String:Any] ?? [:]
        let notificationHandler = ESPNotificationHandler(userInfo)
        // Handled event related with other using notification handler.
        notificationHandler.handleEvent(ESPNotificationCategory(rawValue: response.notification.request.content.categoryIdentifier), response.actionIdentifier)
        completionHandler()
    }
    
    func jpushNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification) {}
    
    func jpushNotificationAuthorization(_ status: JPAuthorizationStatus, withInfo info: [AnyHashable : Any]?) {}
}
