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
    private let fabricDetails = ESPMatterFabricDetails.shared
    
    /// Is a given client cluster supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - clusterId: cluster id
    /// - Returns: is client cluster supported
    public func isClientClusterSupported(groupId: String, deviceId: UInt64, clusterId: UInt) -> (Bool, String?) {
        let val = self.fabricDetails.fetchClientsData(groupId: groupId, deviceId: deviceId)
        for key in val.keys {
            if let list = val[key], list.count > 0, list.contains(clusterId) {
                return (true, key)
            }
        }
        return (false, nil)
    }
    
    /// Matter utility methods
    /// Is on/off client supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: flag
    public func isOnOffClientSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        let val = self.fabricDetails.fetchClientsData(groupId: groupId, deviceId: deviceId)
        for key in val.keys {
            if let list = val[key], list.count > 0, list.contains(onOff.clusterId.uintValue) {
                return (true, key)
            }
        }
        return (false, nil)
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
            if let list = val[key], list.count > 0, list.contains(binding.clusterId.uintValue) {
                endpointClusters[key] = binding.clusterId.uintValue
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
        return isServerClusterSupported(groupId: groupId, deviceId: deviceId, clusterId: onOff.clusterId.uintValue)
    }
    
    /// Is thread border router server supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: (status, endpoint id)
    public func isBRSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        return isServerClusterSupported(groupId: groupId, deviceId: deviceId, clusterId: borderRouter.clusterId.uintValue)
    }
    
    /// Is rainmaker server supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: is rainmaker supported
    public func isRainmakerServerSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        return isServerClusterSupported(groupId: groupId, deviceId: deviceId, clusterId: rainmaker.clusterId.uintValue)
    }
    
    /// Is level control server supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: (status, endpoint if)
    public func isLevelControlServerSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        return isServerClusterSupported(groupId: groupId, deviceId: deviceId, clusterId: levelControl.clusterId.uintValue)
    }
    
    /// Is color control server supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: (result, endpoint id)
    public func isColorControlServerSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        return isServerClusterSupported(groupId: groupId, deviceId: deviceId, clusterId: colorControl.clusterId.uintValue)
    }
    
    /// Is color control server supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: (result, endpoint id)
    public func isRainmakerControllerServerSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        return isServerClusterSupported(groupId: groupId, deviceId: deviceId, clusterId: rainmakerController.clusterId.uintValue)
    }
    
    /// Is open commissioning window supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: (result, endpoint id)
    public func isOpenCommissioningWindowSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        return isServerClusterSupported(groupId: groupId, deviceId: deviceId, clusterId: commissioningWindow.clusterId.uintValue)
    }

    /// Is temperature measurement supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: is temp measurement supported
    public func isTempMeasurementSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        return isServerClusterSupported(groupId: groupId, deviceId: deviceId, clusterId: temperatureMeasurement.clusterId.uintValue)
    }
    
    /// Is Participant Data Supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: (result, endpoint id)
    public func isParticipantDataSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        return isServerClusterSupported(groupId: groupId, deviceId: deviceId, clusterId: participantData.clusterId.uintValue)
    }
    
    /// Is air conditioner Supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: (result, endpoint id)
    public func isThermostatConditionerSupported(groupId: String, deviceId: UInt64) -> (Bool, String?) {
        return isServerClusterSupported(groupId: groupId, deviceId: deviceId, clusterId: thermostat.clusterId.uintValue)
    }
    
    /// Is on off attribute supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: is supported
    public func isOnOffAttributeSupported(groupId: String, deviceId: UInt64) -> Bool {
        return isAttributeSupported(groupId: groupId, deviceId: deviceId, clusterId: onOff.clusterIdString, attributeId: onOff.attributes.onOff.attributeId.uintValue)
    }
    
    /// Is current level attribute supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: is supported
    public func isCurrentLevelAttributeSupported(groupId: String, deviceId: UInt64) -> Bool {
        return isAttributeSupported(groupId: groupId, deviceId: deviceId, clusterId: levelControl.clusterIdString, attributeId: levelControl.attributes.currentLevel.attributeId.uintValue)
    }
    
    /// Is current hue attribute supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: is supported
    public func isCurrentHueAttributeSupported(groupId: String, deviceId: UInt64) -> Bool {
        return isAttributeSupported(groupId: groupId, deviceId: deviceId, clusterId: colorControl.clusterIdString, attributeId: colorControl.attributes.currentHue.attributeId.uintValue)
    }
    
    /// Is current saturation attribute supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: is supported
    public func isCurrentSaturationAttributeSupported(groupId: String, deviceId: UInt64) -> Bool {
        return isAttributeSupported(groupId: groupId, deviceId: deviceId, clusterId: colorControl.clusterIdString, attributeId: colorControl.attributes.currentSaturation.attributeId.uintValue)
    }
    
    /// Is local temperature attribute supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: is supported
    public func isLocalTemperatureAttributeSupported(groupId: String, deviceId: UInt64) -> Bool {
        return isAttributeSupported(groupId: groupId, deviceId: deviceId, clusterId: thermostat.clusterIdString, attributeId: thermostat.attributes.localtemperature.attributeId.uintValue)
    }
    
    /// Is temperature measurement
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: is measure value attribute supported
    public func isMeasuredValueAttributeSupported(groupId: String, deviceId: UInt64) -> Bool {
        return isAttributeSupported(groupId: groupId, deviceId: deviceId, clusterId: temperatureMeasurement.clusterIdString, attributeId: temperatureMeasurement.attributes.measuredValue.attributeId.uintValue)
    }
    
    /// Is node label attribute supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: is node label attribute supported
    public func isNodeLabelAttributeSupported(groupId: String, deviceId: UInt64) -> Bool {
        return isAttributeSupported(groupId: groupId, deviceId: deviceId, clusterId: basicInfomation.clusterIdString, attributeId: basicInfomation.attributes.nodeLabel.attributeId.uintValue)
    }
    
    /// Is server cluster for a cluster id is supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - clusterId: cluster id
    /// - Returns: (is cluster supported, endpoint id)
    public func isServerClusterSupported(groupId: String, deviceId: UInt64, clusterId: UInt) -> (Bool, String?) {
        let val = self.fabricDetails.fetchServersData(groupId: groupId, deviceId: deviceId)
        for key in val.keys {
            if let list = val[key], list.count > 0, list.contains(clusterId) {
                return (true, key)
            }
        }
        return (false, nil)
    }
    
    /// Is current level attribute supported
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    /// - Returns: is supported
    private func isAttributeSupported(groupId: String, deviceId: UInt64, clusterId: String, attributeId: UInt) -> Bool {
        let attributesData = self.fabricDetails.fetchAttributesData(groupId: groupId, deviceId: deviceId)
        if attributesData.count == 0 {
            return true
        }
        if let attributeIds = attributesData[clusterId] {
            for id in attributeIds {
                if id == attributeId {
                    return true
                }
            }
        }
        return false
    }
}
