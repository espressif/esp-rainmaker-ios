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
//  RequestAcceptedCell.swift
//  ESPRainmaker
//

import UIKit
import Foundation

protocol RequestAccpetedActionDelegate: AnyObject {
    func removeSharing(groupId: String, sharedWith: String)
}

class RequestAcceptedCell: UITableViewCell {
    
    static let reuseIdentifier: String = "RequestAcceptedCell"
    var sharing: ESPNodeGroupSharingStruct?
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var sharingAcceptedMessage: UILabel!
    @IBOutlet weak var cancelRequestButton: UIButton!
    var delegate: RequestAccpetedActionDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.container.layer.borderWidth = 1
        self.container.layer.cornerRadius = 10
        self.container.layer.borderColor = UIColor.lightGray.cgColor
        self.container.layer.masksToBounds = true
        self.cancelRequestButton.backgroundColor = UIColor(hexString: ESPMatterConstants.customBackgroundColor)
        self.cancelRequestButton.tintColor = UIColor(hexString: ESPMatterConstants.customBackgroundColor)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    /// Setup UI
    func setupUI() {
        if let sharing = sharing, let grpId = sharing.groupId, let nodeDetails = ESPMatterFabricDetails.shared.getNodeGroupDetails(groupId: grpId), let groups = nodeDetails.groups, let sharedBy = sharing.sharedBy {
            var groupName: String?
            for group in groups {
                if let id = group.groupID, id == grpId, let name = group.groupName {
                    groupName = name
                    break
                }
            }
            self.sharingAcceptedMessage.text = "Group was shared by \(sharedBy)."
            if let groupName = groupName {
                self.sharingAcceptedMessage.text = "Group \(groupName) was shared by \(sharedBy)."
            }
        }
    }
    
    /// Remove sharing
    /// - Parameter sender: sender
    @IBAction func removeSharing(_ sender: Any) {
        DispatchQueue.main.async {
            if let sharing = self.sharing, let grpId = sharing.groupId, let sharedWith = sharing.sharedWith {
                self.delegate?.removeSharing(groupId: grpId, sharedWith: sharedWith)
            }
        }
    }
}
