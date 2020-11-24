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

class Device: Codable {
    var name: String?
    var type: String?
    var attributes: [Attribute]?
    var params: [Param]?
    var node: Node?
    var primary: String?
    var collapsed: Bool = true
    var selectedParams = 0
    var deviceName = ""
    var deviceNameParam = ""

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case primary
        case params
        case attributes
        case deviceName
        case deviceNameParam
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)

        try container.encode(primary, forKey: .primary)
        try container.encode(params, forKey: .params)
        try container.encode(attributes, forKey: .attributes)
        // Additional properties
        try container.encode(deviceName, forKey: .deviceName)
        try container.encode(deviceNameParam, forKey: .deviceNameParam)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        type = try container.decode(String?.self, forKey: .type)
        primary = try container.decode(String?.self, forKey: .primary)
        params = try container.decode([Param]?.self, forKey: .params)
        attributes = try container.decodeIfPresent([Attribute].self, forKey: .attributes)
        //  Additional params
        deviceName = try container.decodeIfPresent(String.self, forKey: .deviceName) ?? ""
        deviceNameParam = try container.decodeIfPresent(String.self, forKey: .deviceNameParam) ?? ""
    }

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

    func isReachable() -> Bool {
        if node?.isConnected ?? false || node?.localNetwork ?? false {
            return true
        }
        return false
    }

    init() {}

    required init(name: String?, type: String?, node: Node?, deviceName: String?) {
        self.name = name
        self.type = type
        self.node = node
        self.deviceName = deviceName ?? name ?? ""
    }

    convenience init(device: Device) {
        self.init(name: device.name, type: device.type, node: device.node, deviceName: device.deviceName)
    }
}
