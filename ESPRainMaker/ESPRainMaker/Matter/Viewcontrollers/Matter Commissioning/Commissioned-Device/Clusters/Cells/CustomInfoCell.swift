// Copyright 2023 Espressif Systems
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
//  CustomInfoCell.swift
//  ESPRainmaker
//

import UIKit

enum InfoType {
    case indoorTemperature
    case outdoorTemperature
}

protocol CustomInfoDelegate: AnyObject {
    func infoFetched()
}

class CustomInfoCell: UITableViewCell {
    
    static let reuseIdentifier = "CustomInfoCell"
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var value: UILabel!
    var deviceId: UInt64?
    weak var nodeGroup: ESPNodeGroup?
    var node: ESPNodeDetails?
    var infoType: InfoType = .indoorTemperature
    weak var customInfoDelegate: CustomInfoDelegate?
    @IBOutlet weak var container: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.container.layer.shadowOpacity = 0.18
        self.container.layer.shadowOffset = CGSize(width: 1, height: 2)
        self.container.layer.shadowRadius = 2
        self.container.layer.shadowColor = UIColor.black.cgColor
        self.container.layer.masksToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    /// Set initial indoor temperature
    func setupInitialIndoorTempUI() {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *), let group = self.nodeGroup, let groupId = group.groupID, let deviceId = self.deviceId {
            ESPMTRCommissioner.shared.readLocalTemperature(groupId: groupId, deviceId: deviceId) { localTemperature in
                if let localTemperature = localTemperature {
                    self.value.text = "\(localTemperature) °C"
                    self.node?.setMatterLocalTemperatureValue(temperature: localTemperature, deviceId: deviceId)
                }
            }
        }
        #endif
    }
}
