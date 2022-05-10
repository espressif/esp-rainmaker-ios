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
//  EditAutomationViewController.swift
//  ESPRainMaker
//

import UIKit

protocol EditAutomationVCDelegate {
    func automationUpdateSuccess(automation: ESPAutomationTriggerAction?)
    func automationDeleteSuccess(automationID: String)
}

class EditAutomationViewController: UIViewController {
    
    var automationTrigger: ESPAutomationTriggerAction?
    var updateAutomationService: ESPUpdateAutomationService?
    var editAutomationDelegate: EditAutomationVCDelegate?
    
    private var espDeleteAutomationService: ESPDeleteAutomationService?
    private var doneAction = UIAlertAction()
    
    static let storybaordID = "editAutomationVC"
    @IBOutlet weak var automationsEditTableView: UITableView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        updateAutomationService = ESPUpdateAutomationService(presenter: self)
        espDeleteAutomationService = ESPDeleteAutomationService(presenter: self)
        automationsEditTableView.tableFooterView = UIView()
    }
    
    func refreshTableView() {
        automationsEditTableView.reloadData()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func updateButtonPressed(_ sender: Any) {
        if let automationTrigger = automationTrigger {
            Utility.showLoader(message: "Update in progress...", view: view)
            updateAutomationService?.updateAutomation(automationTrigger)
        }
    }
    
    private func getEventDeviceDetails() -> (deviceName: String, deviceImage: UIImage?, device: Device?) {
        if let nodeID = automationTrigger?.nodeID {
            if let node = User.shared.associatedNodeList?.first(where: { $0.node_id == nodeID }) {
                if let event = automationTrigger?.events?.first, let param = event[ESPAutomationConstants.params] as? [String:Any] {
                    for (key, _) in param {
                        if let device = node.devices?.first(where: { $0.name == key }) {
                            return (deviceName: device.deviceName, deviceImage:ESPRMDeviceType(rawValue: device.type ?? "")?.getImageFromDeviceType() ?? UIImage(named: Constants.dummyDeviceImage), device: device)
                        }
                    }
                }
            }
        }
        return (deviceName: "", deviceImage: nil, device: nil)
    }
    
    private func getLabelForEvent(device: Device?) -> String {
        if let event = automationTrigger?.events?.first, let param = event[ESPAutomationConstants.params] as? [String:Any], var check = event[ESPAutomationConstants.check] as? String {
            for (_, value) in param {
                if let value = value as? [String:Any] {
                    for (key, value) in value {
                        check = check == "==" ? ":":check
                        if let param = device?.params?.first(where: { $0.name == key }), param.dataType?.lowercased() == "bool", let value = value as? Bool {
                            return key + check + "\(value)"
                        }
                        return key + check + "\(value)"
                    }
                }
            }
        }
        return ""
    }
    
    private func getActionDetails() -> [(devicName: String, deviceImage:UIImage?, actionDetail: String?)]? {
        var actionTuple:[(devicName: String, deviceImage:UIImage?, actionDetail: String?)] = []
        for action in automationTrigger?.actions ?? [] {
            if let nodeID = action.nodeID, let node = User.shared.associatedNodeList?.first(where: { $0.node_id == nodeID }) {
                for (key, _) in action.params ?? [:] {
                    if let device = node.devices?.first(where: { $0.name == key}) {
                        if let value = action.params?[key] {
                            var actions:[String] = []
                            for (key, value) in value {
                                if let param = device.params?.first(where: { $0.name == key }), param.dataType?.lowercased() == "bool", let value = value as? Bool {
                                    actions.append(key + ":" + "\(value)")
                                } else {
                                    actions.append(key + ":" + "\(value)")
                                }
                            }
                            actionTuple.append((devicName: device.deviceName, deviceImage: ESPRMDeviceType(rawValue: device.type ?? "")?.getImageFromDeviceType() ?? UIImage(named: Constants.dummyDeviceImage), actionDetail: actions.joined(separator: ";") ))
                        }
                    }
                }
            }
        }
        return actionTuple
    }
    
    private func getActionCellHeight() -> CGFloat {
        if let actions = self.getActionDetails(), actions.count > 0 {
            return 100.0 + (CGFloat(actions.count) * 60.0) + (CGFloat(actions.count - 1) * 10.0)
        }
        return 100.0
    }
    
    private func renamePressed(tableViewCell: AutomationNameTableViewCell) {
        let input = UIAlertController(title: "Rename", message: "Enter name for your automation", preferredStyle: .alert)

        input.addTextField { textField in
            textField.text = tableViewCell.automationNameLabel.text ?? ""
            textField.delegate = self
        }
        input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        self.doneAction = UIAlertAction(title: "Done", style: .default, handler: { [weak input] _ in
            let textField = input?.textFields![0]
            textField?.keyboardType = .asciiCapable
            guard let name = textField?.text else {
                return
            }
            tableViewCell.automationNameLabel.text = name
            self.automationTrigger?.name = name
        })
        self.doneAction.isEnabled = true
        input.addAction(self.doneAction)
        present(input, animated: true, completion: nil)
    }

}

extension EditAutomationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 4.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: AutomationNameTableViewCell.reuseIdentifier, for: indexPath) as! AutomationNameTableViewCell
            cell.automationNameLabel.text = automationTrigger?.name ?? ""
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: AutomationEventTableViewCell.reuseIdentifier, for: indexPath) as! AutomationEventTableViewCell
            let deviceDetails = getEventDeviceDetails()
            cell.eventDeviceImageView.image = deviceDetails.deviceImage
            cell.eventDeviceLabel.text = deviceDetails.deviceName
            cell.eventDetailLabel.text = getLabelForEvent(device: deviceDetails.device)
            cell.delegate = self
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "automationDeleteTVC", for: indexPath)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: AutomationActionTableViewCell.reuseIdentifier, for: indexPath) as! AutomationActionTableViewCell
            cell.stackView.removeFullyAllArrangedSubviews()
            for actionDetail in getActionDetails() ?? [] {
                let actionSummaryView = AutomationActionSummaryView.instanceFromNib()
                actionSummaryView.deviceImageView.image = actionDetail.deviceImage
                actionSummaryView.deviceLabel.text = actionDetail.devicName
                actionSummaryView.actionLabel.text = actionDetail.actionDetail
                cell.stackView.addArrangedSubview(actionSummaryView)
            }
            cell.delegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
            case 0:
            if let cell = tableView.cellForRow(at: indexPath) as? AutomationNameTableViewCell {
                renamePressed(tableViewCell: cell)
            }
            case 3:
            let alertController = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { _ in
                DispatchQueue.main.async {
                    Utility.showLoader(message: "", view: self.view)
                    if let automationID = self.automationTrigger?.automationID {
                        self.espDeleteAutomationService?.deleteAutomation(automationID)
                    } else {
                        Utility.showToastMessage(view: self.view, message: "Automation ID is not present. Please refresh", duration: 4.0)
                    }
                }
            }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
            default:
                break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
            case 0:
                return 50
            case 2:
                return getActionCellHeight()
            case 3:
                return 50
            default:
                return 170
        }
            
    }
}

extension EditAutomationViewController: AutomationEventCellDelegate {
    func changeEventButtonPressed() {
        let storyboard = UIStoryboard(name: ESPAutomationConstants.storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: SelectEventViewController.storybaordID) as! SelectEventViewController
        vc.automationTrigger = automationTrigger
        vc.isEditFlow = true
        vc.editAutomationVC = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension EditAutomationViewController: AutomationActionCellDelegate {
    func changeActionButtonClicked() {
        let storyboard = UIStoryboard(name: ESPAutomationConstants.storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: AutomationSelectDeviceVC.storyboardID) as! AutomationSelectDeviceVC
        vc.automationTrigger = automationTrigger
        vc.editAutomationVC = self
        vc.isEditFlow = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension UIStackView {
    
    func removeFully(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }
    
    func removeFullyAllArrangedSubviews() {
        arrangedSubviews.forEach { (view) in
            removeFully(view: view)
        }
    }
    
}

extension EditAutomationViewController: ESPUpdateAutomationPresentationLogic {
    func didFinishUpdatingAutomationWith(error: ESPAPIError?) {
        Utility.hideLoader(view: view)
        if let error = error {
            Utility.showToastMessage(view: view, message: "Update failed: " + error.description, duration: 3.0)
        } else {
            editAutomationDelegate?.automationUpdateSuccess(automation: automationTrigger)
            navigationController?.popToRootViewController(animated: false)
        }
    }
}

extension EditAutomationViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Restrict the length of name of automation to be equal to or less than 32 characters.
        let maxLength = 256
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        if newString.length > 1 {
            doneAction.isEnabled = true
        } else {
            doneAction.isEnabled = false
        }
        return newString.length <= maxLength
    }
}

extension EditAutomationViewController: ESPDeleteAutomationPresentationLogic {
    func didFinishDeletingAutomationWith(automationID: String, error: ESPAPIError?) {
        Utility.hideLoader(view: self.view)
        guard let error = error else {
            editAutomationDelegate?.automationDeleteSuccess(automationID: automationID)
            navigationController?.popToRootViewController(animated: false)
            return
        }
        Utility.showToastMessage(view: view, message: "Delete failed: " + error.description, duration: 4.0)
    }
}
