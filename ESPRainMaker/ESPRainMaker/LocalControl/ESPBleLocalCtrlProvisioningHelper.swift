// Copyright 2026 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, this
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  ESPBleLocalCtrlProvisioningHelper.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation
import UIKit

/// BLE-only onboarding: chunked `get_config` / `get_params`, cloud proxy sync, metadata update.
enum ESPBleLocalCtrlProvisioningHelper {

    static func runPostMappingFlow(
        device: ESPDevice,
        nodeId: String,
        deviceName: String,
        pop: String,
        progress: @escaping (String) -> Void,
        completion: @escaping (Bool, String?) -> Void
    ) {
        // Source of truth is the PoP that actually authenticated this session (set on the device
        // during provisioning, including QR flows where the caller-provided `pop` can be empty).
        // Persisting the wrong/empty PoP here breaks the fresh session after an app relaunch.
        let effectivePop: String
        if let devicePop = device.proofOfPossession, !devicePop.isEmpty {
            effectivePop = devicePop
        } else {
            effectivePop = pop
        }
        let api = NetworkManager.shared.apiManager
        progress("Fetching device configuration...")
        User.shared.bleLocalControl.sessionPop = effectivePop
        device.delegate = User.shared.bleLocalControl
        fetchSignedPayload(device: device, dataType: .typeConfig) { _, rawJSON in
            guard let rawJSON = rawJSON else {
                finishFlow(success: false, message: "Failed to read device configuration over BLE.", completion: completion)
                return
            }
            guard let body = makeProxyBody(fromRawResponse: rawJSON) else {
                finishFlow(success: false, message: "Invalid configuration response from device.", completion: completion)
                return
            }
            progress("Reporting configuration to cloud...")
            api.reportProxyConfig(nodeId: nodeId, body: body) { configOk in
                guard configOk else {
                    finishFlow(success: false, message: "Failed to report configuration to cloud.", completion: completion)
                    return
                }
                progress("Fetching device parameters...")
                fetchSignedPayload(device: device, dataType: .typeParams) { _, paramsRawJSON in
                    guard let paramsRawJSON = paramsRawJSON else {
                        finishFlow(success: false, message: "Failed to read device parameters over BLE.", completion: completion)
                        return
                    }
                    guard let initBody = makeProxyBody(fromRawResponse: paramsRawJSON) else {
                        finishFlow(success: false, message: "Invalid parameters response from device.", completion: completion)
                        return
                    }
                    progress("Reporting parameters to cloud...")
                    api.reportProxyInitParams(nodeId: nodeId, body: initBody) { paramsOk in
                        guard paramsOk else {
                            finishFlow(success: false, message: "Failed to report parameters to cloud.", completion: completion)
                            return
                        }
                        let wifiCapable = (device.versionInfo as NSDictionary?)?.hasNetworkProvisioningCapability() ?? false
                        let metadata: [String: Any] = [
                            Constants.bleLocalCtrlMetadataKey: [
                                Constants.name: deviceName,
                                Constants.bleLocalCtrlPopKey: effectivePop,
                                Constants.bleLocalCtrlWifiCapableKey: wifiCapable
                            ]
                        ]
                        progress("Updating node metadata...")
                        api.updateNodeMetadata(nodeId: nodeId, metadata: metadata) { metaOk in
                            if metaOk {
                                User.shared.bleLocalControl.registerProvisionedDevice(
                                    nodeId: nodeId,
                                    device: device,
                                    deviceName: deviceName,
                                    pop: effectivePop
                                )
                            }
                            finishFlow(
                                success: metaOk,
                                message: metaOk ? nil : "Failed to update node metadata.",
                                completion: completion
                            )
                        }
                    }
                }
            }
        }
    }

    private static func finishFlow(success: Bool, message: String?, completion: @escaping (Bool, String?) -> Void) {
        if !success {
            User.shared.bleLocalControl.sessionPop = nil
        }
        completion(success, message)
    }

    private static func fetchSignedPayload(
        device: ESPDevice,
        dataType: RmakerProvLocalCtrl_RMakerLocalCtrlDataType,
        completion: @escaping (_ parsed: [String: Any]?, _ rawJSON: String?) -> Void
    ) {
        let timestamp = Int64(Date().timeIntervalSince1970)
        User.shared.bleLocalControl.fetchRawData(device: device, dataType: dataType, timestamp: timestamp, completion: completion)
    }

    /// Build proxy API body using exact `node_payload` bytes from the device response.
    /// Re-serializing via JSONSerialization can reorder keys and break ECDSA verification.
    static func makeProxyBody(fromRawResponse rawJSON: String) -> [String: Any]? {
        guard let nodePayload = extractJSONObject(named: "node_payload", from: rawJSON),
              let signature = extractJSONString(named: "signature", from: rawJSON),
              !nodePayload.isEmpty, !signature.isEmpty else {
            return nil
        }
        return [
            "node_payload": nodePayload,
            "signature": signature
        ]
    }

    /// Index of the value's opening delimiter (`{` or `"`) after `"key":`.
    private static func advanceToValueStart(after key: String, in json: String, expecting delimiter: Character) -> String.Index? {
        guard let keyRange = json.range(of: "\"\(key)\"") else { return nil }
        var index = keyRange.upperBound
        while index < json.endIndex, json[index].isWhitespace {
            index = json.index(after: index)
        }
        guard index < json.endIndex, json[index] == ":" else { return nil }
        index = json.index(after: index)
        while index < json.endIndex, json[index].isWhitespace {
            index = json.index(after: index)
        }
        guard index < json.endIndex, json[index] == delimiter else { return nil }
        return index
    }

    private static func extractJSONObject(named key: String, from json: String) -> String? {
        guard var index = advanceToValueStart(after: key, in: json, expecting: "{") else { return nil }

        let start = index
        var depth = 0
        var inString = false
        var isEscaped = false
        while index < json.endIndex {
            let character = json[index]
            if inString {
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    inString = false
                }
            } else {
                if character == "\"" {
                    inString = true
                } else if character == "{" {
                    depth += 1
                } else if character == "}" {
                    depth -= 1
                    if depth == 0 {
                        let end = json.index(after: index)
                        return String(json[start..<end])
                    }
                }
            }
            index = json.index(after: index)
        }
        return nil
    }

    /// JSON string contents without decoding `\n` / `\t` / `\uXXXX`. Firmware signatures are Base64 and do not contain escapes.
    private static func extractJSONString(named key: String, from json: String) -> String? {
        guard let valueStart = advanceToValueStart(after: key, in: json, expecting: "\"") else { return nil }
        var index = json.index(after: valueStart)

        var value = ""
        var isEscaped = false
        while index < json.endIndex {
            let character = json[index]
            if isEscaped {
                value.append(character)
                isEscaped = false
            } else if character == "\\" {
                isEscaped = true
            } else if character == "\"" {
                return value
            } else {
                value.append(character)
            }
            index = json.index(after: index)
        }
        return nil
    }

    /// Shown just before the skip-Wi-Fi prompt. BLE-only firmware (no Wi-Fi/Thread
    /// prov caps) takes the same path as tapping Yes. Hybrid still gets the prompt.
    static func offerSkipWifiFlowIfSupported(
        from viewController: UIViewController,
        device: ESPDevice,
        pop: String,
        onContinueWifi: @escaping () -> Void
    ) -> Bool {
        guard let versionInfo = device.versionInfo as NSDictionary?,
              versionInfo.isBleLocalControlSupported() else {
            return false
        }
        if !versionInfo.hasNetworkProvisioningCapability() {
            navigateToBleLocalCtrlFlow(from: viewController, device: device, pop: pop)
            return true
        }
        let alert = UIAlertController(
            title: "Skip Wi-Fi Provisioning?",
            message: "This device can be controlled over BLE without Wi-Fi. Skip Wi-Fi provisioning?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "No", style: .cancel) { _ in
            onContinueWifi()
        })
        alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            navigateToBleLocalCtrlFlow(from: viewController, device: device, pop: pop)
        })
        viewController.present(alert, animated: true)
        return true
    }

    static func navigateToBleLocalCtrlFlow(from viewController: UIViewController, device: ESPDevice, pop: String) {
        let storyboard = viewController.storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        let successVC = storyboard.instantiateViewController(withIdentifier: "successViewController") as! SuccessViewController
        successVC.espDevice = device
        successVC.pop = pop
        successVC.isBleLocalCtrlFlow = true
        viewController.navigationController?.pushViewController(successVC, animated: true)
    }
}
