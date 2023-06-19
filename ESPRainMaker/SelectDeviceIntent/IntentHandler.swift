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
//  IntentHandler.swift
//  ESPRainMaker
//

import Intents

class IntentHandler: INExtension, ConfigurationIntentHandling  {
    
    func provideUserDeviceOptionsCollection(for intent: ConfigurationIntent, with completion: @escaping (INObjectCollection<UserDevice>?, Error?) -> Void) {
        if let nodes = ESPLocalStorageNodes(ESPLocalStorageKeys.suiteName).fetchNodeDetails() {
            var userDevices:[UserDevice] = []
            for node in nodes {
                for device in node.devices ?? [] {
                    let userDevice = UserDevice(identifier: (node.node_id ?? "")+(device.name  ?? ""), display: device.getDeviceName() ?? "")
                    userDevice.name = device.getDeviceName() ?? device.name
                    userDevices.append(userDevice)
                    }
                }
            completion(INObjectCollection(items: userDevices), nil)
        }
        else {
            completion(nil, nil)
        }
        
    }
    
    
    func resolveUserDevice(for intent: ConfigurationIntent, with completion: @escaping (UserDeviceResolutionResult) -> Void) {
        print("")
    }
    
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
}
