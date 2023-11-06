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
//  ESPMTRCommissioner+ParticipantData.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Update participant badge data on matter device
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoint: endpoint
    ///   - data: participant badge data
    ///   - completion: completion handler
    func sendParticipantData(deviceId: UInt64, endpoint: UInt16, data: ESPParticipantData, completion: @escaping (Bool) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                var properties = [[String: Any]]()
                if let name = data.name {
                    let data = [ESPMatterConstants.type: ESPMatterConstants.UTF8String,
                                ESPMatterConstants.value: name]
                    let property: [String: Any] = [ESPMatterConstants.contextTag: 0,
                                    ESPMatterConstants.data: data]
                    properties.append(property)
                }
                if let companyName = data.companyName {
                    let data = [ESPMatterConstants.type: ESPMatterConstants.UTF8String,
                                ESPMatterConstants.value: companyName]
                    let property: [String: Any] = [ESPMatterConstants.contextTag: 1,
                                    ESPMatterConstants.data: data]
                    properties.append(property)
                }
                if let email = data.email {
                    let data = [ESPMatterConstants.type: ESPMatterConstants.UTF8String,
                                ESPMatterConstants.value: email]
                    let property: [String: Any] = [ESPMatterConstants.contextTag: 2,
                                    ESPMatterConstants.data: data]
                    properties.append(property)
                }
                if let contact = data.contact {
                    let data = [ESPMatterConstants.type: ESPMatterConstants.UTF8String,
                                ESPMatterConstants.value: contact]
                    let property: [String: Any] = [ESPMatterConstants.contextTag: 3,
                                    ESPMatterConstants.data: data]
                    properties.append(property)
                }
                if let eventName = data.eventName {
                    let data = [ESPMatterConstants.type: ESPMatterConstants.UTF8String,
                                ESPMatterConstants.value: eventName]
                    let property: [String: Any] = [ESPMatterConstants.contextTag: 4,
                                    ESPMatterConstants.data: data]
                    properties.append(property)
                }
                let finalPayload = [ESPMatterConstants.type: ESPMatterConstants.structure,
                                    ESPMatterConstants.value: properties]
                device.invokeCommand(withEndpointID: NSNumber(value: endpoint),
                                     clusterID: participantData.clusterId,
                                     commandID: participantData.commands.sendData.commandId,
                                     commandFields: finalPayload as Any,
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
    
    /// Read attribute participant name
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoint: endpoint
    ///   - completion: completion handler
    func readAttributeParticipantName(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (String?) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                device.readAttributes(withEndpointID: NSNumber(value: endpoint),
                                      clusterID: participantData.clusterId,
                                      attributeID: participantData.attributes.name.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
                    if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let name = data[ESPMatterConstants.value] as? String {
                        completion(name)
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Read attribute participant company name
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoint: endpoint
    ///   - completion: completion handler
    func readAttributeParticipantCompanyName(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (String?) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                device.readAttributes(withEndpointID: NSNumber(value: endpoint),
                                      clusterID: participantData.clusterId,
                                      attributeID: participantData.attributes.companyName.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
                    if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let companyName = data[ESPMatterConstants.value] as? String {
                        completion(companyName)
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Read attribute participant email
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoint: endpoint
    ///   - completion: completion handler
    func readAttributeParticipantEmail(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (String?) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                device.readAttributes(withEndpointID: NSNumber(value: endpoint),
                                      clusterID: participantData.clusterId,
                                      attributeID: participantData.attributes.email.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
                    if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let email = data[ESPMatterConstants.value] as? String {
                        completion(email)
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Read attribute participant contact
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoint: endpoint
    ///   - completion: completion handler
    func readAttributeParticipantContact(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (String?) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                device.readAttributes(withEndpointID: NSNumber(value: endpoint),
                                      clusterID: participantData.clusterId,
                                      attributeID: participantData.attributes.contact.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
                    if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let contact = data[ESPMatterConstants.value] as? String {
                        completion(contact)
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Read attribute participant contact
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoint: endpoint
    ///   - completion: completion handler
    func readAttributeParticipantEventName(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (String?) -> Void) {
        getMatterDevice(deviceId: deviceId) { device in
            if let device = device {
                device.readAttributes(withEndpointID: NSNumber(value: endpoint),
                                      clusterID: participantData.clusterId,
                                      attributeID: participantData.attributes.eventName.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
                    if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let eventName = data[ESPMatterConstants.value] as? String {
                        completion(eventName)
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Read all participant data
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoint: endpoint
    ///   - completion: completion
    func readParticipantData(deviceId: UInt64, endpoint: UInt16, completion: @escaping (ESPParticipantData?) -> Void) {
        var participantData: ESPParticipantData?
        self.readAttributeParticipantName(deviceId: deviceId, endpoint: endpoint) { name in
            if let name = name {
                if participantData == nil {
                    participantData = ESPParticipantData()
                }
                participantData?.name = name
            }
            self.readAttributeParticipantCompanyName(deviceId: deviceId, endpoint: endpoint) { companyName in
                if let companyName = companyName {
                    if participantData == nil {
                        participantData = ESPParticipantData()
                    }
                    participantData?.companyName = companyName
                }
                self.readAttributeParticipantEmail(deviceId: deviceId, endpoint: endpoint) { email in
                    if let email = email {
                        if participantData == nil {
                            participantData = ESPParticipantData()
                        }
                        participantData?.email = email
                    }
                    self.readAttributeParticipantContact(deviceId: deviceId, endpoint: endpoint) { contact in
                        if let contact = contact {
                            if participantData == nil {
                                participantData = ESPParticipantData()
                            }
                            participantData?.contact = contact
                        }
                        self.readAttributeParticipantEventName(deviceId: deviceId, endpoint: endpoint) { eventName in
                            if let eventName = eventName {
                                if participantData == nil {
                                    participantData = ESPParticipantData()
                                }
                                participantData?.eventName = eventName
                            }
                            completion(participantData)
                        }
                    }
                }
            }
        }
    }
}
#endif
