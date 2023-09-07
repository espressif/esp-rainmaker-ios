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
//  ESPMTRCommissioner+EnhancedCommissioning.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Get disciminator
    /// - Returns: discriminator
    func getDiscriminator() -> UInt32 {
        let lowerLimit: UInt32 = 0000
        let upperLimit: UInt32 = 4095
        let discriminator = arc4random_uniform(upperLimit - lowerLimit) + lowerLimit
        return discriminator
    }
    
    /// Get passcode
    /// - Returns: setup passcode
    func getPasscode() -> UInt32 {
        let invalidPasscodes: [UInt32] = [00000000,
                                11111111,
                                22222222,
                                33333333,
                                44444444,
                                55555555,
                                66666666,
                                77777777,
                                88888888,
                                99999999,
                                12345678,
                                87654321]
        let lowerLimit: UInt32 = 00000001
        let upperLimit: UInt32 = 99999998
        let passcode = arc4random_uniform(upperLimit - lowerLimit) + lowerLimit
        if invalidPasscodes.contains(passcode) {
            return getPasscode()
        }
        return passcode
    }
    
    /// Open commissioning Window
    func openCommissioningWindow(deviceId: UInt64, completion: @escaping (String?) -> Void) {
        if let controller = self.sController {
            controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let commissioningWindowCluster = MTRBaseClusterAdministratorCommissioning(device: device, endpointID: NSNumber(value: 0), queue: ESPMTRCommissioner.shared.matterQueue), let saltData = ESPDefaultData.threadSaltData.data(using: .utf8), let pakeVerifierData = ESPDefaultData.threadPAKEVerifierData.data(using: .utf8), let pakeVerifier = Data(base64Encoded: pakeVerifierData), let salt = Data(base64Encoded: saltData) {
                    let params = MTRAdministratorCommissioningClusterOpenCommissioningWindowParams()
                    params.pakePasscodeVerifier = pakeVerifier
                    params.salt = salt
                    params.discriminator = NSNumber(value: 3840)
                    params.iterations = NSNumber(value: 15000)
                    params.commissioningTimeout = NSNumber(value: 300)
                    params.timedInvokeTimeoutMs = NSNumber(value: 60000)
                    commissioningWindowCluster.openWindow(with: params) { error in
                        if let _ = error {
                            completion(nil)
                        } else {
                            completion(ESPDefaultData.openCWManualPairingCode)
                        }
                    }
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    /// Is commissioning window open
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpointId: endpoint id
    ///   - completion: completion
    func isCommissioningWindowOpen(deviceId: UInt64, endpoint: UInt8 = 0, completion: @escaping (Bool?, Error?) -> Void) {
        if let controller = self.sController {
            let device = MTRBaseDevice(nodeID: NSNumber(value: deviceId), controller: controller)
            if let commissioningWindowCluster = MTRBaseClusterAdministratorCommissioning(device: device, endpointID: NSNumber(value: 0), queue: self.matterQueue) {
                commissioningWindowCluster.readAttributeWindowStatus { val, error in
                    guard let error = error else {
                        if let val = val {
                            completion(val.boolValue, nil)
                        } else {
                            completion(false, nil)
                        }
                        return
                    }
                    completion(false, error)
                    return
                }
            }
        }
        completion(nil, nil)
    }
}
#endif
