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
//  ScheduleSliderTableViewCell.swift
//  ESPRainMaker
//
#if SCHEDULE
    import UIKit

    class ScheduleSliderTableViewCell: UITableViewCell {
        @IBOutlet var slider: UISlider!
        @IBOutlet var minLabel: UILabel!
        @IBOutlet var maxLabel: UILabel!
        @IBOutlet var backView: UIView!
        @IBOutlet var title: UILabel!
        @IBOutlet var checkButton: UIButton!
        @IBOutlet var hueSlider: GradientSlider!
        var delegate: ScheduleActionDelegate?

        var param: Param!
        var sliderValue: Any!
        var device: Device!
        var indexPath: IndexPath!
        var currentHueValue: CGFloat = 0

        override func awakeFromNib() {
            super.awakeFromNib()
            // Initialization code
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)

            // Configure the view for the selected state
        }

        @IBAction func selectPressed(_: Any) {
            if param.selected {
                hueSlider.isEnabled = false
                slider.isEnabled = false
                param.selected = false
                checkButton.setImage(UIImage(named: "unselected"), for: .normal)
                device.selectedParams -= 1
            } else {
                hueSlider.isEnabled = true
                slider.isEnabled = true
                param.selected = true
                checkButton.setImage(UIImage(named: "selected"), for: .normal)
                device.selectedParams += 1
            }
            delegate?.paramStateChangedat(indexPath: indexPath)
        }

        @IBAction func sliderValueChanged(slider: UISlider) {
            if ESPNetworkMonitor.shared.isConnectedToNetwork {
                if param.dataType?.lowercased() ?? "" == "int" {
                    param.value = Int(slider.value)
                } else {
                    param.value = slider.value
                }
            }
        }

        @IBAction func hueSliderValueDragged(_ sender: GradientSlider) {
            hueSlider.thumbColor = UIColor(hue: CGFloat(sender.value / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        }

        @IBAction func hueSliderValueChanged(_ sender: GradientSlider) {
            if currentHueValue != sender.value {
                hueSlider.thumbColor = UIColor(hue: CGFloat(sender.value / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
                if param.dataType?.lowercased() ?? "" == "int" {
                    param.value = Int(sender.value)
                } else {
                    param.value = sender.value
                }
                currentHueValue = sender.value
            }
        }
    }
#endif
