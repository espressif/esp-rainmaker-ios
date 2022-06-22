// Copyright 2022 Espressif Systems
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
//  User+GetDeviceList.swift
//  ESPRainMaker
//

import Foundation

extension User {
    
    /// Method to get device list from user associated nodes.
    ///
    /// - Returns: Returns array of user devices.
    func getDeviceList() -> [Device] {
        var deviceList:[Device] = []
        if let nodeList = self.associatedNodeList, nodeList.count > 0 {
            for node in nodeList {
                deviceList.append(contentsOf: node.devices ?? [])
            }
        }
        return deviceList
    }
}
