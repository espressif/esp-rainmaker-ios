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

class ESPScheduler: CommonDeviceServicesProtocol {
    static let shared = ESPScheduler()
    var schedules: [String: ESPSchedule] = [:]
    var availableDevices: [String: Device] = [:]
    var currentSchedule: ESPSchedule!
    var currentScheduleKey: String!
    var apiManager = ESPAPIManager()
    /// List/cloud/BLE overlay must not rebuild `availableDevices` while the editor is on screen.
    var isEditorActive = false
    
    // MARK constant strings:
    let nodeIdKey = "node_id"
    let payloadKey = "payload"
    
    private init() {
        // Listen for configuration updates and reinitialize API manager
        NotificationCenter.default.addObserver(self, selector: #selector(configurationUpdated), name: NSNotification.Name(Constants.configurationUpdateNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func configurationUpdated() {
        // Reinitialize the API manager to pick up new server trust configuration
        apiManager = ESPAPIManager()
    }
    
    // MARK: - Schedule Operations

    /// Save or edit schedule parameters for a particular Schedule.
    ///
    /// - Parameters:
    ///   - onView:UIView to show message in case of failure.
    ///   - completionHandler: Callback invoked after api response is received
    func saveSchedule(onView: UIView, completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        let actions = createActionsFromDeviceList()
        if canReachNodesForServiceAction(nodeIds: Array(actions.keys)) {
            var jsonString: [String: Any] = [:]
            jsonString["name"] = currentSchedule.name
            jsonString["id"] = currentSchedule.id
            jsonString["operation"] = currentSchedule.operation?.rawValue ?? "add"
            jsonString["triggers"] = [["d": currentSchedule.trigger.days!, "m": currentSchedule.trigger.minutes!]]
            if actions.keys.count > 0 {
                var message = ESPScheduleConstants.scheduleUpdationPartialFailureMessage
                if let operation = currentSchedule.operation, operation == .add {
                    message = ESPScheduleConstants.scheduleCreationPartialFailureMessage
                }
                self.invokeServiceAction(apiManager: apiManager, keys: [String](actions.keys), jsonString: jsonString, text: message, nodeIdKey: nodeIdKey, payloadKey: payloadKey, actions: actions, availableDevices: availableDevices, serviceType: .schedule, isSave: true, onView: onView) { result in
                    if case .success = result {
                        self.currentSchedule.actions = actions
                    }
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
    ///   - completionHandler: Callback invoked after api response is received
    func shouldEnableSchedule(onView: UIView, completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        let nodeIds = [String](currentSchedule.actions.keys)
        if canReachNodesForServiceAction(nodeIds: nodeIds), !nodeIds.isEmpty {
            var jsonString: [String: Any] = [:]
            jsonString["id"] = currentSchedule.id
            jsonString["operation"] = currentSchedule.enabled == true ? "enable" : "disable"
            self.invokeServiceAction(apiManager: apiManager, keys: nodeIds, jsonString: jsonString, text: ESPScheduleConstants.scheduleUpdationPartialFailureMessage, nodeIdKey: nodeIdKey, payloadKey: payloadKey, actions: currentSchedule.actions, availableDevices: availableDevices, serviceType: .schedule, isSave: false, onView: onView) { result  in
                completionHandler(result)
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
    ///   - completionHandler: Callback invoked after api response is received
    func deleteScheduleNodes(key: String, onView: UIView, nodeIDs: [String], completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        if canReachNodesForServiceAction(nodeIds: nodeIDs) {
            if let schedule = ESPScheduler.shared.schedules[key] {
                var jsonString: [String: Any] = [:]
                jsonString["name"] = schedule.name
                jsonString["id"] = schedule.id
                jsonString["operation"] = "remove"
                self.invokeServiceAction(apiManager: apiManager, keys: nodeIDs, jsonString: jsonString, text: ESPScheduleConstants.scheduleDeletionPartialFailureMessage, nodeIdKey: nodeIdKey, payloadKey: payloadKey, actions: schedule.actions, availableDevices: availableDevices, serviceType: .schedule, isSave: false, onView: onView) { result  in
                    if case .success(let nodesFailed) = result, !nodesFailed {
                        self.removeScheduleNodesFromList(key: key, nodeIDs: nodeIDs)
                    }
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
    ///   - completionHandler: Callback invoked after api response is received
    func deleteScheduleAt(key: String, onView: UIView, completionHandler: @escaping (ESPServiceAPIResponseStatus) -> Void) {
        if canReachNodesForServiceAction(nodeIds: [String](ESPScheduler.shared.schedules[key]?.actions.keys ?? [:].keys)) {
            currentSchedule = ESPScheduler.shared.schedules[key]!
            configureDeviceForCurrentSchedule()
            var jsonString: [String: Any] = [:]
            jsonString["name"] = currentSchedule.name
            jsonString["id"] = currentSchedule.id
            jsonString["operation"] = "remove"
            self.invokeServiceAction(apiManager: apiManager, keys: [String](currentSchedule.actions.keys), jsonString: jsonString, text: ESPScheduleConstants.scheduleDeletionPartialFailureMessage, nodeIdKey: nodeIdKey, payloadKey: payloadKey, actions: self.currentSchedule.actions, availableDevices: availableDevices, serviceType: .schedule, isSave: false, onView: onView) { result  in
                if case .success(let nodesFailed) = result, !nodesFailed {
                    self.removeScheduleFromList(key: key)
                }
                completionHandler(result)
            }
        } else {
            completionHandler(.failure)
        }
    }

    // MARK: - Configuration Methods

    /// Add a new schedule.
    func addSchedule() {
        currentSchedule = ESPSchedule()
    }

    /// Remove each element from the schedule list and refetch.
    func refreshScheduleList() {
        guard !isEditorActive else { return }
        ESPScheduler.shared.schedules.removeAll()
        availableDevices.removeAll()
        currentSchedule = nil
    }

    /// Drop a node's actions so firmware ingest can replace stale cloud copies.
    func removeActions(forNodeId nodeId: String) {
        guard !isEditorActive else { return }
        var emptyKeys: [String] = []
        for (key, schedule) in schedules {
            schedule.actions.removeValue(forKey: nodeId)
            if schedule.actions.isEmpty {
                emptyKeys.append(key)
            }
        }
        for key in emptyKeys {
            schedules.removeValue(forKey: key)
            if currentScheduleKey == key {
                currentScheduleKey = nil
            }
        }
    }

    /// In list of available devices select param and update param values as given in the current schedule.
    func configureDeviceForCurrentSchedule() {
        resetAvailableDeviceStatus(availableDevices: &availableDevices)
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

    /// Keep the in-memory schedule after a BLE/local save, and write it to disk
    /// so BLE-only schedules survive an offline relaunch (cloud getNodes never saw them).
    func persistCurrentScheduleInList() {
        guard let schedule = currentSchedule,
              let id = schedule.id,
              let name = schedule.name else {
            return
        }
        schedule.actions = snapshotActionsFromAvailableDevices()
        let key = "\(id).\(name).\(schedule.trigger.days ?? 0).\(schedule.trigger.minutes ?? 0).\(schedule.enabled)"
        currentScheduleKey = key
        schedules[key] = schedule
        ESPLocalStorageHandler().saveSchedules(schedules: schedules)
    }

    /// Snapshot selected schedule actions from the current available-devices list.
    func snapshotActionsFromAvailableDevices() -> [String: [Device]] {
        var actions: [String: [Device]] = [:]
        for device in availableDevices.values where device.selectedParams > 0 {
            guard let nodeId = device.node?.node_id else { continue }
            let snapshot = Device(device: device)
            snapshot.node = device.node
            snapshot.selectedParams = device.selectedParams
            snapshot.params = device.params?.filter { $0.selected }.map { selected in
                let copy = Param(param: selected)
                copy.value = selected.value
                copy.selected = true
                return copy
            }
            if actions[nodeId] != nil {
                actions[nodeId]!.append(snapshot)
            } else {
                actions[nodeId] = [snapshot]
            }
        }
        return actions
    }

    /// Remove a deleted schedule from in-memory list and node schedule params (BLE local control parity).
    func removeScheduleFromList(key: String) {
        guard let schedule = schedules[key], let scheduleId = schedule.id else {
            schedules.removeValue(forKey: key)
            if currentScheduleKey == key {
                currentScheduleKey = nil
            }
            return
        }
        for nodeId in schedule.actions.keys {
            guard let node = User.shared.getNode(id: nodeId) else { continue }
            node.removeServiceEntry(id: scheduleId, kind: .schedule)
        }
        schedules.removeValue(forKey: key)
        if currentScheduleKey == key {
            currentScheduleKey = nil
        }
    }

    /// Remove node associations for a schedule; drop the schedule when no nodes remain.
    func removeScheduleNodesFromList(key: String, nodeIDs: [String]) {
        guard let schedule = schedules[key], let scheduleId = schedule.id else { return }
        for nodeId in nodeIDs {
            schedule.actions.removeValue(forKey: nodeId)
            User.shared.getNode(id: nodeId)?.removeServiceEntry(id: scheduleId, kind: .schedule)
        }
        if schedule.actions.isEmpty {
            schedules.removeValue(forKey: key)
            if currentScheduleKey == key {
                currentScheduleKey = nil
            }
        }
    }

    private func ingestSchedulesFromNode(_ node: Node) {
        guard node.isSchedulingSupported,
              let nodeId = node.node_id,
              let scheduleJSONList = node.serviceEntries(for: .schedule) else {
            return
        }
        for scheduleJSON in scheduleJSONList {
            saveScheduleListFromJSON(nodeID: nodeId, scheduleJSON: scheduleJSON)
        }
    }

    /// Creates list of Schedules from the schedule JSON of a particular node.
    ///
    /// - Parameters:
    ///   - nodeID:Node ID for which JSON is fetched.
    ///   - scheduleJSON: JSON containing schedule parameters for a particular node
    func saveScheduleListFromJSON(nodeID: String, scheduleJSON: [String: Any]) {
        guard !isEditorActive else { return }
        let id = scheduleJSON["id"] as? String ?? ""

        let trigger = ESPTrigger()
        if let triggerJSON = scheduleJSON["triggers"] as? [[String: Any]] {
            let triggerDict = triggerJSON[0]
            trigger.days = triggerDict["d"] as? Int ?? 0
            trigger.minutes = triggerDict["m"] as? Int ?? 0
        }

        let enabled: Bool
        if let intVal = scheduleJSON["enabled"] as? Int {
            enabled = intVal == 1
        } else {
            enabled = scheduleJSON["enabled"] as? Bool ?? false
        }
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
            if !devices.isEmpty {
                existingSchedule.actions[nodeID] = devices
            }
        } else {
            // Create a new schedule object if no key is found on the list
            let newSchedule = ESPSchedule()
            newSchedule.id = id
            newSchedule.enabled = enabled
            newSchedule.name = name
            newSchedule.trigger = trigger
            newSchedule.week = ESPWeek(number: trigger.days ?? 0)
            if !devices.isEmpty {
                newSchedule.actions[nodeID] = devices
            }
            ESPScheduler.shared.schedules[key] = newSchedule
        }
    }

    /// Filters devices based on the capability of whether they support scheduling.
    ///
    /// - Parameters:
    ///   - nodeList: List of nodes. Each node contains devices and information of their services.
    /// BLE-only: that node only. Wi-Fi: every Wi-Fi device that supports scheduling.
    @discardableResult
    func prepareAvailableDevices(for schedule: ESPSchedule?) -> Bool {
        let ble = detectAndConfigureBleSingleDeviceFlow(from: schedule)
        if !ble, let nodeList = User.shared.associatedNodeList {
            getAvailableDeviceWithScheduleCapability(nodeList: nodeList)
        }
        configureDeviceForCurrentSchedule()
        return ble
    }

    /// When editing a schedule tied to a BLE-only node, scope devices to that node only (Android parity).
    @discardableResult
    func detectAndConfigureBleSingleDeviceFlow(from schedule: ESPSchedule?) -> Bool {
        guard let schedule = schedule else { return false }
        return BleDeviceServiceFlow.detectSingleNodeScope(nodeIds: Array(schedule.actions.keys)) { nodeId in
            setAvailableDevicesForBleNode(nodeId: nodeId)
        }
    }

    func setAvailableDevicesForBleNode(nodeId: String) {
        BleDeviceServiceFlow.populateAvailableDevices(nodeId: nodeId, kind: .schedule, into: &availableDevices)
    }

    func getAvailableDeviceWithScheduleCapability(nodeList: [Node]) {
        guard !isEditorActive else { return }
        // Rebuild from scratch each time — otherwise a BLE-only node added via the single-device
        // flow (setAvailableDevicesForBleNode) would linger here forever, since the loop below only
        // skips *adding* excluded nodes, it never removes a stale entry left by a previous call.
        availableDevices.removeAll()
        for node in nodeList {
            ingestSchedulesFromNode(node)
            if BleDeviceServiceFlow.excludesFromMultiDevicePicker(node) {
                continue
            }
            if node.isSchedulingSupported {
                if let devices = node.devices {
                    for device in devices {
                        let copyDevice = Device(device: device)
                        copyDevice.params = []
                        if let params = device.params {
                            for param in params {
                                if param.canUseDeviceServices {
                                    copyDevice.params?.append(Param(param: param))
                                }
                            }
                        }
                        if copyDevice.params?.count ?? 0 > 0 {
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
    
    /// Device names for a schedule row. Uses the schedule's own actions so BLE-only
    /// nodes (excluded from the tab picker) still show a name.
    func actionList(for schedule: ESPSchedule) -> String {
        var names: [String] = []
        for (nodeId, devices) in schedule.actions {
            let node = User.shared.getNode(id: nodeId)
            for device in devices {
                if let liveName = node?.devices?.first(where: { $0.name == device.name })?.getDeviceName() {
                    names.append(liveName)
                } else if !device.deviceName.isEmpty {
                    names.append(device.deviceName)
                } else if let name = device.name {
                    names.append(name)
                }
            }
        }
        return names.sorted().joined(separator: ", ")
    }

    /// Gives list of devices under the current schedule from the shared picker map.
    ///
    /// - Returns: Comma separated string of devices that are part of a schedule
    func getActionList() -> String {
        return self.getActionList(availableDevices: availableDevices)
    }

    // MARK: - Private Methods

    /// Method returns dictionary with:
    ///  key: node ID
    ///  value: devices for which some  action has been selected for schedule
    ///
    /// - Returns: dictionary with above key and values
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
}
