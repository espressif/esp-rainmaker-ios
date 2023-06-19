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
//  ESPMTRCommissioner+Rainmaker.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Fetch rainmaker node id
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func fetchRainmakerNodeId(deviceId: UInt64, _ completion: @escaping (String?) -> Void) {
        getRainmakerCluster(deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeNodeId { rainmakerNodeId, _ in
                    if let rainmakerNodeId = rainmakerNodeId {
                        completion(rainmakerNodeId)
                    } else {
                        completion(nil)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Send matter node id
    /// - Parameters:
    ///   - deviceId: device id
    ///   - matterNodeId: matter node id
    ///   - completion: completion
    func sendMatterNodeId(deviceId: UInt64, matterNodeId: String, _ completion: @escaping (Bool) -> Void) {
        getRainmakerCluster(deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.sendMatterNodeId(matterNodeId) { _, error in
                    if let _ = error {
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Read attribute challenge
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func readAttributeChallenge(deviceId: UInt64, _ completion: @escaping(String?) -> Void) {
        getRainmakerCluster(deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeChallenge { challenge, _ in
                    if let challenge = challenge {
                        completion(challenge)
                    } else {
                        completion(nil)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Get rainmaker cluster
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func getRainmakerCluster(deviceId: UInt64, _ completion: @escaping(MTRBaseClusterRainmaker?) -> Void) {
        if let controller = sController {
            if let device = try? controller.getDeviceBeingCommissioned(deviceId) {
                if let cluster = MTRBaseClusterRainmaker(device: device, endpoint: NSNumber(value: 0), queue: ESPMTRCommissioner.shared.matterQueue) {
                    completion(cluster)
                } else {
                    completion(nil)
                }
            } else {
                controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                    if let device = device, let cluster = MTRBaseClusterRainmaker(device: device, endpoint: NSNumber(value: 0), queue: ESPMTRCommissioner.shared.matterQueue) {
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
}
#endif
