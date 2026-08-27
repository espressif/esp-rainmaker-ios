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
//  ESPBleDiscoveryService.swift
//  ESPRainMaker
//

import CoreBluetooth
import Foundation
import UIKit

/// Presence-only BLE scan. Does not connect and does not use ESPProvisionManager.
protocol ESPBleDiscoveryServiceDelegate: AnyObject {
    func bleDiscoveryDidFind(name: String)
    func bleDiscoveryWindowDidEnd(seenNames: Set<String>)
    func bleDiscoveryBluetoothStateChanged(poweredOn: Bool)
}

/// Repeating CBCentralManager scan windows for local-control reachability.
class ESPBleDiscoveryService: NSObject {

    let scanWindow: TimeInterval = 5.0
    let idleInterval: TimeInterval = 10.0

    weak var delegate: ESPBleDiscoveryServiceDelegate?

    private let devicePrefix: String
    private var centralManager: CBCentralManager!
    private var isEnabled = false
    private var isPaused = false
    private var isScanning = false
    private var isBackground = false
    private var isBluetoothPoweredOn = false
    private var seenThisWindow = Set<String>()
    private var windowWorkItem: DispatchWorkItem?
    private var idleWorkItem: DispatchWorkItem?

    init(devicePrefix: String) {
        self.devicePrefix = devicePrefix
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        cancelScheduledWork()
        if isScanning {
            centralManager.stopScan()
        }
    }

    /// Enable the scan loop and start a window immediately.
    func start() {
        isEnabled = true
        scanNow()
    }

    /// Disable the loop and stop scanning. Does not report an empty window.
    func stop() {
        isEnabled = false
        cancelScheduledWork()
        stopScanWithoutFinishingWindow()
    }

    /// Hold the radio so provisioning (or connect) can scan/connect. Does not report an empty window.
    func pause() {
        isPaused = true
        cancelScheduledWork()
        stopScanWithoutFinishingWindow()
    }

    /// Clear a pause. Restarts a window only if `start()` is still in effect.
    func resume() {
        isPaused = false
        if isEnabled {
            scanNow()
        }
    }

    /// Start or restart a scan window immediately (pull-to-refresh / returning to home).
    func scanNow() {
        guard canRun else { return }
        startWindow()
    }

    // MARK: - Private

    private var canRun: Bool {
        isEnabled && !isPaused && isBluetoothPoweredOn && !isBackground
    }

    private func startWindow() {
        cancelScheduledWork()
        seenThisWindow.removeAll()
        guard canRun else { return }
        isScanning = true
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        let item = DispatchWorkItem { [weak self] in
            self?.finishWindow()
        }
        windowWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + scanWindow, execute: item)
    }

    private func finishWindow() {
        guard isScanning else { return }
        centralManager.stopScan()
        isScanning = false
        let seen = seenThisWindow
        delegate?.bleDiscoveryWindowDidEnd(seenNames: seen)
        scheduleIdle()
    }

    private func scheduleIdle() {
        guard canRun else { return }
        let item = DispatchWorkItem { [weak self] in
            self?.startWindow()
        }
        idleWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + idleInterval, execute: item)
    }

    private func stopScanWithoutFinishingWindow() {
        if isScanning {
            centralManager.stopScan()
            isScanning = false
        }
        seenThisWindow.removeAll()
    }

    private func cancelScheduledWork() {
        windowWorkItem?.cancel()
        windowWorkItem = nil
        idleWorkItem?.cancel()
        idleWorkItem = nil
    }

    private func advertisedName(peripheral: CBPeripheral, advertisementData: [String: Any]) -> String? {
        if let localName = advertisementData["kCBAdvDataLocalName"] as? String, !localName.isEmpty {
            return localName
        }
        return peripheral.name
    }

    @objc private func appDidEnterBackground() {
        isBackground = true
        cancelScheduledWork()
        stopScanWithoutFinishingWindow()
    }

    @objc private func appWillEnterForeground() {
        isBackground = false
        if canRun {
            startWindow()
        }
    }
}

extension ESPBleDiscoveryService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothPoweredOn = true
            delegate?.bleDiscoveryBluetoothStateChanged(poweredOn: true)
            if canRun {
                startWindow()
            }
        case .poweredOff, .resetting, .unauthorized, .unsupported:
            isBluetoothPoweredOn = false
            cancelScheduledWork()
            stopScanWithoutFinishingWindow()
            delegate?.bleDiscoveryBluetoothStateChanged(poweredOn: false)
        default:
            break
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard isScanning else { return }
        guard let name = advertisedName(peripheral: peripheral, advertisementData: advertisementData) else { return }
        guard name.hasPrefix(devicePrefix) else { return }
        let isNewThisWindow = seenThisWindow.insert(name).inserted
        if isNewThisWindow {
            delegate?.bleDiscoveryDidFind(name: name)
        }
    }
}
