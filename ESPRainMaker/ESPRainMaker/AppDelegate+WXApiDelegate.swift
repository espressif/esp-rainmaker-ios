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
//  AppDelegate+WXApiDelegate.swift
//  ESPRainMaker
//

import Foundation

extension AppDelegate: WXApiDelegate {
    
    func onResp(_ resp: BaseResp) {
        if let response = resp as? SendAuthResp, let authCode = response.code, let state = response.state, state == WeChatServiceConfiguration.state {
            if let root = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
                if let nav = root.selectedViewController as? UINavigationController {
                    if let signinNav = nav.presentedViewController as? UINavigationController {
                        let vcs = signinNav.viewControllers
                        if let signin = vcs.last as? SignInViewController {
                            signin.requestWeChatTokens(authCode: authCode)
                        }
                    }
                }
            }
        }
    }
}
