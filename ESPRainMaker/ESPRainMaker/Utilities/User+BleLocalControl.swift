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
//  User+BleLocalControl.swift
//  ESPRainMaker
//

import Foundation

extension User {

    /// WLAN HTTP local control needs the Local Control POP from cloud, not BLE metadata.
    /// Callers must already have a `localServices` entry for `nodeId`.
    func canUseWlanLocalControl(nodeId: String) -> Bool {
        guard let node = associatedNodeList?.first(where: { $0.node_id == nodeId }) else { return false }
        return node.supportsEncryption && !node.pop.isEmpty
    }

    /// Cloud node config after a BLE node joins Wi-Fi (new Local Control POP). Retry until POP is present.
    func refreshNodeAfterWifiJoin(nodeId: String) {
        refreshNodeAfterWifiJoin(nodeId: nodeId, attemptsLeft: 6)
    }

    /// Stop BLE local control scan and disconnect all BLE sessions.
    func stopBleLocalControl() {
        DispatchQueue.main.async {
            self.bleLocalControl.disconnectAll()
        }
    }

    fileprivate func refreshNodeAfterWifiJoin(nodeId: String, attemptsLeft: Int) {
        NetworkManager.shared.getNodeInfo(nodeId: nodeId) { [weak self] node, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let node = node, !node.pop.isEmpty {
                    self.replaceAssociatedNode(node)
                    NotificationCenter.default.post(Notification(name: Notification.Name(Constants.localNetworkUpdateNotification)))
                    return
                }
                if attemptsLeft <= 1 {
                    if let node = node {
                        self.replaceAssociatedNode(node)
                    }
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.refreshNodeAfterWifiJoin(nodeId: nodeId, attemptsLeft: attemptsLeft - 1)
                }
            }
        }
    }

    func replaceAssociatedNode(_ node: Node, localNetwork: Bool? = nil) {
        guard let index = associatedNodeList?.firstIndex(where: { $0.node_id == node.node_id }) else { return }
        let previous = associatedNodeList![index]
        node.localNetwork = localNetwork ?? previous.localNetwork
        node.bleLocalNetwork = previous.bleLocalNetwork
        node.bleLocalControlConnected = previous.bleLocalControlConnected
        if node.pop.isEmpty {
            node.pop = previous.pop
            node.supportsEncryption = previous.supportsEncryption
            if node.securityType == nil {
                node.securityType = previous.securityType
            }
            if node.localControlUsername.isEmpty {
                node.localControlUsername = previous.localControlUsername
            }
        }
        associatedNodeList![index] = node
        setEncryptionOnLocalControl(node: node)
    }
}

extension User: ESPBleLocalControlDelegate {
    func bleLocalControlDidUpdate() {
        bleLocalControl.reapplyBleStatusToNodes()
        NotificationCenter.default.post(Notification(name: Notification.Name(Constants.localNetworkUpdateNotification)))
    }
}
