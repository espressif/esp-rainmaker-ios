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
//  AppMessages.swift
//  ESPRainMaker
//

class AppMessages {
    
    static let blePermissionReqdMsg = "Please ensure that your bluetooth is powered ON and has the requisite permission."
    static let turnBLEOnMsg = "Please ensure that your bluetooth is powered on and restart the provisioning."
    static let upgradeOSVersionMsg = "You must upgrade to iOS 16.4 or above in order to avail this feature."
    static let upgradeOS15VersionMsg = "You must upgrade to iOS 15.0 or above in order to provision thread devices"
    static let connectTBRMsg = "Please ensure the thread border router is powered and connected to home network."
    static let noThreadScanResult = "Device could not find any thread networks to join. Please ensure the thread border router is powered and connected to home network."
}
