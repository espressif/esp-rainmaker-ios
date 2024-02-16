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
//  Node+ControllerUtility.swift
//  ESPRainMaker
//

import Foundation

extension Node {
    
    var controllerSupportKey: String? {
        if let matterNodeId = self.matter_node_id {
            return "matter.controller.supported.device.\(matterNodeId)"
        }
        return nil
    }
    
    /// Does device fabric have a controller
    var isControllerFabric: Bool {
        if let groupId = self.groupId {
            if let nodes = User.shared.associatedNodeList {
                for node in nodes {
                    if let nodeGroupId = node.groupId, groupId == nodeGroupId, let matterNodeId = node.matter_node_id, let nodeDeviceId = matterNodeId.hexToDecimal {
                        if ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: nodeGroupId, deviceId: nodeDeviceId).0 {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    /// Matter controller node
    var matterControllerNode: Node? {
        if let groupId = self.groupId {
            if let nodes = User.shared.associatedNodeList {
                for node in nodes {
                    if let nodeGroupId = node.groupId, groupId == nodeGroupId, let matterNodeId = node.matter_node_id, let nodeDeviceId = matterNodeId.hexToDecimal {
                        if ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: nodeGroupId, deviceId: nodeDeviceId).0 {
                            return node
                        }
                    }
                }
            }
        }
        return nil
    }
    
    /// Matter controller node id
    var matterControllerMatterNodeId: String? {
        if let groupId = self.groupId {
            if let nodes = User.shared.associatedNodeList {
                for node in nodes {
                    if let nodeGroupId = node.groupId, groupId == nodeGroupId, let matterNodeId = node.matter_node_id, let nodeDeviceId = matterNodeId.hexToDecimal {
                        if ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: nodeGroupId, deviceId: nodeDeviceId).0 {
                            return matterNodeId
                        }
                    }
                }
            }
        }
        return nil
    }
    
    /// Is device of type controller
    var isControllerDevice: Bool {
        if let nodeGroupId = self.groupId, let matterNodeId = self.matter_node_id, let nodeDeviceId = matterNodeId.hexToDecimal {
            return ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: nodeGroupId, deviceId: nodeDeviceId).0
        }
        return false
    }
    
    /// Connection status
    var connectionStatus: NodeConnectionStatus {
        if let matterNodeId = self.matter_node_id {
            if User.shared.isMatterNodeConnected(matterNodeId: matterNodeId) {
                return .local
            } else if self.isRainmaker, self.isConnected {
                return .remote
            }
        }
        return .offline
    }
}
