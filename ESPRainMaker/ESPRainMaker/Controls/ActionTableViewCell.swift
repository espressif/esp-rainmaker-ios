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
//  ActionTableViewCell.swift
//  ESPRainMaker
//

import UIKit

protocol ActionTableViewCellDelegate: AnyObject {
    func actionInvoked(device: Device?, param: Param?, paramName: String)
}

class ActionTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "ActionTableViewCell"
    weak var delegate: ActionTableViewCellDelegate?
    
    @IBOutlet var backView: UIView!
    @IBOutlet weak var invokeActionButton: PrimaryButton!
    @IBOutlet var controlValueLabel: UILabel!
    
    var param: Param!
    var device: Device!
    var attributeKey = ""
    var paramName: String = ""
    
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
    
    @IBAction func invokeAction(_ sender: Any) {
        self.delegate?.actionInvoked(device: device, param: param, paramName: paramName)
    }
}
