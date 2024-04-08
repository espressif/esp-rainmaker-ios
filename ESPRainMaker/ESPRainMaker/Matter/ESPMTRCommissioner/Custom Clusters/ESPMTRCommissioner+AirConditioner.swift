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
//  ESPMTRCommissioner+AirConditioner.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Get thermostat cluster
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion (cluster)
    func getThermostatCluster(groupId: String, deviceId: UInt64, completion: @escaping (MTRBaseClusterThermostat?) -> Void) {
        let endpointClusterId = ESPMatterClusterUtil.shared.isThermostatConditionerSupported(groupId: groupId, deviceId: deviceId)
        if let controller = sController, endpointClusterId.0 == true, let key = endpointClusterId.1, let endpoint = UInt16(key) {
            if let device = try? controller.getDeviceBeingCommissioned(deviceId) {
                if let cluster = MTRBaseClusterThermostat(device: device, endpoint: endpoint, queue: ESPMTRCommissioner.shared.matterQueue) {
                    completion(cluster)
                } else {
                    completion(nil)
                }
            } else {
                controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                    if let device = device, let cluster = MTRBaseClusterThermostat(device: device, endpoint: endpoint, queue: ESPMTRCommissioner.shared.matterQueue) {
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
    
    //MARK: Local temperature
    
    /// Read local temp
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func readLocalTemperature(groupId: String, deviceId: UInt64, completion: @escaping (Int16?) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeLocalTemperature { val, error in
                    guard let _ = error else {
                        if let val = val {
                            completion(val.int16Value/100)
                        }
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Subscribe to local temperature
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func subscribeLocalTemperature(groupId: String, deviceId: UInt64, completion: @escaping (Int16?) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.subscribeAttributeLocalTemperature(withMinInterval: 1.0,
                                                           maxInterval: 2.0,
                                                           params: nil,
                                                           subscriptionEstablished: nil) { value, error in
                    guard let _ = error else {
                        if let value = value {
                            completion(value.int16Value/100)
                        } else {
                            completion(nil)
                        }
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    //MARK: Contol sequence of operation
    
    /// Get control sequence of operation
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func readControlSequenceOfOperation(groupId: String, deviceId: UInt64, completion: @escaping (NSNumber?) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeControlSequenceOfOperation { value, error in
                    guard let error = error else {
                        completion(value)
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Set control sequence of operation
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - cos: control sequence of operation
    ///   - completion: completion
    func setControlSequenceOfOperation(groupId: String, deviceId: UInt64, cos: NSNumber, completion: @escaping (Bool) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.writeAttributeControlSequenceOfOperation(withValue: cos) { error in
                    guard let error = error else {
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
    
    /// Subscribe control sequence of operation
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func subscribeControlSequenceOfOperation(groupId: String, deviceId: UInt64, completion: @escaping (NSNumber?) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.subscribeAttributeControlSequenceOfOperation(withMinInterval: 1.0,
                                                                     maxInterval: 5.0,
                                                                     params: nil,
                                                                     subscriptionEstablished: nil) { value, error in
                    guard let _ = error else {
                        completion(value)
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    //MARK: System mode
    
    /// get system mode
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func readSystemMode(groupId: String, deviceId: UInt64, completion: @escaping (NSNumber?) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeSystemMode { val, error in
                    guard let error = error else {
                        completion(val)
                        return
                    }
                    completion(nil)
                }
            } else {
                
            }
        }
    }
    
    /// Set system mode
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - mode: mode
    ///   - completion: completion
    func setSystemMode(groupId: String, deviceId: UInt64, mode: NSNumber, completion: @escaping (Bool) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.writeAttributeSystemMode(withValue: mode) { error in
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
    
    func subscribeSystemMode(groupId: String, deviceId: UInt64, completion: @escaping (NSNumber?) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.subscribeAttributeSystemMode(withMinInterval: 1.0,
                                                     maxInterval: 5.0,
                                                     params: nil,
                                                     subscriptionEstablished: nil) { value, error in
                    guard let _ = error else {
                        completion(value)
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    //MARK: occupied cooling setpoint
    
    /// Read occupied cooling setpoint
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func readOccupiedCoolingSetpoint(groupId: String, deviceId: UInt64, completion: @escaping (Int16?) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeOccupiedCoolingSetpoint { value, error in
                    guard let _ = error else {
                        if let value = value {
                            completion(value.int16Value/100)
                        } else {
                            completion(nil)
                        }
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Set occupied cooling setpoint
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - ocs: occupied cooling setpoint
    ///   - completion: completion
    func setOccupiedCoolingSetpoint(groupId: String, deviceId: UInt64, ocs: NSNumber, completion: @escaping (Bool) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.writeAttributeOccupiedCoolingSetpoint(withValue: ocs) { error in
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
    
    /// Subscribe to occupied cooling setpoint
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func subscribeToOccupiedCoolingSetpoint(groupId: String, deviceId: UInt64, completion: @escaping (Int16?) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.subscribeAttributeOccupiedCoolingSetpoint(withMinInterval: 1.0, 
                                                                  maxInterval: 5.0, 
                                                                  params: nil,
                                                                  subscriptionEstablished: nil) { val, error in
                    guard let _ = error else {
                        if let val = val {
                            completion(val.int16Value/100)
                        } else {
                            completion(nil)
                        }
                        return
                    }
                    completion(nil)
                }
            }
        }
    }
    
    //MARK: occupied heating setpoint
    
    /// Read occupied heating setpoint
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func readOccupiedHeatingSetpoint(groupId: String, deviceId: UInt64, completion: @escaping (Int16?) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeOccupiedHeatingSetpoint { value, error in
                    guard let _ = error else {
                        if let value = value {
                            completion(value.int16Value/100)
                        } else {
                            completion(nil)
                        }
                        return
                    }
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Set occupied heating setpoint
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - ocs: occupied heating setpoint
    ///   - completion: completion
    func setOccupiedHeatingSetpoint(groupId: String, deviceId: UInt64, ocs: NSNumber, completion: @escaping (Bool) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.writeAttributeOccupiedHeatingSetpoint(withValue: ocs) { error in
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
    
    /// Subscribe to occupied cooling setpoint
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func subscribeToOccupiedHeatingSetpoint(groupId: String, deviceId: UInt64, completion: @escaping (Int16?) -> Void) {
        self.getThermostatCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.subscribeAttributeOccupiedHeatingSetpoint(withMinInterval: 1.0,
                                                                  maxInterval: 5.0,
                                                                  params: nil,
                                                                  subscriptionEstablished: nil) { val, error in
                    guard let _ = error else {
                        if let val = val {
                            completion(val.int16Value/100)
                        } else {
                            completion(nil)
                        }
                        return
                    }
                    completion(nil)
                }
            }
        }
    }
}
#endif
