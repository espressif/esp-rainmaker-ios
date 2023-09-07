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
//  DeviceNameCell.swift
//  ESPRainmaker
//

import UIKit
import Foundation

protocol DeviceNameDelegate: NSObject {
    func editNamePressed(rainmakerNode: Node?, completion: @escaping (String?) -> Void)
}

class DeviceNameCell: UITableViewCell {
    
    static let reuseIdentifier = "DeviceNameCell"
    @IBOutlet weak var propertyName: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var container: UIView!
    weak var delegate: DeviceNameDelegate?
    var rainmakerNode: Node?
    
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
    
    @IBAction func editButtonPressed(_ sender: Any) {
        self.delegate?.editNamePressed(rainmakerNode: self.rainmakerNode) { name in
            if let name = name {
                self.deviceName.text = name
            }
        }
    }
}
