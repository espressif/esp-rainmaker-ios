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
//  ESPBleLocalControl.swift
//  ESPRainMaker
//

import CoreBluetooth
import ESPProvision
import Foundation

/// Notifies when BLE local control discovery or connection state changes.
protocol ESPBleLocalControlDelegate: AnyObject {
    func bleLocalControlDidUpdate()
}

/// Manages BLE local control: discovery, on-demand connection, and param I/O.
/// Mirrors the role of `ESPLocalControl` for WLAN, using `ESPProvisionManager` for BLE transport.
class ESPBleLocalControl: NSObject {

    enum ConnectionState {
        case disconnected
        case discovered
        case connecting
        case connected
    }

    struct BleDeviceConnection {
        var scannedDevice: ESPDevice?
        var activeDevice: ESPDevice?
        let bleInfo: BleLocalCtrlInfo
        var state: ConnectionState
        let nodeId: String
    }

    let scanTimeout: TimeInterval = 10.0
    let scanRetryDelay: TimeInterval = 2.0
    let maxScanRetries = 3
    let operationTimeout: TimeInterval = 5.0
    let bleDevicePrefix = Constants.bleDevicePrefix

    weak var delegate: ESPBleLocalControlDelegate?

    /// Tracks phone Bluetooth radio state so we can rediscover after BT off/on.
    lazy var centralManager: CBCentralManager = {
        CBCentralManager(delegate: self, queue: .main)
    }()

    var scanRetryCount = 0
    var isBluetoothPoweredOn = false

    /// PoP used for session init outside the connection map (e.g. BLE-only onboarding).
    var sessionPop: String?

    var connectionMap: [String: BleDeviceConnection] = [:]
    var currentConnectingNodeId: String?
    var connectCallback: ((Bool) -> Void)?
    var isScanning = false
    var proxyReadInProgress: Set<String> = []
    var operationTimers: [String: Timer] = [:]
    var paramUpdateNodeIds = Set<String>()

    /// Sec2 GCM IV is incremented at encrypt time, before the BLE write is queued in
    /// ESPBleTransport. Overlapping set/get on one session desyncs that IV; firmware then
    /// fails `mbedtls_gcm_auth_decrypt` (-18) and kills the link. One in-flight param I/O
    /// per node; pending `set_params` with the same queue tail are coalesced to the latest.
    enum BleLocalCtrlOp {
        case setParams(parameter: [String: Any], completion: (ESPCloudResponseStatus) -> Void)
        case queryParams(completion: ([String: Any]?) -> Void)
        case getParamsWithTimestamp(completion: (_ parsed: [String: Any]?, _ rawJSON: String?) -> Void)
    }

    var bleOpQueue: [String: [BleLocalCtrlOp]] = [:]
    var bleOpRunning = Set<String>()
    var discoveryPaused = false

    // MARK: - Public API

    /// Persist PoP locally — cloud metadata often returns `pop: null` after relaunch.
    static func savePop(nodeId: String, pop: String) {
        guard !nodeId.isEmpty, !pop.isEmpty else { return }
        UserDefaults.standard.set(pop, forKey: Constants.bleLocalCtrlPopStorageKey(nodeId: nodeId))
    }

    static func storedPop(nodeId: String) -> String? {
        UserDefaults.standard.string(forKey: Constants.bleLocalCtrlPopStorageKey(nodeId: nodeId))
    }

    func isConnected(nodeId: String) -> Bool {
        connectionMap[nodeId]?.state == .connected
    }

    func isDiscovered(nodeId: String) -> Bool {
        connectionMap[nodeId]?.state == .discovered
    }

    func isAvailable(nodeId: String) -> Bool {
        isConnected(nodeId: nodeId) || isDiscovered(nodeId: nodeId)
    }

    func isParamUpdateInProgress(nodeId: String) -> Bool {
        paramUpdateNodeIds.contains(nodeId)
    }

    func deviceCapabilities(nodeId: String) -> [String]? {
        activeDevice(nodeId: nodeId)?.capabilities
    }

    func activeDevice(nodeId: String) -> ESPDevice? {
        guard connectionMap[nodeId]?.state == .connected else { return nil }
        return connectionMap[nodeId]?.activeDevice
    }

    /// Re-apply BLE reachability after cloud node list refresh replaces `Node` objects.
    func reapplyBleStatusToNodes() {
        guard let nodeList = User.shared.associatedNodeList else { return }
        for node in nodeList {
            guard let nodeId = node.node_id else { continue }
            guard let conn = connectionMap[nodeId] else { continue }
            switch conn.state {
            case .connected:
                node.bleLocalNetwork = true
                node.bleLocalControlConnected = true
            case .discovered:
                node.bleLocalNetwork = true
                node.bleLocalControlConnected = false
            default:
                break
            }
        }
    }

    func setBleDiscoveredOnNode(nodeId: String) {
        if let node = User.shared.getNode(id: nodeId) {
            node.bleLocalNetwork = true
            node.bleLocalControlConnected = false
        }
    }

    func setBleConnectedOnNode(nodeId: String) {
        if let node = User.shared.getNode(id: nodeId) {
            node.bleLocalNetwork = true
            node.bleLocalControlConnected = true
        }
    }

    func clearBleStatusOnNode(nodeId: String) {
        if let node = User.shared.getNode(id: nodeId) {
            node.bleLocalNetwork = false
            node.bleLocalControlConnected = false
        }
    }

    func notifyUpdate() {
        DispatchQueue.main.async {
            self.delegate?.bleLocalControlDidUpdate()
            NotificationCenter.default.post(name: Notification.Name(Constants.localNetworkUpdateNotification), object: nil)
        }
    }
}
