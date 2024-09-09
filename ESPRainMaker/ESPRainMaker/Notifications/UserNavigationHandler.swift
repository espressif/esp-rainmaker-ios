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
//  UserNavigationHandler.swift
//  ESPRainMaker
//

import Foundation
import UIKit

// Handle navigation on tap of notifications
enum UserNavigationHandler {
    case homeScreen
    case notificationViewController
    case groupSharing
    case userNodeOTA(eventData: [String: Any])
    
    var topVC: UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController
    }
    
    func navigateToPage() {
        // Gets top view controller currently visible on app.
        var top = topVC
        if let presented = top?.presentedViewController {
            top = presented
        } else if let nav = top as? UINavigationController {
            top = nav.visibleViewController
        } else if let tab = top as? UITabBarController {
            top = tab.selectedViewController
            if top?.isKind(of: UINavigationController.self) ?? false {
                let userNavVC = top as? UINavigationController
                top = userNavVC?.visibleViewController
            }
        }
        
        switch self {
        case .homeScreen:
            // Checks if current screen is Home screen.
            if top?.isKind(of: DevicesViewController.self) ?? false {
                let devicesVC = top as? DevicesViewController
                if devicesVC?.isViewLoaded ?? false {
                    devicesVC?.refreshDeviceList()
                } else {
                    User.shared.updateDeviceList = true
                }
                return
            }
            navigateToHomeScreen()
        case .notificationViewController:
            // Checks if current screen is Notification screen.
            if top?.isKind(of: NotificationsViewController.self) ?? false {
                if let notificationVC = top as? NotificationsViewController {
                    notificationVC.refreshData()
                    return
                }
            }
            navigateToNotificationVC()
        case .groupSharing:
            // Checks if current screen is Notification screen.
            if top?.isKind(of: NodeGroupSharingRequestsViewController.self) ?? false {
                if let nodeGroupSharingVC = top as? NodeGroupSharingRequestsViewController {
                    nodeGroupSharingVC.refreshSharingData()
                    return
                }
            }
            navigateToGroupSharingVC()
        case .userNodeOTA(let eventData):
            self.navigateToUserOTAScreen(eventData: eventData)
        }
    }
    
    // Method to redirect user to Notifications screen.
    private func navigateToNotificationVC() {
        if let tabBarController = topVC as? UITabBarController {
            if let viewControllers = tabBarController.viewControllers {
                for viewController in viewControllers {
                    if viewController.isKind(of: UserNavigationController.self) {
                        tabBarController.selectedViewController = viewController
                        tabBarController.tabBar.isHidden = true
                        let settingsPageViewController = (viewController as! UINavigationController).viewControllers.first
                        let userStoryBoard = UIStoryboard(name: Constants.settingsStoryboardName, bundle: nil)
                        let notificationsViewController = userStoryBoard.instantiateViewController(withIdentifier: "notificationsVC") as! NotificationsViewController
                        settingsPageViewController?.navigationController?.pushViewController(notificationsViewController, animated: true)
                    }
                }
            }
        }
    }
    
    // Method to redirect user to Home Screen.
    private func navigateToHomeScreen() {
        if let tabBarController = topVC as? UITabBarController {
            if let viewControllers = tabBarController.viewControllers {
                for viewController in viewControllers {
                    if viewController.isKind(of: DevicesNavigationController.self) {
                        tabBarController.selectedViewController = viewController
                        tabBarController.tabBar.isHidden = false
                        let navigationVC = viewController as? DevicesNavigationController
                        User.shared.updateDeviceList = true
                        navigationVC?.popToRootViewController(animated: false)
                    }
                }
            }
        }
    }
    
    // Method to redirect user to group sharing screen.
    private func navigateToGroupSharingVC() {
        if let tabBarController = topVC as? UITabBarController {
            if let viewControllers = tabBarController.viewControllers {
                for viewController in viewControllers {
                    if viewController.isKind(of: UserNavigationController.self) {
                        tabBarController.selectedViewController = viewController
                        tabBarController.tabBar.isHidden = true
                        let settingsPageViewController = (viewController as! UINavigationController).viewControllers.first
                        let userStoryBoard = UIStoryboard(name: ESPMatterConstants.matterStoryboardId, bundle: nil)
                        let nodeGroupSharingVC = userStoryBoard.instantiateViewController(withIdentifier: NodeGroupSharingRequestsViewController.storyboardId) as! NodeGroupSharingRequestsViewController
                        settingsPageViewController?.navigationController?.pushViewController(nodeGroupSharingVC, animated: true)
                    }
                }
            }
        }
    }
    
    /// Navigate to node OTA Update screen
    /// - Parameter eventData: event data from notification
    private func navigateToUserOTAScreen(eventData: [String: Any]) {
        if let nodeId = eventData["node_id"] as? String, let currentNode = ESPLocalStorageNodes(ESPLocalStorageKeys.suiteName).getNode(nodeID: nodeId) {
            DispatchQueue.main.async {
                if let tabBarController = topVC as? UITabBarController {
                    if let tabNavVCs = tabBarController.viewControllers as? [UINavigationController] {
                        let navigationController = tabNavVCs[tabBarController.selectedIndex]
                        self.presentFirmwareUpdateVC(forNode: currentNode, navigationController: navigationController)
                    }
                }
            }
        }
    }
    
    
    /// Present firmware update viewcontroller
    /// - Parameters:
    ///   - currentNode: current node
    ///   - navigationController: navigation controller
    private func presentFirmwareUpdateVC(forNode currentNode: Node, navigationController: UINavigationController) {
        let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
        let firmwareUpdateVC = deviceStoryboard.instantiateViewController(withIdentifier: "firmwareUpdate") as! FirmwareUpdateViewController
        firmwareUpdateVC.currentNode = currentNode
        firmwareUpdateVC.isFromNotification = true
        navigationController.present(firmwareUpdateVC, animated: true)
    }
}
