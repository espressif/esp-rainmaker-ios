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
//  SelectDevicesViewController.swift
//  ESPRainMaker
//
import UIKit

class SelectDevicesViewController: UIViewController, ScheduleActionDelegate {
    @IBOutlet var tableView: UITableView!
    var availableDeviceCopy: [Device]!
    var selectedIndexPath: [IndexPath] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
        tableView.register(UINib(nibName: "GenericControlTableViewCell", bundle: nil), forCellReuseIdentifier: "genericControlCell")
        tableView.register(UINib(nibName: "DeviceHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "deviceHV")
        tableView.register(UINib(nibName: "SliderTableViewCell", bundle: nil), forCellReuseIdentifier: "SliderTableViewCell")
        tableView.register(UINib(nibName: "DropDownTableViewCell", bundle: nil), forCellReuseIdentifier: "dropDownTableViewCell")
    }

    // MARK: - IBActions

    @IBAction func cancelButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
        ESPScheduler.shared.configureDeviceForCurrentSchedule()
    }

    @IBAction func doneButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - ScheduleActionDelegate

    func headerViewDidTappedFor(section: Int) {
        availableDeviceCopy[section].collapsed = !availableDeviceCopy[section].collapsed
        tableView.reloadSections(IndexSet(arrayLiteral: section), with: .automatic)
    }

    func paramStateChangedat(indexPath: IndexPath) {
        tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
    }

    func expandSection(expand: Bool, section: Int) {
        availableDeviceCopy[section].collapsed = !expand
        tableView.reloadSections(IndexSet(arrayLiteral: section), with: .automatic)
    }

    // MARK: - Private Methods

    private func getTableViewCellBasedOn(indexPath: IndexPath) -> UITableViewCell {
        let device = availableDeviceCopy[indexPath.section]
        let param = device.params![indexPath.row]
        if param.uiType == "esp.ui.slider" {
            if let dataType = param.dataType?.lowercased(), dataType == "int" || dataType == "float" {
                if let bounds = param.bounds {
                    let maxValue = bounds["max"] as? Float ?? 100
                    let minValue = bounds["min"] as? Float ?? 0
                    if minValue < maxValue {
                        let sliderCell = tableView.dequeueReusableCell(withIdentifier: "SliderTableViewCell", for: indexPath) as! SliderTableViewCell
                        object_setClass(sliderCell, ScheduleSliderTableViewCell.self)
                        let cell = sliderCell as! ScheduleSliderTableViewCell
                        cell.hueSlider.isHidden = true
                        cell.slider.isHidden = false
                        if let bounds = param.bounds {
                            cell.slider.minimumValue = bounds["min"] as? Float ?? 0
                            cell.slider.maximumValue = bounds["max"] as? Float ?? 100
                        }
                        if param.dataType!.lowercased() == "int" {
                            let value = param.value as? Int ?? 0
                            cell.minLabel.text = "\(Int(cell.slider.minimumValue))"
                            cell.maxLabel.text = "\(Int(cell.slider.maximumValue))"
                            cell.slider.value = Float(value)
                        } else {
                            cell.minLabel.text = "\(cell.slider.minimumValue)"
                            cell.maxLabel.text = "\(cell.slider.maximumValue)"
                            cell.slider.value = param.value as! Float
                        }
                        cell.param = param
                        cell.title.text = param.name ?? ""
                        if param.selected {
                            cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
                            cell.slider.isEnabled = true
                            cell.slider.alpha = 1.0
                        } else {
                            cell.checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
                            cell.slider.isEnabled = false
                            cell.slider.alpha = 0.5
                        }
                        cell.device = device
                        cell.scheduleDelegate = self
                        cell.indexPath = indexPath
                        return cell
                    }
                }
            }
        } else if param.uiType == "esp.ui.toggle", param.dataType?.lowercased() == "bool" {
            let switchCell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell", for: indexPath) as! SwitchTableViewCell
            object_setClass(switchCell, ScheduleSwitchTableViewCell.self)
            let cell = switchCell as! ScheduleSwitchTableViewCell
            cell.controlName.text = param.name?.deletingPrefix(device.name!)
            cell.param = param

            if let switchState = param.value as? Bool {
                if switchState {
                    cell.controlStateLabel.text = "On"
                } else {
                    cell.controlStateLabel.text = "Off"
                }
                cell.toggleSwitch.setOn(switchState, animated: true)
            }
            cell.toggleSwitch.isEnabled = true
            if param.selected {
                cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
                cell.toggleSwitch.isEnabled = true
            } else {
                cell.checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
                cell.toggleSwitch.isEnabled = false
            }
            cell.device = device
            cell.scheduleDelegate = self
            cell.indexPath = indexPath
            return cell
        } else if param.uiType == "esp.ui.hue-slider" {
            var minValue = 0
            var maxValue = 360
            if let bounds = param.bounds {
                minValue = bounds["min"] as? Int ?? 0
                maxValue = bounds["max"] as? Int ?? 360
            }

            let sliderCell = tableView.dequeueReusableCell(withIdentifier: "SliderTableViewCell", for: indexPath) as! SliderTableViewCell
            object_setClass(sliderCell, ScheduleSliderTableViewCell.self)
            let cell = sliderCell as! ScheduleSliderTableViewCell
            cell.scheduleDelegate = self
            cell.indexPath = indexPath
            cell.slider.isHidden = true
            cell.hueSlider.isHidden = false
            cell.param = param
            cell.hueSlider.minimumValue = CGFloat(minValue)
            cell.hueSlider.maximumValue = CGFloat(maxValue)

            if minValue == 0, maxValue == 360 {
                cell.hueSlider.hasRainbow = true
                cell.hueSlider.setGradientVaryingHue(saturation: 1.0, brightness: 1.0)
            } else {
                cell.hueSlider.hasRainbow = false
                cell.hueSlider.minColor = UIColor(hue: CGFloat(minValue / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
                cell.hueSlider.maxColor = UIColor(hue: CGFloat(maxValue / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
            }

            let value = CGFloat(param.value as? Int ?? 0)
            cell.hueSlider.value = CGFloat(value)
            cell.minLabel.text = "\(minValue)"
            cell.maxLabel.text = "\(maxValue)"
            cell.hueSlider.thumbColor = UIColor(hue: value / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            cell.device = device
            cell.title.text = param.name ?? ""

            if param.selected {
                cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
                cell.hueSlider.isEnabled = true
                cell.hueSlider.alpha = 1.0
            } else {
                cell.checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
                cell.hueSlider.isEnabled = false
                cell.hueSlider.alpha = 0.5
            }

            return cell
        } else if param.uiType == "esp.ui.dropdown" {
            if let dataType = param.dataType?.lowercased(), dataType == "int" || dataType == "string" {
                let dropDownCell = tableView.dequeueReusableCell(withIdentifier: "dropDownTableViewCell", for: indexPath) as! DropDownTableViewCell
                object_setClass(dropDownCell, ScheduleDropDownTableViewCell.self)
                let cell = dropDownCell as! ScheduleDropDownTableViewCell
                cell.controlName.text = param.name?.deletingPrefix(device.name!)
                cell.device = device
                cell.param = param
                cell.scheduleDelegate = self
                cell.indexPath = indexPath

                var currentValue = ""
                if param.dataType?.lowercased() == "string" {
                    currentValue = param.value as! String
                } else {
                    currentValue = String(param.value as! Int)
                }
                cell.controlValueLabel.text = currentValue
                cell.currentValue = currentValue
                cell.dropDownButton.isHidden = false
                var datasource: [String] = []
                if dataType == "int" {
                    guard let bounds = param.bounds, let max = bounds["max"] as? Int, let min = bounds["min"] as? Int, let step = bounds["step"] as? Int, max > min else {
                        return getTableViewGenericCell(param: param, indexPath: indexPath)
                    }
                    for item in stride(from: min, to: max + 1, by: step) {
                        datasource.append(String(item))
                    }
                } else if param.dataType?.lowercased() == "string" {
                    datasource.append(contentsOf: param.valid_strs ?? [])
                }
                cell.datasource = datasource

                if param.selected {
                    cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
                    cell.dropDownButton.isEnabled = true
                    cell.dropDownButton.alpha = 1.0
                } else {
                    cell.checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
                    cell.dropDownButton.isEnabled = false
                    cell.dropDownButton.alpha = 0.5
                }

                if !cell.datasource.contains(currentValue) {
                    cell.controlValueLabel.text = currentValue + " (Invalid)"
                }
                return cell
            }
        }

        return getTableViewGenericCell(param: param, indexPath: indexPath)
    }

    private func getTableViewGenericCell(param: Param, indexPath: IndexPath) -> ScheduleGenericTableViewCell {
        let genericCell = tableView.dequeueReusableCell(withIdentifier: "genericControlCell", for: indexPath) as! GenericControlTableViewCell
        object_setClass(genericCell, ScheduleGenericTableViewCell.self)
        let cell = genericCell as! ScheduleGenericTableViewCell
        cell.device = availableDeviceCopy[indexPath.section]
        cell.scheduleDelegate = self
        cell.indexPath = indexPath
        cell.controlName.text = param.name
        if let value = param.value {
            cell.controlValue = "\(value)"
            cell.controlValueLabel.text = "\(value)"
        }
        if let data_type = param.dataType {
            cell.dataType = data_type
        }
        cell.param = param
        cell.backView.backgroundColor = UIColor.white
        if param.selected {
            cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
            cell.editButton.isHidden = false
        } else {
            cell.checkButton.setImage(UIImage(named: "checkbox_empty"), for: .normal)
            cell.editButton.isHidden = true
        }
        return cell
    }
}

extension SelectDevicesViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 60.5
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 25.0
    }
}

extension SelectDevicesViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if availableDeviceCopy[section].collapsed {
            return 0
        }
        return availableDeviceCopy[section].params?.count ?? 0
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = getTableViewCellBasedOn(indexPath: indexPath)
        cell.borderWidth = 0.5
        cell.borderColor = .lightGray
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "deviceHV") as! DeviceHeaderView
        let device = availableDeviceCopy[section]
        headerView.deviceLabel.text = device.deviceName
        headerView.section = section
        headerView.device = device
        headerView.delegate = self
        if device.collapsed {
            headerView.arrowImageView.image = UIImage(named: "right_arrow")
        } else {
            headerView.arrowImageView.image = UIImage(named: "down_arrow")
        }
        if device.selectedParams == 0 {
            headerView.selectDeviceButton.setImage(UIImage(named: "checkbox_unselect"), for: .normal)
        } else if device.selectedParams == device.params?.count {
            headerView.selectDeviceButton.setImage(UIImage(named: "checkbox_select"), for: .normal)
        } else {
            headerView.selectDeviceButton.setImage(UIImage(named: "checkbox_partial"), for: .normal)
        }
        return headerView
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
        footerView.backgroundColor = UIColor.clear
        return footerView
    }

    func numberOfSections(in _: UITableView) -> Int {
        return availableDeviceCopy.count
    }
}
