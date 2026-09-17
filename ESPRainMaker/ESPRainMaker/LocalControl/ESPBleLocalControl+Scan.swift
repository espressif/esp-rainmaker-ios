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

import CoreBluetooth
import ESPProvision
import Foundation

extension ESPBleLocalControl {

    /// Broad BLE scan; match devices to nodes with `ble_local_ctrl` metadata. No GATT connect.
    func scanForDevices() {
        _ = centralManager.state
        guard !discoveryPaused else { return }
        guard !isScanning else { return }
        guard isBluetoothPoweredOn else { return }

        let bleDevices = collectBleDevicesFromNodes()
        guard !bleDevices.isEmpty else { return }

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

        // Also re-scan already-`.discovered` nodes (advertisement seen, never GATT-connected):
        // without this, once a node is marked `.discovered` it's skipped forever above, so if it
        // powers off before ever being connected, it stays "Reachable on BLE" until app relaunch.
        let pending = connectionMap.values.filter { ($0.state == .disconnected && $0.scannedDevice == nil) || $0.state == .discovered }
        guard !pending.isEmpty else {
            notifyUpdate()
            return
        }

        // Reapply already-known reachability now (e.g. onto Node objects just reloaded from disk),
        // instead of waiting ~10s for the background scan below — that scan only needs to revalidate
        // whether a `.discovered` node is still around, not gate the currently-known status.
        notifyUpdate()

        scanRetryCount = 0
        startBroadScan()
    }

    /// Stop background BLE discovery so provisioning can use `ESPProvisionManager` without a
    /// leftover scan completing as `espDeviceNotFound` on the QR screen.
    func pauseDiscovery() {
        discoveryPaused = true
        stopBroadScan()
    }

    func resumeDiscovery() {
        guard discoveryPaused else { return }
        discoveryPaused = false
        scanForDevices()
    }

    private func startBroadScan() {
        guard !discoveryPaused else { return }
        guard isBluetoothPoweredOn else {
            finishScanPhase()
            return
        }

        isScanning = true

        ESPProvisionManager.shared.searchESPDevices(devicePrefix: bleDevicePrefix, transport: .ble, security: .secure) { [weak self] devices, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isScanning = false
                if self.discoveryPaused {
                    return
                }
                if let devices = devices {
                    self.matchScannedDevices(devices)
                    self.finishScanPhase()
                } else if error != nil {
                    self.retryBroadScanIfNeeded()
                } else {
                    self.finishScanPhase()
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + scanTimeout) { [weak self] in
            guard let self = self, self.isScanning, !self.discoveryPaused else { return }
            self.isScanning = false
            ESPProvisionManager.shared.stopESPDevicesSearch()
            self.finishScanPhase()
        }
    }

    private func retryBroadScanIfNeeded() {
        guard !discoveryPaused else { return }
        scanRetryCount += 1
        if scanRetryCount < maxScanRetries {
            DispatchQueue.main.asyncAfter(deadline: .now() + scanRetryDelay) { [weak self] in
                self?.startBroadScan()
            }
        } else {
            finishScanPhase()
        }
    }

    private func finishScanPhase() {
        markDiscoveredDevices()
        notifyUpdate()
    }

    private func stopBroadScan() {
        guard isScanning else { return }
        isScanning = false
        ESPProvisionManager.shared.stopESPDevicesSearch()
    }

    /// Clear stale discovery/connection state when Bluetooth radio is unavailable.
    private func handleBluetoothUnavailable() {
        stopBroadScan()
        currentConnectingNodeId = nil
        if let callback = connectCallback {
            connectCallback = nil
            callback(false)
        }

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

    private func matchScannedDevices(_ devices: [ESPDevice]) {
        var seenNames = Set<String>()
        for device in devices {
            let scannedName = device.name
            guard scannedName.hasPrefix(bleDevicePrefix) else { continue }
            seenNames.insert(scannedName)
            for (nodeId, var conn) in connectionMap where conn.state == .disconnected || conn.state == .discovered {
                if scannedName == conn.bleInfo.name {
                    conn.scannedDevice = device
                    connectionMap[nodeId] = conn
                    break
                }
            }
        }
        // A previously `.discovered` node that didn't show up in this scan is no longer around —
        // demote it so its BLE-reachable status clears instead of staying stuck indefinitely.
        for (nodeId, var conn) in connectionMap where conn.state == .discovered && !seenNames.contains(conn.bleInfo.name) {
            conn.scannedDevice = nil
            conn.state = .disconnected
            connectionMap[nodeId] = conn
            clearBleStatusOnNode(nodeId: nodeId)
        }
    }

    private func markDiscoveredDevices() {
        for (nodeId, var conn) in connectionMap where conn.state == .disconnected && conn.scannedDevice != nil {
            conn.state = .discovered
            connectionMap[nodeId] = conn
            setBleDiscoveredOnNode(nodeId: nodeId)
        }
    }
}

extension ESPBleLocalControl: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothPoweredOn = true
            handleBluetoothAvailable()
        case .poweredOff, .resetting:
            isBluetoothPoweredOn = false
            handleBluetoothUnavailable()
        case .unauthorized, .unsupported:
            isBluetoothPoweredOn = false
            handleBluetoothUnavailable()
        default:
            break
        }
    }
}
