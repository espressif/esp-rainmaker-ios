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
//  ESPMatterEcosystemInfo.swift
//  ESPRainmaker
//

import Foundation

class ESPMatterEcosystemInfo {
    
    static let shared = ESPMatterEcosystemInfo()
    static let deviceId = "deviceId"
    static let deviceName = "deviceName"
    var homesData: [String: String] = [String: String]()
    var roomsDataForHome: [String: [[String: String]]] = [String: [[String: String]]]()
    static let certDeclarationKey: String = "certificate.declaration.key"
    static let attestationInfoKey: String = "attestation.information.key"
    
    static let borderAgentIdKey = "com.espressif.rainmaker.boder.agent.id"
    static let extendedAddressKey = "com.espressif.rainmaker.extended.address"
    static let controllerNotificationNodeIdKey = "com.espressif.rainmaker.controller.notification.node.id"

    /// Save homes data
    /// - Parameter data: homes
    func saveHomesData(data: [String: String]) {
        if let homesData = try? JSONSerialization.data(withJSONObject: data) {
            let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
            localStorage.saveDataInUserDefault(data: homesData, key: ESPMatterConstants.homesDataKey)
        }
    }
    
    /// Save rooms data
    /// - Parameter data: data
    func saveRoomsData(data: [String: [[String: String]]]) {
        if let roomsData = try? JSONSerialization.data(withJSONObject: data) {
            let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
            localStorage.saveDataInUserDefault(data: roomsData, key: ESPMatterConstants.roomsDataKey)
        }
    }
    
    /// Fetch homes data
    /// - Returns: homes
    func fetchHomesData() -> [String: String]? {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let data = localStorage.getDataFromSharedUserDefault(key: ESPMatterConstants.homesDataKey), let hData = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            return hData
        }
        return nil
    }
    
    /// Fetch rooms data
    /// - Returns: data
    func fetchRoomsData() -> [String: [[String: String]]]? {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let data = localStorage.getDataFromSharedUserDefault(key: ESPMatterConstants.roomsDataKey), let rData = try? JSONSerialization.jsonObject(with: data) as? [String: [[String: String]]] {
            return rData
        }
        return nil
    }
    
    /// Save mattter device data
    /// - Parameters:
    ///   - deviceId: device id
    ///   - deviceName: device name
    func saveMatterDeviceData(deviceId: UInt64, deviceName: String) {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        let data = [ESPMatterEcosystemInfo.deviceId: deviceId as Any,
                    ESPMatterEcosystemInfo.deviceName: deviceName as Any]
        if let devicesData = try? JSONSerialization.data(withJSONObject: data) {
            localStorage.saveDataInUserDefault(data: devicesData, key: ESPMatterConstants.matterDevicesKey)
        }
    }
    
    /// Get matter device data
    /// - Returns: matter device data
    func getMatterDeviceData() -> [String: Any]? {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let data = localStorage.getDataFromSharedUserDefault(key: ESPMatterConstants.matterDevicesKey), let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
            return dict
        }
        return nil
    }
    
    /// Save step
    /// - Parameter step: setp
    func saveStep(_ step: String) {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        var steps = [String]()
        if let data = localStorage.getDataFromSharedUserDefault(key: ESPMatterConstants.matterStepsKey), let stepsData = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String] {
            steps = stepsData
        }
        steps.append(step)
        if let data = try? JSONSerialization.data(withJSONObject: steps) {
            localStorage.saveDataInUserDefault(data: data, key: ESPMatterConstants.matterStepsKey)
        }
    }
    
    /// Get steps
    /// - Returns: get all steps
    func getSteps() -> [String]? {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let data = localStorage.getDataFromSharedUserDefault(key: ESPMatterConstants.matterStepsKey), let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String] {
            return dict
        }
        return nil
    }
    
    /// Save UUID
    /// - Parameter uuid: uuid
    func saveUUID(uuid: UUID) {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let data = uuid.uuidString.data(using: .utf8) {
            localStorage.saveDataInUserDefault(data: data, key: ESPMatterConstants.matterUUIDKey)
        }
    }
    
    /// Get uuids
    /// - Returns: uuids
    func getUUIDs() -> String? {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let data = localStorage.getDataFromSharedUserDefault(key: ESPMatterConstants.matterUUIDKey), let str = String(data: data, encoding: .utf8) {
            return str
        }
        return nil
    }
    
    /// Save onboarding payload
    /// - Parameter onboardingPayload: on boarding payload
    func saveOnboardingPayload(onboardingPayload: String) {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let data = onboardingPayload.data(using: .utf8) {
            localStorage.saveDataInUserDefault(data: data, key: ESPMatterConstants.onboardingPayloadKey)
        }
    }
    
    /// Get onboarding payload
    /// - Returns: payload
    func getOnboardingPayload() -> String? {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let data = localStorage.getDataFromSharedUserDefault(key: ESPMatterConstants.onboardingPayloadKey), let str = String(data: data, encoding: .utf8) {
            return str
        }
        return nil
    }
    
    /// Remove onboarding payload
    func removeOnboardingPayload() {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let _ = localStorage.getDataFromSharedUserDefault(key: ESPMatterConstants.onboardingPayloadKey) {
            localStorage.cleanupData(forKey: ESPMatterConstants.onboardingPayloadKey)
        }
    }
    
    /// Save device name
    /// - Parameter deviceName: device name
    func saveDeviceName(deviceName: String) {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let data = deviceName.data(using: .utf8) {
            localStorage.saveDataInUserDefault(data: data, key: ESPMatterConstants.matterDevicesName)
        }
    }
    
    /// Get device name
    /// - Returns: device name
    func getDeviceName() -> String? {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let data = localStorage.getDataFromSharedUserDefault(key: ESPMatterConstants.matterDevicesName), let str = String(data: data, encoding: .utf8) {
            return str
        }
        return nil
    }
    
    /// Remove device name
    func removeDeviceName() {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let _ = localStorage.getDataFromSharedUserDefault(key: ESPMatterConstants.matterDevicesName) {
            localStorage.cleanupData(forKey: ESPMatterConstants.matterDevicesName)
        }
    }
    
    /// Save certificate declaration
    /// - Parameter certDeclaration: cert declaration
    func saveCertDeclaration(certDeclaration: Data) {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        localStorage.saveDataInUserDefault(data: certDeclaration, key: ESPMatterEcosystemInfo.certDeclarationKey)
    }
    
    /// Get certificate declaration
    /// - Returns: cert declaration data
    func getCertDeclaration() -> Data? {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let data = localStorage.getDataFromSharedUserDefault(key: ESPMatterEcosystemInfo.certDeclarationKey) {
            localStorage.cleanupData(forKey: ESPMatterEcosystemInfo.certDeclarationKey)
            return data
        }
        return nil
    }
    
    /// Remove cert declaration
    func removeCertDeclaration() {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let _ = localStorage.getDataFromSharedUserDefault(key: ESPMatterEcosystemInfo.certDeclarationKey) {
            localStorage.cleanupData(forKey: ESPMatterEcosystemInfo.certDeclarationKey)
        }
    }
    
    /// Save attestation indo
    /// - Parameter attestationInfo: attestation info
    func saveAttestationInfo(attestationInfo: Data) {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        localStorage.saveDataInUserDefault(data: attestationInfo, key: ESPMatterEcosystemInfo.attestationInfoKey)
    }
    
    /// Get attestation info
    /// - Returns: attestation info
    func getAttestationInfo() -> Data? {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let data = localStorage.getDataFromSharedUserDefault(key: ESPMatterEcosystemInfo.attestationInfoKey) {
            localStorage.cleanupData(forKey: ESPMatterEcosystemInfo.attestationInfoKey)
            return data
        }
        return nil
    }
    
    /// Remove attestation info
    func removeAttestationInfo() {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let _ = localStorage.getDataFromSharedUserDefault(key: ESPMatterEcosystemInfo.attestationInfoKey) {
            localStorage.cleanupData(forKey: ESPMatterEcosystemInfo.attestationInfoKey)
        }
    }
    
    func saveBorderAgentIdKey(borderAgentId: Data) {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        
        // Convert new border agent ID to hex string
        let hexString = borderAgentId.hexadecimalString
        
        // Get existing border agent IDs
        var borderAgentIds: [String] = []
        if let existingData = localStorage.getDataFromSharedUserDefault(key: ESPMatterEcosystemInfo.borderAgentIdKey) {
            // Try to decode as array of strings first (new format)
            if let existingIds = try? JSONDecoder().decode([String].self, from: existingData) {
                borderAgentIds = existingIds
            } else {
                // Handle legacy format - single Data object
                borderAgentIds = [existingData.hexadecimalString]
            }
        }
        
        // Add new ID if not already present
        if !borderAgentIds.contains(hexString) {
            borderAgentIds.append(hexString)
        }
        
        // Save updated array
        if let encodedData = try? JSONEncoder().encode(borderAgentIds) {
            localStorage.saveDataInUserDefault(data: encodedData, key: ESPMatterEcosystemInfo.borderAgentIdKey)
        }
    }
    
    func getBorderAgentIdKey() -> [String]? {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let storedData = localStorage.getDataFromSharedUserDefault(key: ESPMatterEcosystemInfo.borderAgentIdKey) {
            // Try to decode as array of strings first (new format)
            if let borderAgentIds = try? JSONDecoder().decode([String].self, from: storedData) {
                return borderAgentIds
            } else {
                // Handle legacy format - single Data object
                return [storedData.hexadecimalString]
            }
        }
        return nil
    }
    
    func saveExtendedAddress(extendedAddress: Data) {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        
        // Convert new border agent ID to hex string
        let hexString = extendedAddress.hexadecimalString
        
        // Get existing border agent IDs
        var extendedAddresses: [String] = []
        if let existingData = localStorage.getDataFromSharedUserDefault(key: ESPMatterEcosystemInfo.extendedAddressKey) {
            // Try to decode as array of strings first (new format)
            if let existingIds = try? JSONDecoder().decode([String].self, from: existingData) {
                extendedAddresses = existingIds
            } else {
                // Handle legacy format - single Data object
                extendedAddresses = [existingData.hexadecimalString]
            }
        }
        
        // Add new ID if not already present
        if !extendedAddresses.contains(hexString) {
            extendedAddresses.append(hexString)
        }
        
        // Save updated array
        if let encodedData = try? JSONEncoder().encode(extendedAddresses) {
            localStorage.saveDataInUserDefault(data: encodedData, key: ESPMatterEcosystemInfo.extendedAddressKey)
        }
    }
    
    func getExtendedAddress() -> [String]? {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let storedData = localStorage.getDataFromSharedUserDefault(key: ESPMatterEcosystemInfo.extendedAddressKey) {
            // Try to decode as array of strings first (new format)
            if let extendedAddresses = try? JSONDecoder().decode([String].self, from: storedData) {
                return extendedAddresses
            } else {
                // Handle legacy format - single Data object
                return [storedData.hexadecimalString]
            }
        }
        return nil
    }
    
    func saveControllerNotificationNodeId(nodeId: String) {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let nodeData = nodeId.data(using: .utf8) {
            localStorage.saveDataInUserDefault(data: nodeData, key: ESPMatterEcosystemInfo.controllerNotificationNodeIdKey)
        }
    }
    
    func getControllerNotificationNodeId() -> String? {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let data = localStorage.getDataFromSharedUserDefault(key: ESPMatterEcosystemInfo.controllerNotificationNodeIdKey), let nodeId = String(data: data, encoding: .utf8) {
            return nodeId
        }
        return nil
    }
    
    func removeControllerNotificationNodeId() {
        let localStorage = ESPLocalStorage(ESPMatterConstants.groupIdKey)
        if let _ = localStorage.getDataFromSharedUserDefault(key: ESPMatterEcosystemInfo.controllerNotificationNodeIdKey) {
            localStorage.cleanupData(forKey: ESPMatterEcosystemInfo.controllerNotificationNodeIdKey)
        }
    }
}
