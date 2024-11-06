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
//  ESPMTRCommissioner+BasicInformation.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Get basic info cluster
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion handler
    func getBasicInfomrationCluster(deviceId: UInt64, completion: @escaping (MTRBaseClusterBasicInformation?) -> Void) {
        if let controller = sController {
            if let device = try? controller.getDeviceBeingCommissioned(deviceId) {
                if let cluster = MTRBaseClusterBasicInformation(device: device, endpointID: NSNumber(value: 0), queue: ESPMTRCommissioner.shared.matterQueue) {
                    completion(cluster)
                } else {
                    completion(nil)
                }
            } else {
                controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                    if let device = device, let cluster = MTRBaseClusterBasicInformation(device: device, endpointID: NSNumber(value: 0), queue: ESPMTRCommissioner.shared.matterQueue) {
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
    
    /// Get vendor Id
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion with device id
    func getVendorId(deviceId: UInt64, completion: @escaping (Int?) -> Void) {
        self.getBasicInfomrationCluster(deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeVendorID { vid, _ in
                    if let vid = vid {
                        completion(vid.intValue)
                    } else {
                        completion(nil)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Get product id
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion with product id
    func getProductId(deviceId: UInt64, completion: @escaping (Int?) -> Void) {
        self.getBasicInfomrationCluster(deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeProductID { pid, _ in
                    if let pid = pid {
                        completion(pid.intValue)
                    } else {
                        completion(nil)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Get software version
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion with software version
    func getSoftwareVersion(deviceId: UInt64, completion: @escaping (Int?) -> Void) {
        self.getBasicInfomrationCluster(deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeSoftwareVersion { swv, _ in
                    if let swv = swv {
                        completion(swv.intValue)
                    } else {
                        completion(nil)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Get software version
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion with software version
    func getSoftwareVersionString(deviceId: UInt64, completion: @escaping (String?) -> Void) {
        self.getBasicInfomrationCluster(deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeSoftwareVersionString { swString, _ in
                    if let swString = swString {
                        completion(swString)
                    } else {
                        completion(nil)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Get device serial number
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion with serial number
    func getDeviceSerialNumber(deviceId: UInt64, completion: @escaping (String?) -> Void) {
        self.getBasicInfomrationCluster(deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeSerialNumber { val, _ in
                    completion(val)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Get device manufacturer name
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion with vendor name
    func getManufacturerName(deviceId: UInt64, completion: @escaping (String?) -> Void) {
        self.getBasicInfomrationCluster(deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeVendorName { val, _ in
                    completion(val)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Get product name
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion with vendor name
    func getProductName(deviceId: UInt64, completion: @escaping (String?) -> Void) {
        self.getBasicInfomrationCluster(deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeProductName { val, _ in
                    completion(val)
                }
            } else {
                completion(nil)
            }
        }
    }
}
#endif
