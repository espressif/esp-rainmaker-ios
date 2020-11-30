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
//  GenericSliderTableViewCell.swift
//  ESPRainMaker
//

import MBProgressHUD
import UIKit

///  Protocol to update listeners about failure in updating params
protocol ParamUpdateProtocol {
    func failureInUpdatingParam()
}

class GenericSliderTableViewCell: UITableViewCell, ParamUpdateProtocol {
    @IBOutlet var slider: UISlider!
    @IBOutlet var minLabel: UILabel!
    @IBOutlet var maxLabel: UILabel!
    @IBOutlet var backView: UIView!
    @IBOutlet var title: UILabel!
    @IBOutlet var hueSlider: GradientSlider!

    var paramName: String = ""
    var device: Device!
    var dataType: String!
    var sliderValue = ""
    var delegate: ParamUpdateProtocol?
    var currentHueValue: CGFloat = 0

    override func awakeFromNib() {
        super.awakeFromNib()
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
        //        slider.setMinimumTrackImage(UIImage(named: "min_track_image"), for: .normal)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        if dataType.lowercased() == "int" {
            sliderValue = paramName + ": \(Int(slider.value))"
            NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: Int(sender.value)]]) { result in
                switch result {
                case .failure:
                    self.failureInUpdatingParam()
                default:
                    break
                }
            }
            NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: Int(sender.value)]]) { result in
                switch result {
                case .failure:
                    self.failureInUpdatingParam()
                default:
                    break
                }
            }
        } else {
            sliderValue = paramName + ": \(slider.value)"
            NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: sender.value]]) { result in
                switch result {
                case .failure:
                    self.failureInUpdatingParam()
                default:
                    break
                }
            }
        }
    }

    @IBAction func hueSliderValueDragged(_ sender: GradientSlider) {
        hueSlider.thumbColor = UIColor(hue: CGFloat(sender.value / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }

    @IBAction func hueSliderValueChanged(_ sender: GradientSlider) {
        if currentHueValue != sender.value {
            hueSlider.thumbColor = UIColor(hue: CGFloat(sender.value / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
            print("hue value changed \(sender.value)")
            NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: Int(sender.value)]]) { result in
                switch result {
                case .failure:
                    self.failureInUpdatingParam()
                default:
                    break
                }
            }
            currentHueValue = sender.value
        }
    }

    func failureInUpdatingParam() {
        delegate?.failureInUpdatingParam()
    }
}
