// Copyright 2023 Espressif Systems
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
//  RequestHandler.swift
//  MatterExtension
//

import MatterSupport

/// Class is used to handle MatterSupport callbacks
@available(iOS 16.4, *)
class RequestHandler: MatterAddDeviceExtensionRequestHandler {
    
    
    /// Use this function to perform additional attestation checks if that is useful for your ecosystem.
    /// - Parameter deviceCredential: cert declaration, attestation data, product Attestation Intermediate Certificate
    override func validateDeviceCredential(_ deviceCredential: MatterAddDeviceExtensionRequestHandler.DeviceCredential) async throws {
        DispatchQueue.main.async {
            ESPMatterExtensionEcoInfo.shared.saveCertDeclaration(certDeclaration: deviceCredential.certificationDeclaration)
            ESPMatterExtensionEcoInfo.shared.saveAttestationInfo(attestationInfo: deviceCredential.deviceAttestationCertificate)
        }
    }
    
    /// // Use this function to select a Wi-Fi network for the device if your ecosystem has special requirements.
    /// Or, return `.defaultSystemNetwork` to use the iOS device's current network.
    /// - Parameter wifiScanResults: wifi scan results
    /// - Returns: scan resilt
    override func selectWiFiNetwork(from wifiScanResults: [MatterAddDeviceExtensionRequestHandler.WiFiScanResult]) async throws -> MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation {
        return .defaultSystemNetwork
    }
    
    /// Use this function to select a Thread network for the device if your ecosystem has special requirements.
    /// Or, return `.defaultSystemNetwork` to use the default Thread network.
    /// - Parameter threadScanResults: thread scan results
    /// - Returns: default system network
    override func selectThreadNetwork(from threadScanResults: [MatterAddDeviceExtensionRequestHandler.ThreadScanResult]) async throws -> MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation {
        return .defaultSystemNetwork
    }
    
    /// Commission device callback
    /// - Parameters:
    ///   - home: home
    ///   - onboardingPayload: onboarding payload
    ///   - commissioningID: commissioning id
    override func commissionDevice(in home: MatterAddDeviceRequest.Home?, onboardingPayload: String, commissioningID: UUID) async throws {
        // Use this function to commission the device with your Matter stack.
        DispatchQueue.main.async {
            ESPMatterExtensionEcoInfo.shared.saveOnboardingPayload(onboardingPayload: onboardingPayload)
        }
    }

    override func rooms(in home: MatterAddDeviceRequest.Home?) async -> [MatterAddDeviceRequest.Room] {
        // Use this function to return the rooms your ecosystem manages.
        // If your ecosystem manages multiple homes, ensure you are returning rooms that belong to the provided home.
        return [.init(displayName: "Living Room")]
    }

    override func configureDevice(named name: String, in room: MatterAddDeviceRequest.Room?) async {
        // Use this function to configure the (now) commissioned device with the given name and room.
        DispatchQueue.main.async {
            ESPMatterExtensionEcoInfo.shared.saveDeviceName(deviceName: name)
        }
    }
}
