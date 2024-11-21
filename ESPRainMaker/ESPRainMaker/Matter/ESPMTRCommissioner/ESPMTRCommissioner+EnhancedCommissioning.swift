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
    
    /// Generate random discriminator for enhanced commisssioning mode
    /// - Returns: discriminator
    func generateRandomDiscriminator() -> NSNumber {
        // Define the range for valid discriminator values
        let minValue = 1
        let maxValue = 0xFFE  // 4094 in decimal

        // Generate a random number within the range
        let randomDiscriminator = Int.random(in: minValue...maxValue)
        
        return NSNumber(value: randomDiscriminator)
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
    
    
    /// Open commissioning window
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion handler with setup payload and error
    func openMTRPairingWindow(deviceId: UInt64, completion: @escaping (String?) -> Void) {
        if let controller = self.sController {
            controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device {
                    let passcode = MTRSetupPayload.generateRandomSetupPasscode()
                    let discriminator = self.generateRandomDiscriminator()
                    device.openCommissioningWindow(withSetupPasscode: passcode,
                                                   discriminator: discriminator,
                                                   duration: NSNumber(value: 300),
                                                   queue: self.matterQueue) { setup, error in
                        guard let _ = error else {
                            if let setup = setup as? MTRSetupPayload {
                                if let manualPairingCode = setup.manualEntryCode() {
                                    completion(manualPairingCode)
                                } else {
                                    completion(nil)
                                }
                            }
                            return
                        }
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    /// Revoke commissioning window
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion handler with success status
    func revokeCommissioningWindow(deviceId: UInt64, completion: @escaping (Bool) -> Void) {
        if let controller = self.sController {
            let device = MTRBaseDevice(nodeID: NSNumber(value: deviceId), controller: controller)
            if let commissioningCluster = MTRBaseClusterAdministratorCommissioning(device: device, endpointID: NSNumber(value: 0), queue: self.matterQueue) {
                let params = MTRAdministratorCommissioningClusterRevokeCommissioningParams()
                commissioningCluster.revokeCommissioning(with: params) { error in
                    guard let _ = error else {
                        // Remove stored OCW date when revoking
                        completion(true)
                        return
                    }
                    completion(false)
                }
            } else {
                completion(false)
            }
        } else {
            completion(false)
        }
    }
}
#endif
