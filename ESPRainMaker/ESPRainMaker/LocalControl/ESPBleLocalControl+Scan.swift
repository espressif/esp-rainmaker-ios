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
//  ESPBleLocalControl+Scan.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation

extension ESPBleLocalControl {

    /// Refresh the node map and start/restart a discovery window. No GATT connect.
    func scanForDevices() {
        _ = discoveryService
        guard Configuration.shared.appConfiguration.supportLocalControl else { return }
        guard !discoveryPaused else { return }
        guard isBluetoothPoweredOn else { return }

        let bleDevices = collectBleDevicesFromNodes()
        syncConnectionMap(with: bleDevices)

        let pending = connectionMap.values.filter { $0.state == .disconnected || $0.state == .discovered }
        guard !pending.isEmpty else {
            discoveryService.stop()
            notifyUpdate()
            return
        }

        notifyUpdate()
        discoveryService.start()
    }

    /// Stop background BLE discovery so provisioning can use `ESPProvisionManager`.
    func pauseDiscovery() {
        discoveryPaused = true
        discoveryService.pause()
    }

    func resumeDiscovery() {
        discoveryPaused = false
        discoveryService.resume()
        scanForDevices()
    }

    /// Resume the discovery loop after a connect-time hold, unless provisioning still owns BLE.
    func resumeDiscoveryAfterConnectHold() {
        guard !discoveryPaused else { return }
        discoveryService.resume()
    }

    /// Clear stale discovery/connection state when Bluetooth radio is unavailable.
    private func handleBluetoothUnavailable() {
        currentConnectingNodeId = nil
        if let callback = connectCallback {
            connectCallback = nil
            callback(false)
        }
        resumeDiscoveryAfterConnectHold()

        for (nodeId, var conn) in connectionMap {
            failQueuedBleOps(nodeId: nodeId)
            conn.activeDevice?.disconnect()
            conn.activeDevice = nil
            conn.scannedDevice = nil
            conn.state = .disconnected
            connectionMap[nodeId] = conn
            clearBleStatusOnNode(nodeId: nodeId)
        }
        notifyUpdate()
    }

    private func handleBluetoothAvailable() {
        scanForDevices()
    }

    private func collectBleDevicesFromNodes() -> [String: BleLocalCtrlInfo] {
        var result: [String: BleLocalCtrlInfo] = [:]
        guard let nodes = User.shared.associatedNodeList else { return result }
        for node in nodes {
            guard let nodeId = node.node_id, let info = node.bleLocalCtrlInfo() else { continue }
            result[nodeId] = info
            if !info.pop.isEmpty {
                ESPBleLocalControl.savePop(nodeId: nodeId, pop: info.pop)
            }
        }
        return result
    }

    private func syncConnectionMap(with bleDevices: [String: BleLocalCtrlInfo]) {
        for (nodeId, bleInfo) in bleDevices {
            if let existing = connectionMap[nodeId] {
                switch existing.state {
                case .connecting, .connected:
                    continue
                case .disconnected, .discovered:
                    connectionMap[nodeId] = BleDeviceConnection(
                        scannedDevice: existing.scannedDevice,
                        activeDevice: existing.activeDevice,
                        bleInfo: bleInfo,
                        state: existing.state,
                        nodeId: nodeId
                    )
                }
            } else {
                connectionMap[nodeId] = BleDeviceConnection(
                    scannedDevice: nil,
                    activeDevice: nil,
                    bleInfo: bleInfo,
                    state: .disconnected,
                    nodeId: nodeId
                )
            }
        }
    }

    private func markDiscovered(name: String) {
        for (nodeId, var conn) in connectionMap where conn.state == .disconnected || conn.state == .discovered {
            guard name == conn.bleInfo.name else { continue }
            if conn.state == .disconnected {
                conn.state = .discovered
                connectionMap[nodeId] = conn
                setBleDiscoveredOnNode(nodeId: nodeId)
                notifyUpdate()
            }
            break
        }
    }

    private func demoteMissingDiscovered(seenNames: Set<String>) {
        var changed = false
        for (nodeId, var conn) in connectionMap where conn.state == .discovered && !seenNames.contains(conn.bleInfo.name) {
            conn.scannedDevice = nil
            conn.state = .disconnected
            connectionMap[nodeId] = conn
            clearBleStatusOnNode(nodeId: nodeId)
            changed = true
        }
        if changed {
            notifyUpdate()
        }
    }
}

extension ESPBleLocalControl: ESPBleDiscoveryServiceDelegate {
    func bleDiscoveryDidFind(name: String) {
        markDiscovered(name: name)
    }

    func bleDiscoveryWindowDidEnd(seenNames: Set<String>) {
        demoteMissingDiscovered(seenNames: seenNames)
    }

    func bleDiscoveryBluetoothStateChanged(poweredOn: Bool) {
        isBluetoothPoweredOn = poweredOn
        if poweredOn {
            handleBluetoothAvailable()
        } else {
            handleBluetoothUnavailable()
        }
    }
}
