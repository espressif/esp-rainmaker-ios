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
//  NetworkManager+BleLocalControl.swift
//  ESPRainMaker
//

import Foundation

extension NetworkManager {

    /// Cloud getNodes when online, then overlay BLE-only firmware scene/schedule params.
    func refreshNodesWithBleOverlay(completion: @escaping () -> Void) {
        let overlay = { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            User.shared.bleLocalControl.reapplyBleStatusToNodes()
            self.overlayBleOnlyFirmwareServiceParams(completion: completion)
        }
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            getNodes { nodes, error in
                if error == nil, let nodes = nodes {
                    User.shared.associatedNodeList = nodes
                }
                overlay()
            }
        } else {
            overlay()
        }
    }

    /// Read params from BLE-only firmware (when reachable) and ingest scenes/schedules from them.
    func overlayBleOnlyFirmwareServiceParams(completion: @escaping () -> Void) {
        guard Configuration.shared.appConfiguration.supportLocalControl else {
            completion()
            return
        }
        let nodeIds = (User.shared.associatedNodeList ?? []).compactMap { node -> String? in
            guard let nodeId = node.node_id,
                  node.isBleOnlyExcludedFromMultiDeviceServices(),
                  User.shared.bleLocalControl.isAvailable(nodeId: nodeId) else {
                return nil
            }
            return nodeId
        }
        overlayBleParamsSequentially(nodeIds: nodeIds, updatedIds: []) { updatedIds in
            if !updatedIds.isEmpty {
                ESPLocalStorageHandler().saveSchedules(schedules: ESPScheduler.shared.schedules)
                ESPLocalStorageHandler().saveScenes(scenes: ESPSceneManager.shared.scenes)
            }
            completion()
        }
    }

    func refreshNodeParamsFromBle(nodeId: String, completionHandler: @escaping (Node?, ESPNetworkError?) -> Void) {
        guard let cachedNode = User.shared.getNode(id: nodeId) else {
            getNodeInfoPrivate(nodeId: nodeId, completionHandler: completionHandler)
            return
        }
        queryBleParamsConnectingIfNeeded(nodeId: nodeId) { json in
            if let json = json {
                self.applyBleParamJson(json, to: cachedNode)
                cachedNode.bleLocalNetwork = true
                completionHandler(cachedNode, nil)
            } else if cachedNode.preferredParamTransport() != .ble, ESPNetworkMonitor.shared.isConnectedToNetwork {
                self.getNodeInfoPrivate(nodeId: nodeId, completionHandler: completionHandler)
            } else {
                completionHandler(nil, .noNetwork)
            }
        }
    }

    func refreshDeviceParamsFromBle(
        nodeId: String,
        device: Device,
        completionHandler: @escaping (ESPNetworkError?) -> Void
    ) {
        let queryParams: () -> Void = { [weak self] in
            guard let self = self else { return }
            User.shared.bleLocalControl.queryParams(nodeId: nodeId) { json in
                if let json = json {
                    self.applyBleParams(json: json, to: device)
                    completionHandler(nil)
                } else if ESPNetworkMonitor.shared.isConnectedToNetwork {
                    self.getDeviceParamPrivate(device: device, completionHandler: completionHandler)
                } else {
                    completionHandler(.noNetwork)
                }
            }
        }

        if User.shared.bleLocalControl.isConnected(nodeId: nodeId) {
            queryParams()
        } else if User.shared.bleLocalControl.isDiscovered(nodeId: nodeId) {
            User.shared.bleLocalControl.connectDevice(nodeId: nodeId) { success in
                if success {
                    queryParams()
                } else if ESPNetworkMonitor.shared.isConnectedToNetwork {
                    self.getDeviceParamPrivate(device: device, completionHandler: completionHandler)
                } else {
                    completionHandler(.noNetwork)
                }
            }
        } else if ESPNetworkMonitor.shared.isConnectedToNetwork {
            getDeviceParamPrivate(device: device, completionHandler: completionHandler)
        } else {
            completionHandler(.noNetwork)
        }
    }

    func applySetParamToLocalNodes(nodeId: String, parameter: [String: Any]) {
        guard let node = User.shared.getNode(id: nodeId) else { return }
        if let devices = node.devices {
            for device in devices {
                applySetParam(parameter: parameter, to: device)
            }
        }
        for service in node.services ?? [] {
            guard let serviceName = service.name,
                  let serviceInfo = parameter[serviceName] as? [String: Any] else { continue }
            for param in service.params ?? [] {
                guard let paramName = param.name, let value = serviceInfo[paramName] else { continue }
                param.value = value
            }
        }
        node.syncServiceEntryCount(for: .scene)
        node.syncServiceEntryCount(for: .schedule)
        ESPLocalStorageHandler().saveNodeDetails(nodes: User.shared.associatedNodeList)
    }

    func reportBleParamsToProxy(nodeId: String) {
        bleProxyReportWorkItems[nodeId]?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.bleProxyReportWorkItems[nodeId] = nil
            self.performReportBleParamsToProxy(nodeId: nodeId)
        }
        bleProxyReportWorkItems[nodeId] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + bleProxyReportDelay, execute: work)
    }

    func clearBleAndFallbackToCloud(
        nodeId: String,
        nodeID: String?,
        parameter: [String: Any],
        completionHandler: @escaping (ESPCloudResponseStatus) -> Void
    ) {
        let node = User.shared.getNode(id: nodeId)
        let stayOnBle: Bool
        if let node = node {
            stayOnBle = node.preferredParamTransport() == .ble
                || (node.isBleLocalControlServiceNode() && !node.isCloudParamTransportAvailable())
        } else {
            stayOnBle = false
        }

        if stayOnBle {
            // BLE-only devices have no cloud param path; keep discovery state and retry scan.
            User.shared.bleLocalControl.scanForDevices()
            completionHandler(.failure)
            return
        }

        User.shared.bleLocalControl.disconnectDevice(nodeId: nodeId)
        if let node = node {
            node.bleLocalNetwork = false
            node.bleLocalControlConnected = false
        }
        setDeviceParamPrivate(nodeID: nodeID, parameter: parameter, completionHandler: completionHandler)
    }

    private func overlayBleParamsSequentially(nodeIds: [String], updatedIds: [String], completion: @escaping ([String]) -> Void) {
        var remaining = nodeIds
        guard let nodeId = remaining.first else {
            completion(updatedIds)
            return
        }
        remaining.removeFirst()
        queryBleParamsConnectingIfNeeded(nodeId: nodeId) { [weak self] json in
            guard let self = self else {
                completion(updatedIds)
                return
            }
            var nextUpdated = updatedIds
            if let json = json, let node = User.shared.getNode(id: nodeId) {
                self.applyBleParamJson(json, to: node)
                if !ESPScheduler.shared.isEditorActive, !ESPSceneManager.shared.isEditorActive {
                    self.ingestBleSchedulesAndScenes(from: json, node: node)
                }
                node.bleLocalNetwork = true
                nextUpdated.append(nodeId)
                if ESPNetworkMonitor.shared.isConnectedToNetwork {
                    self.reportBleParamsToProxy(nodeId: nodeId)
                }
            }
            self.overlayBleParamsSequentially(nodeIds: remaining, updatedIds: nextUpdated, completion: completion)
        }
    }

    private func queryBleParamsConnectingIfNeeded(nodeId: String, completion: @escaping ([String: Any]?) -> Void) {
        let query = {
            User.shared.bleLocalControl.queryParams(nodeId: nodeId, completion: completion)
        }
        if User.shared.bleLocalControl.isConnected(nodeId: nodeId) {
            query()
        } else if User.shared.bleLocalControl.isDiscovered(nodeId: nodeId) {
            User.shared.bleLocalControl.connectDevice(nodeId: nodeId) { success in
                if success {
                    query()
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }

    /// Firmware get_params is either the param map or `{ node_payload: { data: { ... } } }`.
    private func bleParamsDictionary(from json: [String: Any]) -> [String: Any] {
        let payload: [String: Any]
        if let nested = json["node_payload"] as? [String: Any] {
            payload = nested
        } else if let payloadString = json["node_payload"] as? String,
                  let data = payloadString.data(using: .utf8),
                  let nested = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            payload = nested
        } else {
            payload = json
        }
        if let params = payload["data"] as? [String: Any] {
            return params
        }
        return payload
    }

    private func ingestBleSchedulesAndScenes(from json: [String: Any], node: Node) {
        let params = bleParamsDictionary(from: json)
        guard let nodeId = node.node_id else { return }
        if let schedule = params[node.scheduleName] as? [String: Any],
           let schedules = schedule[node.schedulesName] as? [[String: Any]] {
            ESPScheduler.shared.removeActions(forNodeId: nodeId)
            for scheduleJSON in schedules {
                ESPScheduler.shared.saveScheduleListFromJSON(nodeID: nodeId, scheduleJSON: scheduleJSON)
            }
        }
        if let scene = params[node.sceneName] as? [String: Any],
           let scenes = scene[node.scenesName] as? [[String: Any]] {
            ESPSceneManager.shared.removeActions(forNodeId: nodeId)
            for sceneJSON in scenes {
                ESPSceneManager.shared.saveScenesFromJSON(nodeID: nodeId, sceneJSON: sceneJSON)
            }
        }
    }

    private func applyBleParamJson(_ json: [String: Any], to node: Node) {
        let params = bleParamsDictionary(from: json)
        if let devices = node.devices {
            for device in devices {
                applyBleParams(json: params, to: device)
            }
        }
        for service in node.services ?? [] {
            guard let serviceName = service.name,
                  let serviceInfo = params[serviceName] as? [String: Any] else { continue }
            for param in service.params ?? [] {
                guard let paramName = param.name, let value = serviceInfo[paramName] else { continue }
                param.value = value
            }
        }
        node.syncServiceEntryCount(for: .scene)
        node.syncServiceEntryCount(for: .schedule)
    }

    private func applyBleParams(json: [String: Any], to device: Device) {
        let params = bleParamsDictionary(from: json)
        guard let deviceName = device.name,
              let attributes = params[deviceName] as? [String: Any],
              let deviceParams = device.params else { return }
        device.deviceName = deviceName
        for index in deviceParams.indices {
            guard let paramName = deviceParams[index].name,
                  let reportedValue = attributes[paramName] else { continue }
            if deviceParams[index].type == Constants.deviceNameParam {
                device.deviceName = reportedValue as? String ?? deviceName
            }
            deviceParams[index].value = reportedValue
        }
    }

    private func applySetParam(parameter: [String: Any], to device: Device) {
        guard let deviceName = device.name,
              let attributes = parameter[deviceName] as? [String: Any],
              let params = device.params else { return }
        for index in params.indices {
            guard let paramName = params[index].name,
                  let reportedValue = attributes[paramName] else { continue }
            if params[index].type == Constants.deviceNameParam {
                device.deviceName = reportedValue as? String ?? deviceName
            }
            params[index].value = reportedValue
        }
    }

    private func performReportBleParamsToProxy(nodeId: String) {
        guard ESPNetworkMonitor.shared.isConnectedToNetwork else { return }
        User.shared.bleLocalControl.getParamsWithTimestamp(nodeId: nodeId) { _, rawJSON in
            guard let rawJSON = rawJSON,
                  let body = ESPBleLocalCtrlProvisioningHelper.makeProxyBody(fromRawResponse: rawJSON) else {
                return
            }
            self.apiManager.reportProxyParams(nodeId: nodeId, body: body) { _ in }
        }
    }
}
