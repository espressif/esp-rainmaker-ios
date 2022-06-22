// Copyright 2022 Espressif Systems
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
//  AutomationSelectDeviceVC.swift
//  ESPRainMaker
//

import UIKit

protocol ESPAddAutomationDelegate {
    func addAutomationFinishedWith(automation: ESPAutomationTriggerAction?, error: ESPAPIError?)
}

class AutomationSelectDeviceVC: UIViewController, SelectDeviceActionCellDelegate, ScheduleActionDelegate {
    
    
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var devicesTableView: UITableView!
    @IBOutlet weak var rightBarButton: UIButton!
    
    private var listUserDeviceService: ESPListUserDeviceService?
    private var addAutomationService: ESPAddAutomationService?
    private var actionDevices:[Device]?
    
    static let storyboardID = "automationSelectDeviceVC"
    
    var automationTrigger: ESPAutomationTriggerAction?
    var isEditFlow = false
    var editAutomationVC: EditAutomationViewController?
    var addAutomationDelegate: ESPAddAutomationDelegate?
    
    // MARK: - Overriden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        addAutomationService = ESPAddAutomationService(presenter: self)
        listUserDeviceService = ESPListUserDeviceService(presenter: self)
        listUserDeviceService?.getListOfDevicesForActions(nodes: User.shared.associatedNodeList)
        
        if isEditFlow {
            rightBarButton.setTitle("Done", for: .normal)
        } else {
            rightBarButton.setTitle("Save", for: .normal)
        }
        enableSaveButton()
    }
    
    // MARK: - IB Actions
    
    @IBAction func cancelPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func savePressed(_ sender: Any) {
        var actions:[ESPAutomationAction] = []
        if let devices = actionDevices?.filter({ $0.selectedParams > 0 }) {
            for device in devices {
                if let params = device.params?.filter({ $0.selected == true}) {
                    var action = ESPAutomationAction(nodeID: device.node?.node_id ?? "", params: nil)
                    var paramsJSON:[String:Any] = [:]
                    for param in params {
                        paramsJSON[param.name ?? ""] = param.value
                    }
                    action.params = [device.name ?? "":paramsJSON]
                    actions.append(action)
                }
            }
        }
        automationTrigger?.actions = actions
        if isEditFlow {
            editAutomationVC?.automationTrigger = automationTrigger
            editAutomationVC?.refreshTableView()
            navigationController?.popViewController(animated: true)
        } else {
            if let automationTrigger = automationTrigger {
                Utility.showLoader(message: "", view: view)
                addAutomationService?.addNewAutomation(automationTrigger)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialUI() {
        eventLabel.text = "Event: " + (automationTrigger?.getEventDescription(nodes: User.shared.associatedNodeList ?? []) ?? "")
        self.navigationItem.hidesBackButton = true
        self.registerCells(devicesTableView)
        self.devicesTableView.reloadData()
    }
    
    private func updateDeviceSelection() {
        for action in automationTrigger?.actions ?? [] {
            if let nodeID = action.nodeID, let devices = actionDevices?.filter({ $0.node?.node_id == nodeID}) {
                for (key, value) in action.params ?? [:] {
                    if let device = devices.first(where: { $0.name == key}) {
                        for (key, value) in value {
                            if let param = device.params?.first(where: { $0.name == key}) {
                                param.selected = true
                                param.value = value
                                device.selectedParams += 1
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getLabelForEvent() -> String {
        if let event = automationTrigger?.events?.first, let param = event[ESPAutomationConstants.params] as? [String:Any], var check = event[ESPAutomationConstants.check] as? String {
            for (_, value) in param {
                if let value = value as? [String:Any] {
                    for (key, value) in value {
                        check = check == "==" ? ":":check
                        return key + check + "\(value)"
                    }
                }
            }
        }
        return ""
    }
    
    private func enableSaveButton() {
        if let selectedDevice = actionDevices?.filter({ $0.selectedParams > 0 }), selectedDevice.count > 0 {
            rightBarButton.isHidden = false
        } else {
            rightBarButton.isHidden = true
        }
    }
    
    // MARK: - ScheduleActionDelegate

    func takeScheduleNotAllowedAction(action _: ScheduleActionStatus) {}

    func headerViewDidTappedFor(section: Int) {
        actionDevices?[section].collapsed = !(actionDevices?[section].collapsed ?? false)
        devicesTableView.reloadSections(IndexSet(arrayLiteral: section), with: .automatic)
        enableSaveButton()
    }

    func paramStateChangedat(indexPath: IndexPath) {
        devicesTableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
        enableSaveButton()
    }

    func expandSection(expand: Bool, section: Int) {
        actionDevices?[section].collapsed = !expand
        devicesTableView.reloadSections(IndexSet(arrayLiteral: section), with: .automatic)
    }
}

extension AutomationSelectDeviceVC: UITableViewDelegate {
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 60.5
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 25.0
    }
}

extension AutomationSelectDeviceVC: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if actionDevices?[section].collapsed ?? true {
            return 0
        }
        return actionDevices?[section].params?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = getTableViewCellBasedOn(tableView: tableView, availableDeviceCopy: actionDevices, serviceType: .automation, scheduleDelegate: self, indexPath: indexPath)
        cell.borderWidth = 0.5
        cell.borderColor = .lightGray
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "deviceHV") as! DeviceHeaderView
        if let device = actionDevices?[section] {
            headerView.cellType = .automation
            headerView.deviceLabel.text = device.deviceName
            headerView.section = section
            headerView.device = device
            headerView.delegate = self
            if device.collapsed {
                headerView.arrowImageView.image = UIImage(named: "right_arrow")
            } else {
                headerView.arrowImageView.image = UIImage(named: "down_arrow")
            }
            if device.selectedParams == 0 {
                headerView.selectDeviceButton.setImage(UIImage(named: "checkbox_unselect"), for: .normal)
            } else if device.selectedParams == device.params?.count {
                headerView.selectDeviceButton.setImage(UIImage(named: "checkbox_select"), for: .normal)
            } else {
                headerView.selectDeviceButton.setImage(UIImage(named: "checkbox_partial"), for: .normal)
            }
            return headerView
        }
        return headerView
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
        footerView.backgroundColor = UIColor.clear
        return footerView
    }

    func numberOfSections(in _: UITableView) -> Int {
        return actionDevices?.count ?? 0
    }
}

extension AutomationSelectDeviceVC: ESPListUserDevicePresentationLogic {
    
    func listOfDevicesForAutomationEvent(devices: [Device]) {}
    
    func listOfDevicesForAutomationAction(devices: [Device]) {
        actionDevices = devices
        if isEditFlow {
            updateDeviceSelection()
        }
        devicesTableView.reloadData()
    }
    
}

extension AutomationSelectDeviceVC: ESPAddAutomationPresentationLogic {
    func didFinishAddingAutomationWith(automationID: String?, error: ESPAPIError?) {
        Utility.hideLoader(view: view)
        automationTrigger?.automationID = automationID
        addAutomationDelegate?.addAutomationFinishedWith(automation: automationTrigger, error: error)
        self.navigationController?.popToRootViewController(animated: false)
    }
}
