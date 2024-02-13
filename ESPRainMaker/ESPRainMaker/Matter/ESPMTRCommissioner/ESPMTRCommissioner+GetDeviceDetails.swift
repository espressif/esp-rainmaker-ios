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
        //Read and save vendor id
        self.getVendorId(deviceId: deviceId) { vid in
            if let vid = vid {
                self.fabricDetails.saveVendorId(groupId: groupId, deviceId: deviceId, vendorId: vid)
            }
            //Read and save device serial number
            self.getDeviceSerialNumber(deviceId: deviceId) { serialNumber in
                if let serialNumber = serialNumber {
                    self.fabricDetails.saveSerialNumber(groupId: groupId, deviceId: deviceId, serialNumber: serialNumber)
                }
                //Read and save manufacturer name
                self.getManufacturerName(deviceId: deviceId) { manufacturerName in
                    if let manufacturerName = manufacturerName {
                        self.fabricDetails.saveManufacturerName(groupId: groupId, deviceId: deviceId, manufacturerName: manufacturerName)
                    }
                    //Read and save product name
                    self.getProductName(deviceId: deviceId) { productName in
                        if let productName = productName {
                            self.fabricDetails.saveProductName(groupId: groupId, deviceId: deviceId, productName: productName)
                        }
                        //Read and save product id
                        self.getProductId(deviceId: deviceId) { pid in
                            if let pid = pid {
                                self.fabricDetails.saveProductId(groupId: groupId, deviceId: deviceId, productId: pid)
                            }
                            //Read and save software version
                            self.getSoftwareVersionString(deviceId: deviceId) { swString in
                                if let swString = swString {
                                    self.fabricDetails.saveSoftwareVersionString(groupId: groupId, deviceId: deviceId, softwareVersionString: swString)
                                }
                                self.getSoftwareVersion(deviceId: deviceId) { sw in
                                    if let sw = sw {
                                        self.fabricDetails.saveSoftwareVersion(groupId: groupId, deviceId: deviceId, softwareVersion: sw)
                                    }
                                    //Read and save device type
                                    self.getDeviceTypeList(deviceId: deviceId) { deviceType in
                                        if let type = deviceType {
                                            self.fabricDetails.saveDeviceType(groupId: groupId, deviceId: deviceId, type: type)
                                        }
                                        //Read and save all device endpoints
                                        self.getAllDeviceEndpoints(deviceId: deviceId) { endpoints in
                                            if endpoints.count > 0 {
                                                self.fabricDetails.saveEndpointsData(groupId: groupId, deviceId: deviceId, endpoints: endpoints)
                                                //Read and save all clients on all endpoints
                                                self.getAllClients(deviceId: deviceId, index: 0, endpoints: endpoints) { clients in
                                                    if clients.count > 0 {
                                                        self.fabricDetails.saveClientsData(groupId: groupId, deviceId: deviceId, clients: clients)
                                                    }
                                                    //Read and save all servers on all endpoints
                                                    self.getAllServers(deviceId: deviceId, index: 0, endpoints: endpoints) { servers in
                                                        if servers.count > 0 {
                                                            self.fabricDetails.saveServersData(groupId: groupId, deviceId: deviceId, servers: servers)
                                                        }
                                                        //Read and save all attributes on all endpoints
                                                        self.getMatterAttributes(groupID: groupId, deviceId: deviceId) { attributes in
                                                            if attributes.count > 0 {
                                                                self.fabricDetails.saveAttributesData(groupId: groupId, deviceId: deviceId, attributes: attributes)
                                                            }
                                                            completionHandler()
                                                        }
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
            }
        }
    }
}
#endif
