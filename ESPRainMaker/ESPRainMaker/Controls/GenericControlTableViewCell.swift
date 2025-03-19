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
//  GenericControlTableViewCell.swift
//  ESPRainMaker
//

import UIKit

class GenericControlTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "genericControlCell"
    
    // IB Outlets
    @IBOutlet var backView: UIView!
    @IBOutlet var controlName: UILabel!
    @IBOutlet var controlValueLabel: UILabel!
    @IBOutlet var editButton: UIButton!
    @IBOutlet var checkButton: UIButton!
    @IBOutlet var leadingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet var trailingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var tapButton: UIButton!
    
    // Matter related properties
    @IBOutlet weak var backViewTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var backViewBottomSpaceConstraint: NSLayoutConstraint!
    var deviceId: UInt64?
    weak var nodeGroup: ESPNodeGroup?
    var node: ESPNodeDetails?
    var infoType: InfoType = .indoorTemperature
    
    // Stored properties
    var scheduleDelegate: ScheduleActionDelegate?
    var indexPath: IndexPath!
    var attributeKey = ""
    var paramDelegate: ParamUpdateProtocol?
    var controlValue: String?
    var dataType: String = "String"
    var device: Device!
    var boolTypeValidValues: [String: Int] = ["true": 1, "false": 0, "yes": 1, "no": 0, "0": 0, "1": 1]
    var param: Param?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // Adding height constraint for popup textfield
    func addHeightConstraint(textField: UITextField) {
        let heightConstraint = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        textField.addConstraint(heightConstraint)
        textField.font = UIFont(name: textField.font!.fontName, size: 18)
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Failure!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        parentViewController?.present(alert, animated: true, completion: nil)
    }

    @objc func doneButtonAction() {}

    // IB Actions
    @IBAction func checkBoxPressed(_: Any) {}

    @IBAction func editButtonTapped(_: Any) {}
    
    @IBAction func paramTapped(_ sender: Any) {}
    
    // MARK: Matter related functions:
    
    /// Setup locally stored UI
    func setupLocallyStoredUI() {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *), let deviceId = self.deviceId {
            if let localTemperature = self.node?.getMatterLocalTemperatureValue(deviceId: deviceId) {
                DispatchQueue.main.async {
                    self.controlValueLabel.text = "\(localTemperature) °C"
                }
            }
        }
        #endif
    }
    
    /// Subscribe to temperature measurement
    func subscribeToLocalTemperature() {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *), let group = self.nodeGroup, let groupId = group.groupID, let deviceId = self.deviceId {
            ESPMTRCommissioner.shared.subscribeLocalTemperature(groupId: groupId, deviceId: deviceId) { localTemperature in
                if let localTemperature = localTemperature {
                    self.node?.setMatterLocalTemperatureValue(temperature: localTemperature, deviceId: deviceId)
                    DispatchQueue.main.async {
                        self.controlValueLabel.text = "\(localTemperature) °C"
                    }
                }
            }
        }
        #endif
    }
    
    /// Setup offline indoor temperature UI
    func setupOfflineLocalTemperatureUI() {
        self.setupLocallyStoredUI()
    }
    
    /// Set initial indoor temperature UI
    /// First set stored value as UI
    /// Subscribe to local temperature
    func setupLocalTemperatureUI() {
        self.setupLocallyStoredUI()
        self.subscribeToLocalTemperature()
    }
}
