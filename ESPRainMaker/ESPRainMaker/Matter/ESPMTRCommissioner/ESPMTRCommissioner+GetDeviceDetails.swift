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
//  ESPMTRCommissioner+GetDeviceDetails.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Add matter device details locally
    /// - Parameters:
    ///   - writeCatIdOperate: should wite catId
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completionHandler: completion
    func addDeviceDetailsCatId(writeCatIdOperate: Bool = false, groupId: String, deviceId: UInt64, completionHandler: @escaping () -> Void) {
        if writeCatIdOperate {
            self.addCatIdOperate(deviceId: deviceId) {
                self.addDeviceDetails(groupId: groupId, deviceId: deviceId, completionHandler: completionHandler)
            }
        } else {
            self.addDeviceDetails(groupId: groupId, deviceId: deviceId, completionHandler: completionHandler)
        }
    }
    
    /// Add matter device details locally
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completionHandler: completion
    func addDeviceDetails(groupId: String, deviceId: UInt64, completionHandler: @escaping () -> Void) {
        self.getVendorId(deviceId: deviceId) { vid in
            if let vid = vid {
                ESPMatterFabricDetails.shared.saveVendorId(groupId: groupId, deviceId: deviceId, vendorId: vid)
            }
            self.getProductId(deviceId: deviceId) { pid in
                if let pid = pid {
                    ESPMatterFabricDetails.shared.saveProductId(groupId: groupId, deviceId: deviceId, productId: pid)
                }
                self.getSoftwareVersion(deviceId: deviceId) { sw in
                    if let sw = sw {
                        ESPMatterFabricDetails.shared.saveSoftwareVersion(groupId: groupId, deviceId: deviceId, softwareVersion: sw)
                    }
                    self.getDeviceTypeList(deviceId: deviceId) { deviceType in
                        if let type = deviceType {
                            ESPMatterFabricDetails.shared.saveDeviceType(groupId: groupId, deviceId: deviceId, type: type)
                        }
                        self.getAllDeviceEndpoints(deviceId: deviceId) { endpoints in
                            if endpoints.count > 0 {
                                ESPMatterFabricDetails.shared.saveEndpointsData(groupId: groupId, deviceId: deviceId, endpoints: endpoints)
                                self.getAllClients(deviceId: deviceId, index: 0, endpoints: endpoints) { clients in
                                    if clients.count > 0 {
                                        ESPMatterFabricDetails.shared.saveClientsData(groupId: groupId, deviceId: deviceId, clients: clients)
                                    }
                                    self.getAllServers(deviceId: deviceId, index: 0, endpoints: endpoints) { servers in
                                        if servers.count > 0 {
                                            ESPMatterFabricDetails.shared.saveServersData(groupId: groupId, deviceId: deviceId, servers: servers)
                                        }
                                        completionHandler()
                                    }
                                }
                            } else {
                                completionHandler()
                            }
                        }
                    }
                }
            }
        }
    }
}
#endif
