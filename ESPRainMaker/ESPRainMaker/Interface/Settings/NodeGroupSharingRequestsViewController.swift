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
//  NodeGroupSharingRequestsViewController.swift
//  ESPRainMaker
//

import Foundation

import UIKit

class NodeGroupSharingRequestsViewController: UIViewController {
    
    static let storyboardId: String = "NodeGroupSharingRequestsViewController"
    @IBOutlet weak var requestsTable: UITableView!
    @IBOutlet weak var initialView: UIView!
    var acceptedSharings: [ESPNodeGroupSharingStruct] = []
    var pendingNodeGroupRequests: [ESPNodeGroupSharingRequest] = []
    var requestsSent: [ESPNodeGroupSharingRequest] = []
    var sharingsAcceptedBy: [ESPNodeGroupSharingStruct] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
        title = "Group Sharing"
        self.navigationController?.addCustomBottomLine(color: .black, height: 0.5)
        self.navigationController?.view.backgroundColor = .clear
        self.setNavigationTextAttributes(color: .darkGray)
        let goBackButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(goBack))
        goBackButton.tintColor = .systemBlue
        self.navigationItem.leftBarButtonItem = goBackButton
        requestsTable.register(UINib(nibName: RequestSentCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: RequestSentCell.reuseIdentifier)
        requestsTable.register(UINib(nibName: RequestsReceivedCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: RequestsReceivedCell.reuseIdentifier)
        requestsTable.register(UINib(nibName: RequestAcceptedCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: RequestAcceptedCell.reuseIdentifier)
        self.setDefaultData()
        self.refreshSharingData()
    }
    
    func setDefaultData() {
        self.acceptedSharings = ESPMatterFabricDetails.shared.fetchAcceptedSharings()
        self.pendingNodeGroupRequests = ESPMatterFabricDetails.shared.fetchPendingNodeGroupRequests()
        self.requestsSent = ESPMatterFabricDetails.shared.fetchRequestsSent()
        self.sharingsAcceptedBy = ESPMatterFabricDetails.shared.fetchSharingsAcceptedBy()
        self.updateTableView()
    }
    
    /// Refresh sharing data
    /// - Parameters:
    ///   - fetchNodeGroupSharingRequests: fetch node group sharing requests sent
    ///   - acceptedByUserRequests: requests accepted by user
    ///   - nodeGroupSharingRequests: node group sharing requests (received)
    ///   - acceptedSharingRequests: accepted sharing requests
    func refreshSharingData(fetchNodeGroupSharingRequests: Bool = true,
                            acceptedByUserRequests: Bool = true,
                            nodeGroupSharingRequests: Bool = true,
                            acceptedSharingRequests: Bool = true) {
        Utility.showLoader(message: "Fetching sharing requests...", view: self.view)
        self.fetchNodeGroupSharingRequestsSent(skip: !fetchNodeGroupSharingRequests) {
            self.getAcceptedByUserRequests(skip: !acceptedByUserRequests) {
                self.getNodeGroupSharingRequests(skip: !nodeGroupSharingRequests) {
                    self.getAcceptedSharingRequests(skip: !acceptedSharingRequests) {
                        Utility.hideLoader(view: self.view)
                        self.updateTableView()
                    }
                }
            }
        }
    }
    
    func updateTableView() {
        DispatchQueue.main.async {
            if self.acceptedSharings.count + self.pendingNodeGroupRequests.count + self.requestsSent.count + self.sharingsAcceptedBy.count == 0 {
                self.initialView.isHidden = false
                self.requestsTable.isHidden = true
            } else {
                self.initialView.isHidden = true
                self.requestsTable.isHidden = false
                self.requestsTable.reloadData()
            }
        }
    }
}

//MARK: fetching sharing data
extension NodeGroupSharingRequestsViewController {
    
    // MARK: - Private Methods
    
    /// Fetch node group requests sent
    private func fetchNodeGroupSharingRequestsSent(skip: Bool = false, completion: @escaping () -> Void) {
        if skip {
            completion()
        }
        NodeGroupSharingManager.shared.getNodeGroupSharingRequests(isPrimary: true) { data in
            if let data = data {
                if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = response[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.failure {
                    completion()
                    return
                }
                ESPMatterFabricDetails.shared.saveNodeGroupSharingRequestsSent(data: data)
                self.requestsSent = self.fetchRequests()
                ESPMatterFabricDetails.shared.saveRequestsSent(requestsSent: self.requestsSent)
                completion()
            } else {
                completion()
            }
        }
    }
    
    /// Fetch requests
    private func fetchRequests() -> [ESPNodeGroupSharingRequest] {
        var sRequets = [ESPNodeGroupSharingRequest]()
        if let sharingRequests = ESPMatterFabricDetails.shared.getNodeGroupSharingRequestsSent(), let requests = sharingRequests.sharingRequests {
            for sharingRequest in requests {
                if let primaryUser = sharingRequest.sharedBy, primaryUser == User.shared.userInfo.email, let groupIds = sharingRequest.groupIds, let sharedWith = sharingRequest.sharedWith, let requestStatus = sharingRequest.requestStatus, requestStatus.lowercased() == ESPMatterConstants.pending.lowercased() {
                    var groupName: String? = nil
                    if let metadata = sharingRequest.metadata, let name = metadata[ESPMatterConstants.groupName] as? String {
                        groupName = name
                    }
                    for groupId in groupIds {
                        let req = ESPNodeGroupSharingRequest(requestId: sharingRequest.requestId, requestStatus: sharingRequest.requestStatus, requestTimestamp: sharingRequest.requestTimestamp, groupId: groupId, sharedWith: sharedWith, sharedBy: primaryUser, groupName: groupName)
                        sRequets.append(req)
                    }
                }
            }
        }
        return sRequets
    }
    
    /// Get requests accepted by secondary user
    private func getAcceptedByUserRequests(skip: Bool = false, completion: @escaping () -> Void) {
        if skip {
            completion()
        }
        NodeGroupSharingManager.shared.getNodeGroupSharing { sharedData in
            if let sharedData = sharedData, let response = try? JSONSerialization.jsonObject(with: sharedData) as? [String: Any], let status = response[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.failure {
                completion()
                return
            }
            if let sharedData = sharedData {
                ESPMatterFabricDetails.shared.saveNodeGroupSharing(data: sharedData)
            }
            self.sharingsAcceptedBy = self.fetchNodeGroupSharings()
            ESPMatterFabricDetails.shared.saveSharingsAcceptedBy(sharingsAcceptedBy: self.sharingsAcceptedBy)
            completion()
        }
    }
    
    /// setup node group sharings
    private func fetchNodeGroupSharings() -> [ESPNodeGroupSharingStruct] {
        var sharings = [ESPNodeGroupSharingStruct]()
        if let value = ESPMatterFabricDetails.shared.getNodeGroupSharing(), let groupSharing = value.groupSharing {
            for sharing in groupSharing {
                if let grpId = sharing.groupID, let users = sharing.users, let sharedByUsers = users.primary, let sharedWithUsers = users.secondary, sharedByUsers.contains(User.shared.userInfo.email), sharedWithUsers.count > 0 {
                    for secondary in sharedWithUsers {
                        let shar = ESPNodeGroupSharingStruct(groupId: grpId, sharedWith: secondary, sharedBy: User.shared.userInfo.email)
                        sharings.append(shar)
                    }
                }
            }
        }
        return sharings
    }
    
    /// Get pending requests
    private func getNodeGroupSharingRequests(skip: Bool = false, completion: @escaping () -> Void) {
        if skip {
            completion()
        }
        NodeGroupSharingManager.shared.getNodeGroupSharingRequests(isPrimary: false) { data in
            if let data = data {
                print(String(bytes: data, encoding: .utf8)!)
                if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = response[ESPMatterConstants.status] as? String, status.lowercased() == "failure" {
                    completion()
                    return
                }
                ESPMatterFabricDetails.shared.saveNodeGroupSharingRequestsReceived(data: data)
                self.pendingNodeGroupRequests = self.setupPendingRequests()
                ESPMatterFabricDetails.shared.savePendingNodeGroupRequests(pendingNodeGroupRequests: self.pendingNodeGroupRequests)
                completion()
            } else {
                completion()
            }
        }
    }
    
    /// Setup pending requests
    private func setupPendingRequests() -> [ESPNodeGroupSharingRequest] {
        var sRequests = [ESPNodeGroupSharingRequest]()
        if let sharingRequests = ESPMatterFabricDetails.shared.getNodeGroupSharingRequestsReceived() {
            if let requests = sharingRequests.sharingRequests, requests.count > 0 {
                for request in requests {
                    if let sharedWith = request.sharedWith, sharedWith == User.shared.userInfo.email, let sharedBy = request.sharedBy, let requestId = request.requestId, let status = request.requestStatus, status.lowercased() == ESPMatterConstants.pending {
                        var groupName: String? = nil
                        if let metadata = request.metadata, let name = metadata[ESPMatterConstants.groupName] as? String {
                            groupName = name
                        }
                        let req = ESPNodeGroupSharingRequest(requestId: requestId, requestStatus: request.requestStatus, requestTimestamp: request.requestTimestamp, groupId: request.groupIds?.first, sharedWith: sharedWith, sharedBy: sharedBy, groupName: groupName)
                        sRequests.append(req)
                    }
                }
            }
        }
        return sRequests
    }
    
    /// Get accepted sharing requests
    private func getAcceptedSharingRequests(skip: Bool = false, completion: @escaping () -> Void) {
        if skip {
            completion()
        }
        NodeGroupSharingManager.shared.getNodeGroupSharing { sharedData in
            if let sharedData = sharedData {
                if let response = try? JSONSerialization.jsonObject(with: sharedData) as? [String: Any], let status = response[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.failure {
                    completion()
                    return
                }
                ESPMatterFabricDetails.shared.saveNodeGroupSharing(data: sharedData)
                self.acceptedSharings = self.setupNodeGroupSharings()
                ESPMatterFabricDetails.shared.saveAcceptedSharings(acceptedSharings: self.acceptedSharings)
                completion()
            } else {
                completion()
            }
        }
    }
    
    /// Setup node group sharings
    private func setupNodeGroupSharings() -> [ESPNodeGroupSharingStruct] {
        var sharings = [ESPNodeGroupSharingStruct]()
        if let value = ESPMatterFabricDetails.shared.getNodeGroupSharing(), let groupSharing = value.groupSharing {
            for sharing in groupSharing {
                if let groupId = sharing.groupID, let users = sharing.users, let sharedByUsers = users.primary, let sharedWithUsers = users.secondary, sharedWithUsers.contains(User.shared.userInfo.email), let primary = sharedByUsers.first {
                    let shar = ESPNodeGroupSharingStruct(groupId: groupId, sharedWith: User.shared.userInfo.email, sharedBy: primary)
                    sharings.append(shar)
                }
            }
        }
        return sharings
    }
    
}

extension NodeGroupSharingRequestsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let total = self.pendingNodeGroupRequests.count + self.requestsSent.count + self.sharingsAcceptedBy.count + self.acceptedSharings.count
        if indexPath.row < total {
            if indexPath.row < self.pendingNodeGroupRequests.count {
                //sharing
                let request = pendingNodeGroupRequests[indexPath.row]
                if let sharedBy = request.sharedBy, let groupId = request.groupId {
                    var text = "Group \(groupId) was shared by \(sharedBy)."
                    if let groupName = request.groupName {
                        text = "Group \(groupName) was shared by \(sharedBy)."
                    }
                    let height = text.getViewHeight(labelWidth: tableView.frame.width-80.0, font: UIFont.systemFont(ofSize: 15.0))
                    return height+86.0
                }
            } else if indexPath.row >= self.pendingNodeGroupRequests.count, indexPath.row < self.pendingNodeGroupRequests.count + self.requestsSent.count {
                //requests sent
                let count = indexPath.row - self.pendingNodeGroupRequests.count
                let request = self.requestsSent[count]
                let padding = 160.0
                let constrainedWidth = tableView.frame.width - padding
                if let sharedWith = request.sharedWith {
                    var text = "Group shared with \(sharedWith) is pending for approval."
                    if let groupName = request.groupName {
                        text = "Group \(groupName) shared with \(sharedWith) is pending for approval."
                    }
                    let height = text.getViewHeight(labelWidth: constrainedWidth, font: UIFont.systemFont(ofSize: 16.0, weight: .semibold))
                    return height + 45.0
                }
            } else if indexPath.row >= self.pendingNodeGroupRequests.count + self.requestsSent.count, indexPath.row < self.pendingNodeGroupRequests.count + self.requestsSent.count + self.sharingsAcceptedBy.count {
                //requests accepted by secondary user
                let count = indexPath.row - (self.pendingNodeGroupRequests.count + self.requestsSent.count)
                let sharing = self.sharingsAcceptedBy[count]
                let padding = 160.0
                let constrainedWidth = tableView.frame.width - padding
                if let sharedWith = sharing.sharedWith {
                    let text = "Group shared with \(sharedWith)."
                    let height = text.getViewHeight(labelWidth: constrainedWidth, font: UIFont.systemFont(ofSize: 16.0, weight: .semibold))
                    return height + 45.0
                }
            } else if indexPath.row >= self.pendingNodeGroupRequests.count + self.requestsSent.count + self.sharingsAcceptedBy.count, indexPath.row < self.pendingNodeGroupRequests.count + self.requestsSent.count + self.sharingsAcceptedBy.count + acceptedSharings.count {
                //requests accepted by user
                let count = indexPath.row - (self.pendingNodeGroupRequests.count + self.requestsSent.count + self.sharingsAcceptedBy.count)
                let sharing = acceptedSharings[count]
                if let grpId = sharing.groupId, let nodeDetails = ESPMatterFabricDetails.shared.getNodeGroupDetails(groupId: grpId), let groups = nodeDetails.groups, let sharedBy = sharing.sharedBy {
                    var groupName: String?
                    for group in groups {
                        if let id = group.groupID, id == grpId, let name = group.groupName {
                            groupName = name
                            break
                        }
                    }
                    var text = "Group was shared by \(sharedBy)."
                    if let groupName = groupName {
                        text = "Group \(groupName) was shared by \(sharedBy)."
                    }
                    let height = text.getViewHeight(labelWidth: tableView.frame.width-185.0, font: UIFont.systemFont(ofSize: 15.0))
                    return height+80.0
                }
            } else {
                return 0.0
            }
        }
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let total = self.pendingNodeGroupRequests.count + self.requestsSent.count + self.sharingsAcceptedBy.count + self.acceptedSharings.count
        if indexPath.row < total {
            if indexPath.row < self.pendingNodeGroupRequests.count {
                //accepted sharing
                if let cell = tableView.dequeueReusableCell(withIdentifier: RequestsReceivedCell.reuseIdentifier, for: indexPath) as? RequestsReceivedCell {
                    cell.request = pendingNodeGroupRequests[indexPath.row]
                    cell.setupUI()
                    cell.delegate = self
                    return cell
                }
            } else if indexPath.row >= self.pendingNodeGroupRequests.count, indexPath.row < self.pendingNodeGroupRequests.count + self.requestsSent.count {
                //requests sent
                let count = indexPath.row - self.pendingNodeGroupRequests.count
                if let cell = tableView.dequeueReusableCell(withIdentifier: RequestSentCell.reuseIdentifier, for: indexPath) as? RequestSentCell {
                    let request = self.requestsSent[count]
                    cell.request = request
                    cell.sharing = nil
                    cell.setupUI()
                    cell.delegate = self
                    return cell
                }
            } else if indexPath.row >= self.pendingNodeGroupRequests.count + self.requestsSent.count, indexPath.row < self.pendingNodeGroupRequests.count + self.requestsSent.count + self.sharingsAcceptedBy.count {
                //requests accepted by secondary user
                let count = indexPath.row - (self.pendingNodeGroupRequests.count + self.requestsSent.count)
                if let cell = tableView.dequeueReusableCell(withIdentifier: RequestSentCell.reuseIdentifier, for: indexPath) as? RequestSentCell {
                    let sharing = sharingsAcceptedBy[count]
                    cell.request = nil
                    cell.sharing = sharing
                    cell.setupUI()
                    cell.delegate = self
                    return cell
                }
            } else {
                //requests accepted by user
                let count = indexPath.row - (self.pendingNodeGroupRequests.count + self.requestsSent.count + self.sharingsAcceptedBy.count)
                if let cell = tableView.dequeueReusableCell(withIdentifier: RequestAcceptedCell.reuseIdentifier, for: indexPath) as? RequestAcceptedCell {
                    let sharing = acceptedSharings[count]
                    cell.sharing = sharing
                    cell.setupUI()
                    cell.delegate = self
                    return cell
                }
            }
        }
        return UITableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.acceptedSharings.count + self.pendingNodeGroupRequests.count + self.requestsSent.count + self.sharingsAcceptedBy.count
    }
    
    
}

extension NodeGroupSharingRequestsViewController: RequestReceivedAction {
    
    /// Accept group shared by another user
    /// - Parameter request: request
    func acceptRequest(request: ESPNodeGroupSharingRequest?) {
        if let request = request, let requestId = request.requestId {
            Utility.showLoader(message: "Accepting request...", view: self.view)
            NodeGroupSharingManager.shared.actOnSharingRequest(requestId: requestId, accept: true) { result in
                Utility.hideLoader(view: self.view)
                if result {
                    User.shared.updateDeviceList = true
                    self.refreshSharingData(fetchNodeGroupSharingRequests: false,
                                              acceptedByUserRequests: false,
                                              nodeGroupSharingRequests: true,
                                              acceptedSharingRequests: true)
                } else {
                    self.showErrorAlert(title: ESPMatterConstants.failureTxt, message: "Failed to accept request.", buttonTitle: ESPMatterConstants.okTxt, callback: {})
                }
            }
        }
    }
    
    /// Decline group sharing request
    /// - Parameter request: sharing request
    func declineRequest(request: ESPNodeGroupSharingRequest?) {
        if let request = request, let requestId = request.requestId {
            Utility.showLoader(message: "Declining request...", view: self.view)
            NodeGroupSharingManager.shared.actOnSharingRequest(requestId: requestId, accept: false) { result in
                Utility.hideLoader(view: self.view)
                if result {
                    User.shared.updateDeviceList = true
                    self.showErrorAlert(title: ESPMatterConstants.successTxt, message: "Request declined successfully.", buttonTitle: ESPMatterConstants.okTxt, callback: {
                        self.refreshSharingData(fetchNodeGroupSharingRequests: false,
                                                  acceptedByUserRequests: false,
                                                  nodeGroupSharingRequests: true,
                                                  acceptedSharingRequests: false)
                    })
                } else {
                    self.showErrorAlert(title: ESPMatterConstants.failureTxt, message: "Failed to decline request.", buttonTitle: ESPMatterConstants.okTxt, callback: {})
                }
            }
        }
    }
}


extension NodeGroupSharingRequestsViewController: RequestSentActionDelegate {
    
    func deleteSharing(groupId: String, sharedWith: String) {
        let noAction = UIAlertAction(title: ESPMatterConstants.noTxt, style: .default)
        let yesAction = UIAlertAction(title: ESPMatterConstants.yesTxt, style: .destructive, handler: { _ in
            Utility.showLoader(message: ESPMatterConstants.revokingRequestMsg, view: self.view)
            NodeGroupSharingManager.shared.revokeAccess(groupId: groupId, email: sharedWith) { result in
                Utility.hideLoader(view: self.view)
                if result {
                    User.shared.updateDeviceList = true
                    self.refreshSharingData(fetchNodeGroupSharingRequests: true,
                                              acceptedByUserRequests: true,
                                              nodeGroupSharingRequests: false,
                                              acceptedSharingRequests: false)
                } else {
                    self.showErrorAlert(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.revokeRequestFailedMsg, buttonTitle: ESPMatterConstants.okTxt) {}
                }
            }
        })
        self.showAlertWithOptions(title: ESPMatterConstants.revokeRequestTxt, message: ESPMatterConstants.revokeRequestMsg, actions: [noAction, yesAction])
    }
    
    /// Delete request created by user
    /// - Parameter requestId: request Id
    func deleteRequest(requestId: String) {
        let noAction = UIAlertAction(title: ESPMatterConstants.noTxt, style: .default)
        let yesAction = UIAlertAction(title: ESPMatterConstants.yesTxt, style: .destructive, handler: { _ in
            Utility.showLoader(message: ESPMatterConstants.cancellingRequestMsg, view: self.view)
            NodeGroupSharingManager.shared.deleteRequest(requestId: requestId) { result in
                Utility.hideLoader(view: self.view)
                if result {
                    User.shared.updateDeviceList = true
                    self.refreshSharingData(fetchNodeGroupSharingRequests: true,
                                              acceptedByUserRequests: false,
                                              nodeGroupSharingRequests: false,
                                              acceptedSharingRequests: false)
                } else {
                    self.showErrorAlert(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.cancelRequestFailedMsg, buttonTitle: ESPMatterConstants.okTxt) {}
                }
            }
        })
        self.showAlertWithOptions(title: ESPMatterConstants.cancelRequestTxt, message: ESPMatterConstants.cancelRequestMsg, actions: [noAction, yesAction])
    }
}

extension NodeGroupSharingRequestsViewController: RequestAccpetedActionDelegate {
    
    /// Remove group shared by another user
    /// - Parameters:
    ///   - groupId: group Id
    ///   - sharedWith: self
    func removeSharing(groupId: String, sharedWith: String) {
        let noAction = UIAlertAction(title: ESPMatterConstants.noTxt, style: .default)
        let yesAction = UIAlertAction(title: ESPMatterConstants.yesTxt, style: .destructive, handler: { _ in
            Utility.showLoader(message: ESPMatterConstants.removeGroupSharingMsg, view: self.view)
            NodeGroupSharingManager.shared.revokeAccess(groupId: groupId, email: sharedWith) { result in
                Utility.hideLoader(view: self.view)
                if result {
                    User.shared.updateDeviceList = true
                    self.refreshSharingData(fetchNodeGroupSharingRequests: false,
                                              acceptedByUserRequests: false,
                                              nodeGroupSharingRequests: false,
                                              acceptedSharingRequests: true)
                } else {
                    self.showErrorAlert(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.revokeRequestFailedMsg, buttonTitle: ESPMatterConstants.okTxt) {}
                }
            }
        })
        self.showAlertWithOptions(title: ESPMatterConstants.revokeRequestTxt, message: ESPMatterConstants.revokeRequestMsg, actions: [noAction, yesAction])
    }
}
