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
//  DeviceAutomationTableViewCell.swift
//  ESPRainMaker
//

import UIKit

protocol DeviceAutomationCellDelegate {
    func togglePressed(automationID: String, enable: Bool)
}

class DeviceAutomationTableViewCell: UITableViewCell {
    
    @IBOutlet var automationNameLabel: UILabel!
    @IBOutlet var triggerlabel: UILabel!
    @IBOutlet var actionLabel: UILabel!
    @IBOutlet var enableSwitch: UISwitch!

    static let reuseIdentifier = "deviceAutomationTVC"
    
    var delegate: DeviceAutomationCellDelegate?
    var automationID: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func switchStateChanged(_ sender: UISwitch) {
        delegate?.togglePressed(automationID: automationID, enable: sender.isOn)
    }

}
