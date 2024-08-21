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
//  AppDelegate+JPUSHTimer.swift
//  ESPRainMaker
//

import Foundation

extension AppDelegate {
    
    /// Check if JPUSHService registration id is created properly
    /// - Parameter jPushRegistrationId: JPUSHService registration id
    /// - Returns: is the JPUSHService registration id created
    func isJPUSHRegistrationIdCreated(registrationId: String?) -> Bool {
        guard let jPushRegistrationId = registrationId, jPushRegistrationId.count > 0 else {
            return false
        }
        return true
    }
    
    /// Start the JPUSHService timer
    func startJPUSHTimer() {
        self.jPushServiceTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { _ in
            self.createMobileEndpoint()
        })
    }
    
    /// Create mobile endpoint if the registration id is created
    func createMobileEndpoint() {
        let registrationId = JPUSHService.registrationID()
        guard registrationId.count > 0 else {
            return
        }
        self.createJPUSHMobileEndpoint(registrationId: registrationId)
    }
    
    /// Create mobile endpoint using
    /// - Parameter deviceToken: device token
    func createJPUSHMobileEndpoint(registrationId: String) {
        self.jPushServiceTimer?.invalidate()
        self.espNotificationsAPIWorker.createNewPlatformEndpoint(deviceToken: registrationId) { result in
            if result {
                self.deviceToken = registrationId
            }
        }
    }
}

