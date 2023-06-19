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
//  RequestsReceivedCell.swift
//  ESPRainmaker
//

import UIKit

protocol RequestReceivedAction: AnyObject {
    func acceptRequest(request: ESPNodeGroupSharingRequest?)
    func declineRequest(request: ESPNodeGroupSharingRequest?)
}

class RequestsReceivedCell: UITableViewCell {
    
    static let reuseIdentifier: String = "RequestsReceivedCell"
    var request: ESPNodeGroupSharingRequest?
    weak var delegate: RequestReceivedAction?
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var sharingRequestMessage: UILabel!
    @IBOutlet weak var acceptRequestView: UIView!
    @IBOutlet weak var declineRequestView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.configure()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    /// Configure cell
    func configure() {
        self.container.layer.borderWidth = 1
        self.container.layer.cornerRadius = 10
        self.container.layer.borderColor = UIColor.lightGray.cgColor
        self.container.layer.masksToBounds = true
        let accept = UITapGestureRecognizer(target: self, action: #selector(acceptRequest))
        self.acceptRequestView.addGestureRecognizer(accept)
        let decline = UITapGestureRecognizer(target: self, action: #selector(declineRequest))
        self.declineRequestView.addGestureRecognizer(decline)
    }
    
    /// Setup UI
    func setupUI() {
        if let request = self.request, let sharedBy = request.sharedBy, let groupId = request.groupId {
            self.sharingRequestMessage.text = "Group \(groupId) was shared by \(sharedBy)."
            if let groupName = request.groupName {
                self.sharingRequestMessage.text = "Group \(groupName) was shared by \(sharedBy)."
            }
        }
    }
    
    /// accept sharing request
    @objc func acceptRequest() {
        self.delegate?.acceptRequest(request: self.request)
    }
    
    /// decline sharing request
    @objc func declineRequest() {
        self.delegate?.declineRequest(request: self.request)
    }
}
