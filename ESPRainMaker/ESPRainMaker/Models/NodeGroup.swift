// Copyright 2021 Espressif Systems
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
//  NodeGroup.swift
//  ESPRainMaker
//

import Foundation

class Group: Decodable {
    var groups: [NodeGroup]
    var nextID: String?
    
    enum CodingKeys: String, CodingKey {
        case groups
        case nextID = "next_id"
    }
}

class NodeGroup: Codable {
    var group_name: String?
    var group_id: String?
    var fabric_id: String?
    var type: String?
    var nodes: [String]?
    var sub_groups: [NodeGroup]?
    var is_matter: Bool?
    // Additional parameter for referencing node object
    var nodeList: [Node]?
    var group_metadata: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case group_name
        case group_id
        case fabric_id
        case type
        case nodes
        case sub_groups
        case is_matter
        case nodeList
        case group_metadata
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let group_name = group_name {
            try container.encode(group_name, forKey: .group_name)
        }
        if let group_id = group_id {
            try container.encode(group_id, forKey: .group_id)
        }
        if let group_id = group_id {
            try container.encode(group_id, forKey: .group_id)
        }
        if let fabric_id = fabric_id {
            try container.encode(fabric_id, forKey: .fabric_id)
        }
        if let type = type {
            try container.encode(type, forKey: .type)
        }
        if let nodes = nodes {
            try container.encode(nodes, forKey: .nodes)
        }
        if let sub_groups = sub_groups {
            try container.encode(sub_groups, forKey: .sub_groups)
        }
        if let is_matter = is_matter {
            try container.encode(is_matter, forKey: .is_matter)
        }
        if let nodeList = nodeList {
            try container.encode(nodeList, forKey: .nodeList)
        }
        if let group_metadata = group_metadata, let data = try? JSONSerialization.data(withJSONObject: group_metadata, options: []) {
            try container.encode(data, forKey: .group_metadata)
        }
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let group_name = try? container.decodeIfPresent(String?.self, forKey: .group_name) {
            self.group_name = group_name
        }
        if let group_id = try? container.decodeIfPresent(String?.self, forKey: .group_id) {
            self.group_id = group_id
        }
        if let fabric_id = try? container.decodeIfPresent(String?.self, forKey: .fabric_id) {
            self.fabric_id = fabric_id
        }
        if let type = try? container.decodeIfPresent(String?.self, forKey: .type) {
            self.type = type
        }
        if let nodes = try? container.decodeIfPresent([String]?.self, forKey: .nodes) {
            self.nodes = nodes
        }
        if let is_matter = try? container.decodeIfPresent(Bool?.self, forKey: .is_matter) {
            self.is_matter = is_matter
        }
        let jsonDecoder = JSONDecoder()
        if let sub_groups = try? container.decodeIfPresent([NodeGroup]?.self, forKey: .sub_groups) {
            self.sub_groups = sub_groups
        } else if let data = try? container.decodeIfPresent(Data.self, forKey: .sub_groups), let sub_groups = try? jsonDecoder.decode([NodeGroup].self, from: data)  {
            self.sub_groups = sub_groups
        }
        if let nodeList = try? container.decodeIfPresent([Node]?.self, forKey: .nodeList) {
            self.nodeList = nodeList
        } else if let data = try? container.decodeIfPresent(Data.self, forKey: .nodeList), let nodeList = try? jsonDecoder.decode([Node].self, from: data)  {
            self.nodeList = nodeList
        }
        if let group_metadata = try? container.decodeIfPresent([String: Any].self, forKey: .group_metadata) {
            self.group_metadata = group_metadata
        } else if let data = try? container.decode(Data.self, forKey: .group_metadata), let group_metadata = try? JSONSerialization.jsonObject(with: data) as? [String: Any]  {
            self.group_metadata = group_metadata
        }
    }
    
    init() {}
}

class CreateNodeGroupResponse: Decodable {
    var status: String
    var group_id: String
}
