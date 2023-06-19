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
//  BindingTableViewCell.swift
//  ESPRainmaker
//

import UIKit


enum Action {
    case add
    case delete
    case none
}

protocol BindingTableViewCellDelegate: AnyObject {
    func executeLinkingAction(node: ESPNodeDetails?, action: Action)
}

class BindingTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "BindingTableViewCell"
    @IBOutlet weak var actionImage: UIImageView!
    @IBOutlet weak var deviceImage: UIImageView!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var actionImageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionImageProportionalHeight: NSLayoutConstraint!
    var destinationNode: ESPNodeDetails?
    var indexPath: IndexPath!
    var action: Action = .none
    var name: String = ESPMatterConstants.emptyString
    weak var delegate: BindingTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.deviceImage.backgroundColor = UIColor.white
        self.deviceImage.layer.cornerRadius = 4.0
        self.deviceImage.layer.borderWidth = 1.0
        self.deviceImage.layer.borderColor = UIColor.darkGray.cgColor
        self.deviceImage.layer.masksToBounds = true
        self.deviceImage.image = UIImage(named: "default")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(actionCalled))
        self.actionImage.addGestureRecognizer(tapGesture)
    }
    
    @objc func actionCalled() {
        self.delegate?.executeLinkingAction(node: destinationNode, action: self.action)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupUI(flag: Bool, height: CGFloat) {
        if flag {
            if action == .add {
                self.actionImage.image = UIImage(named: ESPMatterConstants.add)
            } else if action == .delete {
                self.actionImage.image = UIImage(named: ESPMatterConstants.delete)
            }
            self.actionImageLeadingConstraint.constant = 10
            self.actionImageProportionalHeight.constant = height/2.0
        } else {
            self.actionImageLeadingConstraint.constant = 0
            self.actionImageProportionalHeight.constant = 0.0
        }
    }
}
