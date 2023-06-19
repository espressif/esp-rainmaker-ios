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
//  ESPMatterAPIEndpoint.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

enum ESPMatterAPIEndpoint {
    
    /// All endpoints
    case getNodes(url: String, token: String)
    
    /*Fabric APIs*/
    case getNodeGroups(url: String, token: String)
    case getNodeGroupsMatterFabricDetails(url: String, token: String)
    case getNodeDetails(url: String, token: String, groupId: String)
    case createMatterFabric(url: String, groupName: String, type: String, mutuallyExclusive: Bool, description: String, isMatter: Bool, token: String)
    case getNodeMetadata(url: String, token: String, nodeId: String?)
    case convertNodeGroupToMatterFabric(url: String, groupId: String, token: String)
    case issueUserNOC(url: String, groupId: String, operation: String, csr: String, token: String)
    case addNodeToMatterFabric(url: String, groupId: String, operation: String, csr: String, token: String, metaData: [String: Any]?)
    case confirmNodeCommissioning(url: String, groupId: String, requestId: String, status: String, token: String)
    case confirmMatterRainmakerCommissioning(url: String, groupId: String, requestId: String, challenge: String, rainmakerNodeId: String, token: String)
    case deleteMatterFabric(url: String, groupId: String, token: String)
    case removeNode(token: String, params: Parameters)
    case removeNodeFromFabric(groupId: String, token: String, params: Parameters)
    
    // MARK: Returns URL string for the corresponding API endpoint
    var url: String {
        
        switch self {
        case .getNodes(let url, _):
            return url + "?node_details=true"
            
        case .getNodeGroups(let url, _):
            return url + "/user/node_group?node_list=true&node_details=true&fabric_details=true"
            
        case .getNodeGroupsMatterFabricDetails(let url, _):
            return url + "/user/node_group?is_matter=true&fabric_details=true"
            
        case .getNodeDetails(let url, _, let groupId):
            return url + "/user/node_group?group_id=\(groupId)&is_matter=true&fabric_details=true&node_details=true"
            
        case .getNodeMetadata(let url, _, let nodeId):
            if let nodeId = nodeId {
                return url + "/user/nodes?node_id=\(nodeId)&node_details=true&is_matter=true"
            }
            return url + "/user/nodes?node_details=true&is_matter=true"
            
        case .createMatterFabric(let url, _, _, _, _, _, _), .issueUserNOC(let url, _, _, _, _), .addNodeToMatterFabric(let url, _, _, _, _, _):
            return url + "/user/node_group"
            
        case .confirmNodeCommissioning(let url, let groupId, _, _, _), .convertNodeGroupToMatterFabric(let url, let groupId, _), .confirmMatterRainmakerCommissioning(let url, let groupId, _, _, _, _):
            return "\(url)/user/node_group?group_id=\(groupId)"
            
        case .deleteMatterFabric(let url, let groupId, _):
            return url + "/user/node_group?group_id=\(groupId)"
            
        case .removeNode(_, _):
            return Constants.addDevice
        case .removeNodeFromFabric(let groupId, _, _):
            return Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/node_group?group_id=\(groupId)"
        }
    }
    
    
    // MARK: Returns HTTPHeaders for the corresponding API endpoint
    var headers: HTTPHeaders {
        switch self {
        case .getNodes(_, let token), .getNodeMetadata(_, let token, _):
            return [ESPMatterConstants.contentType: ESPMatterConstants.applicationJSON,
                    ESPMatterConstants.authorization: token]
            
        case .getNodeGroups(_, let token), .createMatterFabric(_,_,_,_,_,_ ,let token), .addNodeToMatterFabric(_, _, _, _ ,let token, _), .confirmNodeCommissioning(_, _, _, _ ,let token), .deleteMatterFabric(_, _, let token), .convertNodeGroupToMatterFabric(_, _, let token), .issueUserNOC(_, _, _, _ ,let token), .getNodeGroupsMatterFabricDetails(_, let token), .getNodeDetails(_, let token, _), .confirmMatterRainmakerCommissioning(_, _, _, _, _, let token):
            return [ESPMatterConstants.contentType: ESPMatterConstants.applicationJSON,
                    ESPMatterConstants.authorization: token]
            
        case .removeNode(let token, _), .removeNodeFromFabric(_, let token, _):
            return [ESPMatterConstants.contentType: ESPMatterConstants.applicationJSON,
                    ESPMatterConstants.authorization: token]
        }
    }
    
    
    // MARK: Returns HTTPMethod for the corresponding API endpoint
    var method: HTTPMethod {
        switch self {
        case .getNodes(_,_), .getNodeGroups(_,_), .getNodeGroupsMatterFabricDetails(_,_), .getNodeDetails(_,_,_),  .getNodeMetadata(_,_,_):
            return .get
        case .createMatterFabric(_,_,_,_,_,_,_):
            return .post
        case .addNodeToMatterFabric(_,_,_,_,_,_), .confirmNodeCommissioning(_,_,_,_,_), .convertNodeGroupToMatterFabric(_,_,_), .issueUserNOC(_,_,_,_,_), .removeNodeFromFabric(_,_,_), .removeNode(_,_), .confirmMatterRainmakerCommissioning(_,_,_,_,_,_):
            return .put
        case .deleteMatterFabric(_,_,_):
            return .delete
        }
    }
    
    
    // MARK: Returns Parameters for the corresponding API endpoint
    var parameters: Parameters? {
        switch self {
        case .getNodes(_,_), .getNodeMetadata(_,_,_):
            return nil
        case .createMatterFabric(_,let groupName,_, _, _, let isMatter, _):
            return [ESPMatterConstants.groupName: groupName,
                    ESPMatterConstants.isMatter: isMatter]
        case .convertNodeGroupToMatterFabric(_,_,_):
            return [ESPMatterConstants.isMatter: true]
        case .addNodeToMatterFabric(_, let groupId, let operation, let csr, _, let metaData):
            if let metaData = metaData {
                return [ESPMatterConstants.operation: operation,
                        ESPMatterConstants.csrType: ESPMatterConstants.node,
                        ESPMatterConstants.csrRequests: [[ESPMatterConstants.csr: csr,
                                                          ESPMatterConstants.groupId: groupId]],
                        ESPMatterConstants.metadata: metaData]
            }
            return [ESPMatterConstants.operation: operation,
                    ESPMatterConstants.csrType: ESPMatterConstants.node,
                    ESPMatterConstants.csrRequests: [[ESPMatterConstants.csr: csr,
                                                      ESPMatterConstants.groupId: groupId]]]
        case .issueUserNOC(_, let groupId, let operation, let csr, _):
            return [ESPMatterConstants.operation: operation,
                    ESPMatterConstants.csrType: ESPMatterConstants.user,
                    ESPMatterConstants.csrRequests: [[ESPMatterConstants.csr: csr,
                                                      ESPMatterConstants.groupId: groupId]]]
        case .confirmNodeCommissioning(_, _, let requestId, let status, _):
            return [ESPMatterConstants.requestId: requestId,
                    ESPMatterConstants.status: status]
        case .confirmMatterRainmakerCommissioning(_, _, let requestId, let challenge, let rainmakerNodeId, _):
            return [ESPMatterConstants.requestId: requestId,
                    ESPMatterConstants.status: ESPMatterConstants.success,
                    ESPMatterConstants.rainmakerNodeId: rainmakerNodeId,
                    ESPMatterConstants.challenge: challenge]
        case .getNodeGroups(_,_), .deleteMatterFabric(_, _, _), .getNodeGroupsMatterFabricDetails(_,_), .getNodeDetails(_,_,_):
            return nil
        case .removeNode(_, let params), .removeNodeFromFabric(_,_, let params):
            return params
        }
    }
    
    
    // MARK: Returns description for the corresponding API endpoint
    var description: String {
        switch self {
        case .getNodes(_,_):
            return "getNodes"
        case .getNodeGroups(_,_):
            return "getNodeGroups"
        case .getNodeGroupsMatterFabricDetails(_,_):
            return "getNodeGroupsMatterFabricDetails"
        case .getNodeDetails(_,_,_):
            return "getNodeDetails"
        case .createMatterFabric(_,_,_,_,_,_,_):
            return "createNewUser"
        case .addNodeToMatterFabric(_,_,_,_,_,_):
            return "addNodeToMatterFabric"
        case .issueUserNOC(_,_,_,_,_):
            return "issueUserNOC"
        case .confirmNodeCommissioning(_,_,_,_,_):
            return "addNodeToMatterFabric"
        case .confirmMatterRainmakerCommissioning(_,_,_,_,_,_):
            return "confirmMatterRainmakerCommissioning"
        case .deleteMatterFabric(_, _, _):
            return "deleteMatterFabric"
        case .convertNodeGroupToMatterFabric(_,_,_):
            return "convertNodeGroupToMatterFabric"
        case .removeNode(_,_):
            return "removeNode"
        case .removeNodeFromFabric(_,_,_):
            return "removeNodeFromFabric"
        case .getNodeMetadata(_,_,_):
            return "getNodeMetadata"
        }
    }
}
