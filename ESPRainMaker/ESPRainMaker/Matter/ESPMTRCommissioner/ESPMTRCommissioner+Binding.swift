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
    ///   - sourceDeviceId: source
    ///   - destinationDeviveId: destination device id
    ///   - completionHandler: completion handler
    func linkDevice(endpointClusterId: [String: UInt]?, sourceDeviceId: UInt64, destinationDeviveId: UInt64, completionHandler: @escaping (Bool) -> Void) {
        self.readACLAttributes(deviceId: destinationDeviveId) { attributes in
            if let attributes = attributes, var subjects = attributes.subjects as? [NSNumber] {
                subjects.append(NSNumber(value: sourceDeviceId))
                attributes.subjects = subjects
                self.writeACLAttributes(deviceId: destinationDeviveId, accessControlEntry: attributes) { result in
                    if result {
                        self.bind(endpointClusterId: endpointClusterId, sourceDeviceId: sourceDeviceId, destinationDeviceId: destinationDeviveId, completionHandler: completionHandler)
                    } else {
                        completionHandler(result)
                    }
                }
            }
        }
    }
    
    /// Bind device
    /// - Parameters:
    ///   - sourceDeviceId: source device id
    ///   - destinationDeviceId: destination device id
    ///   - completionHandler: completion handler
    func bind(endpointClusterId: [String: UInt]?, sourceDeviceId: UInt64, destinationDeviceId: UInt64, completionHandler: @escaping (Bool) -> Void) {
        if let controller = sController {
            controller.getBaseDevice(sourceDeviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let endpointClusterId = endpointClusterId, endpointClusterId.keys.count > 0, let endpoint = Int(endpointClusterId.keys.first!), let bindingCluster = MTRBaseClusterBinding(device: device, endpointID: NSNumber(value: endpoint), queue: ESPMTRCommissioner.shared.matterQueue) {
                    let param = MTRBindingClusterTargetStruct()
                    param.node = NSNumber(value: destinationDeviceId)
                    param.cluster = NSNumber(value: 6)
                    param.endpoint = NSNumber(value: 1)
                    bindingCluster.writeAttributeBinding(withValue: [param]) { error in
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
    
    /// Unlink device. Update ACL
    /// - Parameters:
    ///   - sourceDeviceId: source device id
    ///   - destinationDeviveId: destination device id
    ///   - completionHandler:completion handler
    func unlinkDevice(endpointClusterId: [String: UInt]?, sourceDeviceId: UInt64, destinationDeviveId: UInt64, completionHandler: @escaping (Bool) -> Void) {
        self.readACLAttributes(deviceId: destinationDeviveId) { attributes in
            if let attributes = attributes, let subjects = attributes.subjects as? [NSNumber] {
                var newSubjects = subjects
                for i in 0..<subjects.count {
                    let subject = subjects[i]
                    if sourceDeviceId == subject.uint64Value {
                        newSubjects.remove(at: i)
                        break
                    }
                }
                attributes.subjects = newSubjects
                self.writeACLAttributes(deviceId: destinationDeviveId, accessControlEntry: attributes) { result in
                    if result {
                        self.unbind(endpointClusterId: endpointClusterId, sourceDeviceId: sourceDeviceId, destinationDeviceId: destinationDeviveId, completionHandler: completionHandler)
                    } else {
                        completionHandler(false)
                    }
                }
            }
        }
    }
    
    /// Unbind devices
    /// - Parameters:
    ///   - sourceDeviceId: source device id
    ///   - destinationDeviceId: destination device id
    ///   - completionHandler: completion handler
    func unbind(endpointClusterId: [String: UInt]?, sourceDeviceId: UInt64, destinationDeviceId: UInt64, completionHandler: @escaping (Bool) -> Void) {
        if let controller = sController {
            controller.getBaseDevice(sourceDeviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let endpointClusterId = endpointClusterId, endpointClusterId.keys.count > 0, let endpoint = Int(endpointClusterId.keys.first!), let bindingCluster = MTRBaseClusterBinding(device: device, endpointID: NSNumber(value: endpoint), queue: ESPMTRCommissioner.shared.matterQueue) {
                    bindingCluster.readAttributeBinding(with: nil) { val, _ in
                        if let params = val as? [MTRBindingClusterTargetStruct], params.count > 0 {
                            let newParams = params.filter {
                                if let id = $0.node?.uint64Value, id == destinationDeviceId {
                                    return false
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
