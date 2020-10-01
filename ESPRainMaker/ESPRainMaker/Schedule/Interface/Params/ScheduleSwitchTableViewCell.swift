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
//  ScheduleSwitchTableViewCell.swift
//  ESPRainMaker
//
#if SCHEDULE
    import UIKit

    class ScheduleSwitchTableViewCell: UITableViewCell {
        @IBOutlet var backView: UIView!
        @IBOutlet var controlName: UILabel!
        @IBOutlet var toggleSwitch: UISwitch!
        @IBOutlet var controlStateLabel: UILabel!
        @IBOutlet var checkButton: UIButton!

        var param: Param!
        var device: Device!
        var delegate: ScheduleActionDelegate?
        var indexPath: IndexPath!

        override func awakeFromNib() {
            super.awakeFromNib()
            // Initialization code
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
        }

        @IBAction func selectPressed(_: Any) {
            if param.selected {
                toggleSwitch.isEnabled = false
                checkButton.setImage(UIImage(named: "unselected"), for: .normal)
                param.selected = false
                device.selectedParams -= 1
            } else {
                toggleSwitch.isEnabled = true
                checkButton.setImage(UIImage(named: "selected"), for: .normal)
                param.selected = true
                device.selectedParams += 1
            }
            delegate?.paramStateChangedat(indexPath: indexPath)
        }

        @IBAction func switchStateChanged(_ sender: UISwitch) {
            if sender.isOn {
                controlStateLabel.text = "On"
            } else {
                controlStateLabel.text = "Off"
            }
            param.value = sender.isOn
        }
    }
#endif
