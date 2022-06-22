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
//  SelectEventViewController.swift
//  ESPRainMaker
//

import UIKit

class SelectEventViewController: UIViewController {
    
    static let storybaordID = "selectEventVC"
    
    @IBOutlet weak var deviceListTableView: UITableView!
    
    // IBOutlets for param selection
    @IBOutlet weak var paramSelectionView: UIView!
    @IBOutlet weak var sliderSelectionView: UIView!
    @IBOutlet weak var genericSelectionView: UIView!
    @IBOutlet weak var confirmationView: UIView!
    @IBOutlet weak var casesSegmentControl: UISegmentedControl!
    @IBOutlet weak var genericParamLabel: UILabel!
    @IBOutlet weak var sliderParamLabel: UILabel!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var selectionSwitch: UISwitch!
    
    // IBOutlers for Slider selection view
    @IBOutlet weak var sliderMaxLabel: UILabel!
    @IBOutlet weak var sliderMinLabel: UILabel!
    @IBOutlet weak var sliderCurrentLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet var eventSelectionCenterConstraint: NSLayoutConstraint!
    
    private var currentSelectedParam: Param?
    private var eventDevices:[Device] = []
    private var listUserDeviceService:ESPListUserDeviceService?
    
    var currentDevice:Device?
    var automationTrigger: ESPAutomationTriggerAction?
    var isEditFlow = false
    var editAutomationVC: EditAutomationViewController?
    var addAutomationDelegate: ESPAddAutomationDelegate?
    
    // MARK: - Overriden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Hide tab bar
        tabBarController?.tabBar.isHidden = true
        // Start list user device service
        listUserDeviceService = ESPListUserDeviceService(presenter: self)
        listUserDeviceService?.getListOfDevicesForEvent(nodes: User.shared.associatedNodeList)
        // Set segment control appearance
        casesSegmentControl.setAppearance()
        valueTextField.setBottomBorder(color: UIColor(hexString: "#8265E3").cgColor)
        deviceListTableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Add gesture recognizer to hide keyboard(if open) on tapping anywhere on screen
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {            UIView.animate(withDuration: 0.2) {
            self.eventSelectionCenterConstraint.constant = -100.0
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.2) {
            self.eventSelectionCenterConstraint.constant = 0
        }
    }
    
    @objc private func hideKeyBoard() {
        valueTextField.resignFirstResponder()
        view.endEditing(true)
    }
    
    // MARK: - IB Actions
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        switch currentSelectedParam?.dataType?.lowercased() {
            case "int":
                sliderCurrentLabel.text = "\(Int(slider.value))"
            default:
                sliderCurrentLabel.text = "\(slider.value)"
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        paramSelectionView.isHidden = true
    }
    
    @IBAction func confirmPressed(_ sender: Any) {
        switch currentSelectedParam?.uiType {
            case Constants.toggle:
                setEventForToggleParams()
            case Constants.slider:
                setEventForSliderParams()
            default:
                setEventForGenericParams()
        }
        if isEditFlow {
            editAutomationVC?.automationTrigger = automationTrigger
            editAutomationVC?.refreshTableView()
            navigationController?.popViewController(animated: false)
        } else {
            showDeviceSelectionVC()
        }
    }
    
    // MARK: - Private Methods
    
    private func showParamSelectionFor(device: Device) {
        let actionSheet = UIAlertController(title: "", message: "Choose Parameter", preferredStyle: .actionSheet)
        if let params = device.params?.filter({  $0.type != Constants.deviceNameParam }) {
            for param in params {
                let action = UIAlertAction(title: param.name ?? "", style: .default) { action in
                    self.automationTrigger?.nodeID = device.node?.node_id ?? ""
                    self.currentSelectedParam = param
                    self.currentDevice = device
                    self.setConditionForParam(param: param)
                }
                actionSheet.addAction(action)
            }
        }
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    private func setConditionForParam(param: Param) {
        switch param.dataType?.lowercased() {
            case "int","float":
                prepareSegmentControl(showAllChecks: true)
            default:
                prepareSegmentControl(showAllChecks: false)
        }
        switch param.uiType {
            case Constants.toggle:
                showToggleSelectionView()
            case Constants.slider:
                showSliderSelectionView()
            default:
                showGenericSelectionView()
        }
        paramSelectionView.isHidden = false
    }
    
    private func showToggleSelectionView() {
        sliderSelectionView.isHidden = true
        genericSelectionView.isHidden = false
        selectionSwitch.isHidden = false
        valueTextField.isHidden = true
        genericParamLabel.text = currentSelectedParam?.name ?? ""
    }
    
    private func showGenericSelectionView() {
        sliderSelectionView.isHidden = true
        genericSelectionView.isHidden = false
        selectionSwitch.isHidden = true
        valueTextField.isHidden = false
        switch currentSelectedParam?.dataType?.lowercased() {
            case "int":
                valueTextField.keyboardType = .numberPad
            case "float":
                valueTextField.keyboardType = .decimalPad
            default:
                break
        }
        genericParamLabel.text = currentSelectedParam?.name ?? ""
    }
    
    private func showSliderSelectionView() {
        genericSelectionView.isHidden = true
        sliderSelectionView.isHidden = false
        let sliderBounds = currentSelectedParam?.getSliderBounds() ?? (min:0,max:100)
        slider.maximumValue = sliderBounds.max
        slider.minimumValue = sliderBounds.min
        if currentSelectedParam?.dataType?.lowercased() == "int" {
            let value = Int(currentSelectedParam?.value as? Float ?? 100)
            sliderMinLabel.text = "\(Int(slider.minimumValue))"
            sliderMaxLabel.text = "\(Int(slider.maximumValue))"
            slider.value = Float(value)
        } else {
            sliderMinLabel.text = "\(slider.minimumValue)"
            sliderMaxLabel.text = "\(slider.maximumValue)"
            slider.value = currentSelectedParam?.value as? Float ?? 100
        }
        sliderCurrentLabel.text = "\(slider.value)"
        sliderParamLabel.text = currentSelectedParam?.name ?? ""
        prepareSegmentControl(showAllChecks: true)
    }
    
    
    private func prepareSegmentControl(showAllChecks: Bool) {
        casesSegmentControl.removeAllSegments()
        if showAllChecks {
            for (index, element) in ESPEventChecks.allCases.enumerated() {
                casesSegmentControl.insertSegment(withTitle: element.rawValue, at: index, animated: false)
            }
            casesSegmentControl.selectedSegmentIndex = 1
            casesSegmentControl.isUserInteractionEnabled = true
        } else {
            casesSegmentControl.insertSegment(withTitle: "Equals", at: 0, animated: false)
            casesSegmentControl.isUserInteractionEnabled = false
        }
    }
    
    private func setEventForToggleParams() {
        var automationEvent:[String: Any] = [:]
        automationEvent[ESPAutomationConstants.check] = "=="
        automationEvent[ESPAutomationConstants.params] = [currentDevice?.name ?? "": [currentSelectedParam?.name: selectionSwitch.isOn]]
        automationTrigger?.events = [automationEvent]
    }
    
    private func setEventForGenericParams() {
        var automationEvent:[String: Any] = [:]
        if casesSegmentControl.numberOfSegments == 1 {
            automationEvent[ESPAutomationConstants.check] = "=="
        } else {
            var titleSegment = casesSegmentControl.titleForSegment(at: casesSegmentControl.selectedSegmentIndex)
            titleSegment = titleSegment == "=" ? "==":titleSegment
            automationEvent[ESPAutomationConstants.check] = titleSegment
        }
        switch currentSelectedParam?.dataType?.lowercased() {
            case "int":
            if let intValue = Int(valueTextField.text ?? "0") {
                automationEvent[ESPAutomationConstants.params] = [currentDevice?.name ?? "": [currentSelectedParam?.name: intValue]]
            }
            case "float":
            if let floatValue = Float(valueTextField.text ?? "0") {
                automationEvent[ESPAutomationConstants.params] = [currentDevice?.name ?? "": [currentSelectedParam?.name: floatValue]]
            }
            default:
            automationEvent[ESPAutomationConstants.check] = "=="
            if let stringValue = valueTextField.text {
                automationEvent[ESPAutomationConstants.params] = [currentDevice?.name ?? "": [currentSelectedParam?.name:stringValue]]
            }
        }
        automationTrigger?.events = [automationEvent]
    }
    
    private func setEventForSliderParams() {
        var automationEvent:[String: Any] = [:]
        var titleSegment = casesSegmentControl.titleForSegment(at: casesSegmentControl.selectedSegmentIndex)
        titleSegment = titleSegment == "=" ? "==" :titleSegment
        automationEvent[ESPAutomationConstants.check] = titleSegment
        switch currentSelectedParam?.dataType?.lowercased() {
            case "int":
                automationEvent[ESPAutomationConstants.params] = [currentDevice?.name ?? "": [currentSelectedParam?.name: Int(slider.value)]]
            default:
                automationEvent[ESPAutomationConstants.params] = [currentDevice?.name ?? "": [currentSelectedParam?.name: slider.value]]
        }
        automationTrigger?.events = [automationEvent]
    }
    
    private func showDeviceSelectionVC() {
        let storyboard = UIStoryboard(name: ESPAutomationConstants.storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: AutomationSelectDeviceVC.storyboardID) as! AutomationSelectDeviceVC
        vc.automationTrigger = automationTrigger
        vc.addAutomationDelegate = addAutomationDelegate
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension SelectEventViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return eventDevices.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectEventTableViewCell.reuseIdentifier, for: indexPath) as! SelectEventTableViewCell
        let device = eventDevices[indexPath.section]
        cell.deviceImageView.image = ESPRMDeviceType(rawValue: device.type ?? "")?.getImageFromDeviceType() ?? UIImage(named: Constants.dummyDeviceImage)
        cell.deviceNameLabel.text = device.deviceName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showParamSelectionFor(device: eventDevices[indexPath.section])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
}

extension SelectEventViewController: ESPListUserDevicePresentationLogic {
    func listOfDevicesForAutomationEvent(devices: [Device]) {
        eventDevices = devices
        deviceListTableView.reloadData()
    }
    
    func listOfDevicesForAutomationAction(devices: [Device]) {}
    
}
