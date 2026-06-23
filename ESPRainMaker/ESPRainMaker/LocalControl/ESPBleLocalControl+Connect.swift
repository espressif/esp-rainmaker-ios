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
//  ESPBleLocalControl+Connect.swift
//  ESPRainMaker
//

import CoreBluetooth
import ESPProvision
import Foundation

extension ESPBleLocalControl {

    func connectDevice(nodeId: String, completion: @escaping (Bool) -> Void) {
        guard var conn = connectionMap[nodeId], let scannedDevice = conn.scannedDevice else {
            completion(false)
            return
        }
        if conn.state == .connected {
            completion(true)
            return
        }
        if conn.state == .connecting {
            completion(false)
            return
        }
        if currentConnectingNodeId != nil {
            completion(false)
            return
        }

        let scannedName = scannedDevice.name ?? ""
        guard scannedName == conn.bleInfo.name else {
            completion(false)
            return
        }

        currentConnectingNodeId = nodeId
        connectCallback = completion
        conn.state = .connecting
        connectionMap[nodeId] = conn

        let device = scannedDevice
        device.security = .secure2
        device.username = Configuration.shared.appConfiguration.localControlSec2Username
        device.delegate = self
        device.bleDelegate = ESPBleDeviceDelegateProxy(owner: self, nodeId: nodeId)
        if !conn.bleInfo.pop.isEmpty {
            device.proofOfPossession = conn.bleInfo.pop
        }
        conn.activeDevice = device
        connectionMap[nodeId] = conn

        device.connectBleForLocalControl(delegate: self) { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .connected:
                if var updated = self.connectionMap[nodeId] {
                    updated.state = .connected
                    self.connectionMap[nodeId] = updated
                }
                self.setBleConnectedOnNode(nodeId: nodeId)
                self.finishConnect(nodeId: nodeId, success: true)
            default:
                if var updated = self.connectionMap[nodeId] {
                    updated.state = .discovered
                    updated.activeDevice = nil
                    self.connectionMap[nodeId] = updated
                }
                self.setBleDiscoveredOnNode(nodeId: nodeId)
                self.finishConnect(nodeId: nodeId, success: false)
            }
        }
    }

    func disconnectDevice(nodeId: String) {
        failQueuedBleOps(nodeId: nodeId)
        if let device = connectionMap[nodeId]?.activeDevice {
            device.disconnect()
        }
        if var conn = connectionMap[nodeId] {
            conn.state = .disconnected
            conn.activeDevice = nil
            connectionMap[nodeId] = conn
        }
        clearBleStatusOnNode(nodeId: nodeId)
        notifyUpdate()
    }

    func disconnectAll() {
        isScanning = false
        ESPProvisionManager.shared.stopESPDevicesSearch()
        currentConnectingNodeId = nil
        connectCallback = nil
        for (nodeId, conn) in connectionMap {
            failQueuedBleOps(nodeId: nodeId)
            conn.activeDevice?.disconnect()
            clearBleStatusOnNode(nodeId: nodeId)
        }
        connectionMap.removeAll()
        notifyUpdate()
    }

    /// Keep the active provisioning BLE session so home screen can control immediately.
    func registerProvisionedDevice(nodeId: String, device: ESPDevice, deviceName: String, pop: String) {
        ESPBleLocalControl.savePop(nodeId: nodeId, pop: pop)
        let bleInfo = BleLocalCtrlInfo(name: deviceName, pop: pop)
        connectionMap[nodeId] = BleDeviceConnection(
            scannedDevice: device,
            activeDevice: device,
            bleInfo: bleInfo,
            state: .connected,
            nodeId: nodeId
        )
        sessionPop = nil
        setBleConnectedOnNode(nodeId: nodeId)
        notifyUpdate()
    }

    private func finishConnect(nodeId: String, success: Bool) {
        let callback = connectCallback
        connectCallback = nil
        currentConnectingNodeId = nil
        callback?(success)
        notifyUpdate()
    }

    /// Called when the SDK reports the underlying peripheral disconnected (e.g. device powered off).
    /// Resets the node back to `.disconnected` so a future `scanForDevices()` can rediscover and
    /// reconnect it once it's back — without this, the stale `.connected` entry is skipped forever
    /// by `scanForDevices()`/`matchScannedDevices()`, requiring an app relaunch to recover.
    func handlePeripheralDisconnected(nodeId: String) {
        guard var conn = connectionMap[nodeId], conn.state != .disconnected else { return }
        failQueuedBleOps(nodeId: nodeId)
        conn.activeDevice = nil
        conn.scannedDevice = nil
        conn.state = .disconnected
        connectionMap[nodeId] = conn
        clearBleStatusOnNode(nodeId: nodeId)
        notifyUpdate()
    }
}

/// Per-connection `ESPBLEDelegate` so a shared `ESPBleLocalControl` can tell which node
/// disconnected without needing access to `ESPDevice`'s internal (non-public) `peripheral` property.
private final class ESPBleDeviceDelegateProxy: NSObject, ESPBLEDelegate {
    private weak var owner: ESPBleLocalControl?
    private let nodeId: String

    init(owner: ESPBleLocalControl, nodeId: String) {
        self.owner = owner
        self.nodeId = nodeId
    }

    func peripheralConnected() {}

    func peripheralDisconnected(peripheral: CBPeripheral, error: Error?) {
        owner?.handlePeripheralDisconnected(nodeId: nodeId)
    }

    func peripheralFailedToConnect(peripheral: CBPeripheral?, error: Error?) {}
}

extension ESPBleLocalControl: ESPDeviceConnectionDelegate {
    func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
        if let nodeId = currentConnectingNodeId {
            let mapPop = connectionMap[nodeId]?.bleInfo.pop ?? ""
            if !mapPop.isEmpty {
                completionHandler(mapPop)
                return
            }
            if let stored = ESPBleLocalControl.storedPop(nodeId: nodeId), !stored.isEmpty {
                completionHandler(stored)
                return
            }
        }
        if let sessionPop = sessionPop, !sessionPop.isEmpty {
            completionHandler(sessionPop)
        } else {
            completionHandler("")
        }
    }

    func getUsername(forDevice: ESPDevice, completionHandler: @escaping (String?) -> Void) {
        if let caps = forDevice.capabilities,
           caps.contains(ESPScanConstants.threadProv) || caps.contains(ESPScanConstants.threadScan) {
            completionHandler(Configuration.shared.espProvSetting.threadSec2Username)
        } else {
            completionHandler(Configuration.shared.espProvSetting.wifiSec2Username)
        }
    }
}
