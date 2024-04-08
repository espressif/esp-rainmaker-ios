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
//  ESPMTRCommissioner+Subscriber.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Get level controller
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - controller: controller
    ///   - completionHandler: completion handler
    func getLevelController(groupId: String, deviceId: UInt64, completionHandler: @escaping (MTRBaseClusterLevelControl?) -> Void) {
        let endpointClusterId = ESPMatterClusterUtil.shared.isLevelControlServerSupported(groupId: groupId, deviceId: deviceId)
        if let controller = sController, endpointClusterId.0 == true, let key = endpointClusterId.1, let endpoint = UInt16(key) {
            if let device = try? controller.getDeviceBeingCommissioned(deviceId) {
                if let cluster = MTRBaseClusterLevelControl(device: device, endpoint: endpoint, queue: ESPMTRCommissioner.shared.matterQueue) {
                    completionHandler(cluster)
                } else {
                    completionHandler(nil)
                }
            } else {
                controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                    if let device = device, let cluster = MTRBaseClusterLevelControl(device: device, endpoint: endpoint, queue: ESPMTRCommissioner.shared.matterQueue) {
                        completionHandler(cluster)
                    } else {
                        completionHandler(nil)
                    }
                }
            }
        } else {
            completionHandler(nil)
        }
    }
    
    /// Get color controller
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completionHandler: completion
    func getColorCluster(groupId: String, deviceId: UInt64, completionHandler: @escaping (MTRBaseClusterColorControl?) -> Void) {
        let endpointClusterId = ESPMatterClusterUtil.shared.isColorControlServerSupported(groupId: groupId, deviceId: deviceId)
        if let controller = sController, endpointClusterId.0 == true, let key = endpointClusterId.1, let endpoint = UInt16(key) {
            if let device = try? controller.getDeviceBeingCommissioned(deviceId) {
                if let cluster = MTRBaseClusterColorControl(device: device, endpoint: endpoint, queue: ESPMTRCommissioner.shared.matterQueue) {
                    completionHandler(cluster)
                } else {
                    completionHandler(nil)
                }
            } else {
                controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                    if let device = device, let cluster = MTRBaseClusterColorControl(device: device, endpoint: endpoint, queue: ESPMTRCommissioner.shared.matterQueue) {
                        completionHandler(cluster)
                    } else {
                        completionHandler(nil)
                    }
                }
            }
        } else {
            completionHandler(nil)
        }
    }
    
    
    /// Subscribe to on/off attribute
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion handler with on/off value
    func subscribeToOnOffValue(groupId: String, deviceId: UInt64, completion: @escaping (Bool) -> Void) {
        ESPMTRCommissioner.shared.getOnOffCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                let params = MTRSubscribeParams()
                params.minInterval = NSNumber(value: 1.0)
                params.maxInterval = NSNumber(value: 2.0)
                cluster.subscribeAttributeOnOff(with: params, subscriptionEstablished: nil) { val, _ in
                    if let val = val {
                        completion(val.boolValue)
                    }
                }
            }
        }
    }
    
    /// Subscribte to level value
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func subscribeToLevelValue(groupId: String, deviceId: UInt64, completion: @escaping (Int) -> Void) {
        ESPMTRCommissioner.shared.getLevelController(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                let params = MTRSubscribeParams()
                params.minInterval = NSNumber(value: 1.0)
                params.maxInterval = NSNumber(value: 2.0)
                cluster.subscribeAttributeCurrentLevel(with: params, subscriptionEstablished: nil) { val, _ in
                    if let val = val {
                        completion(val.intValue)
                    }
                }
            }
        }
    }
    
    /// Subscribe to hue values
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion with hue value
    func subscribeToHueValue(groupId: String, deviceId: UInt64, completion: @escaping (Int) -> Void) {
        ESPMTRCommissioner.shared.getColorCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                let params = MTRSubscribeParams()
                params.minInterval = NSNumber(value: 1.0)
                params.maxInterval = NSNumber(value: 2.0)
                cluster.subscribeAttributeCurrentHue(with: params, subscriptionEstablished: nil) { val, _ in
                    if let val = val {
                        completion(val.intValue)
                    }
                }
            }
        }
    }
    
    /// Subscribe to saturation value
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion with saturation value
    func subscribeToSaturationValue(groupId: String, deviceId: UInt64, completion: @escaping (Int) -> Void) {
        ESPMTRCommissioner.shared.getColorCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                let params = MTRSubscribeParams()
                params.minInterval = NSNumber(value: 1.0)
                params.maxInterval = NSNumber(value: 2.0)
                cluster.subscribeAttributeCurrentSaturation(with: params, subscriptionEstablished: nil) { val, _ in
                    if let val = val {
                        completion(val.intValue)
                    }
                }
            }
        }
    }
}
#endif
