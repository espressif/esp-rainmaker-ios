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
//  ESPMTRCommissioner+Binding.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Link device. Update ACL.
    /// - Parameters:
    ///   - bindingEndpointClusterId: binding endpoint cluster id
    ///   - sourceDeviceId: source
    ///   - destinationDeviveId: destination device id
    ///   - completionHandler: completion handler
    func linkDevice(bindingEndpointClusterId: [String: UInt]?, cluster: String, sourceDeviceId: UInt64, destinationDeviveId: UInt64, completionHandler: @escaping (Bool) -> Void) {
        self.readAllACLAttributes(deviceId: destinationDeviveId) { attributes in
            if var attributes = attributes {
                if let index = try? attributes.firstIndex(where: { $0.privilege.intValue == 5 }) {
                    let attribute = attributes[index]
                    if var subjects = attribute.subjects as? [NSNumber] {
                        if subjects.contains(NSNumber(value: sourceDeviceId)) {
                            self.bind(bindingEndpointClusterId: bindingEndpointClusterId, cluster: cluster, sourceDeviceId: sourceDeviceId, destinationDeviceId: destinationDeviveId, completionHandler: completionHandler)
                            return
                        }
                        subjects.append(NSNumber(value: sourceDeviceId))
                        attribute.subjects = subjects
                        attributes[index] = attribute
                    }
                }
                self.writeAllACLAttributes(deviceId: destinationDeviveId, accessControlEntry: attributes) { result in
                    if result {
                        self.bind(bindingEndpointClusterId: bindingEndpointClusterId, cluster: cluster, sourceDeviceId: sourceDeviceId, destinationDeviceId: destinationDeviveId, completionHandler: completionHandler)
                    } else {
                        completionHandler(result)
                    }
                }
            }
        }
    }
    
    /// Bind device
    /// - Parameters:
    ///   - bindingEndpointClusterId: binding endpoint cluster id
    ///   - sourceDeviceId: source device id
    ///   - destinationDeviceId: destination device id
    ///   - completionHandler: completion handler
    func bind(bindingEndpointClusterId: [String: UInt]?, cluster: String, sourceDeviceId: UInt64, destinationDeviceId: UInt64, completionHandler: @escaping (Bool) -> Void) {
        if let controller = sController {
            controller.getBaseDevice(sourceDeviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let clusterId = cluster.clusterId, let device = device, let bindingEndpointClusterId = bindingEndpointClusterId, bindingEndpointClusterId.keys.count > 0, let key = bindingEndpointClusterId.keys.first, let endpoint = Int(key), let bindingCluster = MTRBaseClusterBinding(device: device, endpointID: NSNumber(value: endpoint), queue: ESPMTRCommissioner.shared.matterQueue) {
                    bindingCluster.readAttributeBinding(with: nil) { params, _ in
                        var finalParams = [MTRBindingClusterTargetStruct]()
                        if let params = params as? [MTRBindingClusterTargetStruct], params.count > 0 {
                            for param in params {
                                if let nodeId = param.node?.intValue, nodeId == destinationDeviceId {
                                    completionHandler(true)
                                    return
                                }
                            }
                            finalParams = params
                        }
                        let param = MTRBindingClusterTargetStruct()
                        param.node = NSNumber(value: destinationDeviceId)
                        param.cluster = NSNumber(value: clusterId)
                        param.endpoint = NSNumber(value: 1)
                        if let group = self.group, let groupId = group.groupID {
                            let destinationECId = ESPMatterClusterUtil.shared.isServerClusterSupported(groupId: groupId, deviceId: destinationDeviceId, clusterId: clusterId)
                            if let key = destinationECId.1, let ep = UInt16(key) {
                                param.endpoint = NSNumber(value: ep)
                            }
                        }
                        finalParams.append(param)
                        bindingCluster.writeAttributeBinding(withValue: finalParams) { error in
                            if let _ = error {
                                completionHandler(false)
                            } else {
                                completionHandler(true)
                            }
                        }
                    }
                } else {
                    completionHandler(false)
                }
            }
        } else {
            completionHandler(false)
        }
    }
    
    /// Unlink device. Update ACL
    /// - Parameters:
    ///   - bindingEndpointClusterId: binding endpoint cluster id
    ///   - sourceDeviceId: source device id
    ///   - destinationDeviveId: destination device id
    ///   - completionHandler:completion handler
    func unlinkDevice(bindingEndpointClusterId: [String: UInt]?, cluster: String, sourceDeviceId: UInt64, destinationDeviveId: UInt64, completionHandler: @escaping (Bool) -> Void) {
        self.unbind(bindingEndpointClusterId: bindingEndpointClusterId, cluster: cluster, sourceDeviceId: sourceDeviceId, destinationDeviceId: destinationDeviveId) { unbindResult in
            if unbindResult {
                self.readAllACLAttributes(deviceId: destinationDeviveId) { attributes in
                    if var attributes = attributes, attributes.count > 0 {
                        if let index = try? attributes.firstIndex(where: { $0.privilege.intValue == 5 }) {
                            let attribute = attributes[index]
                            if var subjects = attribute.subjects as? [NSNumber] {
                                let finalSubjects = subjects.filter {
                                    return !($0.uint64Value == sourceDeviceId)
                                }
                                attribute.subjects = finalSubjects
                            }
                            attributes[index] = attribute
                        }
                        self.writeAllACLAttributes(deviceId: destinationDeviveId, accessControlEntry: attributes) { writeACLResult in
                            completionHandler(writeACLResult)
                        }
                    } else {
                        completionHandler(false)
                    }
                }
            } else {
                completionHandler(false)
            }
        }
    }
    
    /// Unbind devices
    /// - Parameters:
    ///   - bindingEndpointClusterId: binding endpoint cluster id
    ///   - sourceDeviceId: source device id
    ///   - destinationDeviceId: destination device id
    ///   - completionHandler: completion handler
    func unbind(bindingEndpointClusterId: [String: UInt]?, cluster: String, sourceDeviceId: UInt64, destinationDeviceId: UInt64, completionHandler: @escaping (Bool) -> Void) {
        if let controller = sController {
            controller.getBaseDevice(sourceDeviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let bindingEndpointClusterId = bindingEndpointClusterId, bindingEndpointClusterId.keys.count > 0, let key = bindingEndpointClusterId.keys.first, let endpoint = Int(key), let bindingCluster = MTRBaseClusterBinding(device: device, endpointID: NSNumber(value: endpoint), queue: ESPMTRCommissioner.shared.matterQueue) {
                    bindingCluster.readAttributeBinding(with: nil) { val, _ in
                        if let params = val as? [MTRBindingClusterTargetStruct], params.count > 0 {
                            let newParams = params.filter {
                                if let id = $0.node?.uint64Value, id == destinationDeviceId {
                                    if let deviceCluster = $0.cluster {
                                        let deviceClusterId = deviceCluster.intValue
                                        if let cId = cluster.clusterId, cId == deviceClusterId {
                                            return false
                                        }
                                    }
                                }
                                return true
                            }
                            bindingCluster.writeAttributeBinding(withValue: newParams) { error in
                                if let _ = error {
                                    completionHandler(false)
                                } else {
                                    completionHandler(true)
                                }
                            }
                        } else {
                            completionHandler(false)
                        }
                    }
                } else {
                    completionHandler(false)
                }
            }
        } else {
            completionHandler(false)
        }
    }
    
    /// Check if nodes are linked
    /// - Parameters:
    ///   - sourceDeviceId: source device id
    ///   - destinationDeviceId: destination device id
    ///   - endpoint: endpoint
    ///   - completion: callback
    func areDevicesLinked(sourceDeviceId: UInt64, destinationDeviceId: UInt64, endpoint: UInt, completion: @escaping (Bool) -> Void) {
        self.readACLAttributes(deviceId: destinationDeviceId) { attributes in
            if let attributes = attributes, let subjects = attributes.subjects as? [NSNumber] {
                var foundSubject = false
                for subject in subjects {
                    let id = subject.uint64Value
                    if id == sourceDeviceId {
                        foundSubject = true
                        break
                    }
                }
                if foundSubject {
                    self.readBindingData(deviceId: sourceDeviceId, destinationDeviceId: destinationDeviceId, endpointId: endpoint) { isLinked in
                        completion(isLinked)
                    }
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
}
#endif
