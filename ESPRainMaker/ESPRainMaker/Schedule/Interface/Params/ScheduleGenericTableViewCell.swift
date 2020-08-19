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
//  ScheduleGenericTableViewCell.swift
//  ESPRainMaker
//
#if SCHEDULE
    import UIKit

    class ScheduleGenericTableViewCell: UITableViewCell {
        @IBOutlet var backView: UIView!
        @IBOutlet var controlName: UILabel!
        @IBOutlet var controlValueLabel: UILabel!
        @IBOutlet var editButton: UIButton!
        @IBOutlet var checkButton: UIButton!

        var controlValue: String?
        var dataType: String = "String"
        var device: Device!
        var boolTypeValidValues: [String: Int] = ["true": 1, "false": 0, "yes": 1, "no": 0, "0": 0, "1": 1]
        var param: Param!
        var delegate: ScheduleActionDelegate?
        var indexPath: IndexPath!

        override func awakeFromNib() {
            super.awakeFromNib()
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)

            // Configure the view for the selected state
        }

        @IBAction func editButtonTapped(_: Any) {
            if Utility.isConnected(view: parentViewController!.view) {
                let input = UIAlertController(title: param?.attributeKey, message: "Enter new value", preferredStyle: .alert)
                input.addTextField { textField in
                    textField.text = self.controlValue ?? ""
                    self.addHeightConstraint(textField: textField)
                }

                input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
                }))
                input.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak input] _ in
                    let valueTextField = input?.textFields![0]
                    self.controlValue = valueTextField?.text
                    self.doneButtonAction()
                }))
                parentViewController?.present(input, animated: true, completion: nil)
            }
        }

        private func addHeightConstraint(textField: UITextField) {
            let heightConstraint = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
            textField.addConstraint(heightConstraint)
            textField.font = UIFont(name: textField.font!.fontName, size: 18)
        }

        func showAlert(message: String) {
            let alert = UIAlertController(title: "Failure!", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            parentViewController?.present(alert, animated: true, completion: nil)
        }

        @objc func valueUpdated() {}

        @objc func doneButtonAction() {
            if let value = controlValue {
                if dataType.lowercased() == "int" {
                    if let intValue = Int(value) {
                        if let bounds = param?.bounds, let max = bounds["max"] as? Int, let min = bounds["min"] as? Int {
                            if intValue >= min, intValue <= max {
                                param?.value = intValue
                                controlValueLabel.text = value
                            } else {
                                showAlert(message: "Value out of bound.")
                            }
                        } else {
                            param?.value = intValue
                            controlValueLabel.text = value
                        }
                    } else {
                        showAlert(message: "Please enter a valid integer value.")
                    }
                } else if dataType.lowercased() == "float" {
                    if let floatValue = Float(value) {
                        if let bounds = param?.bounds, let max = bounds["max"] as? Float, let min = bounds["min"] as? Float {
                            if floatValue >= min, floatValue <= max {
                                param?.value = floatValue
                                controlValueLabel.text = value
                            } else {
                                showAlert(message: "Value out of bound.")
                            }
                        } else {
                            param?.value = floatValue
                            controlValueLabel.text = value
                        }
                    } else {
                        showAlert(message: "Please enter a valid float value.")
                    }
                } else if dataType.lowercased() == "bool" {
                    if boolTypeValidValues.keys.contains(value) {
                        let validValue = boolTypeValidValues[value]!
                        if validValue == 0 {
                            param?.value = false
                            controlValueLabel.text = value
                        } else {
                            param?.value = true
                            controlValueLabel.text = value
                        }
                    } else {
                        showAlert(message: "Please enter a valid boolean value.")
                    }
                } else {
                    param?.value = controlValue
                    controlValueLabel.text = value
                }
            }
        }

        @IBAction func selectPressed(_: Any) {
            if param.selected {
                editButton.isHidden = true
                checkButton.setImage(UIImage(named: "unselected"), for: .normal)
                param.selected = false
                device.selectedParams -= 1
            } else {
                editButton.isHidden = false
                checkButton.setImage(UIImage(named: "selected"), for: .normal)
                param.selected = true
                device.selectedParams += 1
            }
            delegate?.paramStateChangedat(indexPath: indexPath)
        }
    }
#endif
