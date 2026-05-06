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
import UIKit

class ScheduleGenericTableViewCell: GenericControlTableViewCell {
    
    var cellType: DeviceServiceType = .none
    
    override func layoutSubviews() {
        super.layoutSubviews()
        checkButton.isHidden = false
        trailingSpaceConstraint.constant = 0
        leadingSpaceConstraint.constant = 30.0
        backView.backgroundColor = .white
        setupSelections()
    }

    @IBAction override func editButtonTapped(_: Any) {
        let input = UIAlertController(title: param?.attributeKey, message: "Enter new value", preferredStyle: .alert)
        input.addTextField { textField in
            textField.text = self.controlValue ?? ""
            self.addHeightConstraint(textField: textField)
        }

        input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
        }))
        input.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak input] _ in
            // Safe array access: use first instead of force unwrap
            guard let valueTextField = input?.textFields?.first,
                  let value = valueTextField.text else {
                return
            }
            self.controlValue = value
            self.doneButtonAction()
        }))
        parentViewController?.present(input, animated: true, completion: nil)
    }

    @objc override func doneButtonAction() {
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
                // Safe dictionary access: use optional binding instead of force unwrap
                if let validValue = boolTypeValidValues[value] {
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

    @IBAction override func checkBoxPressed(_: Any) {
        // Safe optional handling: guard against nil param to prevent crashes
        guard let currentParam = param else {
            return
        }
        
        if currentParam.selected {
            // Param is being deselected - hide edit button since it's no longer part of schedule/scene
            editButton.isHidden = true
            checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
            currentParam.selected = false
            device.selectedParams -= 1
        } else {
            // Param is being selected - show edit button so user can set the value for schedule/scene
            editButton.isHidden = false
            checkButton.setImage(UIImage(named: "selected"), for: .normal)
            currentParam.selected = true
            device.selectedParams += 1
        }
        scheduleDelegate?.paramStateChangedat(indexPath: indexPath)
    }
}

extension ScheduleGenericTableViewCell: ScheduleSceneActionAllowedProtocol {
    func setupSelections() {
        let isAllowed = isCellEnabled(cellType: cellType, device: device)
        if isAllowed {
            self.alpha = 1.0
            checkButton.isEnabled = true
            // Show edit button when param is selected (so user can edit the value for schedule/scene)
            // Hide edit button when param is not selected (not part of schedule/scene)
            editButton.isHidden = !(param?.selected ?? false)
        } else {
            self.alpha = 0.6
            checkButton.isEnabled = false
            editButton.isHidden = true
            scheduleDelegate?.takeScheduleNotAllowedAction(action: device.scheduleAction)
        }
    }
}
