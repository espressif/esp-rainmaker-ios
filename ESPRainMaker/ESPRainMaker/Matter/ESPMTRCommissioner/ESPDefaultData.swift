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
//  ESPDefaultData.swift
//  ESPRainmaker
//

import Foundation

/// Default data
class ESPDefaultData {
    
    private init() {}
    static let shared = ESPDefaultData()
    let vendorIdQueue = DispatchQueue(label: "com.espressif.vendorid.queue", attributes: .concurrent)
    
    /// Thread hard-coded values
    static let threadSaltData = "Y8T4twDbVKTkppiUS5lpH8xi9qX8HTjkE1yMSL7uwhA="
    static let threadPAKEVerifierData = "6lws/Pp8n7nm9l3B/vX0bYkRk/KgKM614w4wDeDrRMcELNYqAYSnZ3ewoimHKTbU/obSirNe+L4msaUU09ibgUfWDgvMR7GaLG3BWDqI9BpRgyjPfz0qTt193G7r3oYwbg=="
    static let openCWManualPairingCode = "35174439122"
    
    /// Save value for key in keychain
    /// - Parameters:
    ///   - value: value to be saved
    ///   - key: corresponding key
    func saveVendorId(groupId: String, vendorId: UInt16?) {
        vendorIdQueue.async(flags: .barrier) {
            let key = "vendor.id.\(groupId)"
            if let vendorId = vendorId {
                do {
                    try ESPKeychainWrapper.shared.set(value: "\(vendorId)", account: key)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

    /// Get vendor id
    /// - Parameter groupId: group id
    /// - Returns: vendor id
    func getVendorId(groupId: String) -> UInt16? {
        vendorIdQueue.sync {
            let key = "vendor.id.\(groupId)"
            if let vendorIdStr = try? ESPKeychainWrapper.shared.get(account: key), let vendorId = UInt16(vendorIdStr) {
                return vendorId
            }
            return nil
        }
    }
    
    static func convertPEMString(toDER pem: String) -> Data? {
        var result = pem.replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
        result = result.replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
        result = result.replacingOccurrences(of: "\n", with: "")
        if let data = Data(base64Encoded: result, options: []) {
            return data
        }
        return nil
    }
}


