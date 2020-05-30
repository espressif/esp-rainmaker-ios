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
//  Device.swift
//  ESPRainMaker
//

import Foundation

class Device: Equatable {
    static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.attributes == rhs.attributes && lhs.params == rhs.params && lhs.name == rhs.name
    }

    var name: String?
    var type: String?
    var attributes: [Attribute]?
    var params: [Param]?
    weak var node: Node?
    var primary: String?

    func getDeviceName() -> String? {
        if let deviceNameParam = self.params?.first(where: { param -> Bool in
            param.type == Constants.deviceNameParam
        }) {
            if let name = deviceNameParam.value as? String {
                return name
            }
        }
        return name
    }
}
