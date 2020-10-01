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
//  DeviceHeaderView.swift
//  ESPRainMaker
//
#if SCHEDULE
    import UIKit

    protocol ScheduleActionDelegate {
        func headerViewDidTappedFor(section: Int)
        func paramStateChangedat(indexPath: IndexPath)
    }

    class DeviceHeaderView: UITableViewHeaderFooterView {
        @IBOutlet var deviceLabel: UILabel!
        @IBOutlet var arrowImageView: UIImageView!
        @IBOutlet var selectDeviceButton: UIButton!
        var delegate: ScheduleActionDelegate?
        var section: Int!
        var device: Device!

        @IBAction func headerViewTapped(_: Any) {
            delegate?.headerViewDidTappedFor(section: section)
        }

        @IBAction func selectDeviceParams(_: Any) {
            if device.selectedParams == 0 {
                selectDeviceButton.setImage(UIImage(named: "checkbox_select"), for: .normal)
                for param in device.params! {
                    param.selected = true
                    device.selectedParams += 1
                }
                delegate?.paramStateChangedat(indexPath: IndexPath(row: 0, section: section))
            } else if device.selectedParams == device.params?.count {
                selectDeviceButton.setImage(UIImage(named: "checkbox_unselect"), for: .normal)
                for param in device.params! {
                    param.selected = false
                }
                device.selectedParams = 0
                delegate?.paramStateChangedat(indexPath: IndexPath(row: 0, section: section))
            } else {
                selectDeviceButton.setImage(UIImage(named: "checkbox_unselect"), for: .normal)
                for param in device.params! {
                    param.selected = false
                }
                device.selectedParams = 0
                delegate?.paramStateChangedat(indexPath: IndexPath(row: 0, section: section))
            }
        }
    }
#endif
