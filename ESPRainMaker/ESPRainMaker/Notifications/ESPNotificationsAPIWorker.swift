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
//  ESPSilentNotificationHandler.swift
//  ESPRainMaker
//

import Foundation

class ESPNotificationsAPIWorker {
    
    let apiManager = ESPAPIManager()
    let platformKey = "platform"
    let apns = "APNS"
    let mobileDeviceTokenKey = "mobile_device_token"
    
    /// Create new iOS platform endpoint
    /// - Parameters:
    ///   - deviceToken: device token
    ///   - completion: completion handler
    func createNewPlatformEndpoint(deviceToken: String, completion: @escaping (Bool) -> Void) {
        let parameters = [platformKey: apns,
                mobileDeviceTokenKey: deviceToken]
        self.apiManager.genericAuthorizedJSONRequest(url: Constants.pushNotification, parameter: parameters, method: .post) { response, error in
            guard let _ = error else {
                completion(true)
                return
            }
            completion(false)
        }
    }
    
    /// Delete platform endpoint
    /// - Parameters:
    ///   - deviceToken: device token
    ///   - completionHandler: completion handler
    func deletePlatformEndpoint(deviceToken: String, completionHandler: @escaping () -> Void) {
        self.apiManager.genericAuthorizedJSONRequest(url: Constants.pushNotification + "?\(mobileDeviceTokenKey)=" + deviceToken, parameter: nil, method: .delete) { response, error in
            completionHandler()
        }
    }
}
