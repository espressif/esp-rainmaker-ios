// Copyright 2023 Espressif Systems
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
//  ESPMatterDeviceManager.swift
//  ESPRainmaker
//

import Foundation

class ESPMatterDeviceManager {
    
    static var shared: ESPMatterDeviceManager = ESPMatterDeviceManager()
    
    func getNextAvailableDeviceID() -> UInt64 {
        let nextAvailableDeviceIdentifier: UInt64 = 1
        if let value = UserDefaults.standard.value(forKey: ESPMatterConstants.chipDeviceId) as? UInt64 {
            return value
        }
        UserDefaults.standard.set(nextAvailableDeviceIdentifier, forKey: ESPMatterConstants.chipDeviceId)
        return nextAvailableDeviceIdentifier
    }
    
    func setNextAvailableDeviceID(_ id: UInt64) {
        UserDefaults.standard.set(id, forKey: ESPMatterConstants.chipDeviceId)
    }
    
    func getCurrentDeviceId() -> UInt64 {
        return (getNextAvailableDeviceID()-1)
    }
    
}
