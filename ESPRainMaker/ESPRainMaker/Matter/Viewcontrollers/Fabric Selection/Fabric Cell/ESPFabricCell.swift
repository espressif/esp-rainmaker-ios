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
//  ESPFabricCell.swift
//  ESPRainMaker
//

import UIKit

class ESPFabricCell: UITableViewCell {
    
    static let reuseIdentifier = "ESPFabricCell"
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var deviceName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.container.layer.cornerRadius = CGFloat(10)
        self.container.layer.backgroundColor = UIColor.white.cgColor
        self.container.layer.shadowColor = UIColor.lightGray.cgColor
        self.container.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        self.container.layer.shadowRadius = 1.0
        self.container.layer.shadowOpacity = 1
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
