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
//  ESPMatterClusterUtil.swift
//  ESPRainmaker
//

import Foundation

public class ESPMatterClusterUtil {
    
    public static let shared = ESPMatterClusterUtil()
    private let onOffClusterId: UInt = 6
    private let levelControlClusterId: UInt = 8
    private let colorControlClusterId: UInt = 768
    private let commissioningWindowClusterId: UInt = 60
    private let bindingClusterId: UInt = 30
    let fabricDetails = ESPMatterFabricDetails.shared
    
    /// Matter utility methods
    /// Is on/off client supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: flag
    public func isOnOffClientSupported(groupId: String, deviceId: UInt64) -> Bool {
        let val = self.fabricDetails.fetchClientsData(groupId: groupId, deviceId: deviceId)
        for key in val.keys {
            if let list = val[key], list.count > 0, list.contains(onOffClusterId) {
                return true
            }
        }
        return false
    }
    
    /// fetch on off clients
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: [endpoint id: cluster id]
    public func fetchOnOffClients(groupId: String, deviceId: UInt64) -> [String: UInt] {
        let val = self.fabricDetails.fetchClientsData(groupId: groupId, deviceId: deviceId)
        var endpointClusters: [String: UInt] = [String: UInt]()
        for key in val.keys {
            if let list = val[key], list.count > 0, list.contains(onOffClusterId) {
                endpointClusters[key] = onOffClusterId
            }
        }
        return endpointClusters
    }
    
    /// fetch binding servers
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: [endpoint id: cluster id]]
    public func fetchBindingServers(groupId: String, deviceId: UInt64) -> [String: UInt] {
        let val = self.fabricDetails.fetchServersData(groupId: groupId, deviceId: deviceId)
        var endpointClusters: [String: UInt] = [String: UInt]()
        for key in val.keys {
            if let list = val[key], list.count > 0, list.contains(bindingClusterId) {
                endpointClusters[key] = bindingClusterId
            }
        }
        return endpointClusters
    }
    
    /// Is on off server supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: (status, endpoint id)
    public func isOnOffServerSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        let val = self.fabricDetails.fetchServersData(groupId: groupId, deviceId: deviceId)
        for key in val.keys {
            if let list = val[key], list.count > 0, list.contains(onOffClusterId) {
                return (true, key)
            }
        }
        return (false, nil)
    }
    
    /// Is rainmaker server supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: is rainmaker supported
    public func isRainmakerServerSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        let val = self.fabricDetails.fetchServersData(groupId: groupId, deviceId: deviceId)
        for key in val.keys {
            if let list = val[key], list.count > 0, list.contains(rainmaker.clusterId.uintValue) {
                return (true, key)
            }
        }
        return (false, nil)
    }
    
    /// Is level control server supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: (status, endpoint if)
    public func isLevelControlServerSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        let val = self.fabricDetails.fetchServersData(groupId: groupId, deviceId: deviceId)
        for key in val.keys {
            if let list = val[key], list.count > 0, list.contains(levelControlClusterId) {
                return (true, key)
            }
        }
        return (false, nil)
    }
    
    /// Is color control server supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: (result, endpoint id)
    public func isColorControlServerSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        let val = self.fabricDetails.fetchServersData(groupId: groupId, deviceId: deviceId)
        for key in val.keys {
            if let list = val[key], list.count > 0, list.contains(colorControlClusterId) {
                return (true, key)
            }
        }
        return (false, nil)
    }
    
    /// Is color control server supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: (result, endpoint id)
    public func isRainmakerControllerServerSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        let val = self.fabricDetails.fetchServersData(groupId: groupId, deviceId: deviceId)
        for key in val.keys {
            if let list = val[key], list.count > 0, list.contains(ESPMatterConstants.controllerClusterId) {
                return (true, key)
            }
        }
        return (false, nil)
    }
    
    /// Is open commissioning window supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: (result, endpoint id)
    public func isOpenCommissioningWindowSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        let val = self.fabricDetails.fetchServersData(groupId: groupId, deviceId: deviceId)
        for key in val.keys {
            if let list = val[key], list.count > 0, list.contains(commissioningWindowClusterId) {
                return (true, key)
            }
        }
        return (false, nil)
    }
}
