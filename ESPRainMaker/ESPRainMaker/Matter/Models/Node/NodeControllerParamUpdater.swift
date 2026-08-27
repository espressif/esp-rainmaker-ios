// Copyright 2026 Espressif Systems
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
//  NodeControllerParamUpdater.swift
//  ESPRainMaker
//

import Foundation

/// Shared writer for RainMaker / client-only controller auth params.
/// Packs the service payload on `Node` and sends it via `DeviceControlHelper`.
enum NodeControllerParamUpdater {

    static func updateRmakerControllerParams(
        node: Node,
        baseURL: String,
        refreshToken: String,
        groupId: String?,
        delegate: ParamUpdateProtocol?,
        completion: @escaping () -> Void
    ) {
        var params: [String: Any] = [:]
        if let paramName = node.rmakerControllerUserTokenParam?.name {
            params[paramName] = refreshToken
        }
        if let paramName = node.rmakerControllerBaseURLParam?.name {
            params[paramName] = baseURL
        }
        if let groupId = groupId, let paramName = node.rmakerControllerGroupParam?.name {
            params[paramName] = groupId
        }
        send(
            node: node,
            params: params,
            serviceType: RainmakerControllerConstants.rmakerControllerServiceType,
            delegate: delegate,
            completion: completion
        )
    }

    static func updateClientOnlyControllerParams(
        node: Node,
        baseURL: String,
        refreshToken: String,
        groupId: String?,
        delegate: ParamUpdateProtocol?,
        completion: @escaping () -> Void
    ) {
        var params: [String: Any] = [:]
        if let paramName = node.clientOnlyControllerUserTokenParam?.name {
            params[paramName] = refreshToken
        }
        if let paramName = node.clientOnlyControllerBaseURLParam?.name {
            params[paramName] = baseURL
        }
        if let groupId = groupId, let paramName = node.clientOnlyControllerRmakerGroupParam?.name {
            params[paramName] = groupId
        }
        if let groupId = groupId, let paramName = node.clientOnlyControllerGroupParam?.name {
            params[paramName] = groupId
        }
        send(
            node: node,
            params: params,
            serviceType: ClientOnlyControllerConstants.serviceType,
            delegate: delegate,
            completion: completion
        )
    }

    private static func send(
        node: Node,
        params: [String: Any],
        serviceType: String,
        delegate: ParamUpdateProtocol?,
        completion: @escaping () -> Void
    ) {
        guard params.count > 0, let serviceName = node.getServiceName(forServiceType: serviceType) else {
            completion()
            return
        }
        DeviceControlHelper.shared.updateParam(
            nodeID: node.node_id ?? "",
            parameter: [serviceName: params as Any],
            delegate: delegate
        ) { _ in
            completion()
        }
    }
}
