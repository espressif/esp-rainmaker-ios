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
//  ParticipantDataCell.swift
//  ESPRainmaker
//

import UIKit

protocol BadgeCellDelegate: AnyObject {
    func updateBadgeData()
}

class ParticipantDataCell: UITableViewCell {
    
    static let reuseIdentifier = "ParticipantDataCell"
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var participantName: UILabel!
    @IBOutlet weak var companyName: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var contact: UILabel!
    @IBOutlet weak var eventName: UILabel!
    @IBOutlet weak var updateButton: UIButton!
    
    weak var delegate: BadgeCellDelegate?
    
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
    
    
    @IBAction func updateParticipantDataInvoked(_ sender: Any) {
        self.delegate?.updateBadgeData()
    }
    
    func setupUI(data: ESPParticipantData) {
        if let name = data.name {
            self.participantName.text = name.replacingOccurrences(of: "\0", with: "")
        }
        if let companyName = data.companyName {
            self.companyName.text = companyName.replacingOccurrences(of: "\0", with: "")
        }
        if let email = data.email {
            self.email.text = email.replacingOccurrences(of: "\0", with: "")
        }
        if let contact = data.contact {
            self.contact.text = contact.replacingOccurrences(of: "\0", with: "")
        }
        if let eventName = data.eventName {
            self.eventName.text = eventName.replacingOccurrences(of: "\0", with: "")
        }
    }
}
