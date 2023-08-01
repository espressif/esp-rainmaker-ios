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
//  ESPMATRCommissioner+RainmakerController.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Get rainmaker cluster
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func getRainmakerConttollerCluster(endpoint: UInt16, deviceId: UInt64, _ completion: @escaping(MTRBaseClusterRainmakerController?) -> Void) {
        if let controller = sController {
            if let device = try? controller.getDeviceBeingCommissioned(deviceId) {
                if let cluster = MTRBaseClusterRainmakerController(device: device, endpoint: NSNumber(value: endpoint), queue: ESPMTRCommissioner.shared.matterQueue) {
                    completion(cluster)
                } else {
                    completion(nil)
                }
            } else {
                controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                    if let device = device, let cluster = MTRBaseClusterRainmakerController(device: device, endpoint: NSNumber(value: endpoint), queue: ESPMTRCommissioner.shared.matterQueue) {
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
    
    /// Read attribute refresh token
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func readAttributeRefreshToken(deviceId: UInt64, _ completion: @escaping (String?) -> Void) {
        getRainmakerConttollerCluster(endpoint: 0, deviceId: deviceId) { cluster in
            if let cluster = cluster as? MTRBaseClusterRainmakerController {
                cluster.readAttributeRefreshToken() { val, error in
                    guard let val = val else {
                        completion(nil)
                        return
                    }
                    completion(val)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// read access token
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func readAttributeAccessToken(deviceId: UInt64, _ completion: @escaping (String?) -> Void) {
        getRainmakerConttollerCluster(endpoint: 0, deviceId: deviceId) { cluster in
            if let cluster = cluster as? MTRBaseClusterRainmakerController {
                cluster.readAttributeAccessToken() { val, error in
                    guard let val = val else {
                        completion(nil)
                        return
                    }
                    completion(val)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// read authorized
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func readAttributeAuthorized(deviceId: UInt64, _ completion: @escaping (Bool) -> Void) {
        getRainmakerConttollerCluster(endpoint: 0, deviceId: deviceId) { cluster in
            if let cluster = cluster as? MTRBaseClusterRainmakerController {
                cluster.readAttributeAuthorized() { val, _ in
                    guard let val = val else {
                        completion(false)
                        return
                    }
                    completion(val.intValue == 0 ? false : true)
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// read User NOC installed
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func readAttributeUserNOCInstalled(deviceId: UInt64, _ completion: @escaping (Bool) -> Void) {
        getRainmakerConttollerCluster(endpoint: 0, deviceId: deviceId) { cluster in
            if let cluster = cluster as? MTRBaseClusterRainmakerController {
                cluster.readAttributeUserNOCInstalled() { val, _ in
                    guard let val = val else {
                        completion(false)
                        return
                    }
                    completion(val.intValue == 0 ? false : true)
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Read attribute endpoint URL
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func readAttributeEndpointURL(deviceId: UInt64, _ completion: @escaping (String?) -> Void) {
        getRainmakerConttollerCluster(endpoint: 0, deviceId: deviceId) { cluster in
            if let cluster = cluster as? MTRBaseClusterRainmakerController {
                cluster.readAttributeEndpointURL() { val, _ in
                    guard let val = val else {
                        completion(nil)
                        return
                    }
                    completion(val)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Read attribute rainmaker group id
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func readAttributeRainmakerGroupId(deviceId: UInt64, _ completion: @escaping (String?) -> Void) {
        getRainmakerConttollerCluster(endpoint: 0, deviceId: deviceId) { cluster in
            if let cluster = cluster as? MTRBaseClusterRainmakerController {
                cluster.readAttributeRainmakerGroupId() { val, _ in
                    guard let val = val else {
                        completion(nil)
                        return
                    }
                    completion(val)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Append refresh token
    /// - Parameters:
    ///   - token: refresh token
    ///   - completion: completion
    func appendRefreshToken(deviceId: UInt64, token: String, completion: @escaping (Bool) -> Void) {
        getRainmakerConttollerCluster(endpoint: 0, deviceId: deviceId) { cluster in
            if let cluster = cluster as? MTRBaseClusterRainmakerController {
                cluster.appendRefreshToken(token) { val in
                    guard let _ = val else {
                        completion(true)
                        return
                    }
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Reset refresh token
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func resetRefreshToken(deviceId: UInt64, completion: @escaping (Bool) -> Void) {
        getRainmakerConttollerCluster(endpoint: 0, deviceId: deviceId) { cluster in
            if let cluster = cluster as? MTRBaseClusterRainmakerController {
                cluster.resetRefreshToken() { val in
                    guard let _ = val else {
                        completion(true)
                        return
                    }
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Validate refresh token
    /// - Parameters:
    ///   - deviceId: device id
    ///   - refreshTokenLength: refresh token length
    ///   - CRC32Result: CRC32Result length
    ///   - completion: completion
    func validateRefreshToken(deviceId: UInt64, refreshTokenLength: UInt16, CRC32Result: UInt32, completion: @escaping (Bool) -> Void) {
        getRainmakerConttollerCluster(endpoint: 0, deviceId: deviceId) { cluster in
            if let cluster = cluster as? MTRBaseClusterRainmakerController {
                cluster.validateRefreshToken(withLength: refreshTokenLength, andCRC32Result: CRC32Result) { val in
                    guard let _ = val else {
                        completion(true)
                        return
                    }
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Authorize
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpointURL: endpoint URL
    ///   - completion: completion
    func authorize(deviceId: UInt64, endpointURL: String, completion: @escaping (Bool) -> Void) {
        getRainmakerConttollerCluster(endpoint: 0, deviceId: deviceId) { cluster in
            if let cluster = cluster as? MTRBaseClusterRainmakerController {
                cluster.authorize(withEndpointURL: endpointURL) { val in
                    guard let _ = val else {
                        completion(true)
                        return
                    }
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Update device list
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func updateUserNOC(deviceId: UInt64, completion: @escaping (Bool) -> Void) {
        getRainmakerConttollerCluster(endpoint: 0, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.updateUserNOC() { val in
                    guard let _ = val else {
                        completion(true)
                        return
                    }
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Update device list
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func updateDeviceList(deviceId: UInt64, completion: @escaping (Bool) -> Void) {
        getRainmakerConttollerCluster(endpoint: 0, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.updateDeviceList() { val in
                    guard let _ = val else {
                        completion(true)
                        return
                    }
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
}
#endif
