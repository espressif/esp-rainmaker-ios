// Copyright 2020 Espressif Systems
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
//  AppDelegate.swift
//  ESPRainMaker
//

import Alamofire
import AWSCognitoIdentityProvider
import AWSMobileClient
import DropDown
import ESPProvision
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var signInViewController: SignInViewController?
    var mfaViewController: MFAViewController?
    var navigationController: UINavigationController?
    var storyboard: UIStoryboard?
    var rememberDeviceCompletionSource: AWSTaskCompletionSource<NSNumber>?
    var user: AWSCognitoIdentityUser?
    var isInitialized = false

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // fetch the user pool client we initialized in above step
        storyboard = UIStoryboard(name: "Login", bundle: nil)
        User.shared.pool.delegate = self
        VersionManager.shared.checkForAppUpdate()
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: Configuration.shared.awsConfiguration.awsRegion,
            identityPoolId: Configuration.shared.awsConfiguration.poolID
        )
        let configuration = AWSServiceConfiguration(
            region: Configuration.shared.awsConfiguration.awsRegion,
            credentialsProvider: credentialsProvider
        )
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        ESPNetworkMonitor.shared.startMonitoring()
        DropDown.startListeningToKeyboard()

        // Set tab bar appearance to match theme
        setTabBarAttribute()

        // Uncomment the next line to see library related logs.
        // ESPProvisionManager.shared.enableLogs(true)
        return true
    }

    // Method to set appearance of Tab Bar
    private func setTabBarAttribute() {
        var currentBGColor = UIColor(hexString: "#8265E3")
        if let color = AppConstants.shared.appThemeColor {
            currentBGColor = color
        }
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray], for: .normal)
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#8265E3")], for: .selected)
        } else {
            UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: currentBGColor], for: .selected)
        }
    }

    func applicationWillResignActive(_: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//        VersionManager.shared.checkForAppUpdate()
    }

    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

// MARK: - AWSCognitoIdentityInteractiveAuthenticationDelegate protocol delegate

extension AppDelegate: AWSCognitoIdentityInteractiveAuthenticationDelegate {
    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        if navigationController == nil {
            if !Thread.isMainThread {
                DispatchQueue.main.sync {
                    navigationController = storyboard?.instantiateViewController(withIdentifier: "signInController") as? UINavigationController
                }
            } else {
                navigationController = storyboard?.instantiateViewController(withIdentifier: "signInController") as? UINavigationController
            }
        }
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                if signInViewController == nil {
                    signInViewController = navigationController?.viewControllers[0] as? SignInViewController
                    navigationController?.modalPresentationStyle = .fullScreen
                }

                navigationController!.popToRootViewController(animated: true)
                if !navigationController!.isViewLoaded
                    || navigationController!.view.window == nil
                {
                    window?.rootViewController?.present(navigationController!,
                                                        animated: true,
                                                        completion: nil)
                }
            }
        } else {
            if signInViewController == nil {
                signInViewController = navigationController?.viewControllers[0] as? SignInViewController
                navigationController?.modalPresentationStyle = .fullScreen
            }

            navigationController!.popToRootViewController(animated: true)
            if !navigationController!.isViewLoaded
                || navigationController!.view.window == nil
            {
                window?.rootViewController?.present(navigationController!,
                                                    animated: true,
                                                    completion: nil)
            }
        }
        return signInViewController!
    }

    func startMultiFactorAuthentication() -> AWSCognitoIdentityMultiFactorAuthentication {
        if mfaViewController == nil {
            mfaViewController = MFAViewController()
            mfaViewController?.modalPresentationStyle = .popover
        }
        DispatchQueue.main.async {
            if !self.mfaViewController!.isViewLoaded
                || self.mfaViewController!.view.window == nil
            {
                // display mfa as popover on current view controller
                let viewController = self.window?.rootViewController!
                viewController?.present(self.mfaViewController!,
                                        animated: true,
                                        completion: nil)

                // configure popover vc
                let presentationController = self.mfaViewController!.popoverPresentationController
                presentationController?.permittedArrowDirections = UIPopoverArrowDirection.left
                presentationController?.sourceView = viewController!.view
                presentationController?.sourceRect = viewController!.view.bounds
            }
        }
        return mfaViewController!
    }

    func startRememberDevice() -> AWSCognitoIdentityRememberDevice {
        return self
    }
}

// MARK: - AWSCognitoIdentityRememberDevice protocol delegate

extension AppDelegate: AWSCognitoIdentityRememberDevice {
    func getRememberDevice(_ rememberDeviceCompletionSource: AWSTaskCompletionSource<NSNumber>) {
        self.rememberDeviceCompletionSource = rememberDeviceCompletionSource
        DispatchQueue.main.async {
            // dismiss the view controller being present before asking to remember device
            self.window?.rootViewController!.presentedViewController?.dismiss(animated: true, completion: nil)
            let alertController = UIAlertController(title: "Remember Device",
                                                    message: "Do you want to remember this device?.",
                                                    preferredStyle: .actionSheet)

            let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { _ in
                self.rememberDeviceCompletionSource?.set(result: true)
            })
            let noAction = UIAlertAction(title: "No", style: .default, handler: { _ in
                self.rememberDeviceCompletionSource?.set(result: false)
            })
            alertController.addAction(yesAction)
            alertController.addAction(noAction)

            self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }

    func didCompleteStepWithError(_ error: Error?) {
        DispatchQueue.main.async {
            if let error = error as NSError? {
                let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                        message: error.userInfo["message"] as? String,
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "ok", style: .default, handler: nil)
                alertController.addAction(okAction)
                DispatchQueue.main.async {
                    self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
}
