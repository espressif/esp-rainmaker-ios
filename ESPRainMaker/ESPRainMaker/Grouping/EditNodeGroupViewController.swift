// Copyright 2021 Espressif Systems
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
//  EditNodeGroupViewController.swift
//  ESPRainMaker
//

import UIKit

// Class to manage renaming and removing of existing device in a group
class EditNodeGroupViewController: UIViewController {
    @IBOutlet var addButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var addButton: UIButton!
    @IBOutlet weak var shareButton: BarButton!
    
    // List of nodes in the group
    var groupNodes: [Node] = []
    // List of other nodes available but not included in the group
    var remainingNodes: [Node] = []
    var singleDeviceNodeCount = 0
    var currentNodeGroup: NodeGroup!
    private let removeGroupFooterButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
        #if ESPRainMakerMatter
        self.hideTopBarRemoveButton()
        #else
        self.shareButton.isHidden = true
        #endif
        // Show option to Add Device if there are available nodes not already added in the current group
        getRemainingNodes()
        if remainingNodes.count < 1 {
            addButtonHeightConstraint.constant = 0
            addButton.isHidden = true
        }
        // Configure collection view for display of group nodes
        getSingleDeviceNodeCount()
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        collectionView.collectionViewLayout = GroupDevicesFlowLayout()
        setupBottomRemoveButton()
        // Add name of current group in label
        nameLabel.text = currentNodeGroup.group_name ?? ""
    }

    // MARK: - IB Actions

    @IBAction func removeGroupButtonPressed(_: Any) {
        // Add confirmation alert before removing node group
        let alertController = UIAlertController(title: "Remove", message: "Are you sure you want to remove this group?", preferredStyle: .alert)
        alertController.view.tintColor = UIColor(hexString: "#8265E3")
        let cancelAction = UIAlertAction(title: "No", style: .default, handler: nil)
        let confirmAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            Utility.showLoader(message: "Removing group...", view: self.view)
            // Perform remove node group operation for selected group
            NodeGroupManager.shared.performNodeGroupOperation(group: self.currentNodeGroup, parameter: nil, method: .delete) { success, error in
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                    // Check if remove node group operation is successful
                    if success {
                        if let nodeGroup = self.currentNodeGroup, let groupId = nodeGroup.group_id {
                            ESPMatterFabricDetails.shared.removeGroupMetadata(groupId: groupId)
                        }
                        if let index = NodeGroupManager.shared.nodeGroups.firstIndex(where: { $0.group_id == self.currentNodeGroup.group_id }) {
                            NodeGroupManager.shared.nodeGroups.remove(at: index)
                        }
                        User.shared.updateDeviceList = true
                        NodeGroupManager.shared.listUpdated = true
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        // In case remove operation is unsuccessful, show error as toast
                        Utility.showToastMessage(view: self.view, message: error!.description, duration: 5.0)
                    }
                }
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func nameButtonPressed(_: Any) {
        // Open dialog box for renaming the group
        let input = UIAlertController(title: "Enter new name", message: "", preferredStyle: .alert)
        input.view.tintColor = UIColor(hexString: "#8265E3")
        // Add textfield for entering new name of the group
        input.addTextField { textField in
            textField.text = self.currentNodeGroup.group_name ?? ""
        }
        input.addAction(UIAlertAction(title: ESPMatterConstants.cancelTxt, style: .destructive, handler: { _ in

        }))
        input.addAction(UIAlertAction(title: "Rename", style: .default, handler: { [weak input] _ in
            let textField = input?.textFields![0]
            guard let name = textField?.text, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                return
            }
            Utility.showLoader(message: "Renaming...", view: self.view)
            // API call for renaming the existing group
            NodeGroupManager.shared.performNodeGroupOperation(group: self.currentNodeGroup, parameter: ["group_name": name], method: .put) { success, error in
                Utility.hideLoader(view: self.view)
                // Rename operation is successful.
                if success {
                    DispatchQueue.main.async {
                        User.shared.updateDeviceList = true
                        self.nameLabel.text = name
                        // Update group instance with new name
                        self.currentNodeGroup.group_name = name
                    }
                } else {
                    Utility.showToastMessage(view: self.view, message: error!.description, duration: 5.0)
                }
            }
        }))
        present(input, animated: true, completion: nil)
    }

    @IBAction func addDeviceButtonPressed(_: Any) {
        let nodeGroupStoryBoard = UIStoryboard(name: "NodeGrouping", bundle: nil)
        let addDeviceNodeVC = nodeGroupStoryBoard.instantiateViewController(withIdentifier: "addNodeGroupVC") as! AddNodeGroupsViewController
        addDeviceNodeVC.nodeList = remainingNodes
        addDeviceNodeVC.currentGroup = currentNodeGroup
        navigationController?.pushViewController(addDeviceNodeVC, animated: true)
    }

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    #if ESPRainMakerMatter
    @IBAction func shareButtonPressed(_ sender: Any) {
        let sharingDetailsVC = GroupSharingDetailsViewController(group: currentNodeGroup)
        navigationController?.pushViewController(sharingDetailsVC, animated: true)
    }
    #endif
    
    private func showGroupSharingFailedDialog(message: String) {
        self.showErrorAlert(title: ESPMatterConstants.failureTxt,
                            message: message,
                            buttonTitle: ESPMatterConstants.okTxt,
                            callback: {})
    }

    private func getSingleDeviceNodeCount() {
        singleDeviceNodeCount = 0
        if let nodeList = currentNodeGroup.nodeList {
            for item in nodeList {
                if item.devices?.count == 1 {
                    singleDeviceNodeCount += 1
                }
            }
        }
    }

    // MARK: - Private Methods

    private func getDeviceAt(indexPath: IndexPath) -> Device {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return currentNodeGroup.nodeList![indexPath.row].devices![0]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return currentNodeGroup.nodeList![index].devices![indexPath.row]
    }

    private func getNodeAt(indexPath: IndexPath) -> Node {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return currentNodeGroup.nodeList![indexPath.section]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return currentNodeGroup.nodeList![index]
    }

    private func getRemainingNodes() {
        if currentNodeGroup.nodes?.count ?? 0 < 1 {
            remainingNodes = User.shared.associatedNodeList ?? []
            return
        }
        var nodeList: [Node] = []
        for each in User.shared.associatedNodeList ?? [] {
            if let nodes = currentNodeGroup.nodes, !nodes.contains(each.node_id ?? "") {
                nodeList.append(each)
            }
        }
        remainingNodes = nodeList
    }

    private func hideTopBarRemoveButton() {
        guard let topBarView = shareButton.superview else { return }
        for case let button as BarButton in topBarView.subviews where button !== shareButton {
            if button.currentTitle == "Remove" {
                button.isHidden = true
                button.isEnabled = false
                break
            }
        }
    }

    private func setupBottomRemoveButton() {
        removeGroupFooterButton.translatesAutoresizingMaskIntoConstraints = false
        removeGroupFooterButton.setTitle("Remove Group", for: .normal)
        removeGroupFooterButton.setTitleColor(UIColor(hexString: "#F45C10"), for: .normal)
        removeGroupFooterButton.backgroundColor = UIColor(hexString: "#FFECE4")
        removeGroupFooterButton.layer.cornerRadius = 10.0
        removeGroupFooterButton.layer.borderWidth = 2.0
        removeGroupFooterButton.layer.borderColor = UIColor(hexString: "#F45C10").cgColor
        removeGroupFooterButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        removeGroupFooterButton.setImage(UIImage(named: "trash"), for: .normal)
        removeGroupFooterButton.tintColor = UIColor(hexString: "#F45C10")
        removeGroupFooterButton.semanticContentAttribute = .forceRightToLeft
        removeGroupFooterButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: -6)
        removeGroupFooterButton.addTarget(self, action: #selector(removeGroupButtonPressed(_:)), for: .touchUpInside)
        view.addSubview(removeGroupFooterButton)
        NSLayoutConstraint.activate([
            removeGroupFooterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16.0),
            removeGroupFooterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16.0),
            removeGroupFooterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12.0),
            removeGroupFooterButton.heightAnchor.constraint(equalToConstant: 48.0)
        ])
    }
}

extension EditNodeGroupViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0, singleDeviceNodeCount > 0 {
            return CGSize(width: 0, height: 10.0)
        }
        return CGSize(width: collectionView.bounds.width, height: 55.0)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForFooterInSection _: Int) -> CGSize {
        return CGSize(width: 0, height: 10.0)
    }
}

extension EditNodeGroupViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var index = section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return singleDeviceNodeCount
            }
            index = index + singleDeviceNodeCount - 1
        }
        return currentNodeGroup.nodeList![index].devices?.count ?? 0
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        let count = currentNodeGroup.nodeList?.count ?? 0
        if count == 0 {
            return count
        }
        if singleDeviceNodeCount > 0 {
            return count - singleDeviceNodeCount + 1
        }
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "selectGroupNodeCVC", for: indexPath) as! SelectGroupNodeCollectionViewCell
        let device = getDeviceAt(indexPath: indexPath)
        if let node = device.node, node.isMatter, let groupId = node.groupId, let matterNodeId = node.matter_node_id, let deviceId = matterNodeId.hexToDecimal, node.clientOnlyControllerNodeIdParam == nil {
            
            let (result, _) = ESPMatterClusterUtil.shared.isOnOffServerSupported(groupId: groupId, deviceId: deviceId)
            if result {
                cell.deviceImageView.image = UIImage(named: ESPMatterConstants.lightDevice)
            } else if ESPMatterClusterUtil.shared.isOnOffClientSupported(groupId: groupId, deviceId: deviceId).0 {
                cell.deviceImageView.image = UIImage(named: ESPMatterConstants.switchDevice)
            } else {
                cell.deviceImageView.image = UIImage(named: ESPMatterConstants.defaultDevice)
            }
            if ESPMatterClusterUtil.shared.isThermostatConditionerSupported(groupId: groupId, deviceId: deviceId).0 {
                cell.deviceImageView.image = UIImage(named: ESPMatterConstants.airConditioner)
            } else if ESPMatterClusterUtil.shared.isOnOffServerSupported(groupId: groupId, deviceId: deviceId).0, let type = node.deviceType, type == 266 || type == 267 {
                cell.deviceImageView.image = UIImage(named: ESPMatterConstants.outletDevice)
            } else if ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: groupId, deviceId: deviceId).0 {
                cell.deviceImageView.image = UIImage(named: ESPMatterConstants.controller)
            } else if ESPMatterClusterUtil.shared.isTBRMSupported(groupId: groupId, deviceId: deviceId).0 {
                cell.deviceImageView.image = UIImage(named: ESPMatterConstants.threadBR)
            } else if ESPMatterClusterUtil.shared.isDoorLockServerSupported(groupId: groupId, deviceId: deviceId).0 {
                cell.deviceImageView.image = UIImage(named: ESPMatterConstants.lock)
            } else if ESPMatterClusterUtil.shared.isWindowCoveringServerSupported(groupId: groupId, deviceId: deviceId).0 {
                cell.deviceImageView.image = UIImage(named: ESPMatterConstants.externalBlinds)
            }
            if let deviceName = node.matterDeviceName {
                cell.selectButton.isHidden = true
                cell.selectedImage.isHidden = true
                cell.deviceName.text = deviceName
            }
            return cell
        }
        cell.deviceName.text = device.getDeviceName()
        if device.node?.devices?.count ?? 0 > 1 {
            cell.selectButton.isHidden = true
            cell.selectedImage.isHidden = true
        } else {
            cell.selectButton.isHidden = false
            cell.selectedImage.isHidden = false
        }

        cell.selectButtonAction = {
            Utility.showLoader(message: "Removing device..", view: self.view)
            let parameter: [String: Any] = [ESPMatterConstants.operation: ESPMatterConstants.remove, ESPMatterConstants.nodes: [device.node?.node_id ?? ""]]
            NodeGroupManager.shared.performNodeGroupOperation(group: self.currentNodeGroup, parameter: parameter, method: .put) { success, error in
                Utility.hideLoader(view: self.view)
                if success {
                    DispatchQueue.main.async {
                        User.shared.updateDeviceList = true
                        self.remainingNodes.insert(device.node!, at: 0)
                        if let index = self.currentNodeGroup.nodes?.firstIndex(of: device.node?.node_id ?? "") {
                            self.currentNodeGroup.nodes?.remove(at: index)
                        }
                        if let index = self.currentNodeGroup.nodeList?.firstIndex(where: { $0.node_id == device.node?.node_id ?? "" }) {
                            self.currentNodeGroup.nodeList?.remove(at: index)
                        }
                        self.singleDeviceNodeCount = self.singleDeviceNodeCount - 1

                        if self.remainingNodes.count > 0, self.addButton.isHidden {
                            self.addButtonHeightConstraint.constant = 55
                            self.addButton.isHidden = false
                        }

                        self.collectionView.reloadData()
                    }
                } else {
                    Utility.showToastMessage(view: self.view, message: error!.description, duration: 5.0)
                }
            }
        }

        cell.layer.backgroundColor = UIColor.white.cgColor
        cell.layer.shadowColor = UIColor.lightGray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        cell.layer.shadowRadius = 0.5
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false

        cell.deviceImageView.image = ESPRMDeviceType(rawValue: device.type ?? "")?.getImageFromDeviceType() ?? UIImage(named: Constants.dummyDeviceImage)
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "selectNodeCollectionReusableView", for: indexPath) as! SelectNodeHeaderCollectionReusableView
            let node = getNodeAt(indexPath: indexPath)
            if singleDeviceNodeCount > 0 {
                if indexPath.section == 0 {
                    headerView.topBorder.backgroundColor = .clear
                    headerView.headerLabel.isHidden = true
                    headerView.selectButton.isHidden = true
                    headerView.selectedImage.isHidden = true
                    headerView.borderWidth = 0.0
                    return headerView
                } else {
                    headerView.headerLabel.isHidden = false
                    headerView.selectButton.isHidden = false
                    headerView.selectedImage.isHidden = false
                }
            }
            headerView.headerLabel.text = node.info?.name ?? "Node"
            headerView.selectButtonAction = {
                Utility.showLoader(message: "Removing device..", view: self.view)
                let parameter: [String: Any] = [ESPMatterConstants.operation: ESPMatterConstants.remove, ESPMatterConstants.nodes: [node.node_id ?? ""]]
                NodeGroupManager.shared.performNodeGroupOperation(group: self.currentNodeGroup, parameter: parameter, method: .put) { success, error in
                    Utility.hideLoader(view: self.view)
                    if success {
                        DispatchQueue.main.async {
                            User.shared.updateDeviceList = true
                            self.remainingNodes.append(node)
                            if let index = self.currentNodeGroup.nodes?.firstIndex(of: node.node_id ?? "") {
                                self.currentNodeGroup.nodes?.remove(at: index)
                            }
                            if let index = self.currentNodeGroup.nodeList?.firstIndex(where: { $0.node_id == node.node_id ?? "" }) {
                                self.currentNodeGroup.nodeList?.remove(at: index)
                            }

                            if self.remainingNodes.count > 0, self.addButton.isHidden {
                                self.addButtonHeightConstraint.constant = 55
                                self.addButton.isHidden = false
                            }

                            self.collectionView.reloadData()
                        }
                    } else {
                        Utility.showToastMessage(view: self.view, message: error!.description, duration: 5.0)
                    }
                }
            }
            return headerView
        default:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "selectionNodeFooterCV", for: indexPath) as! SelectNodeFooterCollectionReusableView
            if singleDeviceNodeCount > 0 {
                footerView.bottomBorder.backgroundColor = .clear
            }
            return footerView
        }
    }
}

#if ESPRainMakerMatter
private enum GroupSharingSection: Int, CaseIterable {
    case overview
    case sharedUsers
}

private struct GroupSharingRequestRow {
    let requestId: String
    let sharedWith: String
    let requestTimestamp: Int
}

final class GroupSharingDetailsViewController: UIViewController {
    private enum UIConstants {
        static let cardCornerRadius: CGFloat = 10.0
        static let cardBorderWidth: CGFloat = 0.5
        static let cardHorizontalInset: CGFloat = 0.0
        static let cardVerticalInset: CGFloat = 0.0
        static let rowHeight: CGFloat = 56.0
        static let pendingHeaderRowHeight: CGFloat = 40.0
        static let headerHeight: CGFloat = 50.0
        static let sectionSpacing: CGFloat = 20.0
        static let addMemberTextColor = UIColor(hexString: "#8265E3")
        static let appToggleOnColor = UIColor(hexString: "#8265E3")
    }

    private let group: NodeGroup
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private let topBarView = TopBarView()
    private let topBarTitle = BarTitle()
    private let backButton = BarButton()
    private let topBarBottomLine = UIView()
    private var canManageSharing = false
    private var sharedUsers: [String] = []
    private var pendingRequests: [GroupSharingRequestRow] = []
    private var isLoading = false
    private var collapsedSections = [false, false]

    init(group: NodeGroup) {
        self.group = group
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        tabBarController?.tabBar.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureTopBar()
        configureTableView()
        refreshData()
    }

    private func configureTopBar() {
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        topBarTitle.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        topBarBottomLine.translatesAutoresizingMaskIntoConstraints = false

        topBarTitle.text = group.group_name ?? NodeGroupSharingConstants.titleGroupDetails
        topBarTitle.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        topBarTitle.textAlignment = .center

        backButton.setTitle("Back", for: .normal)
        backButton.contentHorizontalAlignment = .left
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)

        view.addSubview(topBarView)
        topBarView.addSubview(topBarTitle)
        topBarView.addSubview(backButton)
        topBarView.addSubview(topBarBottomLine)
        topBarBottomLine.backgroundColor = UIColor(white: 0.67, alpha: 1.0)

        let proportionalHeightConstraint = topBarView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.107)
        proportionalHeightConstraint.priority = .required

        NSLayoutConstraint.activate([
            topBarView.topAnchor.constraint(equalTo: view.topAnchor),
            topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            proportionalHeightConstraint,
            topBarView.heightAnchor.constraint(lessThanOrEqualToConstant: 96.0),

            topBarTitle.centerXAnchor.constraint(equalTo: topBarView.centerXAnchor),
            topBarTitle.bottomAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: -14.0),

            backButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: 16.0),
            backButton.centerYAnchor.constraint(equalTo: topBarTitle.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 70.0),
            backButton.heightAnchor.constraint(equalToConstant: 50.0),

            topBarBottomLine.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor),
            topBarBottomLine.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor),
            topBarBottomLine.bottomAnchor.constraint(equalTo: topBarView.bottomAnchor),
            topBarBottomLine.heightAnchor.constraint(equalToConstant: 1.0)
        ])
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "NodeDetailsHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "nodeDetailsHV")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GroupSharingCell")
        tableView.register(UINib(nibName: "MembersInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "membersInfoTVC")
        tableView.register(UINib(nibName: "SharingTableViewCell", bundle: nil), forCellReuseIdentifier: "sharingTVC")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = UIConstants.headerHeight
        tableView.estimatedRowHeight = 70.0
        tableView.rowHeight = UIConstants.rowHeight
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: 20.0),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32.0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32.0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc
    private func backButtonPressed() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func handlePullToRefresh() {
        refreshData()
    }

    private func refreshData() {
        guard !isLoading else { return }
        isLoading = true
        Utility.showLoader(message: NodeGroupSharingConstants.fetchingSharingDetailsMsg, view: view)

        let group = DispatchGroup()
        var sharingData: Data?
        var requestData: Data?

        group.enter()
        NodeGroupSharingManager.shared.getNodeGroupSharing(groupId: self.group.group_id) { data in
            sharingData = data
            group.leave()
        }

        group.enter()
        NodeGroupSharingManager.shared.getNodeGroupSharingRequests(isPrimary: true) { data in
            requestData = data
            group.leave()
        }

        group.notify(queue: .main) {
            Utility.hideLoader(view: self.view)
            self.refreshControl.endRefreshing()
            self.isLoading = false
            self.applySharingData(sharingData)
            self.applyPendingRequestData(requestData)
            self.tableView.reloadData()
        }
    }

    private func applySharingData(_ data: Data?) {
        sharedUsers.removeAll()
        canManageSharing = false
        guard
            let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let groupSharing = json["group_sharing"] as? [[String: Any]],
            let item = groupSharing.first,
            let users = item["users"] as? [String: Any]
        else {
            return
        }

        let currentUser = User.shared.userInfo.email
        let primaryUsers = users["primary"] as? [String] ?? []
        let secondaryUsers = users["secondary"] as? [String] ?? []

        canManageSharing = primaryUsers.contains(currentUser)
        if canManageSharing {
            let usersToShow = (primaryUsers + secondaryUsers).filter { $0 != currentUser }
            sharedUsers = Array(Set(usersToShow)).sorted()
        } else {
            sharedUsers = Array(Set(primaryUsers)).sorted()
        }
    }

    private func applyPendingRequestData(_ data: Data?) {
        pendingRequests.removeAll()
        guard
            let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let sharingRequests = json["sharing_requests"] as? [[String: Any]],
            let groupId = group.group_id
        else {
            return
        }

        let currentUser = User.shared.userInfo.email
        for request in sharingRequests {
            let requestStatus = (request["request_status"] as? String ?? "").lowercased()
            guard requestStatus == NodeGroupSharingConstants.statusPending else { continue }
            guard let groupIds = request["group_ids"] as? [String], groupIds.contains(groupId) else { continue }
            guard let sharedBy = request["primary_user_name"] as? String, sharedBy == currentUser else { continue }
            guard let requestId = request["request_id"] as? String else { continue }
            let sharedWith = request["user_name"] as? String ?? NodeGroupSharingConstants.unknownUser
            let requestTimestamp = request["request_timestamp"] as? Int ?? 0
            pendingRequests.append(GroupSharingRequestRow(requestId: requestId, sharedWith: sharedWith, requestTimestamp: requestTimestamp))
        }
    }

    private func presentAddMemberPrompt() {
        let alert = UIAlertController(title: NodeGroupSharingConstants.titleAddMember, message: nil, preferredStyle: .alert)
        alert.view.tintColor = UIColor(hexString: "#8265E3")
        let grantSwitch = UISwitch()
        grantSwitch.onTintColor = UIConstants.appToggleOnColor

        alert.addTextField { field in
            field.keyboardType = .emailAddress
            field.placeholder = NodeGroupSharingConstants.usernamePlaceholder
        }
        alert.addTextField { field in
            field.text = "Grant full access"
            field.clearButtonMode = .never
            field.rightView = grantSwitch
            field.rightViewMode = .always
        }

        alert.addAction(UIAlertAction(title: ESPMatterConstants.cancelTxt, style: .cancel))
        alert.addAction(UIAlertAction(title: ESPMatterConstants.shareTxt, style: .default) { _ in
            guard
                let email = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                !email.isEmpty,
                let groupId = self.group.group_id,
                let groupName = self.group.group_name
            else {
                return
            }
            self.sendGroupShareRequest(email: email, groupId: groupId, groupName: groupName, isPrimary: grantSwitch.isOn)
        })
        present(alert, animated: true)
    }

    private func sendGroupShareRequest(email: String, groupId: String, groupName: String, isPrimary: Bool) {
        Utility.showLoader(message: NodeGroupSharingConstants.sharingGroupMsg, view: self.view)
        NodeGroupSharingManager.shared.shareNodeGroup(groupId: groupId, groupName: groupName, userName: email, isPrimary: isPrimary) { data in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                if let data = data,
                   let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = response[ESPMatterConstants.status] as? String,
                   status.lowercased() == ESPMatterConstants.success {
                    self.refreshData()
                    return
                }
                let response = (data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }) ?? [:]
                let message = (response[Constants.descriptionKey] as? String) ?? NodeGroupSharingConstants.groupShareFailedMsg
                Utility.showToastMessage(view: self.view, message: message, duration: 5.0)
            }
        }
    }

    private func revokeSharing(forEmail email: String) {
        guard let groupId = group.group_id else { return }
        Utility.showLoader(message: NodeGroupSharingConstants.revokingRequestMsg, view: view)
        NodeGroupSharingManager.shared.revokeAccess(groupId: groupId, email: email) { success, message in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                if success {
                    self.refreshData()
                } else {
                    Utility.showToastMessage(view: self.view, message: message ?? NodeGroupSharingConstants.revokeRequestFailedMsg, duration: 5.0)
                }
            }
        }
    }

    private func cancelPendingRequest(requestId: String) {
        Utility.showLoader(message: NodeGroupSharingConstants.cancellingRequestMsg, view: view)
        NodeGroupSharingManager.shared.deleteRequest(requestId: requestId) { success, message in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                if success {
                    self.refreshData()
                } else {
                    Utility.showToastMessage(view: self.view, message: message ?? NodeGroupSharingConstants.cancelRequestFailedMsg, duration: 5.0)
                }
            }
        }
    }

    private func remainingDays(for requestTimestamp: Int) -> Int {
        guard requestTimestamp > 0 else { return -1 }
        let requestDate = Date(timeIntervalSince1970: TimeInterval(requestTimestamp))
        let calendar = Calendar.current
        let startOfRequestDate = calendar.startOfDay(for: requestDate)
        let startOfToday = calendar.startOfDay(for: Date())
        let elapsedDays = calendar.dateComponents([.day], from: startOfRequestDate, to: startOfToday).day ?? 0
        return 7 - elapsedDays
    }

    @objc
    private func pendingCancelButtonPressed(_ sender: UIButton) {
        guard let requestId = sender.accessibilityIdentifier, !requestId.isEmpty else { return }
        presentConfirmationAlert(
            title: ESPMatterConstants.cancelTxt,
            message: NodeGroupSharingConstants.cancelGroupSharingRequestConfirmationMsg
        ) {
            self.cancelPendingRequest(requestId: requestId)
        }
    }

    @objc
    private func approvedRemoveButtonPressed(_ sender: UIButton) {
        guard let email = sender.accessibilityIdentifier, !email.isEmpty else { return }
        presentConfirmationAlert(
            title: ESPMatterConstants.revoke,
            message: NodeGroupSharingConstants.revokeGroupSharingAccessConfirmationMsg
        ) {
            self.revokeSharing(forEmail: email)
        }
    }

    private func presentConfirmationAlert(title: String, message: String, onConfirm: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = UIColor(hexString: "#8265E3")
        alert.addAction(UIAlertAction(title: ESPMatterConstants.no, style: .cancel))
        alert.addAction(UIAlertAction(title: ESPMatterConstants.yes, style: .destructive) { _ in
            onConfirm()
        })
        present(alert, animated: true)
    }

    private func applyCardStyle(to cell: UITableViewCell) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .white
        cell.contentView.layer.cornerRadius = UIConstants.cardCornerRadius
        cell.contentView.layer.borderWidth = UIConstants.cardBorderWidth
        cell.contentView.layer.borderColor = UIColor.lightGray.cgColor
        cell.contentView.layer.masksToBounds = true
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
    }

    private enum SharedSectionRow {
        case user(String)
        case addMember
        case pendingHeader
        case pendingRequest(GroupSharingRequestRow)
    }

    private func sharedSectionRows() -> [SharedSectionRow] {
        var rows: [SharedSectionRow] = []

        if !sharedUsers.isEmpty {
            rows.append(contentsOf: sharedUsers.map { .user($0) })
        }

        if canManageSharing {
            rows.append(.addMember)
            if !pendingRequests.isEmpty {
                rows.append(.pendingHeader)
                rows.append(contentsOf: pendingRequests.map { .pendingRequest($0) })
            }
        }
        return rows
    }
}

extension GroupSharingDetailsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return GroupSharingSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = GroupSharingSection(rawValue: section) else { return 0 }
        if collapsedSections[section.rawValue] {
            return 0
        }
        switch section {
        case .overview:
            return 2
        case .sharedUsers:
            return sharedSectionRows().count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = GroupSharingSection(rawValue: indexPath.section) else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        switch section {
        case .overview:
            let cell = tableView.dequeueReusableCell(withIdentifier: "membersInfoTVC", for: indexPath) as! MembersInfoTableViewCell
            cell.selectionStyle = .none
            cell.removeMemberButton.isHidden = true
            cell.timeStampLabel.isHidden = true
            cell.secondaryUserLabel.textColor = .label
            if indexPath.row == 0 {
                cell.secondaryUserLabel.text = "Name: \(group.group_name ?? "NA")"
            } else {
                let isMatter = group.is_matter ?? false
                cell.secondaryUserLabel.text = "Matter Fabric: \(isMatter ? "Yes" : "No")"
            }
            return cell
        case .sharedUsers:
            let rows = sharedSectionRows()
            guard indexPath.row < rows.count else {
                return UITableViewCell(style: .default, reuseIdentifier: nil)
            }
            switch rows[indexPath.row] {
            case .pendingHeader:
                let pendingHeaderCell = tableView.dequeueReusableCell(withIdentifier: "sharingTVC", for: indexPath) as! SharingTableViewCell
                pendingHeaderCell.selectionStyle = .none
                return pendingHeaderCell
            case .addMember:
                let addMemberCell = tableView.dequeueReusableCell(withIdentifier: "membersInfoTVC", for: indexPath) as! MembersInfoTableViewCell
                addMemberCell.selectionStyle = .none
                addMemberCell.removeMemberButton.isHidden = true
                addMemberCell.timeStampLabel.isHidden = true
                addMemberCell.secondaryUserLabel.text = NodeGroupSharingConstants.titleAddMember
                addMemberCell.secondaryUserLabel.textColor = UIConstants.addMemberTextColor
                return addMemberCell
            case .user(let email):
                let userCell = tableView.dequeueReusableCell(withIdentifier: "membersInfoTVC", for: indexPath) as! MembersInfoTableViewCell
                userCell.selectionStyle = .none
                userCell.secondaryUserLabel.text = email
                userCell.secondaryUserLabel.textColor = .label
                userCell.timeStampLabel.isHidden = true
                if canManageSharing {
                    userCell.removeMemberButton.isHidden = false
                    userCell.removeButtonAction = { [weak self] in
                        self?.presentConfirmationAlert(
                            title: ESPMatterConstants.revoke,
                            message: NodeGroupSharingConstants.revokeGroupSharingAccessConfirmationMsg
                        ) {
                            self?.revokeSharing(forEmail: email)
                        }
                    }
                } else {
                    userCell.removeMemberButton.isHidden = true
                }
                return userCell
            case .pendingRequest(let request):
                let pendingCell = tableView.dequeueReusableCell(withIdentifier: "membersInfoTVC", for: indexPath) as! MembersInfoTableViewCell
                pendingCell.selectionStyle = .none
                pendingCell.secondaryUserLabel.text = request.sharedWith
                pendingCell.secondaryUserLabel.textColor = .label
                let remaining = remainingDays(for: request.requestTimestamp)
                if remaining == 0 {
                    pendingCell.timeStampLabel.text = NodeGroupSharingConstants.expiresToday
                    pendingCell.timeStampLabel.isHidden = false
                } else if remaining > 0 && remaining <= 7 {
                    pendingCell.timeStampLabel.text = NodeGroupSharingConstants.expiresInDays(remaining)
                    pendingCell.timeStampLabel.isHidden = false
                } else {
                    pendingCell.timeStampLabel.isHidden = true
                }
                pendingCell.removeMemberButton.isHidden = false
                pendingCell.removeButtonAction = { [weak self] in
                    self?.presentConfirmationAlert(
                        title: ESPMatterConstants.cancelTxt,
                        message: NodeGroupSharingConstants.cancelGroupSharingRequestConfirmationMsg
                    ) {
                        self?.cancelPendingRequest(requestId: request.requestId)
                    }
                }
                return pendingCell
            }
        }
        return UITableViewCell(style: .default, reuseIdentifier: nil)
    }
}

extension GroupSharingDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = GroupSharingSection(rawValue: indexPath.section) else { return }
        if section == .sharedUsers {
            let rows = sharedSectionRows()
            if indexPath.row < rows.count, case .addMember = rows[indexPath.row] {
                tableView.deselectRow(at: indexPath, animated: true)
                presentAddMemberPrompt()
            }
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = GroupSharingSection(rawValue: indexPath.section) else {
            return UIConstants.rowHeight
        }
        if section == .sharedUsers {
            let rows = sharedSectionRows()
            if indexPath.row < rows.count, case .pendingHeader = rows[indexPath.row] {
                return UIConstants.pendingHeaderRowHeight
            }
        }
        return UIConstants.rowHeight
    }

    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let resolvedSection = GroupSharingSection(rawValue: section) else { return 0 }
        switch resolvedSection {
        case .overview, .sharedUsers:
            return UIConstants.headerHeight
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let resolvedSection = GroupSharingSection(rawValue: section) else { return nil }
        let title: String
        switch resolvedSection {
        case .overview:
            title = NodeGroupSharingConstants.titleGroupInfo
        case .sharedUsers:
            title = canManageSharing ? NodeGroupSharingConstants.titleSharedWith : NodeGroupSharingConstants.titleSharedBy
        }

        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "nodeDetailsHV") as? NodeDetailsHeaderView
        headerView?.headerLabel.text = title
        headerView?.tintColor = .clear
        let isCollapsed = collapsedSections[resolvedSection.rawValue]
        headerView?.arrowImageView.isHidden = false
        headerView?.arrowImageView.image = UIImage(named: isCollapsed ? "right_arrow_icon" : "down_arrow_icon")
        headerView?.headerTappedAction = { [weak self] in
            guard let self = self else { return }
            self.collapsedSections[resolvedSection.rawValue].toggle()
            self.tableView.reloadSections(IndexSet(integer: resolvedSection.rawValue), with: .automatic)
        }
        return headerView
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return UIConstants.sectionSpacing
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        return footerView
    }

    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt _: IndexPath) {
        let inset = UIEdgeInsets(top: UIConstants.cardVerticalInset,
                                 left: UIConstants.cardHorizontalInset,
                                 bottom: UIConstants.cardVerticalInset,
                                 right: UIConstants.cardHorizontalInset)
        cell.separatorInset = inset
        cell.layoutMargins = inset
        cell.preservesSuperviewLayoutMargins = false
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let section = GroupSharingSection(rawValue: indexPath.section) else { return nil }
        guard section == .sharedUsers else {
            return nil
        }
        let rows = sharedSectionRows()
        guard indexPath.row < rows.count else { return nil }
        switch rows[indexPath.row] {
        case .user(let email):
            guard canManageSharing else { return nil }
            let action = UIContextualAction(style: .destructive, title: "Revoke") { _, _, completion in
                self.presentConfirmationAlert(
                    title: ESPMatterConstants.revoke,
                    message: NodeGroupSharingConstants.revokeGroupSharingAccessConfirmationMsg
                ) {
                    self.revokeSharing(forEmail: email)
                }
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [action])
        case .pendingRequest(let request):
            guard canManageSharing else { return nil }
            let action = UIContextualAction(style: .destructive, title: "Cancel") { _, _, completion in
                self.presentConfirmationAlert(
                    title: ESPMatterConstants.cancelTxt,
                    message: NodeGroupSharingConstants.cancelGroupSharingRequestConfirmationMsg
                ) {
                    self.cancelPendingRequest(requestId: request.requestId)
                }
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [action])
        default:
            return nil
        }
    }
}
#endif
