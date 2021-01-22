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
//  ScheduleViewController.swift
//  ESPRainMaker
//
import UIKit

class ScheduleViewController: UIViewController {
    @IBOutlet var repeatViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet var actionTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var onDaysImageView: UIImageView!
    @IBOutlet var scheduleNameLabel: UILabel!
    @IBOutlet var dailyImageView: UIImageView!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var repeatView: UIView!
    @IBOutlet var repeatImage: UIImageView!
    @IBOutlet var daysLabel: UILabel!
    var isCollapsed = true
    @IBOutlet var actionListTextView: UITextView!

    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // Update list of available devices for schedule
        if let nodeList = User.shared.associatedNodeList {
            ESPScheduler.shared.getAvailableDeviceWithScheduleCapability(nodeList: nodeList)
        }

        // Configure view for current schedule
        ESPScheduler.shared.configureDeviceForCurrentSchedule()

        // Configure time of date picker based on the value of schedule minute field.
        datePicker.backgroundColor = UIColor.white
        if ESPScheduler.shared.currentSchedule.id != nil {
            scheduleNameLabel.text = ESPScheduler.shared.currentSchedule.name
            let dateString = ESPScheduler.shared.currentSchedule.trigger.getTimeDetails()
            datePicker.setDate(from: dateString, format: "h:mm a", animated: true)
        }

        actionListTextView.textContainer.heightTracksTextView = true
        actionListTextView.isScrollEnabled = false
        setRepeatStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        // Show list of actions added on a schedule.
        let actionList = ESPScheduler.shared.getActionList()
        if actionList == "" {
            actionListTextView.text = ""
            actionTextViewHeightConstraint.priority = .defaultHigh
            saveButton.isHidden = true
        } else {
            actionListTextView.text = actionList
            actionTextViewHeightConstraint.priority = .defaultLow
            saveButton.isHidden = false
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "selectDaysVC" {
            if let vc = segue.destination as? SelectDaysViewController {
                vc.pvc = self
            }
        }
    }

    // MARK: - IBActions

    @IBAction func scheduleNamePressed(_: Any) {
        let input = UIAlertController(title: "Add name", message: "Choose name for your schedule", preferredStyle: .alert)

        input.addTextField { textField in
            textField.text = self.scheduleNameLabel.text ?? ""
            textField.delegate = self
            self.addHeightConstraint(textField: textField)
        }
        input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in

        }))
        input.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak input] _ in
            let textField = input?.textFields![0]
            guard let name = textField?.text else {
                return
            }
            self.scheduleNameLabel.text = name
        }))
        present(input, animated: true, completion: nil)
    }

    @IBAction func repeatButtonPressed(_: Any) {
        if isCollapsed {
            isCollapsed = false
            repeatImage.image = UIImage(named: "down_arrow")
            UIView.animate(withDuration: 1.0) {
                self.repeatView.isHidden = false
                self.repeatViewHeightConstraint.constant = 80.0
            }
        } else {
            isCollapsed = true
            repeatImage.image = UIImage(named: "right_arrow")
            UIView.animate(withDuration: 1.0) {
                self.repeatView.isHidden = true
                self.repeatViewHeightConstraint.constant = 0
            }
        }
    }

    @IBAction func backButtonPressed(_: Any) {
        ESPScheduler.shared.configureDeviceForCurrentSchedule()
        navigationController?.popViewController(animated: true)
    }

    @IBAction func onDaysButtonPressed(_: Any) {}

    @IBAction func dailyButtonTapped(_: Any) {
        onDaysImageView.isHidden = true
        dailyImageView.isHidden = false
        daysLabel.text = "Never"
        ESPScheduler.shared.currentSchedule.trigger.days = 0
    }

    @IBAction func saveSchedule(_: Any) {
        // Check if the user has provided name for the schedule
        let scheduleName = scheduleNameLabel.text ?? ""
        if scheduleName == "" {
            let alert = UIAlertController(title: "Error", message: "Please enter name of the schedule to proceed.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            Utility.showLoader(message: "", view: view)
            // If no id is present that means new schedule is added.
            if ESPScheduler.shared.currentSchedule.id == nil {
                // Generate a unique 4 length id for the new schedule.
                ESPScheduler.shared.currentSchedule.id = NanoID.new(4)
                ESPScheduler.shared.currentSchedule.operation = .add
            } else {
                // Schedule already present so will run edit operation on it.
                ESPScheduler.shared.currentSchedule.operation = .edit
            }

            // Give value for the schedule parameters based on the user selection.
            ESPScheduler.shared.currentSchedule.name = scheduleName
            let trigger = ESPTrigger()
            trigger.days = ESPScheduler.shared.currentSchedule.week.getDecimalConversionOfSelectedDays()

            let date = datePicker.date
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            let hour = components.hour!
            let minute = components.minute!
            trigger.minutes = hour * 60 + minute
            ESPScheduler.shared.currentSchedule.trigger = trigger

            // Call save operation.
            ESPScheduler.shared.saveSchedule(onView: view) { result in
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    Utility.hideLoader(view: self.view)
                    if result {
                        // Result is success. Navigate back to schedule list and refetch the list.
                        // To check if schedule is successfully added.
                        User.shared.updateDeviceList = true
                        self.navigationController?.popToRootViewController(animated: false)
                    } else {
                        Utility.showToastMessage(view: self.view, message: "Failed to schedule devices. Please check your network connection!!")
                    }
                }
            }
        }
    }

    @IBAction func selectDevicesPressed(_: Any) {
        let selectDeviceVC = storyboard?.instantiateViewController(withIdentifier: "selecDevicesVC") as! SelectDevicesViewController
        var availableDeviceCopy: [Device] = []
        // Re-order list of devices such that devices whose params are selected be on top.
        for device in ESPScheduler.shared.availableDevices.values {
            if device.selectedParams > 0 {
                availableDeviceCopy.insert(device, at: 0)
            } else {
                availableDeviceCopy.append(device)
            }
        }
        selectDeviceVC.availableDeviceCopy = availableDeviceCopy
        navigationController?.pushViewController(selectDeviceVC, animated: true)
    }

    // MARK: - Private Methods

    private func addHeightConstraint(textField: UITextField) {
        let heightConstraint = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        textField.addConstraint(heightConstraint)
        textField.font = UIFont(name: textField.font!.fontName, size: 18)
    }

    // MARK: -

    func setRepeatStatus() {
        if ESPScheduler.shared.currentSchedule.trigger.days == 0 {
            onDaysImageView.isHidden = true
            dailyImageView.isHidden = false
            daysLabel.text = "Never"
        } else {
            onDaysImageView.isHidden = false
            dailyImageView.isHidden = true
            daysLabel.text = ESPScheduler.shared.currentSchedule.week.getShortDescription()
        }
    }
}

extension ScheduleViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Restrict the length of name of schedule to be equal to or less than 32 characters.
        let maxLength = 32
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
}
