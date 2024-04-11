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
//  Node.swift
//  ESPRainMaker
//

import Foundation

class Node: Codable {
    
    var node_id: String?
    var config_version: String?
    var info: Info?
    var devices: [Device]?
    var attributes: [Attribute]?
    var primary: [String]?
    var secondary: [String]?
    var services: [Service]?
    var isConnected = true
    var timestamp: Int = 0
    var isSchedulingSupported = false
    var localNetwork = false
    var supportsEncryption = false
    var pop = ""
    var fromLocalStorage = false
    var maxSchedulesCount = -1
    var currentSchedulesCount = 0
    var scheduleName = "Schedule"
    var schedulesName = "Schedules"
    var isSceneSupported = false
    var maxScenesCount = -1
    var currentScenesCount = 0
    var sceneName = "Scene"
    var scenesName = "Scenes"
    var isMatter = false
    var matter_node_id: String?
    var metadata: [String: Any]?
    var node_type: String?
    var securityType: Int?

    enum CodingKeys: String, CodingKey {
        case node_id = "id"
        case status
        case config
        case devices
        case config_version
        case info
        case isSchedulingSupported
        case primary
        case secondary
        case services
        case maxSchedulesCount
        case currentSchedulesCount
        case supportsEncryption
        case pop
        case timestamp
        case isConnected
        case isMatter
        case matter_node_id
        case metadata
        case node_type
        case securityType
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let node_id = node_id {
            try container.encode(node_id, forKey: .node_id)
        }
        try container.encode(isSchedulingSupported, forKey: .isSchedulingSupported)
        if let devices = devices {
            try container.encode(devices, forKey: .devices)
        }
        if let primary = primary {
            try container.encode(primary, forKey: .primary)
        }
        if let secondary = secondary {
            try container.encode(secondary, forKey: .primary)
        }
        if let services = services {
            try container.encode(services, forKey: .primary)
        }
        try container.encode(maxSchedulesCount, forKey: .maxSchedulesCount)
        try container.encode(currentSchedulesCount, forKey: .currentSchedulesCount)
        try container.encode(supportsEncryption, forKey: .supportsEncryption)
        try container.encode(pop, forKey: .pop)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isConnected, forKey: .isConnected)
        try container.encode(isMatter, forKey: .isMatter)
        if let matter_node_id = matter_node_id {
            try container.encode(matter_node_id, forKey: .matter_node_id)
        }
        if let metadata = metadata, let data = try? JSONSerialization.data(withJSONObject: metadata, options: []) {
            try container.encode(data, forKey: .metadata)
        }
        var configContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .config)
        if let info = info {
            try configContainer.encodeIfPresent(info, forKey: .info)
        }
        if let config_version = config_version {
            try configContainer.encodeIfPresent(config_version, forKey: .config_version)
        }
        if let node_type = node_type {
            try container.encode(node_type, forKey: .node_type)
        }
        if let securityType = securityType {
            try container.encode(securityType, forKey: .securityType)
        }
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let node_id = try? container.decodeIfPresent(String?.self, forKey: .node_id) {
            self.node_id = node_id
        }
        if let devices = try? container.decodeIfPresent([Device].self, forKey: .devices) {
            self.devices = devices
        }
        if let primary = try? container.decodeIfPresent([String].self, forKey: .primary) {
            self.primary = primary
        }
        if let secondary = try? container.decodeIfPresent([String].self, forKey: .secondary) {
            self.secondary = secondary
        }
        if let services = try? container.decodeIfPresent([Service].self, forKey: .services) {
            self.services = services
        }
        if let isMatter = try? container.decodeIfPresent(Bool.self, forKey: .isMatter) {
            self.isMatter = isMatter
        }
        if let matter_node_id = try? container.decodeIfPresent(String.self, forKey: .matter_node_id) {
            self.matter_node_id = matter_node_id
        }
        if let data = try? container.decode(Data.self, forKey: .metadata), let meta = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            metadata = meta
        }
        if let node_type = try? container.decodeIfPresent(String?.self, forKey: .node_type) {
            self.node_id = node_type
        }
        let configContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .config)
        if let info = try? configContainer.decode(Info.self, forKey: .info) {
            self.info = info
        }
        if let config_version = try? configContainer.decode(String.self, forKey: .config_version) {
            self.config_version = config_version
        }
        timestamp = 0
        if let nodeDevices = devices {
            for device in nodeDevices {
                device.node = self
            }
        }
        if let isSchedulingSupported = try? container.decode(Bool.self, forKey: .isSchedulingSupported) {
            self.isSchedulingSupported = isSchedulingSupported
        }
        if let maxSchedulesCount = try? container.decode(Int.self, forKey: .maxSchedulesCount) {
            self.maxSchedulesCount = maxSchedulesCount
        }
        if let currentSchedulesCount = try? container.decode(Int.self, forKey: .currentSchedulesCount) {
            self.currentSchedulesCount = currentSchedulesCount
        }
        if let supportsEncryption = try? container.decode(Bool.self, forKey: .supportsEncryption) {
            self.supportsEncryption = supportsEncryption
        }
        if let pop = try? container.decode(String.self, forKey: .pop) {
            self.pop = pop
        }
        if let isConnected = try? container.decode(Bool.self, forKey: .isConnected) {
            self.isConnected = isConnected
        }
        if let timestamp = try? container.decode(Int.self, forKey: .timestamp) {
            self.timestamp = timestamp
        }
        if let securityType = try? container.decodeIfPresent(Int?.self, forKey: .securityType) {
            self.securityType = securityType
        }
        fromLocalStorage = true
    }

    init() {}
    
    /// Returns reachability status of node
    var nodeStatus: String {
        var status = ""
        if fromLocalStorage {
            if localNetwork {
                if supportsEncryption {
                    return "🔒 Reachable on WLAN"
                }
               return "Reachable on WLAN"
            }
            return status
        }
        if localNetwork {
            if supportsEncryption {
                return "🔒 Reachable on WLAN"
            }
            status = "Reachable on WLAN"
        } else {
            if isConnected {
                return status
            } else {
                if timestamp == 0 {
                    status = "Offline"
                } else {
                    status = "Offline at " + timestamp.getShortDate()
                }
            }
        }
        return status
    }
}

class Service: Codable {
    var name: String?
    var params: [Param]?
    var type: String?
}

struct Info: Codable {
    var name: String?
    var fw_version: String?
    var type: String?
}
