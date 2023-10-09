// Copyright 2024 Espressif Systems
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
//  ESPMTRCommissioner+ThreadBorderRouter.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Configure thread dataset
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion handler
    func configureThreadDataset(deviceId: UInt64, threadDataSet: String, _ completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                let commandFields: [String: Any] = [:]
                device.invokeCommand(withEndpointID: NSNumber(value: 0),
                                     clusterID: borderRouter.clusterId,
                                     commandID: borderRouter.commands.configureThreadDataset.commandId,
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
    func updateActiveThreadOperationalDataset(deviceId: UInt64, operationalDataset: String, completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                let finalPayload = ["type": "Structure",
                                    "value": [["contextTag": 0,
                                               "data": ["type": "UTF8String",
                                                        "value": operationalDataset]]]]
                
                device.invokeCommand(withEndpointID: NSNumber(value: 0),
                                     clusterID: borderRouter.clusterId,
                                     commandID: borderRouter.commands.configureThreadDataset.commandId,
                                     commandFields: finalPayload
                                     as Any,
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
    
    /// Start custom thread network
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func startThreadNetwork(deviceId: UInt64, completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                let commandFields: [String: Any] = [ESPMatterConstants.type: ESPMatterConstants.structure,
                                                     ESPMatterConstants.value: []]
                device.invokeCommand(withEndpointID: NSNumber(value: 0),
                                     clusterID: borderRouter.clusterId,
                                     commandID: borderRouter.commands.startThreadNetwork.commandId,
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
    
    /// Stop custom thread network
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func stopThreadNetwork(deviceId: UInt64, completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                let commandFields: [String: Any] = [ESPMatterConstants.type: ESPMatterConstants.structure,
                                                     ESPMatterConstants.value: []]
                device.invokeCommand(withEndpointID: NSNumber(value: 0),
                                     clusterID: borderRouter.clusterId,
                                     commandID: borderRouter.commands.stopThreadNetwork.commandId,
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
    
    /// read attribute active ops dataser
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion containing active thread ops data
    func readAttributeActiveOpDataset(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (Data?) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                device.readAttributes(withEndpointID: NSNumber(value: endpoint),
                                      clusterID: borderRouter.clusterId,
                                      attributeID: borderRouter.attributes.activeOperationalDataset.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
                    if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let dataset = data[ESPMatterConstants.value] as? Data {
                        completion(dataset)
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// read attribute active ops dataser
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion containing active thread ops data
    func readAttributeBorderAgentId(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (Data?) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                device.readAttributes(withEndpointID: NSNumber(value: endpoint),
                                      clusterID: borderRouter.clusterId,
                                      attributeID: borderRouter.attributes.borderAgentId.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
                    if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let borderAgentId = data[ESPMatterConstants.value] as? Data {
                        completion(borderAgentId)
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
