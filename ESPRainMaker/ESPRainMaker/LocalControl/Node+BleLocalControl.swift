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
//  Node+BleLocalControl.swift
//  ESPRainMaker
//

import Foundation

/// BLE local control metadata stored on the cloud node after BLE-only onboarding.
struct BleLocalCtrlInfo {
    let name: String
    let pop: String
}

extension Node {

    /// Parse `metadata.ble_local_ctrl` for post-provision BLE control.
    /// Use `isBleLocalControlServiceNode()` when only presence is needed.
    func bleLocalCtrlInfo() -> BleLocalCtrlInfo? {
        guard let bleLocalCtrl = metadata?[Constants.bleLocalCtrlMetadataKey] as? [String: Any] else {
            return nil
        }
        let name = bleLocalCtrl[Constants.name] as? String ?? ""
        guard !name.isEmpty else { return nil }
        let metadataPop = bleLocalCtrl[Constants.bleLocalCtrlPopKey] as? String ?? ""
        let pop: String
        if metadataPop.isEmpty, let nodeId = node_id, let stored = ESPBleLocalControl.storedPop(nodeId: nodeId) {
            pop = stored
        } else {
            pop = metadataPop
        }
        return BleLocalCtrlInfo(name: name, pop: pop)
    }

    /// Cloud-connected, on WLAN, or reachable over BLE (discovered or connected).
    func isParamReachable() -> Bool {
        isConnected || localNetwork || bleLocalNetwork
    }

    /// BLE-only node excluded from multi-device schedule/scene flows.
    /// List ingest still runs for these nodes via `BleDeviceServiceFlow`.
    /// Uses persistent `ble_local_ctrl` metadata (not momentary connection state) so a
    /// BLE-only node stays excluded even while merely discovered or disconnected.
    func isBleOnlyExcludedFromMultiDeviceServices() -> Bool {
        !isConnected && isBleLocalControlServiceNode()
    }
}

/// Schedule vs scene service list on a node (shared BLE local-control handling).
enum BleDeviceServiceKind {
    case schedule
    case scene

    var serviceType: String {
        switch self {
        case .schedule: return Constants.scheduleServiceType
        case .scene: return Constants.sceneServiceType
        }
    }

    var paramType: String {
        switch self {
        case .schedule: return Constants.scheduleParamType
        case .scene: return Constants.sceneParamType
        }
    }

    fileprivate func applyEntryCount(_ count: Int, to node: Node) {
        switch self {
        case .schedule: node.currentSchedulesCount = count
        case .scene: node.currentScenesCount = count
        }
    }
}

extension Node {

    /// Node supports BLE local control (metadata present). Used to scope single-device editors.
    func isBleLocalControlServiceNode() -> Bool {
        guard let bleLocalCtrl = metadata?[Constants.bleLocalCtrlMetadataKey] as? [String: Any] else {
            return false
        }
        let name = bleLocalCtrl[Constants.name] as? String ?? ""
        return !name.isEmpty
    }

    private func serviceListParam(for kind: BleDeviceServiceKind) -> Param? {
        guard let service = services?.first(where: { $0.type == kind.serviceType }),
              let param = service.params?.first(where: { $0.type == kind.paramType }) else {
            return nil
        }
        return param
    }

    func serviceEntries(for kind: BleDeviceServiceKind) -> [[String: Any]]? {
        serviceListParam(for: kind)?.value as? [[String: Any]]
    }

    func syncServiceEntryCount(for kind: BleDeviceServiceKind) {
        guard let entries = serviceEntries(for: kind) else {
            kind.applyEntryCount(0, to: self)
            return
        }
        kind.applyEntryCount(entries.count, to: self)
    }

    @discardableResult
    func removeServiceEntry(id: String, kind: BleDeviceServiceKind) -> Bool {
        guard let param = serviceListParam(for: kind),
              let entries = param.value as? [[String: Any]] else {
            return false
        }
        let filtered = entries.filter { ($0["id"] as? String) != id }
        guard filtered.count != entries.count else { return false }
        param.value = filtered
        kind.applyEntryCount(filtered.count, to: self)
        return true
    }
}

extension NSDictionary {

    /// Device supports BLE-only local control onboarding (skip Wi-Fi).
    func isBleLocalControlSupported() -> Bool {
        guard let rmakerExtra = self[ESPScanConstants.rmakerExtra] as? NSDictionary,
              let caps = rmakerExtra[ESPScanConstants.capabilities] as? [String],
              caps.contains(ESPScanConstants.localCtrl) else {
            return false
        }
        return isChallengeResponseSupported()
    }
}
