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
//  ESPMTRCommissioner+CustomCluster.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Get Matter device
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func getMatterDevice(deviceId: UInt64, completion: @escaping (MTRBaseDevice?) -> Void) {
        if let controller = sController {
            if let device = try? controller.getDeviceBeingCommissioned(deviceId) {
                completion(device)
                return
            }
            let device = MTRBaseDevice(nodeID: NSNumber(value: deviceId), controller: controller)
            completion(device)
            return
        }
        completion(nil)
    }
    
    /// Read rainmaker node id
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func readAttributeRainmakerNodeIdFromDevice(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (String?) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                device.readAttributes(withEndpointID: NSNumber(value: endpoint),
                                      clusterID: rainmaker.clusterId,
                                      attributeID: rainmaker.attributes.rainmakerNodeId.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
                    if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let nodeId = data[ESPMatterConstants.value] as? String {
                        completion(nodeId)
                        return
                    }
                    completion(nil)
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
    func sendMatterNodeIdToDevice(deviceId: UInt64, endpoint: UInt16, matterNodeId: String, _ completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                let data = [ESPMatterConstants.type: ESPMatterConstants.UTF8String,
                            ESPMatterConstants.value: matterNodeId]
                device.invokeCommand(withEndpointID: NSNumber(value: endpoint),
                                     clusterID: rainmaker.clusterId,
                                     commandID: rainmaker.commands.sendNodeId.commandId,
                                     commandFields: data,
                                     timedInvokeTimeout: nil,
                                     queue: self.matterQueue) { value, error in
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
    
    /// Read attribute challenge
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func readAttributeChallengeFromDevice(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping(String?) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                device.readAttributes(withEndpointID: NSNumber(value: endpoint),
                                      clusterID: rainmaker.clusterId,
                                      attributeID: rainmaker.attributes.challenge.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
                    if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let nodeId = data[ESPMatterConstants.value] as? String {
                        completion(nodeId)
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
}
#endif
