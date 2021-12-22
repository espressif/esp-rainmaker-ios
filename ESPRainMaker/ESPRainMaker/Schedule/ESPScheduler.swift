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
//  ESPScheduler.swift
//  ESPRainMaker
//
import Foundation
import UIKit

/// Enum with states for response from cloud regarding the param API response
enum ESPScheduleAPIResponseStatus {
    
    case success(Bool) //API success with flag giving info on whether some nodes failed or not true for success and false for no nodes failed
    case failure //API failure
}

class ESPScheduler {
    static let shared = ESPScheduler()
    var schedules: [String: ESPSchedule] = [:]
    var availableDevices: [String: Device] = [:]
    var currentSchedule: ESPSchedule!
    var currentScheduleKey: String!
    let apiManager = ESPAPIManager()
    
    // MARK constant strings:
    let nodeIdKey = "node_id"
    let payloadKey = "payload"
    let saveScheduleFailureMessage: String = "Unable to save schedule for"
    let editScheduleFailureMessage: String = "Unable to edit schedule for"
    let deleteScheduleFailureMessage: String = "Unable to delete schedule for"
    
    // Is date and name changed:
    var isDateChanged: Bool = false
    var isNameChanged: Bool = false

    // MARK: - Schedule Operations

    /// Save or edit schedule parameters for a particular Schedule.
    ///
    /// - Parameters:
    ///   - onView:UIView to show message in case of failure.
    ///   - completionHandler: Callback invoked after api response is recieved
    func saveSchedule(onView: UIView, completionHandler: @escaping (ESPScheduleAPIResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            var jsonString: [String: Any] = [:]
            jsonString["name"] = currentSchedule.name
            jsonString["id"] = currentSchedule.id
            jsonString["operation"] = currentSchedule.operation?.rawValue ?? "add"
            jsonString["triggers"] = [["d": currentSchedule.trigger.days!, "m": currentSchedule.trigger.minutes!]]
            let actions = createActionsFromDeviceList()
            if actions.keys.count > 0 {
                var actionsList = [[String: Any]]()
                actions.keys.forEach {
                    var deviceJSON: [String: Any] = [:]
                    actions[$0]!.forEach {
                        var actionJSON: [String: Any] = [:]
                        $0.params!.filter { $0.selected == true }
                                        .forEach { actionJSON[$0.name ?? ""] = $0.value }
                        deviceJSON[$0.name ?? ""] = actionJSON
                    }
                    jsonString["action"] = deviceJSON
                    let (scheduleKey, schedulesKey)  = getScheduleKeys(id: $0)
                    let payload = [scheduleKey: [schedulesKey: [jsonString]]]
                    actionsList.append([nodeIdKey: $0 as Any,
                                        payloadKey:  payload as Any])
                }
                callParamsAPIWithActions(list: actionsList, actions: actions, onView: onView, text: saveScheduleFailureMessage) { result  in
                    completionHandler(result)
                }
            } else {
                completionHandler(.failure)
            }
        } else {
            completionHandler(.failure)
        }
    }

    /// Enable/disable schedule from the list.
    ///
    /// - Parameters:
    ///   - onView:UIView to show message in case of failure.
    ///   - completionHandler: Callback invoked after api response is recieved
    func shouldEnableSchedule(onView: UIView, completionHandler: @escaping (ESPScheduleAPIResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            configureDeviceForCurrentSchedule()
            var jsonString: [String: Any] = [:]
            jsonString["id"] = currentSchedule.id
            jsonString["operation"] = currentSchedule.enabled == true ? "enable" : "disable"
            let actions = createActionsFromDeviceList()
            if actions.keys.count > 0 {
                var actionsList = [[String: Any]]()
                actions.keys.forEach {
                    let (scheduleKey, schedulesKey)  = getScheduleKeys(id: $0)
                    let payload = [scheduleKey: [schedulesKey: [jsonString]]]
                    actionsList.append([nodeIdKey: $0 as Any,
                                        payloadKey: payload as Any])
                }
                callParamsAPIWithActions(list: actionsList, actions: actions, onView: onView, text: editScheduleFailureMessage) { result  in
                    completionHandler(result)
                }
            } else {
                completionHandler(.failure)
            }
        } else {
            completionHandler(.failure)
        }
    }
    
    
    /// Delete nodes for a schedule
    /// - Parameters:
    ///   - key: schedule ID
    ///   - onView: UIView to show message in case of failure.
    ///   - nodeIDs: List of node IDs to be deleted
    ///   - completionHandler: Callback invoked after api response is recieved
    func deleteScheduleNodes(key: String, onView: UIView, nodeIDs: [String], completionHandler: @escaping (ESPScheduleAPIResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            if let schedule = ESPScheduler.shared.schedules[key] {
                var jsonString: [String: Any] = [:]
                jsonString["name"] = schedule.name
                jsonString["id"] = schedule.id
                jsonString["operation"] = "remove"
                var actionsList = [[String: Any]]()
                nodeIDs.forEach {
                    let (scheduleKey, schedulesKey)  = getScheduleKeys(id: $0)
                    let payload = [scheduleKey: [schedulesKey: [jsonString]]]
                    actionsList.append([nodeIdKey: $0 as Any,
                                        payloadKey: payload as Any])
                }
                callParamsAPIWithActions(list: actionsList, actions: schedule.actions, onView: onView, text: deleteScheduleFailureMessage) { result  in
                    completionHandler(result)
                }
            } else {
                completionHandler(.failure)
            }
        } else {
            completionHandler(.failure)
        }
    }

    /// Delete schedule from the list.
    ///
    /// - Parameters:
    ///   - onView:UIView to show message in case of failure.
    ///   - completionHandler: Callback invoked after api response is recieved
    func deleteScheduleAt(key: String, onView: UIView, completionHandler: @escaping (ESPScheduleAPIResponseStatus) -> Void) {
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            currentSchedule = ESPScheduler.shared.schedules[key]!
            configureDeviceForCurrentSchedule()
            var jsonString: [String: Any] = [:]
            jsonString["name"] = currentSchedule.name
            jsonString["id"] = currentSchedule.id
            jsonString["operation"] = "remove"
            var actionsList = [[String: Any]]()
            currentSchedule.actions.keys.forEach {
                let (scheduleKey, schedulesKey)  = getScheduleKeys(id: $0)
                let payload = [scheduleKey: [schedulesKey: [jsonString]]]
                actionsList.append([nodeIdKey: $0 as Any,
                                    payloadKey: payload as Any])
            }
            callParamsAPIWithActions(list: actionsList, actions: self.currentSchedule.actions, onView: onView, text: deleteScheduleFailureMessage) { result  in
                completionHandler(result)
            }
        } else {
            completionHandler(.failure)
        }
    }

    // MARK: - Conifguration Methods

    /// Add a new schedule.
    func addSchedule() {
        currentSchedule = ESPSchedule()
    }

    /// Remove each element from the schedule list and refetch.
    func refreshScheduleList() {
        ESPScheduler.shared.schedules.removeAll()
        availableDevices.removeAll()
        currentSchedule = nil
    }

    /// In list of available devices select param and update param values as given in the current schedule.
    func configureDeviceForCurrentSchedule() {
        resetAvailableDeviceStatus()
        if let schedule = ESPScheduler.shared.currentSchedule, schedule.actions.count > 0 {
            for key in schedule.actions.keys {
                for device in schedule.actions[key]! {
                    let id = [key, device.name].compactMap { $0 }.joined(separator: ".")
                    if let availableDevice = availableDevices[id], let params = device.params {
                        for param in params {
                            if let availableDeviceParam = availableDevice.params?.first(where: { $0.name == param.name }) {
                                availableDeviceParam.value = param.value
                                availableDeviceParam.selected = true
                                availableDevice.selectedParams += 1
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: -

    /// Creates list of Schedules from the schedule JSON of a particular node.
    ///
    /// - Parameters:
    ///   - nodeID:Node ID for which JSON is fetched.
    ///   - scheduleJSON: JSON containing schedule parameters for a particular node
    func saveScheduleListFromJSON(nodeID: String, scheduleJSON: [String: Any]) {
        let id = scheduleJSON["id"] as? String ?? ""

        let trigger = ESPTrigger()
        if let triggerJSON = scheduleJSON["triggers"] as? [[String: Any]] {
            let triggerDict = triggerJSON[0]
            trigger.days = triggerDict["d"] as? Int ?? 0
            trigger.minutes = triggerDict["m"] as? Int ?? 0
        }

        let enabled = scheduleJSON["enabled"] as? Int ?? 0 == 1 ? true : false
        let name = scheduleJSON["name"] as? String ?? ""

        var devices: [Device] = []
        let node = Node()
        node.node_id = nodeID

        let actionDict = scheduleJSON["action"] as? [String: Any] ?? [:]
        for key in actionDict.keys {
            let newDevice = Device()
            newDevice.name = key
            newDevice.node = node
            newDevice.params = []
            if let paramJSON = actionDict[key] as? [String: Any] {
                for paramKey in paramJSON.keys {
                    let newParam = Param()
                    newParam.name = paramKey
                    newParam.value = paramJSON[paramKey]
                    newDevice.params?.append(newParam)
                }
            }
            devices.append(newDevice)
        }

        // Same schedule id can have different value.
        // To properly define a single schedule we need to create a unique id based on the combination of each parameters.
        let key = "\(id).\(name).\(trigger.days!).\(trigger.minutes!).\(enabled)"

        // Check for existing schedule in the list for a given key
        if let existingSchedule = ESPScheduler.shared.schedules[key] {
            existingSchedule.actions[nodeID] = devices
        } else {
            // Create a new schedule object if no key is found on the list
            let newSchedule = ESPSchedule()
            newSchedule.id = id
            newSchedule.enabled = enabled
            newSchedule.name = name
            newSchedule.trigger = trigger
            newSchedule.week = ESPWeek(number: trigger.days ?? 0)
            newSchedule.actions[nodeID] = devices
            ESPScheduler.shared.schedules[key] = newSchedule
        }
    }

    /// Filters devices based on the capability of whether they support scheduling.
    ///
    /// - Parameters:
    ///   - nodeList: List of nodes. Each node contains devices and information of their services.
    func getAvailableDeviceWithScheduleCapability(nodeList: [Node]) {
        for node in nodeList {
            if node.isSchedulingSupported {
                if let devices = node.devices {
                    for device in devices {
                        let copyDevice = Device(device: device)
                        copyDevice.params = []
                        if let params = device.params {
                            for param in params {
                                if param.canBeScheduled {
                                    copyDevice.params?.append(Param(param: param))
                                }
                            }
                        }
                        if copyDevice.params!.count > 0 {
                            let key = [copyDevice.node?.node_id, copyDevice.name].compactMap { $0 }.joined(separator: ".")
                            ESPScheduler.shared.availableDevices[key] = copyDevice
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Call this method when there is an update in the device name.
    /// This method is needed to show updated names on the action list.
    func updateDeviceName(for nodeID: String?, name: String?, deviceName: String) {
        let key = [nodeID, name].compactMap { $0 }.joined(separator: ".")
        if let deviceExist = availableDevices[key] {
            deviceExist.deviceName = deviceName
        }
    }

    /// Gives list of devices under a schedule.
    ///
    /// - Returns: Comma seperated string of devices that are part of a particular schedule.
    func getActionList() -> String {
        var actionList: [String] = []
        for device in ESPScheduler.shared.availableDevices.values {
            if device.selectedParams > 0 {
                actionList.append(device.deviceName)
            }
        }
        if actionList.count > 0 {
            actionList = actionList.sorted(by: <)
            return actionList.compactMap { $0 }.joined(separator: ", ")
        } else {
            return ""
        }
    }

    // MARK: - Private Methods

    private func createActionsFromDeviceList() -> [String: [Device]] {
        var actions: [String: [Device]] = [:]
        for device in availableDevices.values {
            if device.selectedParams > 0 {
                if actions.keys.contains(device.node?.node_id ?? "") {
                    actions[device.node?.node_id ?? ""]!.append(device)
                } else {
                    actions[device.node?.node_id ?? ""] = [device]
                }
            }
        }
        return actions
    }

    /// Reset available devices parameter .
    private func resetAvailableDeviceStatus() {
        for device in availableDevices.values {
            device.selectedParams = 0
            device.collapsed = true
            if let params = device.params {
                for param in params {
                    param.selected = false
                }
            }
        }
    }
    
    /// Get device names of a node for which schedule operation is performed
    private func getDeviceListFromActions(action: [String: [Device]], forNodes nodes: [ESPCloudResponse]) -> String {
        var deviceNames: [String] = [String]()
        nodes.forEach {
            if let node_id = $0.node_id, let devices = action[node_id] {
                devices.forEach {
                    let key = [node_id, $0.name].compactMap { $0 }.joined(separator: ".")
                    if let availableDevice = availableDevices[key] {
                        deviceNames.append(availableDevice.deviceName)
                    } else {
                        deviceNames.append($0.name ?? "")
                    }
                }
            }
        }
        return deviceNames.joined(separator: ", ")
    }

    /// Get device names of a node for which schedule operation is performed
    private func getDeviceListFromAction(action: [String: [Device]], forKey: String) -> String {
        if let devices = action[forKey] {
            var deviceNames: [String] = []
            for device in devices {
                let key = [forKey, device.name].compactMap { $0 }.joined(separator: ".")
                if let availableDevice = availableDevices[key] {
                    deviceNames.append(availableDevice.deviceName)
                } else {
                    deviceNames.append(device.name ?? "")
                }
            }
            return deviceNames.joined(separator: ", ")
        }
        return forKey
    }
    
    /// Method returns the service & param name for schedules
    /// - Parameter id: node id
    /// - Returns: service name, param name
    private func getScheduleKeys(id: String) -> (String, String) {
        if let node = User.shared.getNode(id: id) {
            return (node.scheduleName, node.schedulesName)
        }
        return (Constants.scheduleKey, Constants.schedulesKey)
    }
    
    /// Call params API
    /// - Parameters:
    ///   - list: list of user actions
    ///   - actions: dictionary of node ids and their devices
    ///   - onView: UIView to show message in case of failure.
    ///   - text: error text to be shown
    ///   - completionHandler: Callback invoked after api response is recieved
    private func callParamsAPIWithActions(list: [[String: Any]], actions: [String: [Device]], onView: UIView, text: String, completionHandler: @escaping (ESPScheduleAPIResponseStatus) -> Void) {
        apiManager.setMultipleDeviceParam(parameter: list) { cloudResponse, error in
            if error == nil {
                self.handleResponse(cloudResponse: cloudResponse, actions: actions, onView: onView, errorText: text, completionHandler: completionHandler)
            } else {
                completionHandler(.failure)
            }
        }
    }
    
    /// Handle response from cloud
    /// - Parameters:
    ///   - cloudResponse: list of ESPCloudResponse objects
    ///   - actions: dictionary of node ids and their devices
    ///   - onView: UIView to show message in case of failure.
    ///   - errorText: error text to be shown
    ///   - completionHandler: Callback invoked after api response is recieved
    private func handleResponse(cloudResponse: [ESPCloudResponse]?, actions: [String: [Device]], onView: UIView, errorText: String, completionHandler: @escaping (ESPScheduleAPIResponseStatus) -> Void) {
        var failureString = ""
        if let response = cloudResponse, response.count > 0 {
            let (successResponse: successNodes, failureResponse: failedNodes) = ESPCloudResponseParser().getNodesWithStatus(response: response)
            if failedNodes.count > 0 {
                failureString = self.getDeviceListFromActions(action: actions, forNodes: failedNodes)
                Utility.showToastMessage(view: onView, message: "\(errorText) \(failureString)")
            }
            if successNodes.count > 0 {
                if failureString.count > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        completionHandler(.success(true))
                    }
                } else {
                    completionHandler(.success(false))
                }
            } else {
                completionHandler(.failure)
            }
        }
    }
}
