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
//  DeviceAutomationsListVC.swift
//  ESPRainMaker
//

import UIKit

class DeviceAutomationsListVC: UIViewController {
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var initialAddButton: PrimaryButton!
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var initialLabel: UILabel!
    @IBOutlet weak var initialView: UIView!
    @IBOutlet weak var automationsTableView: UITableView!
    
    static let storyboardID = "deviceAutomationsListVC"
    
    var automationList:[ESPAutomationTriggerAction] = []
    
    private var espGetAutomationService:ESPGetAutomationService?
    private var espEnableAutomationService: ESPEnableAutomationService?
    private var espDeleteAutomationService: ESPDeleteAutomationService?
    private let refreshControl = UIRefreshControl()
    private var doneAction = UIAlertAction()
    
    // MARK: - Overriden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        startAutomationServices()
        // Add refresh control to table view.
        refreshControl.addTarget(self, action: #selector(refreshAutomationList), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        automationsTableView.refreshControl = refreshControl
        automationsTableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Disable editing if enabled for table view.
        automationsTableView.isEditing = false
        editButton.setTitle("Edit", for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    @objc func refreshAutomationList() {
        refreshControl.endRefreshing()
        Utility.showLoader(message: "Getting automations...", view: view)
        espGetAutomationService?.getAutomation()
    }
    
    // MARK: - IB Actions
    
    @IBAction func editTableView(_ sender: UIButton) {
        automationsTableView.isEditing = !automationsTableView.isEditing
        sender.setTitle(automationsTableView.isEditing ? "Done" : "Edit", for: .normal)
    }
    
    @IBAction func addPressed(_ sender: Any) {
        // Enter name before proceeding to add new automation
        let input = UIAlertController(title: "Add name", message: "Choose name for your automation", preferredStyle: .alert)
        input.addTextField { textField in
            textField.delegate = self
        }
        input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
        }))
        doneAction = UIAlertAction(title: "Done", style: .default, handler: { [weak input] _ in
            let textField = input?.textFields![0]
            textField?.keyboardType = .asciiCapable
            guard let name = textField?.text, name.count > 0 else {
                //Show name error alert
                self.showErrorAlert(title: "Error", message: "Please enter a name for the automation to proceed.", buttonTitle: "OK", callback: {
                })
                return
            }
            self.addNewAutomation(name: name)
        })
        doneAction.isEnabled = false
        input.addAction(doneAction)
        present(input, animated: true, completion: nil)
    }
    
    @IBAction func reloadPressed(_ sender: Any) {
        espGetAutomationService?.getAutomation()
        Utility.showLoader(message: "Getting automations...", view: view)
    }
    
    func addNewAutomation(name: String) {
        var automation = ESPAutomationTriggerAction()
        automation.name = name
        let storyboard = UIStoryboard(name: ESPAutomationConstants.storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: SelectEventViewController.storybaordID) as! SelectEventViewController
        vc.automationTrigger = automation
        vc.addAutomationDelegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Private Methods
    
    private func updateView() {
        if automationList.count > 0 {
            initialView.isHidden = true
            automationsTableView.isHidden = false
            automationsTableView.reloadData()
            addButton.isHidden = false
        } else {
            initialView.isHidden = false
            automationsTableView.isHidden = true
            addButton.isHidden = true
        }
    }
    
    private func startAutomationServices() {
        Utility.showLoader(message: "Getting automations...", view: view)
        espGetAutomationService = ESPGetAutomationService(presenter: self)
        espGetAutomationService?.getAutomation()
        espEnableAutomationService = ESPEnableAutomationService(presenter: self)
        espDeleteAutomationService = ESPDeleteAutomationService(presenter: self)
    }
    
}

extension DeviceAutomationsListVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return automationList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DeviceAutomationTableViewCell.reuseIdentifier, for: indexPath) as! DeviceAutomationTableViewCell
        let automation = automationList[indexPath.section]
        cell.automationNameLabel.text = automation.name ?? ""
        cell.triggerlabel.text = "If: " + automation.getEventDescription(nodes: User.shared.associatedNodeList ?? [])
        cell.actionLabel.text = "Set: " + automation.getActionDescription(nodes: User.shared.associatedNodeList  ?? [])
        cell.automationID = automation.automationID ?? ""
        cell.enableSwitch.isOn = automation.enabled
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let automation = automationList[indexPath.section]
        let storyboard = UIStoryboard(name: ESPAutomationConstants.storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: EditAutomationViewController.storybaordID) as! EditAutomationViewController
        vc.automationTrigger = automation
        vc.editAutomationDelegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alertController = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { _ in
                DispatchQueue.main.async {
                    Utility.showLoader(message: "", view: self.view)
                    let automation = self.automationList[indexPath.section]
                    self.automationsTableView.isEditing = false
                    if let automationID = automation.automationID {
                        self.espDeleteAutomationService?.deleteAutomation(automationID)
                    } else {
                        Utility.showToastMessage(view: self.view, message: "Automation ID is not present. Please refresh", duration: 4.0)
                    }
                }
            }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        }
    }
}

extension DeviceAutomationsListVC: ESPGetAutomationPresentationLogic {
    func automationListFetched(automations: ESPAutomation?, error: ESPAPIError?) {
        Utility.hideLoader(view: view)
        guard let error = error else {
            if let automationActions = automations?.automationTriggerActions {
                automationList = automationActions.sorted(by: { $0.name ?? "" < $1.name ?? ""})
            }
            updateView()
            return
        }
        Utility.showToastMessage(view: view, message: error.description, duration: 3.0)
        updateView()
    }
}

extension DeviceAutomationsListVC: UITextFieldDelegate {
    
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

extension DeviceAutomationsListVC: DeviceAutomationCellDelegate {
    func togglePressed(automationID: String, enable: Bool) {
        Utility.showLoader(message: "", view: view)
        espEnableAutomationService?.enableAutomation(automationID, enable)
    }
}

extension DeviceAutomationsListVC: ESPEnableAutomationPresentationLogic {
    func didFinishEnablingAutomationWith(automationID: String, error: ESPAPIError?) {
        Utility.hideLoader(view: view)
        if var automationTrigger = automationList.first(where: { $0.automationID == automationID }) {
        guard let error = error else {
            automationTrigger.enabled = !automationTrigger.enabled
            if let index = automationList.firstIndex(where: { $0.automationID == automationID }) {
                automationList[index] = automationTrigger
            }
            Utility.showToastMessage(view: view, message: "Automation \(automationTrigger.enabled == true ? "enabled":"disabled") successfully", duration: 3.0)
            return
        }
        Utility.showToastMessage(view: view, message: error.description, duration: 4.0)
        automationsTableView.reloadData()
        }
    }
}

extension DeviceAutomationsListVC: ESPDeleteAutomationPresentationLogic {
    func didFinishDeletingAutomationWith(automationID: String, error: ESPAPIError?) {
        Utility.hideLoader(view: self.view)
        editButton.setTitle("Edit", for: .normal)
        guard let error = error else {
            automationList.removeAll(where: { $0.automationID == automationID})
            updateView()
            Utility.showToastMessage(view: view, message: "Automation deleted successfully", duration: 4.0)
            return
        }
        Utility.showToastMessage(view: view, message: "Delete failed: " + error.description, duration: 4.0)
        updateView()
    }
}

extension DeviceAutomationsListVC: EditAutomationVCDelegate {
    func automationUpdateSuccess(automation: ESPAutomationTriggerAction?) {
        if var automation = automation {
            automationList = automationList.filter({ $0.automationID != automation.automationID})
            automation.enabled = true
            automationList.insert(automation, at: 0)
            automationList = automationList.sorted(by: { $0.name ?? "" < $1.name ?? ""})
            automationsTableView.reloadData()
            Utility.showToastMessage(view: view, message: "Automation updated successfully", duration: 3.0)
        }
    }
    
    func automationDeleteSuccess(automationID: String) {
        automationList.removeAll(where: { $0.automationID == automationID})
        updateView()
        Utility.showToastMessage(view: view, message: "Automation deleted successfully", duration: 4.0)
    }
}

extension DeviceAutomationsListVC: ESPAddAutomationDelegate {
    func addAutomationFinishedWith(automation: ESPAutomationTriggerAction?, error: ESPAPIError?) {
        guard let error = error else {
            if let automation = automation {
                Utility.showToastMessage(view: view, message: "Automation added successfully", duration: 3.0)
                automationList.insert(automation, at: 0)
                automationList = automationList.sorted(by: { $0.name ?? "" < $1.name ?? ""})
                updateView()
            }
            return
        }
        Utility.showToastMessage(view: view, message: error.description, duration: 3.0)
    }
}
