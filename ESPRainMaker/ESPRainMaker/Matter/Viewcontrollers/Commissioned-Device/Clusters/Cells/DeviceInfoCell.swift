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
//  DeviceInfoCell.swift
//  ESPRainmaker
//

import UIKit
import Foundation

enum DeviceInfo {
    case deviceName
    case matterDeviceName
}

protocol DeviceNameDelegate: NSObject {
    func editNamePressed(rainmakerNode: Node?, completion: @escaping (String?) -> Void)
    func editMTRDeviceNamePressed(rainmakerNode: Node?, deviceName: String, completion: @escaping (String?) -> Void)
}

class DeviceInfoCell: UITableViewCell {
    
    static let reuseIdentifier = "DeviceInfoCell"
    @IBOutlet weak var propertyName: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var editButton: UIButton!
    weak var delegate: DeviceNameDelegate?
    var rainmakerNode: Node?
    var deviceInfo: DeviceInfo = .deviceName
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.container.layer.shadowOpacity = 0.18
        self.container.layer.shadowOffset = CGSize(width: 1, height: 2)
        self.container.layer.shadowRadius = 2
        self.container.layer.shadowColor = UIColor.black.cgColor
        self.container.layer.masksToBounds = false
        self.setEditButtonTextColor(UIColor(hexString: Constants.customColor))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        switch deviceInfo {
        case .deviceName:
            self.delegate?.editNamePressed(rainmakerNode: self.rainmakerNode) { name in
                if let name = name {
                    self.deviceName.text = name
                }
            }
        case .matterDeviceName:
            if let node = self.rainmakerNode, let deviceName = node.matterDeviceName {
                self.delegate?.editMTRDeviceNamePressed(rainmakerNode: self.rainmakerNode, deviceName: deviceName) { nodeLabel in
                    if let nodeLabel = nodeLabel {
                        DispatchQueue.main.async {
                            self.deviceName.text = nodeLabel
                        }
                    }
                }
            }
        }
    }
    
    func setEditButtonTextColor(_ color: UIColor) {
        editButton.setTitleColor(color, for: .normal)
    }
}
