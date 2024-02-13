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
//  ESPMTRCommissioner+GetAttributeDetails.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Get matter attributes
    /// - Parameters:
    ///   - groupID: group id
    ///   - deviceId: device id
    ///   - completionHandler: completion
    func getMatterAttributes(groupID: String, deviceId: UInt64, completionHandler: @escaping ([String: [UInt]]) -> Void) {
        self.attributesData = [String: [UInt]]()
        self.getOnOffAttributes(groupID: groupID, deviceId: deviceId) { onOffVal in
            if let onOffVal = onOffVal {
                self.attributesData[onOff.clusterIdString] = onOffVal
            }
            self.getLevelAttributes(groupID: groupID, deviceId: deviceId) { level in
                if let level = level {
                    self.attributesData[levelControl.clusterIdString] = level
                }
                self.getColorAttributes(groupID: groupID, deviceId: deviceId) { color in
                    if let color = color {
                        self.attributesData[colorControl.clusterIdString] = color
                    }
                    completionHandler(self.attributesData)
                }
            }
        }
    }
    
    /// Get On/Off cluster attributes
    /// - Parameters:
    ///   - groupID: group id
    ///   - deviceId: device id
    ///   - completionHadnler: completion
    func getOnOffAttributes(groupID: String, deviceId: UInt64, completionHandler: @escaping ([UInt]?) -> Void) {
        self.getOnOffCluster(groupId: groupID, deviceId: deviceId) { onOffCluster in
            if let onOffCluster = onOffCluster {
                onOffCluster.readAttributeAttributeList { attributesList, _ in
                    if let attributesList = attributesList as? [UInt] {
                        completionHandler(attributesList)
                    } else {
                        completionHandler(nil)
                    }
                }
            } else {
                completionHandler(nil)
            }
        }
    }
    
    /// Get level control cluster attributes
    /// - Parameters:
    ///   - groupID: group id
    ///   - deviceId: device id
    ///   - completionHadnler: completion
    func getLevelAttributes(groupID: String, deviceId: UInt64, completionHandler: @escaping ([UInt]?) -> Void) {
        self.getLevelController(timeout: 10.0, groupId: groupID, deviceId: deviceId) { levelControl in
            if let levelControl = levelControl {
                levelControl.readAttributeAttributeList { attributesList, _ in
                    if let attributesList = attributesList as? [UInt] {
                        completionHandler(attributesList)
                    } else {
                        completionHandler(nil)
                    }
                }
            } else {
                completionHandler(nil)
            }
        }
    }
    
    /// Get color control cluster attributes
    /// - Parameters:
    ///   - groupID: group id
    ///   - deviceId: device id
    ///   - completionHadnler: completion
    func getColorAttributes(groupID: String, deviceId: UInt64, completionHandler: @escaping ([UInt]?) -> Void) {
        self.getColorCluster(timeout: 10.0, groupId: groupID, deviceId: deviceId) { colorControl in
            if let colorControl = colorControl {
                colorControl.readAttributeAttributeList { attributesList, _ in
                    if let attributesList = attributesList as? [UInt] {
                        completionHandler(attributesList)
                    } else {
                        completionHandler(nil)
                    }
                }
            } else {
                completionHandler(nil)
            }
        }
    }
}
#endif
