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
    
    /// Get on off cluster
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion (cluster)
    func getOnOffCluster(groupId: String, deviceId: UInt64, completion: @escaping (MTRBaseClusterOnOff?) -> Void) {
        let endpointClusterId = ESPMatterClusterUtil.shared.isOnOffServerSupported(groupId: groupId, deviceId: deviceId)
        if let controller = sController, endpointClusterId.0 == true, let key = endpointClusterId.1, let endpoint = UInt16(key) {
            controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let cluster = MTRBaseClusterOnOff(device: device, endpoint: endpoint, queue: ESPMTRCommissioner.shared.matterQueue) {
                    completion(cluster)
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    /// Toggle switch
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func toggleSwitch(groupId: String, deviceId: UInt64, completion: @escaping (Bool) -> Void) {
        self.getOnOffCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.toggle() { error in
                    guard let _ = error else {
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
    
    /// Find light switch value
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion (is loght on)
    func isLightOn(groupId: String, deviceId: UInt64, completion: @escaping (Bool) -> Void) {
        self.getOnOffCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeOnOff { value, _ in
                    if let value = value, value.intValue == 1 {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
}
#endif
