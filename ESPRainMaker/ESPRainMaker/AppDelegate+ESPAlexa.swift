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
//  AppDelegate+ESPAlexa.swift
//  ESPRainMaker
//

import Foundation
import UIKit

extension AppDelegate {
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if ESPLocaleManager.shared.isLocaleChina {
            return WXApi.handleOpenUniversalLink(userActivity, delegate: self)
        }
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let url = userActivity.webpageURL {
                let appLinkFromAlexa = isAppLinkingFromAlexaApp(alexaURL: url)
                if appLinkFromAlexa.0, let rainmakerURLString = appLinkFromAlexa.1 {
                    self.launchAlexaApp(rainmakerURLString: rainmakerURLString)
                    return false
                }
                var isRainmakerAuthCode = false
                if url.absoluteString.contains(ESPAlexaServiceConstants.rainmakerCode) {
                    isRainmakerAuthCode = true
                }
                if let vc = ESPEnableAlexaSkillService.getTopVC() as? ESPEnableAlexaSkillPresenter {
                    if isRainmakerAuthCode {
                        vc.actOnURL(url: url.absoluteString, state: .rainMakerAuthCode)
                    } else {
                        vc.actOnURL(url: url.absoluteString, state: .none)
                    }
                } else {
                    if User.shared.isUserSessionActive {
                        if isRainmakerAuthCode {
                            navigateToEnableSkillPage(url: url.absoluteString, state: .rainMakerAuthCode)
                        } else {
                            navigateToEnableSkillPage(url: url.absoluteString, state: .none)
                        }
                    }
                }
            }
        }
        return false
    }
    
    /// Check if URL is from alexa app
    /// - Parameter alexaURL: URL to check
    /// - Returns: (is URL from Alexa, Alexa URL)
    func isAppLinkingFromAlexaApp(alexaURL: URL) -> (Bool, String?) {
        if let components = URLComponents(url: alexaURL, resolvingAgainstBaseURL: false) {
            if let queryItems = components.queryItems {
                var redirectURL = ""
                var state = ""
                var scope = ""
                var clientId = ""
                for queryItem in queryItems {
                    if let value = queryItem.value {
                        if queryItem.name == ESPAlexaServiceConstants.redirectURI {
                            redirectURL = value
                            continue
                        }
                        if queryItem.name == ESPAlexaServiceConstants.scope {
                            scope = value
                            continue
                        }
                        if queryItem.name == ESPAlexaServiceConstants.state {
                            state = value
                            continue
                        }
                        if queryItem.name == ESPAlexaServiceConstants.clientId {
                            clientId = value
                            continue
                        }
                    }
                }
                if clientId.count > 0, state.count > 0, redirectURL.count > 0, scope.count > 0, redirectURL.contains(ESPAlexaServiceConstants.alexaRedirectURI) {
                    let rainmakerURL = "\(Configuration.shared.awsConfiguration.authURL!)/authorize?response_type=code&client_id=\(clientId)&redirect_uri=\(redirectURL)&state=\(state)&scope=\(scope)"
                    return (true, rainmakerURL)
                }
            }
        }
        return (false, nil)
    }
    
    /// Launch alexa app
    /// - Parameter rainmakerURLString: rainmaker URL string
    func launchAlexaApp(rainmakerURLString: String) {
        if let rainmakerURL = URL(string: rainmakerURLString) {
            if User.shared.isUserSessionActive {
                if let controller = UIApplication.topViewController() {
                    if let navBar = controller.navigationController, let tabBar = navBar.tabBarController {
                        if let connectToAlexaVC = ESPEnableAlexaSkillService.getConnectToAlexaVC() {
                            connectToAlexaVC.isLaunchedFromAlexa = true
                            self.rainmakerURL = rainmakerURL
                            connectToAlexaVC.espLinkSkillFromAlexaDelegate = self
                            tabBar.present(connectToAlexaVC, animated: true)
                        }
                    }
                }
            }
        }
    }

    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        return WXApi.handleOpen(url, delegate: self)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return WXApi.handleOpen(url, delegate: self)
    }
    
    /// Method navigates to ESPAlexaConnectViewController from whatever screen is opened in the screen.
    /// - Parameters:
    ///   - url: url: URL retrieved from WKWebview or Alexa app
    ///   - state: state for which url is retrieved
    private func navigateToEnableSkillPage(url: String, state: ESPEnableSkillState) {
        if let tabBarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
            if let viewControllers = tabBarController.viewControllers {
                for viewController in viewControllers {
                    if viewController.isKind(of: UserNavigationController.self) {
                        tabBarController.selectedViewController = viewController
                        if let vc = viewController as? UINavigationController {
                            for viewController in vc.viewControllers {
                                viewController.presentedViewController?.dismiss(animated: true, completion: nil)
                            }
                            vc.popToRootViewController(animated: true)
                        }
                        let settingsPageViewController = (viewController as! UINavigationController).viewControllers.first
                        if let vc = getVoicesVC(), let connectToAlexaVC = ESPEnableAlexaSkillService.getConnectToAlexaVC() {
                            settingsPageViewController?.navigationController?.pushViewController(vc, animated: true)
                            settingsPageViewController?.navigationController?.pushViewController(connectToAlexaVC, animated: true)
                            DispatchQueue.main.asyncAfter(deadline: .now()+2.0, execute: {
                                connectToAlexaVC.checkAccountLinkingAndActOnURL(url: url, state: state)
                            })
                        }
                    }
                }
            }
        }
    }
    
    /// Method gets an object of VoiceServicesViewController
    /// - Returns: instance of VoiceServicesViewController
    private func getVoicesVC() -> VoiceServicesViewController? {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "VoiceServicesViewController") as? VoiceServicesViewController {
            return vc
        }
        return nil
    }
}

extension AppDelegate: ESPLinkSkillFromAlexaDelegate {
    
    /// Launch cognito hosted UI in browser
    func launchCognitoURL() {
        if UIApplication.shared.canOpenURL(self.rainmakerURL) {
            UIApplication.shared.open(self.rainmakerURL, options: [.universalLinksOnly: false]) { _ in}
        }
    }
}

extension UIApplication {
    
    /// This method returns an instance of the top viewcontroller for currently displayed for the app
    /// - Parameter base: Base viewcontroller (default: UIApplication.shared.keyWindow?.rootViewController)
    /// - Returns:instance of the top viewcontroller
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        /// If the base view controller is a UINavigationController,
        /// the function calls itself recursively with the currently visible view controller (nav.visibleViewController) as the new base.
        /// This ensures that it traverses to the top-most view controller on the navigation stack.
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        /// If the base view controller is a UITabBarController, it checks for the selected view controller
        ///  and calls itself recursively with the selected view controller (tab.selectedViewController).
        ///  This ensures it correctly identifies the active tab's view controller.
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        /// If the base view controller has a presented view controller (base?.presentedViewController),
        /// it calls itself recursively with that presented view controller.
        /// This handles modal presentations and ensures the function reaches the top-most presented view controller.
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        /// If none of the conditions apply, it simply returns the base view controller.
        return base
    }
}
