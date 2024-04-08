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
//  MatterControllerParser+Utility.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
@available(iOS 16.4, *)
extension MatterControllerParser {
    
    /// Get value for cluster id/attribute id
    /// - Parameters:
    ///   - cluster: cluster
    ///   - clusterId: cluster id
    ///   - attributeId: attriubute id
    /// - Returns: cluster/attribute value
    func getClusterAttributeValue(cluster: [String: MatterAttributeData]?, clusterId: String, attributeId: String) -> String? {
        if let cluster = cluster {
            for cId in cluster.keys {
                if cId == clusterId {
                    if let attributesData = cluster[clusterId], let attributes = attributesData.attributes {
                        for aId in attributes.keys {
                            if aId == attributeId, let attributeValue = attributes[attributeId] {
                                return attributeValue
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    /// Get matter endpoiints data for matter node
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    /// - Returns: endpoints data
    func getMatterNodesEndpointsData(controllerNodeId: String, matterNodeId: String) -> [String: MatterEndpointsData]? {
        if let matterNodesData = self.getMatterNodesData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
            if let endpointsData = self.getMatterEndpointsData(matterNodeId: matterNodeId, matterNodesData: matterNodesData) {
                return endpointsData
            }
        }
        return nil
    }
    
    /// Matter nodes data
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: device matter node id
    /// - Returns: matter nodes data
    func getMatterNodesData(controllerNodeId: String, matterNodeId: String) -> [String: MatterNodeData]? {
        if let controller = self.fetchMatterControllerData(nodeId: controllerNodeId) {
            if let controllerData = controller.matterControllerData, let matterNodesData = controllerData.matterNodesData {
                return matterNodesData
            }
        }
        return nil
    }
    
    /// Get matter node data
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    func getMatterNodeData(controllerNodeId: String, matterNodeId: String) -> MatterNodeData? {
        if let controller = self.fetchMatterControllerData(nodeId: controllerNodeId) {
            if let controllerData = controller.matterControllerData, let matterNodesData = controllerData.matterNodesData {
                for mtrId in matterNodesData.keys {
                    if mtrId.lowercased() == matterNodeId.lowercased(), let matterNodeData = matterNodesData[mtrId] {
                        return matterNodeData
                    }
                }
            }
        }
        return nil
    }
    
    /// Get endpoints data
    /// - Parameters:
    ///   - matterNodeId: matter node id
    ///   - matterNodesData: matter nodes data
    /// - Returns: endpoints data
    func getMatterEndpointsData(matterNodeId: String, matterNodesData: [String: MatterNodeData]) -> [String: MatterEndpointsData]? {
        for mId in matterNodesData.keys {
            if mId.lowercased() == matterNodeId.lowercased() {
                if let matterNodeData = matterNodesData[mId], let endpointsData = matterNodeData.endpointsData {
                    return endpointsData
                }
            }
        }
        return nil
    }
    
    /// Get matter endpoints
    /// - Parameters:
    ///   - endpointsData: endpoints data
    ///   - endpointId: endpoint id
    /// - Returns: matter endpoints
    func getMatterEndpoints(endpointsData: [String: MatterEndpointsData], endpointId: String) -> [MatterEndpointData]? {
        for eId in endpointsData.keys {
            if eId == endpointId, let matterEndpointsData = endpointsData[endpointId] as? MatterEndpointsData, let endpoints = matterEndpointsData.endpoints as? [MatterEndpointData] {
                return endpoints
            }
        }
        return nil
    }
    
    /// Get ,matter endpoint id
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    ///   - clusterId: cluster id
    /// - Returns: matter cluster endpoint id
    func getMatterEndpointId(controllerNodeId: String, matterNodeId: String, clusterId: String) -> String? {
        if let matterNodesData = self.getMatterNodesData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId) {
            if let endpointsData = self.getMatterEndpointsData(matterNodeId: matterNodeId, matterNodesData: matterNodesData) {
                for endpointId in endpointsData.keys {
                    if let matterEndpointsData = endpointsData[endpointId] as? MatterEndpointsData, let endpoints = matterEndpointsData.endpoints as? [MatterEndpointData] {
                        for endpoint in endpoints {
                            if let clusters = endpoint.clusters {
                                for clusterData in clusters {
                                    if let cluster = clusterData.cluster {
                                        for cId in cluster.keys {
                                            if cId == clusterId {
                                                return endpointId
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
}
#endif
