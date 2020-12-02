// Copyright 2020 Espressif Systems
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
//  JSONParser.swift
//  ESPRainMaker
//
//  Created by Vikas Chandra on 18/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

struct JSONParser {
    /// Returns array of objects of Node  type
    ///
    /// Method to fetch accessToken of the signed-in user.
    /// Applicable when user is logged in with cognito id.
    ///
    /// - Parameters:
    ///   - data: node information in the form of JSON.
    static func parseNodeArray(data: [[String: Any]], forSingleNode: Bool) -> [Node]? {
        var singleDeviceNodeList: [Node] = []
        var multiDeviceNodeList: [Node] = []
        var nodeList: [Node] = []

        for node_details in data {
            var result: [Device] = []
            // Saving node related information
            let node = Node()
            node.node_id = node_details["id"] as? String

            if let config = node_details["config"] as? [String: Any] {
                if Configuration.shared.appConfiguration.supportSchedule { // Check whether scheduling is supported in the node
                    if let services = config["services"] as? [[String: Any]] {
                        for service in services {
                            if let type = service["type"] as? String, type == Constants.scheduleServiceType, let params = service["params"] as? [[String: Any]] {
                                for param in params {
                                    if let paramType = param["type"] as? String, paramType == Constants.scheduleParamType {
                                        node.isSchedulingSupported = true
                                    }
                                }
                            }
                        }
                    }
                }

                if let nodeInfo = config["info"] as? [String: String] {
                    node.info = Info(name: nodeInfo["name"], fw_version: nodeInfo["fw_version"], type: nodeInfo["type"])
                }
                node.config_version = config["config_version"] as? String
                if let attributeList = config["attributes"] as? [[String: Any]] {
                    node.attributes = []
                    for attributeItem in attributeList {
                        let attribute = Attribute()
                        attribute.name = attributeItem["name"] as? String
                        attribute.value = attributeItem["value"] as? String
                        node.attributes?.append(attribute)
                    }
                }

                if let devices = config["devices"] as? [[String: Any]] {
                    for item in devices {
                        let newDevice = Device()
                        newDevice.name = item["name"] as? String
                        newDevice.type = item["type"] as? String
                        newDevice.primary = item["primary"] as? String
                        newDevice.node = node

                        if let dynamicParams = item["params"] as? [[String: Any]] {
                            newDevice.params = []
                            for attr in dynamicParams {
                                let dynamicAttr = Param()
                                if let attrName = attr["name"] as? String {
                                    dynamicAttr.name = attrName
                                } else {
                                    dynamicAttr.name = attr["name"] as? String
                                }
                                dynamicAttr.uiType = attr["ui_type"] as? String
                                dynamicAttr.dataType = attr["data_type"] as? String
                                dynamicAttr.properties = attr["properties"] as? [String]
                                dynamicAttr.bounds = attr["bounds"] as? [String: Any]
                                dynamicAttr.type = attr["type"] as? String
                                dynamicAttr.valid_strs = attr["valid_strs"] as? [String]

                                if dynamicAttr.properties?.contains("write") ?? false {
                                    if dynamicAttr.type != Constants.deviceNameParam {
                                        dynamicAttr.canBeScheduled = true
                                    }
                                }

                                newDevice.params?.append(dynamicAttr)
                            }
                        }

                        if let staticParams = item["attributes"] as? [[String: Any]] {
                            newDevice.attributes = []
                            for attr in staticParams {
                                let staticAttr = Attribute()
                                staticAttr.name = attr["name"] as? String
                                staticAttr.value = attr["value"] as? String
                                newDevice.attributes?.append(staticAttr)
                            }
                        }
                        result.append(newDevice)
                    }
                }
                node.devices = result.sorted { $0.name! < $1.name! }
            }

            if let statusInfo = node_details["status"] as? [String: Any], let connectivity = statusInfo["connectivity"] as? [String: Any], let status = connectivity["connected"] as? Bool {
                node.isConnected = status
                node.timestamp = connectivity["timestamp"] as? Int ?? 0
            }

            if let paramInfo = node_details["params"] as? [String: Any], let devices = node.devices {
                for device in devices {
                    if let deviceName = device.name, let attributes = paramInfo[deviceName] as? [String: Any] {
                        device.deviceName = deviceName
                        if let params = device.params {
                            for index in params.indices {
                                if let reportedValue = attributes[params[index].name ?? ""] {
                                    if params[index].type == Constants.deviceNameParam {
                                        device.deviceName = reportedValue as? String ?? deviceName
                                    }
                                    params[index].value = reportedValue
                                }
                            }
                        }
                    }
                }

                if Configuration.shared.appConfiguration.supportSchedule {
                    if let schedule = paramInfo[Constants.scheduleKey] as? [String: Any], let schedules = schedule[Constants.schedulesKey] as? [[String: Any]] {
                        for scheduleJSON in schedules {
                            ESPScheduler.shared.saveScheduleListFromJSON(nodeID: node.node_id ?? "", scheduleJSON: scheduleJSON)
                        }
                    }
                }
            }
            if node.devices?.count == 1 {
                singleDeviceNodeList.append(node)
            } else {
                multiDeviceNodeList.append(node)
            }
        }
        nodeList.append(contentsOf: singleDeviceNodeList.sorted { $0.node_id! < $1.node_id! })
        nodeList.append(contentsOf: multiDeviceNodeList.sorted { $0.node_id! < $1.node_id! })
        if nodeList.isEmpty {
            return nil
        }
        if Configuration.shared.appConfiguration.supportSchedule {
            if !forSingleNode {
                ESPScheduler.shared.getAvailableDeviceWithScheduleCapability(nodeList: nodeList)
            }
        }
        return nodeList
    }
}
