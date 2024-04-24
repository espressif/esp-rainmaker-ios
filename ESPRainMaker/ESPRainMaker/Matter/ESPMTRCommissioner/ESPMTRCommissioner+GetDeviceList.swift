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
//  ESPMTRCommissioner+GetDeviceList.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Add cat id operate to node ACL
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completion: completion
    func addCatIdOperate(deviceId: UInt64, completion: @escaping () -> Void) {
        if let group = self.group, let fabricDetails = group.fabricDetails, let catIdoperate = fabricDetails.catIdOperateDecimal {
            self.readAllACLAttributes(deviceId: deviceId) { accessControlEntries in
                if let accessControlEntries = accessControlEntries {
                    var entries = [MTRAccessControlClusterAccessControlEntryStruct]()
                    var fabricIndex = 0
                    var authMode = 0
                    for entry in accessControlEntries {
                        if entry.privilege.intValue == 5 {
                            fabricIndex = entry.fabricIndex.intValue
                            authMode = entry.authMode.intValue
                            entries.append(entry)
                            break
                        }
                    }
                    let entry = MTRAccessControlClusterAccessControlEntryStruct()
                    entry.fabricIndex = NSNumber(value: fabricIndex)
                    entry.authMode = NSNumber(value: authMode)
                    entry.privilege = NSNumber(value: 3)
                    entry.subjects = [NSNumber(value: catIdoperate)]
                    entries.append(entry)
                    self.writeAllACLAttributes(deviceId: deviceId, accessControlEntry: entries) { result in
                        completion()
                    }
                } else {
                    completion()
                }
            }
        } else {
            completion()
        }
    }
    
    /// Get matter device type list
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completionHandler: device type
    func getDeviceTypeList(deviceId: UInt64, completionHandler: @escaping (Int64?) -> Void) {
        getDescriptor(deviceId: deviceId, endPoint: 1) { desc in
            if let desc = desc {
                desc.readAttributeDeviceTypeList { values, error in
                    guard let _ = error else {
                        if let values = values as? [MTRDescriptorClusterDeviceTypeStruct], values.count > 0 {
                            let numberType = values[0].deviceType
                            let type = numberType.int64Value
                            if type != nil {
                                completionHandler(type)
                            } else {
                                completionHandler(nil)
                            }
                        } else {
                            completionHandler(nil)
                        }
                        return
                    }
                    completionHandler(nil)
                }
            }
        }
    }
    
    /// Get matter device type list
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completionHandler: device type
    func getAllDeviceTypeList(deviceId: UInt64, completionHandler: @escaping ([MTRDescriptorClusterDeviceTypeStruct]?) -> Void) {
        getDescriptor(deviceId: deviceId, endPoint: 1) { desc in
            if let desc = desc {
                desc.readAttributeDeviceTypeList { values, error in
                    guard let _ = error else {
                        if let values = values as? [MTRDescriptorClusterDeviceTypeStruct], values.count > 0 {
                            completionHandler(values)
                        } else {
                            completionHandler(nil)
                        }
                        return
                    }
                    completionHandler(nil)
                }
            }
        }
    }
}
#endif
