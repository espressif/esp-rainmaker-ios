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
//  RequestSentCell.swift
//  ESPRainmaker
//

import UIKit

protocol RequestSentActionDelegate: AnyObject {
    func deleteSharing(groupId: String, sharedWith: String)
    func deleteRequest(requestId: String)
}

class RequestSentCell: UITableViewCell {
    
    static let reuseIdentifier: String = "RequestSentCell"
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var sharedWithText: UILabel!
    @IBOutlet weak var cancelRequestButton: UIButton!
    var request: ESPNodeGroupSharingRequest?
    var sharing: ESPNodeGroupSharingStruct?
    weak var delegate: RequestSentActionDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.container.layer.borderWidth = 1
        self.container.layer.cornerRadius = 10
        self.container.layer.borderColor = UIColor.lightGray.cgColor
        self.container.layer.masksToBounds = true
        if let request = self.request, let sharedWith = request.sharedWith {
            self.sharedWithText.text = "Group shared with \(sharedWith)."
        }
        self.cancelRequestButton.backgroundColor = UIColor(hexString: ESPMatterConstants.customBackgroundColor)
        self.cancelRequestButton.tintColor = UIColor(hexString: ESPMatterConstants.customBackgroundColor)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    /// Cancel request
    @IBAction func cancelRequest(_ sender: Any) {
        if let request = self.request, let requestId = request.requestId {
            self.delegate?.deleteRequest(requestId: requestId)
        } else if let sharing = self.sharing, let sharedWith = sharing.sharedWith, let groupId = sharing.groupId {
            self.delegate?.deleteSharing(groupId: groupId, sharedWith: sharedWith)
        }
    }
    
    /// Setup sharing request cell UI
    func setupUI() {
        DispatchQueue.main.async {
            if let request = self.request, let sharedWith = request.sharedWith {
                self.sharedWithText.text = "Group shared with \(sharedWith) is pending for approval."
                if let groupName = request.groupName {
                    self.sharedWithText.text = "Group \(groupName) shared with \(sharedWith) is pending for approval."
                }
                self.cancelRequestButton.setTitle(ESPMatterConstants.cancelTxt, for: .normal)
            } else if let sharing = self.sharing, let sharedWith = sharing.sharedWith {
                self.sharedWithText.text = "Group shared with \(sharedWith)."
                if let grpId = sharing.groupId, let data = ESPMatterFabricDetails.shared.getGroupData(groupId: grpId), let groupName = data.groupName {
                    self.sharedWithText.text = "Group \(groupName) shared with \(sharedWith)."
                }
                self.cancelRequestButton.setTitle(ESPMatterConstants.revoke, for: .normal)
            }
            self.cancelRequestButton.backgroundColor = UIColor(hexString: ESPMatterConstants.customBackgroundColor)
            self.cancelRequestButton.tintColor = UIColor(hexString: ESPMatterConstants.customBackgroundColor)
        }
    }
}
