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
//  MatterControllerDataModels.swift
//  ESPRainmaker
//

import Foundation

@available(iOS 16.4, *)
struct MatterController {
    
    var matterControllerDataVersion: String?
    var matterControllerData: MatterControllerData?
    
    enum CodingKeys: String, CodingKey {
        case matterControllerDataVersion = "matter-controller-data-version"
        case matterControllerData = "matter-controller-data"
    }
}

@available(iOS 16.4, *)
struct MatterControllerData {
    
    var matterNodesData: [String: MatterNodeData]?
}

@available(iOS 16.4, *)
struct MatterNodeData {
    
    var enabled: Bool?
    var reachable: Bool?
    var endpointsData: [String: MatterEndpointsData]?
    
    var finalEndpointsData: [String: MatterEndpointData]?
}

@available(iOS 16.4, *)
struct MatterEndpointsData {
    
    var endpoints: [MatterEndpointData]?
}

@available(iOS 16.4, *)
struct MatterEndpointData {
    
    var clusters: [MatterClusterData]?
    
    var clustersData: [String: MatterClusterData]?
    var clients: [String: [String]]?
}

@available(iOS 16.4, *)
struct MatterClusterData {
    
    var cluster: [String: MatterAttributeData]?
    
    var servers: [MatterServersData]?
}

@available(iOS 16.4, *)
struct MatterServersData {
    
    var attributes: [String: Any]?
    var events: [String: Any]?
}

@available(iOS 16.4, *)
struct MatterAttributeData {
    
    var attributes: [String: String]?
    var finalAttributes: [String: Any]?
}
