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
//  ESPMTRCommissioner+AccessControl.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Read ACL attributes
    /// - Parameters:
    ///   - deviceId: deviceId
    ///   - completionHandler: completion handler
    func readACLAttributes(deviceId: UInt64, completionHandler: @escaping (MTRAccessControlClusterAccessControlEntryStruct?) -> Void) {
        if let controller = sController {
            controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let accessControlCluster = MTRBaseClusterAccessControl(device: device, endpointID: NSNumber(value: 0), queue: ESPMTRCommissioner.shared.matterQueue) {
                    accessControlCluster.readAttributeACL(with: nil) { val, _ in
                        if let val = val as? [MTRAccessControlClusterAccessControlEntryStruct], val.count > 0 {
                            let value = val[0]
                            completionHandler(value)
                        } else {
                            completionHandler(nil)
                        }
                    }
                } else {
                    completionHandler(nil)
                }
            }
        } else {
            completionHandler(nil)
        }
    }
    
    /// Read all ACL attributes
    /// - Parameters:
    ///   - deviceId: deviceId
    ///   - completionHandler: completion handler
    func readAllACLAttributes(deviceId: UInt64, completionHandler: @escaping ([MTRAccessControlClusterAccessControlEntryStruct]?) -> Void) {
        if let controller = sController {
            controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let accessControlCluster = MTRBaseClusterAccessControl(device: device, endpointID: NSNumber(value: 0), queue: ESPMTRCommissioner.shared.matterQueue) {
                    accessControlCluster.readAttributeACL(with: nil) { val, _ in
                        if let val = val as? [MTRAccessControlClusterAccessControlEntryStruct] {
                            completionHandler(val)
                        } else {
                            completionHandler(nil)
                        }
                    }
                } else {
                    completionHandler(nil)
                }
            }
        } else {
            completionHandler(nil)
        }
    }
    
    /// Write ACL attributes
    /// - Parameters:
    ///   - deviceId: device id
    ///   - accessControlEntry: access control entry
    ///   - completionHandler: completion handler
    func writeACLAttributes(deviceId: UInt64, accessControlEntry: MTRAccessControlClusterAccessControlEntryStruct, completionHandler: @escaping (Bool) -> Void) {
        if let controller = sController {
            controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let accessControlCluster = MTRBaseClusterAccessControl(device: device, endpointID: NSNumber(value: 0), queue: ESPMTRCommissioner.shared.matterQueue) {
                    accessControlCluster.writeAttributeACL(withValue: [accessControlEntry]) { error in
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
    
    /// Write ACL attributes
    /// - Parameters:
    ///   - deviceId: device id
    ///   - accessControlEntry: access control entry
    ///   - completionHandler: completion handler
    func writeAllACLAttributes(deviceId: UInt64, accessControlEntry: [MTRAccessControlClusterAccessControlEntryStruct], completionHandler: @escaping (Bool) -> Void) {
        if let controller = sController {
            controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let accessControlCluster = MTRBaseClusterAccessControl(device: device, endpointID: NSNumber(value: 0), queue: ESPMTRCommissioner.shared.matterQueue) {
                    accessControlCluster.writeAttributeACL(withValue: accessControlEntry) { error in
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
    
    func readBindingData(deviceId: UInt64, destinationDeviceId: UInt64, endpointId: UInt, completion: @escaping (Bool) -> Void) {
        if let controller = sController {
            controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let bindingCluster = MTRBaseClusterBinding(device: device, endpointID: NSNumber(value: endpointId), queue: ESPMTRCommissioner.shared.matterQueue) {
                    bindingCluster.readAttributeBinding(with: nil) { val, _ in
                        if var params = val as? [MTRBindingClusterTargetStruct], params.count > 0 {
                            for param in params {
                                if let dest = param.node?.uint64Value, dest == destinationDeviceId {
                                    completion(true)
                                    return
                                }
                            }
                        }
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        } else {
            completion(false)
        }
    }
}
#endif
