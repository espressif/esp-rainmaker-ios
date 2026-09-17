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
//  APIClient.swift
//  ESPRainMaker
//

import Alamofire
import Foundation
import JWTDecode

class NetworkManager {
    /// A singleton class that manages Network call for this application
    static let shared = NetworkManager()
    var session: Session!
    var apiManager = ESPAPIManager()
    private var bleProxyReportWorkItems: [String: DispatchWorkItem] = [:]
    private let bleProxyReportDelay: TimeInterval = 0.5
    
    private init() {
        // Listen for configuration updates and reinitialize API manager
        NotificationCenter.default.addObserver(self, selector: #selector(configurationUpdated), name: NSNotification.Name(Constants.configurationUpdateNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func configurationUpdated() {
        // Reinitialize the API manager to pick up new server trust configuration
        apiManager = ESPAPIManager()
    }

    // MARK: - Node APIs

    /// Method to fetch node and devices associated with the user
    ///
    /// - Parameters:
    ///   - completionHandler: after response is parsed this block will be called with node array and error(if any) as argument
    func getNodes(completionHandler: @escaping ([Node]?, ESPNetworkError?) -> Void) {
        apiManager.getNodes(completionHandler: completionHandler)
    }

    /// Get node info like device list, param list and online/offline status
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get node info is received
    func getNodeInfo(nodeId: String, completionHandler: @escaping (Node?, ESPNetworkError?) -> Void) {
        if Configuration.shared.appConfiguration.supportLocalControl, let availableService = User.shared.localServices[nodeId] {
            availableService.getPropertyInfo { response, error in
                if error != nil {
                    if ESPNetworkMonitor.shared.isConnectedToNetwork {
                        self.getNodeInfoPrivate(nodeId: nodeId, completionHandler: completionHandler)
                    } else {
                        completionHandler(nil, .localServerError(error!))
                    }
                    return
                }
                var responseJSON = response!
                if nodeId.count > 0 {
                    responseJSON["id"] = nodeId
                }
                if let node = JSONParser.parseNodeArray(data: [responseJSON], forSingleNode: true)?[0] {
                    node.node_id = nodeId
                    if node.devices?.count ?? 0 < 1 {
                        completionHandler(nil, .unknownError)
                    } else {
                        completionHandler(node, nil)
                    }
                    return
                }
                completionHandler(nil, .emptyConfigData)
            }
        } else if User.shared.bleLocalControl.isConnected(nodeId: nodeId) {
            self.refreshNodeParamsFromBle(nodeId: nodeId, completionHandler: completionHandler)
        } else {
            getNodeInfoPrivate(nodeId: nodeId, completionHandler: completionHandler)
        }
    }

    private func getNodeInfoPrivate(nodeId: String, completionHandler: @escaping (Node?, ESPNetworkError?) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            apiManager.getNodeInfo(nodeId: nodeId, completionHandler: completionHandler)
        } else {
            completionHandler(nil, .noNetwork)
        }
    }

    /// Method to fetch online/offline status of associated nodes
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get node status is received
    func getNodeStatus(node: Node, completionHandler: @escaping (Node?, Error?) -> Void) {
        apiManager.getNodeStatus(node: node, completionHandler: completionHandler)
    }

    // MARK: - Device Association

    /// Method to send request of adding device to currently active user
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to add device to user is received with id of the request
    func addDeviceToUser(parameter: [String: String], completionHandler: @escaping (String?, ESPNetworkError?) -> Void) {
        apiManager.addDeviceToUser(parameter: parameter, completionHandler: completionHandler)
    }

    /// Subscribe a controller node to the selected group.
    func addControllerToGroup(nodeId: String, groupId: String, completionHandler: @escaping (Bool, ESPNetworkError?) -> Void) {
        apiManager.addControllerToGroup(nodeId: nodeId, groupId: groupId, completionHandler: completionHandler)
    }

    /// Method to fetch device association status
    ///
    /// - Parameters:
    ///   - nodeID: Id of the node for which association status is fetched
    ///   - completionHandler: handler called when response to deviceAssociationStatus is received
    func deviceAssociationStatus(nodeID: String, requestID: String, completionHandler: @escaping (String) -> Void) {
        apiManager.deviceAssociationStatus(nodeID: nodeID, requestID: requestID, completionHandler: completionHandler)
    }

    // MARK: - Thing Shadow

    /// Method to get device parameter values
    ///
    /// - Parameters:
    ///   - device: Device for which get param is required
    ///   - completionHandler: handler called when response to getDeviceParam is received
    func getDeviceParam(device: Device, completionHandler: @escaping (ESPNetworkError?) -> Void) {
        NotificationCenter.default.post(Notification(name: Notification.Name(Constants.paramUpdateNotification)))
        if Configuration.shared.appConfiguration.supportLocalControl {
            if let nodeid = device.node?.node_id {
                if let availableService = User.shared.localServices[nodeid] {
                    availableService.getPropertyInfo { response, error in
                        if error != nil {
                            if ESPNetworkMonitor.shared.isConnectedToNetwork {
                                self.getDeviceParamPrivate(device: device, completionHandler: completionHandler)
                            } else {
                                completionHandler(.localServerError(error!))
                            }
                            return
                        }
                        if let params = response!["params"] as? [String:Any], let deviceName = device.name, let attributes = params[deviceName] as? [String: Any] {
                            device.deviceName = deviceName
                            if let params = device.params {
                                for index in params.indices {
                                    if let reportedValue = attributes[params[index].name ?? ""] {
                                        if params[index].type == Constants.deviceNameParam {
                                            device.deviceName = reportedValue as? String ?? deviceName
                                        }
                                        params[index].value = reportedValue
                                    }
                                }
                            }
                            completionHandler(nil)
                        } else {
                            completionHandler(nil)
                        }
                    }
                } else if User.shared.bleLocalControl.isAvailable(nodeId: nodeid) {
                    refreshDeviceParamsFromBle(nodeId: nodeid, device: device, completionHandler: completionHandler)
                } else {
                    getDeviceParamPrivate(device: device, completionHandler: completionHandler)
                }
            }
        } else {
            getDeviceParamPrivate(device: device, completionHandler: completionHandler)
        }
    }

    private func getDeviceParamPrivate(device: Device, completionHandler: @escaping (ESPNetworkError?) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            apiManager.getDeviceParams(device: device, completionHandler: completionHandler)
        } else {
            completionHandler(.noNetwork)
        }
    }

    /// Method to update device thing shadow
    /// Any changes of the device params from the app trigger this method
    ///
    /// - Parameters:
    ///   - nodeID: Id of the node for which thing shadow is updated
    ///   - completionHandler: handler called when response to setDeviceParam is received
    func setDeviceParam(nodeID: String?, parameter: [String: Any], completionHandler: @escaping (ESPCloudResponseStatus) -> Void) {
        NotificationCenter.default.post(Notification(name: Notification.Name(Constants.paramUpdateNotification)))
        if Configuration.shared.appConfiguration.supportLocalControl {
            if let nodeid = nodeID {
                if let availableService = User.shared.localServices[nodeid] {
                    availableService.setProperty(json: parameter) { success, _ in
                        if !success {
                            self.setDeviceParamPrivate(nodeID: nodeID, parameter: parameter, completionHandler: completionHandler)
                        } else {
                            completionHandler(.success)
                        }
                    }
                } else if User.shared.bleLocalControl.isAvailable(nodeId: nodeid) {
                    User.shared.bleLocalControl.connectAndSetParams(nodeId: nodeid, parameter: parameter) { status in
                        switch status {
                        case .success:
                            self.applySetParamToLocalNodes(nodeId: nodeid, parameter: parameter)
                            completionHandler(.success)
                            self.reportBleParamsToProxy(nodeId: nodeid)
                        default:
                            self.clearBleAndFallbackToCloud(nodeId: nodeid, nodeID: nodeID, parameter: parameter, completionHandler: completionHandler)
                        }
                    }
                } else {
                    setDeviceParamPrivate(nodeID: nodeID, parameter: parameter, completionHandler: completionHandler)
                }
            }
        } else {
            setDeviceParamPrivate(nodeID: nodeID, parameter: parameter, completionHandler: completionHandler)
        }
    }

    // MARK: - BLE local control helpers

    /// Cloud getNodes when online, then overlay BLE-only firmware scene/schedule params.
    func refreshAssociatedNodesThenOverlayBleFirmware(completion: @escaping () -> Void) {
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
                for nodeId in updatedIds {
                    ESPSceneManager.shared.removeActions(forNodeId: nodeId)
                    ESPScheduler.shared.removeActions(forNodeId: nodeId)
                }
                if let nodeList = User.shared.associatedNodeList {
                    ESPSceneManager.shared.getAvailableDeviceWithSceneCapability(nodeList: nodeList)
                    ESPScheduler.shared.getAvailableDeviceWithScheduleCapability(nodeList: nodeList)
                }
            }
            completion()
        }
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

    private func refreshNodeParamsFromBle(nodeId: String, completionHandler: @escaping (Node?, ESPNetworkError?) -> Void) {
        guard let cachedNode = User.shared.getNode(id: nodeId) else {
            getNodeInfoPrivate(nodeId: nodeId, completionHandler: completionHandler)
            return
        }
        User.shared.bleLocalControl.queryParams(nodeId: nodeId) { json in
            if let json = json {
                self.applyBleParamJson(json, to: cachedNode)
                cachedNode.bleLocalNetwork = true
                completionHandler(cachedNode, nil)
            } else if ESPNetworkMonitor.shared.isConnectedToNetwork {
                self.getNodeInfoPrivate(nodeId: nodeId, completionHandler: completionHandler)
            } else {
                completionHandler(nil, .noNetwork)
            }
        }
    }

    private func applyBleParamJson(_ json: [String: Any], to node: Node) {
        if let devices = node.devices {
            for device in devices {
                applyBleParams(json: json, to: device)
            }
        }
        for service in node.services ?? [] {
            guard let serviceName = service.name,
                  let serviceInfo = json[serviceName] as? [String: Any] else { continue }
            for param in service.params ?? [] {
                guard let paramName = param.name, let value = serviceInfo[paramName] else { continue }
                param.value = value
            }
        }
        node.syncServiceEntryCount(for: .scene)
        node.syncServiceEntryCount(for: .schedule)
    }

    private func applyBleParams(json: [String: Any], to device: Device) {
        guard let deviceName = device.name,
              let attributes = json[deviceName] as? [String: Any],
              let params = device.params else { return }
        device.deviceName = deviceName
        for index in params.indices {
            guard let paramName = params[index].name,
                  let reportedValue = attributes[paramName] else { continue }
            if params[index].type == Constants.deviceNameParam {
                device.deviceName = reportedValue as? String ?? deviceName
            }
            params[index].value = reportedValue
        }
    }

    private func applySetParamToLocalNodes(nodeId: String, parameter: [String: Any]) {
        guard let node = User.shared.getNode(id: nodeId), let devices = node.devices else { return }
        for device in devices {
            applySetParam(parameter: parameter, to: device)
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

    private func refreshDeviceParamsFromBle(
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

    private func reportBleParamsToProxy(nodeId: String) {
        bleProxyReportWorkItems[nodeId]?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.bleProxyReportWorkItems[nodeId] = nil
            self.performReportBleParamsToProxy(nodeId: nodeId)
        }
        bleProxyReportWorkItems[nodeId] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + bleProxyReportDelay, execute: work)
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

    private func clearBleAndFallbackToCloud(
        nodeId: String,
        nodeID: String?,
        parameter: [String: Any],
        completionHandler: @escaping (ESPCloudResponseStatus) -> Void
    ) {
        let node = User.shared.getNode(id: nodeId)
        let isBleOnlyNode = node?.isBleLocalControlServiceNode() == true && !(node?.isConnected ?? false)

        if isBleOnlyNode {
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

    private func setDeviceParamPrivate(nodeID: String?, parameter: [String: Any], completionHandler: @escaping (ESPCloudResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            apiManager.setDeviceParam(nodeID: nodeID, parameter: parameter, completionHandler: completionHandler)
        } else {
            completionHandler(.failure)
        }
    }

    // MARK: - Generic Request

    /// Method to make generic api request
    ///
    /// - Parameters:
    ///   - url: URL of the api
    ///   - method: HTTPMethod like post, get, etc.
    ///   - parameters: Parameter to be included in the api call
    ///   - encoding: ParameterEncoding
    ///   - header: HTTp headers
    ///   - completionHandler: Callback invoked after api response is received
    func genericRequest(url: URLConvertible, method: HTTPMethod, parameters: Parameters, encoding: ParameterEncoding, headers: HTTPHeaders, completionHandler: @escaping ([String: Any]?) -> Void) {
        apiManager.genericRequest(url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, completionHandler: completionHandler)
    }

    /// Method to make generic authorized request
    ///
    /// - Parameters:
    ///   - url: URL of the api
    ///   - parameters: Parameter to be included in the api call
    ///   - completionHandler: Callback invoked after api response is received
    func genericAuthorizedDataRequest(url: String, parameter: [String: Any]?, completionHandler: @escaping (Data?, ESPNetworkError?) -> Void) {
        apiManager.genericAuthorizedDataRequest(url: url, parameter: parameter, completionHandler: completionHandler)
    }
}
