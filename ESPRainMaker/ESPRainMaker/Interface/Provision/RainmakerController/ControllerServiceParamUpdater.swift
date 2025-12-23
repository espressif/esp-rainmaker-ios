// Copyright 2025 Espressif Systems
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
//  ControllerServiceParamUpdater.swift
//  ESPRainMaker
//

import Foundation

/// Shared controller service / param handling aligned with Android `ControllerLoginActivity` and `GroupSelectionActivity`.
struct ControllerServiceParamUpdater {
    
    private static let groupParamTypes = [
        MatterControllerConstants.paramRainmakerGroupId,
        MatterControllerConstants.paramGroupId
    ]
    
    private static let groupSelectionServiceTypes = [
        RainmakerControllerConstants.rmakerControllerServiceType,
        RainmakerControllerConstants.rmControllerServiceType,
        MatterControllerConstants.serviceType,
        MatterControllerConstants.setupServiceType,
        RainmakerControllerConstants.groupsServiceType
    ]
    
    static func hasControllerLoginService(node: Node) -> Bool {
        return node.isRmakerControllerSupported
            || node.isRmControllerSupported
            || node.getService(forServiceType: MatterControllerConstants.serviceType) != nil
            || node.isMatterControllerSetupSupported
    }
    
    static func isGroupsServiceOnlyFlow(node: Node) -> Bool {
        return node.isGroupsServiceSupported && !hasControllerLoginService(node: node)
    }
    
    /// Post-provision: matches Android `hasGroupIdParam` — group-id param type present; value not checked.
    static func shouldOpenGroupSelectionAfterProvisioning(node: Node) -> Bool {
        return hasGroupIdParam(node: node)
    }
    
    /// Params screen and manual flows: group selection when group-id param exists and value is empty.
    static func shouldOpenGroupSelection(node: Node) -> Bool {
        for serviceType in groupSelectionServiceTypes {
            guard let service = node.getService(forServiceType: serviceType),
                  let params = service.params else { continue }
            for param in params {
                let value = (param.value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if let type = param.type,
                   groupParamTypes.contains(type),
                   value.isEmpty {
                    return true
                }
            }
        }
        return false
    }
    
    /// Params screen Update Params: always group-select for `esp.service.rmaker-controller` (Piyush); other services when group id is empty.
    static func shouldOpenGroupSelectionForUpdateParams(node: Node) -> Bool {
        if node.isRmControllerSupported {
            return true
        }
        return shouldOpenGroupSelection(node: node)
    }
    
    /// Matches Android: `addControllerToGroup` when `rmaker-controller` service is present.
    static func shouldCallAddControllerToGroup(node: Node, groupId: String?) -> Bool {
        guard let groupId = groupId, !groupId.isEmpty else { return false }
        return node.isRmControllerSupported
    }
    
    static func buildLoginParamBody(node: Node,
                                    baseURL: String,
                                    refreshToken: String,
                                    groupId: String?,
                                    onlyIfGroupIdEmpty: Bool) -> [String: Any] {
        var body: [String: Any] = [:]
        appendLoginParams(node: node,
                          serviceType: RainmakerControllerConstants.rmakerControllerServiceType,
                          baseURL: baseURL,
                          refreshToken: refreshToken,
                          groupId: groupId,
                          includeRmakerGroupId: true,
                          includeGroupId: false,
                          onlyIfGroupIdEmpty: onlyIfGroupIdEmpty,
                          body: &body)
        appendLoginParams(node: node,
                          serviceType: RainmakerControllerConstants.rmControllerServiceType,
                          baseURL: baseURL,
                          refreshToken: refreshToken,
                          groupId: groupId,
                          includeRmakerGroupId: true,
                          includeGroupId: true,
                          onlyIfGroupIdEmpty: onlyIfGroupIdEmpty,
                          body: &body)
        appendLoginParams(node: node,
                          serviceType: MatterControllerConstants.serviceType,
                          baseURL: baseURL,
                          refreshToken: refreshToken,
                          groupId: groupId,
                          includeRmakerGroupId: true,
                          includeGroupId: true,
                          onlyIfGroupIdEmpty: onlyIfGroupIdEmpty,
                          body: &body)
        appendLoginParams(node: node,
                          serviceType: MatterControllerConstants.setupServiceType,
                          baseURL: baseURL,
                          refreshToken: refreshToken,
                          groupId: groupId,
                          includeRmakerGroupId: true,
                          includeGroupId: true,
                          onlyIfGroupIdEmpty: onlyIfGroupIdEmpty,
                          body: &body)
        return body
    }
    
    static func updateLoginParams(node: Node,
                                  baseURL: String,
                                  refreshToken: String,
                                  groupId: String?,
                                  onlyIfGroupIdEmpty: Bool,
                                  delegate: ParamUpdateProtocol?,
                                  completion: @escaping () -> Void) {
        let body = buildLoginParamBody(node: node,
                                       baseURL: baseURL,
                                       refreshToken: refreshToken,
                                       groupId: groupId,
                                       onlyIfGroupIdEmpty: onlyIfGroupIdEmpty)
        guard !body.isEmpty, let nodeId = node.node_id else {
            completion()
            return
        }
        DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: body, delegate: delegate) { _ in
            completion()
        }
    }
    
    static func updateGroupsServiceParams(node: Node,
                                          groupId: String,
                                          delegate: ParamUpdateProtocol?,
                                          completion: @escaping () -> Void) {
        guard let serviceName = node.getServiceName(forServiceType: RainmakerControllerConstants.groupsServiceType) else {
            completion()
            return
        }
        var params: [String: Any] = [:]
        if let name = node.groupsServiceRmakerGroupParam?.name {
            params[name] = groupId
        }
        if let name = node.groupsServiceGroupParam?.name {
            params[name] = groupId
        }
        guard !params.isEmpty, let nodeId = node.node_id else {
            completion()
            return
        }
        let body = [serviceName: params] as [String: Any]
        DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: body, delegate: delegate) { _ in
            completion()
        }
    }
    
    static func performPostLoginControllerSetup(node: Node,
                                                baseURL: String,
                                                refreshToken: String,
                                                groupId: String?,
                                                delegate: ParamUpdateProtocol?,
                                                completion: @escaping () -> Void) {
        guard let nodeId = node.node_id else {
            completion()
            return
        }
        let applyParams = {
            updateLoginParams(node: node,
                              baseURL: baseURL,
                              refreshToken: refreshToken,
                              groupId: groupId,
                              onlyIfGroupIdEmpty: false,
                              delegate: delegate,
                              completion: completion)
        }
        if shouldCallAddControllerToGroup(node: node, groupId: groupId), let groupId = groupId {
            NetworkManager.shared.addControllerToGroup(nodeId: nodeId, groupId: groupId) { success, _ in
                if success {
                    applyParams()
                }
            }
        } else {
            applyParams()
        }
    }
    
    static func sendUpdateDeviceListCommand(node: Node,
                                            delegate: ParamUpdateProtocol?,
                                            completion: @escaping (ESPCloudResponseStatus?) -> Void) {
        guard let nodeId = node.node_id else {
            completion(nil)
            return
        }
        var pending: [(String, String)] = []
        if node.getService(forServiceType: MatterControllerConstants.serviceType) != nil,
           let service = node.getServiceName(forServiceType: MatterControllerConstants.serviceType),
           let cmd = node.clientOnlyControllerUpdateDeviceListCommandParam?.name {
            pending.append((service, cmd))
        }
        if node.isRmakerControllerSupported,
           let service = node.getServiceName(forServiceType: RainmakerControllerConstants.rmakerControllerServiceType),
           let cmd = node.rmakerControllerUpdateDeviceListCommandParam?.name {
            pending.append((service, cmd))
        }
        if let service = node.getServiceName(forServiceType: MatterControllerConstants.setupServiceType),
           let cmd = node.getServiceParam(forServiceType: MatterControllerConstants.setupServiceType,
                                          andParamType: MatterControllerConstants.paramMatterCtlCmd)?.name {
            pending.append((service, cmd))
        }
        sendUpdateDeviceListCommands(nodeId: nodeId, pending: pending, index: 0, delegate: delegate, completion: completion)
    }
    
    static func sendUpdateDeviceListToControllerSetupNodes(groupId: String?) {
        guard let groupId = groupId, !groupId.isEmpty, let allNodes = User.shared.associatedNodeList else { return }
        let setupNodes = allNodes.filter { node in
            node.groupId == groupId && node.getServiceName(forServiceType: MatterControllerConstants.setupServiceType) != nil
        }
        for setupNode in setupNodes {
            guard let nodeId = setupNode.node_id,
                  let serviceName = setupNode.getServiceName(forServiceType: MatterControllerConstants.setupServiceType),
                  let cmdParamName = setupNode.getServiceParam(forServiceType: MatterControllerConstants.setupServiceType,
                                                               andParamType: MatterControllerConstants.paramMatterCtlCmd)?.name else { continue }
            let params: [String: Any] = [serviceName: [cmdParamName: 2] as Any]
            DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: params, delegate: nil)
        }
    }
    
    // MARK: - Private
    
    private static func hasGroupIdParam(node: Node) -> Bool {
        for serviceType in groupSelectionServiceTypes {
            guard let params = node.getServiceParams(forServiceType: serviceType) else { continue }
            for param in params {
                if let type = param.type, groupParamTypes.contains(type) {
                    return true
                }
            }
        }
        return false
    }
    
    private static func appendLoginParams(node: Node,
                                          serviceType: String,
                                          baseURL: String,
                                          refreshToken: String,
                                          groupId: String?,
                                          includeRmakerGroupId: Bool,
                                          includeGroupId: Bool,
                                          onlyIfGroupIdEmpty: Bool,
                                          body: inout [String: Any]) {
        guard let serviceName = node.getServiceName(forServiceType: serviceType) else { return }
        var params: [String: Any] = [:]
        if !refreshToken.isEmpty,
           let param = node.getServiceParam(forServiceType: serviceType, andParamType: RainmakerControllerConstants.paramUserToken),
           let name = param.name {
            params[name] = refreshToken
        }
        if !baseURL.isEmpty,
           let param = node.getServiceParam(forServiceType: serviceType, andParamType: RainmakerControllerConstants.paramBaseURL),
           let name = param.name {
            params[name] = baseURL
        }
        if let groupId = groupId, !groupId.isEmpty {
            if includeRmakerGroupId,
               let param = node.getServiceParam(forServiceType: serviceType, andParamType: RainmakerControllerConstants.paramRainmakerGroupId),
               let name = param.name,
               shouldWriteGroupId(param: param, onlyIfEmpty: onlyIfGroupIdEmpty) {
                params[name] = groupId
            }
            if includeGroupId,
               let param = node.getServiceParam(forServiceType: serviceType, andParamType: RainmakerControllerConstants.paramGroupId),
               let name = param.name,
               shouldWriteGroupId(param: param, onlyIfEmpty: onlyIfGroupIdEmpty) {
                params[name] = groupId
            }
        }
        if !params.isEmpty {
            body[serviceName] = params
        }
    }
    
    private static func shouldWriteGroupId(param: Param, onlyIfEmpty: Bool) -> Bool {
        if !onlyIfEmpty { return true }
        let value = (param.value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty
    }
    
    private static func sendUpdateDeviceListCommands(nodeId: String,
                                                     pending: [(String, String)],
                                                     index: Int,
                                                     delegate: ParamUpdateProtocol?,
                                                     completion: @escaping (ESPCloudResponseStatus?) -> Void) {
        guard index < pending.count else {
            completion(pending.isEmpty ? nil : .success)
            return
        }
        let (serviceName, cmdName) = pending[index]
        let params: [String: Any] = [serviceName: [cmdName: 2] as Any]
        DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: params, delegate: delegate) { status in
            if index + 1 < pending.count {
                sendUpdateDeviceListCommands(nodeId: nodeId, pending: pending, index: index + 1, delegate: delegate, completion: completion)
            } else {
                completion(status)
            }
        }
    }
}
