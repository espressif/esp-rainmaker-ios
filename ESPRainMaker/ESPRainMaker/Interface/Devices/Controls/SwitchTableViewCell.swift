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
//  SwitchTableViewCell.swift
//  ESPRainMaker
//

import UIKit

class SwitchTableViewCell: UITableViewCell, ParamUpdateProtocol {
    @IBOutlet var backView: UIView!
    @IBOutlet var controlName: UILabel!
    @IBOutlet var toggleSwitch: UISwitch!
    @IBOutlet var controlStateLabel: UILabel!
    @IBOutlet var leadingConstraint: NSLayoutConstraint!

    var attributeKey = ""
    var param: Param!
    var device: Device!
    var delegate: ParamUpdateProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = UIColor.clear

        backView.layer.borderWidth = 1
        backView.layer.cornerRadius = 10
        backView.layer.borderColor = UIColor.clear.cgColor
        backView.layer.masksToBounds = true

        layer.shadowOpacity = 0.18
        layer.shadowOffset = CGSize(width: 1, height: 2)
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.black.cgColor
        layer.masksToBounds = false
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func switchStateChanged(_ sender: UISwitch) {
        if sender.isOn {
            controlStateLabel.text = "On"
        } else {
            controlStateLabel.text = "Off"
        }
        NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: sender.isOn]]) { result in
            switch result {
            case .failure:
                self.failureInUpdatingParam()
            default:
                break
            }
        }
    }

    func failureInUpdatingParam() {
        delegate?.failureInUpdatingParam()
    }
}
