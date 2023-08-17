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
    func readAttributeRainmakerNodeIdFromDevice(deviceId: UInt64, _ completion: @escaping (String?) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                device.readAttributes(withEndpointID: NSNumber(value: 0),
                                      clusterID: rainmaker.clusterId,
                                      attributeID: rainmaker.attributes.rainmakerNodeId.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
                    if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let nodeId = data[ESPMatterConstants.value] as? String {
                        print(nodeId)
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
    func sendMatterNodeIdToDevice(deviceId: UInt64, matterNodeId: String, _ completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                let data = [ESPMatterConstants.type: ESPMatterConstants.UTF8String,
                            ESPMatterConstants.value: matterNodeId]
                device.invokeCommand(withEndpointID: NSNumber(value: 0),
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
    func readAttributeChallengeFromDevice(deviceId: UInt64, _ completion: @escaping(String?) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                device.readAttributes(withEndpointID: NSNumber(value: 0),
                                      clusterID: rainmaker.clusterId,
                                      attributeID: rainmaker.attributes.challenge.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
                    if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let nodeId = data[ESPMatterConstants.value] as? String {
                        print(nodeId)
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
    
    /// Reset refresh token
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func resetRefreshTokenInDevice(deviceId: UInt64, completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                let commandFields: [String: Any] = [ESPMatterConstants.type: ESPMatterConstants.structure,
                                                     ESPMatterConstants.value: []]
                device.invokeCommand(withEndpointID: NSNumber(value: 0),
                                     clusterID: rainmakerController.clusterId,
                                     commandID: rainmakerController.commands.resetRefreshToken.commandId,
                                     commandFields: commandFields as Any,
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
    
    /// Append refresh token
    /// - Parameters:
    ///   - token: refresh token
    ///   - completion: completion
    func appendRefreshTokenToDevice(deviceId: UInt64, token: String, completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                let commandFields = [ESPMatterConstants.type: ESPMatterConstants.UTF8String,
                              ESPMatterConstants.value: token]
                device.invokeCommand(withEndpointID: NSNumber(value: 0),
                                     clusterID: rainmakerController.clusterId,
                                     commandID: rainmakerController.commands.appendRefreshToken.commandId,
                                     commandFields: commandFields as Any,
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
    
    /// Authorize
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpointURL: endpoint URL
    ///   - completion: completion
    func authorizeDevice(deviceId: UInt64, endpointURL: String, completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                let commandFields = [ESPMatterConstants.type: ESPMatterConstants.UTF8String,
                                     ESPMatterConstants.value: endpointURL]
                device.invokeCommand(withEndpointID: NSNumber(value: 0),
                                     clusterID: rainmakerController.clusterId,
                                     commandID: rainmakerController.commands.authorize.commandId,
                                     commandFields: commandFields,
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
    
    /// Update device list
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func updateUserNOCOnDevice(deviceId: UInt64, completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                let commandFields: [String: Any] = [ESPMatterConstants.type: ESPMatterConstants.structure,
                                                     ESPMatterConstants.value: []]
                device.invokeCommand(withEndpointID: NSNumber(value: 0),
                                     clusterID: rainmakerController.clusterId,
                                     commandID: rainmakerController.commands.updateUserNOC.commandId,
                                     commandFields: commandFields as Any,
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
    
    /// Update device list
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func updateDeviceListOnDevice(deviceId: UInt64, completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                let commandFields: [String: Any] = [ESPMatterConstants.type: ESPMatterConstants.structure,
                                                    ESPMatterConstants.value: []]
                device.invokeCommand(withEndpointID: NSNumber(value: 0),
                                     clusterID: rainmakerController.clusterId,
                                     commandID: rainmakerController.commands.updateDeviceList.commandId,
                                     commandFields: commandFields as Any,
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
    
    /// read User NOC installed
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func readAttributeUserNOCInstalledOnDevice(deviceId: UInt64, _ completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                device.readAttributes(withEndpointID: NSNumber(value: 0),
                                      clusterID: rainmakerController.clusterId,
                                      attributeID: rainmakerController.attributes.userNOCInstalled.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
                    if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let status = data[ESPMatterConstants.value] as? Bool {
                        completion(status)
                        return
                    }
                    completion(false)
                }
            }
        }
    }
    
    /// read User NOC installed
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func readAttributeAuthorizedOnDevice(deviceId: UInt64, _ completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                device.readAttributes(withEndpointID: NSNumber(value: 0),
                                      clusterID: rainmakerController.clusterId,
                                      attributeID: rainmakerController.attributes.authorized.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
                    if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let status = data[ESPMatterConstants.value] as? Bool {
                        completion(status)
                        return
                    }
                    completion(false)
                }
            }
        }
    }
}
#endif
