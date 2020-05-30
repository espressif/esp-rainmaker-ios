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
//  SliderTableViewCell.swift
//  ESPRainMaker
//

import MBProgressHUD
import UIKit

class SliderTableViewCell: UITableViewCell {
    @IBOutlet var sliderValue: UILabel!
    @IBOutlet var slider: BrightnessSlider!
    @IBOutlet var backView: UIView!
    @IBOutlet var title: UILabel!

    var paramName: String!
    var device: Device!
    var dataType: String!

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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        if Utility.isConnected(view: parentViewController!.view) {
            if dataType.lowercased() == "int" {
                sliderValue.text = paramName + ": \(Int(slider.value))"
                NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: Int(sender.value)]])
            } else {
                sliderValue.text = paramName + ": \(slider.value)"
                NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: sender.value]])
            }
        }
    }
}
