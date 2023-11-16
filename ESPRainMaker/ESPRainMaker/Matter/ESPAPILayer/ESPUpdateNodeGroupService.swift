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
//  ESPNodeGroupMetadataService.swift
//  ESPRainmaker
//

import Foundation
import Alamofire

class ESPNodeGroupMetadataService {
    
    let apiWorker = ESPAPIWorker()
    let sessionWorker = ESPExtendUserSessionWorker()
    let url = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes"
    let groupURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/node_group"
    var switchIndex: Int?
    let fabricDetails = ESPMatterFabricDetails.shared
    
    init(switchIndex: Int? = nil) {
        self.switchIndex = switchIndex
    }
    
    /// Bind device
    /// - Parameters:
    ///   - node: source node
    ///   - destinationNodeId: destination node id
    ///   - completion: completion
    func bindDevice(node: Node, destinationNodeId: String, completion: @escaping (Bool) -> Void) {
        if let groupId = node.groupId {
            self.addDeviceToGroupMetadata(groupId: groupId, node: node, destinationNodeId: destinationNodeId) { result in
                completion(result)
            }
        } else {
            completion(false)
        }
    }
    
    /// Unbind device
    /// - Parameters:
    ///   - node: source node
    ///   - destinationNodeId: detination node id
    ///   - completion: completion
    func unbindDevice(node: Node, destinationNodeId: String, completion: @escaping (Bool) -> Void) {
        if let groupId = node.groupId {
            self.removeDeviceFromGroupMetadata(groupId: groupId, node: node, destinationNodeId: destinationNodeId) { result in
                completion(result)
            }
        } else {
            completion(false)
        }
    }
    
    //MARK: Update node group metadata (binding data)
    
    /// Get binding string from list of node ids
    /// - Parameter ids: ids
    /// - Returns: bidning string
    func getBindingValue(ids: [String]) -> String {
        var finalStr = ""
        for index in 0..<ids.count {
            if index == ids.count - 1 {
                finalStr+="\(ids[index])"
            } else {
                finalStr+="\(ids[index]),"
            }
        }
        return finalStr
    }
    
    /// Add device binding to group metadagta
    /// - Parameters:
    ///   - groupId: grouip id
    ///   - node: node
    ///   - destinationNodeId: destination node id
    func addDeviceToGroupMetadata(groupId: String, node: Node, destinationNodeId: String, completion: @escaping (Bool) -> Void) {
        var finalMetadata: [String: Any]?
        if let sourceNodeId = node.node_id, var metadata = self.fabricDetails.getGroupMetadata(groupId: groupId) {
            let keys = metadata.keys
            if keys.contains(sourceNodeId), let value = metadata[sourceNodeId] as? String {
                if !value.contains(destinationNodeId) {
                    if let index = self.switchIndex {
                        metadata[sourceNodeId] = value+",\(destinationNodeId).\(index)" as Any
                    } else {
                        metadata[sourceNodeId] = value+",\(destinationNodeId)" as Any
                    }
                }
            } else {
                if let index = self.switchIndex {
                    metadata[sourceNodeId] = "\(destinationNodeId).\(index)" as Any
                } else {
                    metadata[sourceNodeId] = destinationNodeId as Any
                }
            }
            finalMetadata = metadata
        } else if let sourceNodeId = node.node_id {
            finalMetadata = [String: Any]()
            if let index = self.switchIndex {
                finalMetadata?[sourceNodeId] = "\(destinationNodeId).\(index)" as Any
            } else {
                finalMetadata?[sourceNodeId] = destinationNodeId as Any
            }
        }
        if let data = finalMetadata {
            self.updateGroupMetadata(groupId: groupId, groupMetadata: data) { result in
                if result {
                    if data.isEmpty {
                        self.fabricDetails.removeGroupMetadata(groupId: groupId)
                    } else {
                        self.fabricDetails.saveGroupMetadata(groupId: groupId, groupMetadata: data)
                    }
                }
                completion(result)
            }
        } else {
            completion(false)
        }
    }
    
    /// Remove device from group metadata
    /// - Parameters:
    ///   - groupId: group id
    ///   - node: source node
    ///   - destinationNodeId: destination node id
    ///   - completion: completion
    func removeDeviceFromGroupMetadata(groupId: String, node: Node, destinationNodeId: String, completion: @escaping (Bool) -> Void) {
        if let sourceNodeId = node.node_id, var metadata = self.fabricDetails.getGroupMetadata(groupId: groupId) {
            let keys = metadata.keys
            if keys.contains(sourceNodeId), let value = metadata[sourceNodeId] as? String {
                var finalIds = [String]()
                let ids = value.components(separatedBy: ",")
                for id in ids {
                    if let index = self.switchIndex, id == "\(destinationNodeId).\(index)" {
                        continue
                    } else if id == destinationNodeId {
                        continue
                    }
                    finalIds.append(id)
                }
                if finalIds.count == 0 {
                    metadata = [:]
                } else {
                    let finalValue = self.getBindingValue(ids: finalIds)
                    metadata[sourceNodeId] = finalValue
                }
                self.updateGroupMetadata(groupId: groupId, groupMetadata: metadata) { result in
                    if result {
                        if metadata.isEmpty {
                            self.fabricDetails.removeGroupMetadata(groupId: groupId)
                        } else {
                            self.fabricDetails.saveGroupMetadata(groupId: groupId, groupMetadata: metadata)
                        }
                    }
                    completion(result)
                }
            } else {
                completion(true)
            }
        } else {
            completion(false)
        }
    }
    
    /// Remove source node from group metadata
    /// - Parameters:
    ///   - groupId: groupId
    ///   - node: node to be removed
    ///   - completion: completion
    func removeSourceNodeFromGroupMetadata(groupId: String, node: Node, completion: @escaping (Bool) -> Void) {
        if let sourceNodeId = node.node_id, var metadata = self.fabricDetails.getGroupMetadata(groupId: groupId) {
            if let _ = metadata[sourceNodeId] {
                metadata[sourceNodeId] = nil
            }
            self.updateMetadata(groupId: groupId, groupMetadata: metadata, completion: completion)
        } else {
            completion(false)
        }
    }
    
    /// Remove destination node from groups metadata
    /// - Parameters:
    ///   - groupId: group id
    ///   - destinationNodeId: destination node id
    ///   - completion: completion
    func removeDestinationNodeFromGroupMetadata(groupId: String, destinationNodeId: String, completion: @escaping (Bool) -> Void) {
        if var metadata = self.fabricDetails.getGroupMetadata(groupId: groupId) {
            for key in metadata.keys {
                if let val = metadata[key] as? String {
                    let fields = val.components(separatedBy: ",")
                    let finalList = fields.filter {
                        return !$0.contains(destinationNodeId)
                    }
                    if finalList.count > 0 {
                        let str = self.getBindingValue(ids: finalList)
                        metadata[key] = str
                    } else {
                        metadata[key] = nil
                    }
                }
            }
            self.updateMetadata(groupId: groupId, groupMetadata: metadata, completion: completion)
        } else {
            completion(false)
        }
    }
    
    /// Make API call to update metadata on cloud
    /// - Parameters:
    ///   - groupId: group id
    ///   - groupMetadata: group metadata
    ///   - completion: completion
    func updateMetadata(groupId: String, groupMetadata: [String: Any], completion: @escaping (Bool) -> Void) {
        self.updateGroupMetadata(groupId: groupId, groupMetadata: groupMetadata) { result in
            if result {
                if groupMetadata.isEmpty {
                    self.fabricDetails.removeGroupMetadata(groupId: groupId)
                } else {
                    self.fabricDetails.saveGroupMetadata(groupId: groupId, groupMetadata: groupMetadata)
                }
            }
            completion(result)
        }
    }
    
    /// Update group metadata
    /// - Parameters:
    ///   - groupId: group id
    ///   - groupMetadata: group metadata
    ///   - completion: completion
    func updateGroupMetadata(groupId: String, groupMetadata: [String: Any], completion: @escaping (Bool) -> Void) {
        if let group = self.fabricDetails.getGroupData(groupId: groupId), let groupName = group.groupName {
            let sessionWorker = ESPExtendUserSessionWorker()
            sessionWorker.checkUserSession { token, _ in
                if let token = token {
                    let updateURL = self.groupURL + "?group_id=\(groupId)"
                    let headers: HTTPHeaders = [ESPMatterConstants.contentType: ESPMatterConstants.applicationJSON,
                                                ESPMatterConstants.authorization: token]
                    let params = [ESPMatterConstants.groupName: groupName,
                                  ESPMatterConstants.groupMetadata: groupMetadata as Any]
                    self.apiWorker.callDataAPI(url: updateURL, method: .put, parameters: params, headers: headers, apiDescription: "Update Group Metadata") { data, _ in
                        guard let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = json[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                } else {
                    completion(false)
                }
            }
        }
    }
}
