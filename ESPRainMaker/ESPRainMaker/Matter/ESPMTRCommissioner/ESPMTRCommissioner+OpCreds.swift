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
//  ESPMTRCommissioner+OpCreds.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Get operational credentials cluster
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func getOpCredsCluster(deviceId: UInt64, endpoint: UInt16 = 0, completion: @escaping (MTRBaseClusterOperationalCredentials?) -> Void) {
        if let controller = sController {
            if let device = try? controller.getDeviceBeingCommissioned(deviceId) {
                if let cluster = MTRBaseClusterOperationalCredentials(device: device, endpointID: NSNumber(value: 0), queue: ESPMTRCommissioner.shared.matterQueue) {
                    completion(cluster)
                } else {
                    completion(nil)
                }
            } else {
                controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                    if let device = device, let cluster = MTRBaseClusterOperationalCredentials(device: device, endpointID: NSNumber(value: 0), queue: ESPMTRCommissioner.shared.matterQueue) {
                        completion(cluster)
                    } else {
                        completion(nil)
                    }
                }
            }
        } else {
            completion(nil)
        }
    }
    
    /// Read current fabric index
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func readCurrentFabricIndex(deviceId: UInt64, completion: @escaping (NSNumber?) -> Void) {
        self.getOpCredsCluster(deviceId: deviceId) { cluster in
            guard let cluster = cluster else {
                completion(nil)
                return
            }
            cluster.readAttributeCurrentFabricIndex { index, _ in
                guard let index = index else {
                    completion(nil)
                    return
                }
                completion(index)
            }
        }
    }
    
    func removeFabricAtIndex(deviceId: UInt64, atIndex index: NSNumber, completion: @escaping (Bool) -> Void) {
        self.getOpCredsCluster(deviceId: deviceId) { cluster in
            guard let cluster = cluster else {
                completion(false)
                return
            }
            let params = MTROperationalCredentialsClusterRemoveFabricParams()
            params.fabricIndex = index
            cluster.removeFabric(with: params) { response, _ in
                guard let response = response else {
                    completion(false)
                    return
                }
                let statusCode = response.statusCode
                if statusCode.intValue == 0 {
                    completion(true)
                    return
                }
                completion(false)
            }
        }
    }
}
#endif
