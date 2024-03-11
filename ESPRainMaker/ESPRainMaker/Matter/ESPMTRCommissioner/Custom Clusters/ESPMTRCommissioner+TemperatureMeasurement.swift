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
//  ESPMTRCommissioner+TemperatureMeasurement.swift
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
    func getTempMeasurementCluster(groupId: String, deviceId: UInt64, completion: @escaping (MTRBaseClusterTemperatureMeasurement?) -> Void) {
        let endpointClusterId = ESPMatterClusterUtil.shared.isTempMeasurementSupported(groupId: groupId, deviceId: deviceId)
        if let controller = sController, endpointClusterId.0 == true, let key = endpointClusterId.1, let endpoint = UInt16(key) {
            if let device = try? controller.getDeviceBeingCommissioned(deviceId) {
                if let cluster = MTRBaseClusterTemperatureMeasurement(device: device, endpoint: endpoint, queue: ESPMTRCommissioner.shared.matterQueue) {
                    completion(cluster)
                } else {
                    completion(nil)
                }
            } else {
                controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                    if let device = device, let cluster = MTRBaseClusterTemperatureMeasurement(device: device, endpoint: endpoint, queue: ESPMTRCommissioner.shared.matterQueue) {
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
    
    //MARK: Measured temperature
    
    /// Read local temp
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func readMeasuredTemperatureValue(groupId: String, deviceId: UInt64, completion: @escaping (Int16?) -> Void) {
        self.getTempMeasurementCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.readAttributeMaxMeasuredValue { val, error in
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
    func subscribeMeasuredTemperatureValue(groupId: String, deviceId: UInt64, completion: @escaping (Int16?) -> Void) {
        self.getTempMeasurementCluster(groupId: groupId, deviceId: deviceId) { cluster in
            if let cluster = cluster {
                cluster.subscribeAttributeMeasuredValue(withMinInterval: 1.0,
                                                        maxInterval: 2.0,
                                                        params: nil,
                                                        subscriptionEstablished: nil) { value, error in
                    guard let _ = error else {
                        if let value = value {
                            completion(value.int16Value/100)
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
}
#endif
