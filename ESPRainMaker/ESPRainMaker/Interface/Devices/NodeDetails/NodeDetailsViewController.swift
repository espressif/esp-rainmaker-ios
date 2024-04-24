// Copyright 2020 Espressif Systems
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
//  NodeDetailsViewController.swift
//  ESPRainMaker
//

import Toast_Swift
import UIKit
import Matter

class NodeDetailsViewController: UIViewController {
    // Constants
    let systemServices = "System Services"
    let firmwareUpdate = "firmwareUpdate"
    let enablePairingMode = "enablePairingMode"
    let bindingAction = "bindingAction"
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var loadingIndicator: SpinnerView!
    @IBOutlet var loadingLabel: UILabel!

    var currentNode: Node!

    var dataSource: [[String]] = [[]]
    var collapsed: [Bool] = [true, true, true, true, true]
    var pendingRequests: [SharingRequest] = []
    var sharingIndex = 0
    var timeZoneParam: Param!
    var timeZoneService: Service!
    var shareAction: UIAlertAction?
    
    var vendorId: String?
    var productId: String?
    var softwareVersion: String?
    
    let nodeRemovalFailedMsg = "Unable to remove node. Please check your internet connection."
    
    //Binding requirements
    var group: ESPNodeGroup?
    var node: ESPNodeDetails?
    var allNodes: [ESPNodeDetails]?
    var switchIndex: Int?
    var bindingEndpointClusterId: [String: UInt]?
    var sourceNode: ESPNodeDetails?

    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "NodeDetailsHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "nodeDetailsHV")
        tableView.register(UINib(nibName: "NodeDetailActionTableViewCell", bundle: nil), forCellReuseIdentifier: "nodeDetailActionTVC")
        tableView.register(UINib(nibName: "MembersInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "membersInfoTVC")
        tableView.register(UINib(nibName: "NewMemberTableViewCell", bundle: nil), forCellReuseIdentifier: "newMemberTVC")
        tableView.register(UINib(nibName: "SharingTableViewCell", bundle: nil), forCellReuseIdentifier: "sharingTVC")
        tableView.register(UINib(nibName: "DropDownTableViewCell", bundle: nil), forCellReuseIdentifier: "dropDownTableViewCell")

        tableView.estimatedRowHeight = 70.0
        tableView.tableFooterView = UIView()

        if Configuration.shared.appConfiguration.supportSharing {
            getSharingInfo()
        }

        // Add gesture to hide keyoboard on tapping anywhere on screen
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        createDataSource()
    }

    @objc func hideKeyboard() {
        view.endEditing(true)
    }

    // MARK: - IB Actions

    @IBAction func deleteNode(_: Any) {
        // Display message based on number of devices in the nodes.
        let title = "Are you sure?"
        var message = ""
        if let devices = currentNode.devices, devices.count > 1 {
            message = "By removing a node, all the associated devices will also be removed"
        }
        // Display a confirmation pop up on action of delete node.
        let confirmAction = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            Utility.showLoader(message: "Deleting node", view: self.view)
            #if ESPRainMakerMatter
            self.removeFabric { _ in
                self.removeDeviceInformation()
            }
            #else
            self.removeDeviceInformation()
            #endif
        }
        let noAction = UIAlertAction(title: "No", style: .default, handler: nil)
        confirmAction.addAction(noAction)
        confirmAction.addAction(yesAction)
        present(confirmAction, animated: true, completion: nil)
    }
    
    #if ESPRainMakerMatter
    @available(iOS 16.4, *)
    private func getTableViewCellForEnablePairingMode(forIndexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nodeDetailActionTVC", for: forIndexPath) as! NodeDetailActionTableViewCell
        view.endEditing(true)
        cell.nodeDetailActionLabel.text = "Turn On Pairing Mode"
        cell.addMemberButtonAction = {
            if let node = self.currentNode, let matterNodeId = node.matter_node_id, User.shared.isMatterNodeConnected(matterNodeId: matterNodeId) {
                self.openCommissioningWindow()
            } else {
                Utility.showToastMessage(view: self.view, message: ESPMatterConstants.deviceNotReachableMsg)
            }
        }
        return cell
    }
    
    /// Open commissioning Window
    @available(iOS 16.4, *)
    func openCommissioningWindow() {
        if let node = currentNode, let matterNodeId = node.matter_node_id, let id = matterNodeId.hexToDecimal {
            ESPMTRCommissioner.shared.openCommissioningWindow(deviceId: id) { setupPasscode in
                DispatchQueue.main.async {
                    if let setupPasscode = setupPasscode {
                        self.showManualPairingCode(setupPasscode: setupPasscode)
                    } else {
                        self.alertUser(title: ESPMatterConstants.failureTxt,
                                       message: ESPMatterConstants.commissioningWindowOpenFailedMsg,
                                       buttonTitle: ESPMatterConstants.okTxt,
                                       callback: {})
                    }
                }
            }
        }
    }
    
    /// Show manual pairing code
    func showManualPairingCode(setupPasscode: String) {
        let dismissAction = UIAlertAction(title: ESPMatterConstants.dismissTxt, style: .default) { _ in}
        let copyMsgAction = UIAlertAction(title: ESPMatterConstants.copyCodeMsg, style: .default) { _ in
            let pasteboard = UIPasteboard.general
            pasteboard.string = setupPasscode
        }
        self.showAlertWithOptions(title: ESPMatterConstants.pairingModeTitle, message: ESPMatterConstants.pairingModeMessage, actions: [copyMsgAction, dismissAction])
    }
    
    private func getTableViewCellForBinding(forIndexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nodeDetailActionTVC", for: forIndexPath) as! NodeDetailActionTableViewCell
        view.endEditing(true)
        cell.nodeDetailActionLabel.text = "Device Bindings"
        cell.addMemberButtonAction = {
            if #available(iOS 16.4, *) {
                self.openClusterSelection()
            } else {
                self.alertUser(title: ESPMatterConstants.emptyString,
                               message: ESPMatterConstants.upgradeOSVersionMsg, buttonTitle: ESPMatterConstants.okTxt, callback: {})
            }
        }
        return cell
    }
    
    @available(iOS 16.4, *)
    func openClusterSelection() {
        if let node = self.currentNode {
            let storyboard = UIStoryboard(name: ESPMatterConstants.matterStoryboardId, bundle: nil)
            let clusterSelectionVC = storyboard.instantiateViewController(withIdentifier: ClusterSelectionViewController.storyboardId) as! ClusterSelectionViewController
            clusterSelectionVC.group = self.group
            clusterSelectionVC.allNodes = self.allNodes
            clusterSelectionVC.sourceNode = self.sourceNode
            clusterSelectionVC.bindingEndpointClusterId = self.bindingEndpointClusterId
            clusterSelectionVC.switchIndex = self.switchIndex
            self.navigationController?.pushViewController(clusterSelectionVC, animated: true)
        }
    }
    #endif
    
    /// Remove fabric
    /// - Parameter completion: completion handler
    func removeFabric(completion: @escaping (Bool) -> Void) {
        if let node = currentNode, let matterNodeId = node.matter_node_id, User.shared.isMatterNodeConnected(matterNodeId: matterNodeId), let deviceId = matterNodeId.hexToDecimal {
            #if ESPRainMakerMatter
            if #available(iOS 16.4, *) {
                ESPMTRCommissioner.shared.readCurrentFabricIndex(deviceId: deviceId) { index in
                    if let index = index {
                        ESPMTRCommissioner.shared.removeFabricAtIndex(deviceId: deviceId, atIndex: index) { result in
                            completion(result)
                        }
                    } else {
                        completion(false)
                    }
                }
            } else {
                completion(false)
            }
            #else
            completion(false)
            #endif
        } else {
            completion(false)
        }
    }
    
    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    // Method to create data source for table view based on user role, sharing details and node information.
    func createDataSource() {
        collapsed = []
        
        // First section will contain node id
        var index = 0
        dataSource = [[]]
        dataSource[index].append("Node ID")
        dataSource[index].append("Node ID:\(currentNode.node_id ?? "")")
        collapsed.append(false)

        // Second section will contain node information
        index += 1
        dataSource.append([])
        dataSource[index].append("Node Information")
        if let type = currentNode.info?.type {
            dataSource[index].append("Type:\(type)")
        }
        if let fw_version = currentNode.info?.fw_version {
            dataSource[index].append("Firmware version:\(fw_version)")
        }
        #if ESPRainMakerMatter
        if let vid = currentNode.vendorId {
            dataSource[index].append("Vendor Id:\(vid)")
        }
        if let pid = currentNode.productId {
            dataSource[index].append("Product Id:\(pid)")
        }
        if let softwareVersion = currentNode.swVersion {
            dataSource[index].append("Software version:\(softwareVersion)")
        }
        if let softwareVersionString = currentNode.swVersionString {
            dataSource[index].append("Software version string:\(softwareVersionString)")
        }
        if let sn = currentNode.serialNumber {
            dataSource[index].append("Serial Number:\(sn)")
        }
        if let manufacturerName = currentNode.manufacturerName {
            dataSource[index].append("Manufacturer:\(manufacturerName)")
        }
        if let productName = currentNode.productName {
            dataSource[index].append("Product Name:\(productName)")
        }
        #endif
        if let tzService = currentNode.services?.first(where: { $0.type == Constants.timezoneServiceName }) {
            if let tzParam = tzService.params?.first(where: { $0.type == Constants.timezoneServiceParam }) {
                let timezone = tzParam.value as? String
                timeZoneParam = tzParam
                timeZoneService = tzService
                dataSource[index].append("Timezone:\(timezone ?? "")")
            }
        }
        if let attributes = currentNode.attributes {
            for attribute in attributes {
                dataSource[index].append("\(attribute.name ?? ""):\(attribute.value ?? "")")
            }
        }
        collapsed.append(true)

        // If sharing is supported third section will contain related information.
        if Configuration.shared.appConfiguration.supportSharing {
            index += 1
            sharingIndex = index
            dataSource.append([])
            dataSource[index].append("Sharing")
            if let primaryUsers = currentNode.primary {
                if primaryUsers.contains(User.shared.userInfo.email) {
                    // If user is primary displayed information about the user currently this node is shared with.
                    dataSource[index][0] = "Shared With"
                    if let secondaryUsers = currentNode.secondary {
                        dataSource[index].append(contentsOf: secondaryUsers)
                    }
                    // Provided option to add new members.
                    dataSource[index].append("Add Member")
                    loadingIndicator.isHidden = false
                    loadingIndicator.animate()
                    loadingLabel.isHidden = false
                    getSharingRequests()
                } else {
                    // If user is secondary displayed information about the primary user.
                    dataSource[index][0] = "Shared by"
                    dataSource[index].append(contentsOf: primaryUsers)
                }
            } else {
                // No sharing information is available
                dataSource[index].append("Not Available")
            }
            collapsed.append(true)
        }
        
        // Check for system services support
        if let systemService = currentNode.services?.first(where: { $0.type == Constants.systemService}), let primary = currentNode.primary, primary.contains(User.shared.userInfo.email) {
            var serviceParam: [String] = []
            for param in systemService.params ?? [] {
                if param.dataType?.lowercased() == Constants.boolType, let properties = param.properties, properties.contains(Constants.writeType), let paramType = ESPSystemService.init(rawValue: param.type ?? ""), let paramName = param.name {
                    serviceParam.append(paramName)
                    serviceParam.append(paramType.rawValue)
                }
            }
            if serviceParam.count > 0 {
                index += 1
                dataSource.append([])
                dataSource[index].append(systemServices)
                dataSource[index].append(contentsOf: serviceParam)
                collapsed.append(true)
            }
        }
        
        // Add option for OTA update if supported
        if Configuration.shared.appConfiguration.supportOTAUpdate {
            var showFirmwareUpdateButton = false
            if #available(iOS 16.4, *), let node = currentNode, node.isMatter, node.isRainmaker {
                showFirmwareUpdateButton = true
            } else if let node = currentNode, !node.isMatter {
                showFirmwareUpdateButton = true
            }
            if showFirmwareUpdateButton {
                index += 1
                dataSource.append([])
                dataSource[index].append(firmwareUpdate)
                collapsed.append(false)
            }
        }
        
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *), let node = currentNode, let matterNodeId = node.matter_node_id {
            if node.isOpenCommissioningWindowSupported.0 {
                index += 1
                dataSource.append([])
                dataSource[index].append(enablePairingMode)
                collapsed.append(false)
            }
            if node.bindingServers.count > 0 {
                index += 1
                dataSource.append([])
                dataSource[index].append(bindingAction)
                collapsed.append(false)
            }
        }
        #endif
        
        tableView.reloadData()
    }

    // MARK: - Private Methods

    // Method to update sharing data based on number of pending requests.
    private func updateSharingData() {
        if pendingRequests.count < 1 {
            dataSource[sharingIndex].removeLast()
        }
        DispatchQueue.main.async {
            self.tableView.reloadSections(IndexSet(arrayLiteral: self.sharingIndex), with: .automatic)
        }
    }

    // Method to fetch sharing information for current node.
    private func getSharingInfo() {
        loadingIndicator.isHidden = false
        loadingIndicator.animate()
        loadingLabel.isHidden = false
        NodeSharingManager.shared.getSharingDetails(node: currentNode) { error in
            DispatchQueue.main.async {
                self.loadingIndicator.isHidden = true
                self.loadingLabel.isHidden = true
            }
            if error != nil {
                // Unable to collect sharing information for this particular node.
                Utility.showToastMessage(view: self.view, message: "Unable to update current node details with error:\(error!.description).")
                return
            }
            // Navigate to node details view controller
            self.createDataSource()
        }
    }

    // Method to get all pending sharing request raised for this node.
    private func getSharingRequests() {
        NodeSharingManager.shared.getSharingRequests(primaryUser: true) { requests, error in
            DispatchQueue.main.async {
                self.loadingIndicator.isHidden = true
                self.loadingLabel.isHidden = true
            }
            guard let apiError = error else {
                self.pendingRequests.removeAll()

                if let sharingRequests = requests {
                    for request in sharingRequests {
                        // Filter pending request for current node.
                        if request.request_status?.lowercased() == "pending" {
                            if let nodeIDs = request.node_ids, nodeIDs.contains(self.currentNode.node_id ?? "") {
                                self.pendingRequests.append(request)
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        // If pending request count is non zero, show these requests in a separate section.
                        if self.pendingRequests.count > 0 {
                            if !self.dataSource[self.sharingIndex].contains("Pending for acceptance") {
                                self.dataSource[self.sharingIndex].append("Pending for acceptance")
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
                return
            }
            Utility.showToastMessage(view: self.view, message: apiError.description, duration: 5.0)
        }
    }

    // Method to get table view cell with Add Member option
    private func getTableViewCellForAddMember(forIndexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nodeDetailActionTVC", for: forIndexPath) as! NodeDetailActionTableViewCell
        view.endEditing(true)
        cell.addMemberButtonAction = {
            // Open dialog box for entering email of the secondary user
            let input = UIAlertController(title: "Add Member", message: "", preferredStyle: .alert)
            input.addTextField { textField in
                textField.placeholder = "Enter email"
                textField.keyboardType = .emailAddress
                textField.delegate = self
                textField.addTarget(self, action: #selector(self.textFieldDidChange(textField:)), for: .editingChanged)
            }
            input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in

            }))

            let shareAction = UIAlertAction(title: "Share", style: .default, handler: { [weak input] _ in
                let textField = input?.textFields![0]
                guard let email = textField?.text, !email.trimmingCharacters(in: .whitespaces).isEmpty else {
                    return
                }
                Utility.showLoader(message: "Sharing in progress..", view: self.view)
                NodeSharingManager.shared.createSharingRequest(userName: email, node: self.currentNode) { request, error in
                    Utility.hideLoader(view: self.view)
                    guard let apiError = error else {
                        DispatchQueue.main.async {
                            if self.pendingRequests.count < 1 {
                                self.dataSource[self.sharingIndex].append("Pending for acceptance")
                            }
                            self.pendingRequests.append(request!)
                            self.tableView.reloadSections(IndexSet(arrayLiteral: self.sharingIndex), with: .automatic)
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        self.view.makeToast("Failed to share node with error: \(apiError.description)", duration: 5.0, position: ToastManager.shared.position, title: nil, image: nil, style: ToastManager.shared.style, completion: nil)
                    }
                }
            })

            shareAction.isEnabled = false
            self.shareAction = shareAction

            input.addAction(shareAction)

            self.present(input, animated: true, completion: nil)
        }
        return cell
    }

    // Method to get table view cell for pending requests.
    private func getTableViewCellForPendingRequest(forIndexPath: IndexPath) -> UITableViewCell {
        let request = pendingRequests[forIndexPath.row + 1 - dataSource[sharingIndex].count]
        let cell = tableView.dequeueReusableCell(withIdentifier: "membersInfoTVC", for: forIndexPath) as! MembersInfoTableViewCell
        cell.removeMemberButton.isHidden = false
        cell.removeButtonAction = {
            Utility.showLoader(message: "Removing request..", view: self.view)
            NodeSharingManager.shared.deleteSharingRequest(request: request) { _, error in
                Utility.hideLoader(view: self.view)
                guard let apiError = error else {
                    self.pendingRequests.remove(at: forIndexPath.row + 1 - self.dataSource[self.sharingIndex].count)
                    self.updateSharingData()
                    return
                }
                DispatchQueue.main.async {
                    Utility.showToastMessage(view: self.view, message: "Failed to delete node sharing request with error: \(apiError.description)")
                }
            }
        }
        cell.secondaryUserLabel.text = request.user_name
        if let timestamp = request.request_timestamp {
            let expirationDate = Date(timeIntervalSince1970: timestamp)
            let days = Date().days(from: expirationDate)
            var expiringText = "Expires today"
            let daysLeft = 7 - days
            if daysLeft > 1 {
                expiringText = "Expires in \(daysLeft) days"
            } else if daysLeft == 1 {
                expiringText = "Expires in 1 day"
            } else {
                expiringText = "Expires today"
            }
            cell.timeStampLabel.isHidden = false
            cell.timeStampLabel.text = expiringText
        }
        return cell
    }

    @objc func textFieldDidChange(textField: UITextField) {
        // Enable share button if text is non empty
        if let text = textField.text, text.count > 0 {
            shareAction?.isEnabled = true
        } else {
            shareAction?.isEnabled = false
        }
    }
}

extension NodeDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return UIView()
        }
        let headerTitle = dataSource[section][0]
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "nodeDetailsHV") as! NodeDetailsHeaderView
        headerView.headerLabel.text = headerTitle
        headerView.tintColor = .clear
        headerView.headerTappedAction = {
            self.collapsed[section] = !self.collapsed[section]
            self.tableView.reloadSections(IndexSet(arrayLiteral: section), with: .automatic)
        }
        if collapsed[section] {
            headerView.arrowImageView.image = UIImage(named: "right_arrow_icon")
        } else {
            headerView.arrowImageView.image = UIImage(named: "down_arrow_icon")
        }
        
        // Check if device is offline
        if headerTitle == systemServices, !currentNode.isConnected {
            headerView.headerLabel.text = headerTitle + " (Offline)"
        }
        
        if headerTitle == firmwareUpdate || headerTitle == enablePairingMode || headerTitle == bindingAction {
            return UIView()
        }
        
        return headerView
    }

    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        let sectionValue = dataSource[section][0]
        if sectionValue == firmwareUpdate || sectionValue == enablePairingMode || sectionValue == bindingAction {
            return 10
        }
        return 50.0
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if pendingRequests.count > 0 {
            if indexPath.section == sharingIndex, indexPath.row + 1 == dataSource[sharingIndex].count - 1 {
                if dataSource[sharingIndex][indexPath.row + 1] == "Pending for acceptance" {
                    return 40.0
                }
            }
        }
        return 55.0
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 0
    }

    func tableView(_: UITableView, willDisplayFooterView view: UIView, forSection _: Int) {
        view.tintColor = .clear
    }
}

extension NodeDetailsViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if collapsed[section] {
            return 0
        }
        if section == sharingIndex {
            return dataSource[section].count - 1 + pendingRequests.count
        }
        let sectionValue = dataSource[section][0]
        if sectionValue == systemServices {
            return dataSource[section].count/2
        }
        if sectionValue == firmwareUpdate || sectionValue == enablePairingMode || sectionValue == bindingAction {
            return 1
        }
        return dataSource[section].count - 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if Configuration.shared.appConfiguration.supportSharing {
            if indexPath.section == sharingIndex {
                let header = dataSource[sharingIndex][0]
                if indexPath.row + 1 >= dataSource[sharingIndex].count {
                    return getTableViewCellForPendingRequest(forIndexPath: indexPath)
                }
                var rowValue = dataSource[sharingIndex][indexPath.row + 1]
                switch header {
                case "Shared With":
                    switch rowValue {
                    case "Add Member":
                        return getTableViewCellForAddMember(forIndexPath: indexPath)
                    case "Pending for acceptance":
                        let cell = tableView.dequeueReusableCell(withIdentifier: "sharingTVC", for: indexPath) as! SharingTableViewCell
                        return cell
                    default:
                        let cell = tableView.dequeueReusableCell(withIdentifier: "membersInfoTVC", for: indexPath) as! MembersInfoTableViewCell
                        cell.timeStampLabel.isHidden = true
                        cell.removeMemberButton.isHidden = false
                        cell.removeButtonAction = {
                            Utility.showLoader(message: "Removing user..", view: self.view)
                            NodeSharingManager.shared.deleteSharing(forNode: self.currentNode, email: cell.secondaryUserLabel.text ?? "") { success, error in
                                Utility.hideLoader(view: self.view)
                                guard let apiError = error else {
                                    if success {
                                        if let index = self.currentNode.secondary!.firstIndex(of: cell.secondaryUserLabel.text ?? "") {
                                            self.currentNode.secondary!.remove(at: index)
                                        }
                                        self.dataSource[self.sharingIndex].remove(at: indexPath.row + 1)
                                        DispatchQueue.main.async {
                                            self.tableView.reloadSections(IndexSet(arrayLiteral: self.sharingIndex), with: .automatic)
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            Utility.showToastMessage(view: self.view, message: "Failed to delete node sharing with error: Unknown error.")
                                        }
                                    }
                                    return
                                }
                                DispatchQueue.main.async {
                                    Utility.showToastMessage(view: self.view, message: "Failed to delete node sharing with error: \(apiError.description)")
                                }
                            }
                        }
                        cell.secondaryUserLabel.text = rowValue
                        return cell
                    }
                case "Shared by":
                    rowValue = dataSource[sharingIndex][indexPath.row + 1]
                    let cell = tableView.dequeueReusableCell(withIdentifier: "membersInfoTVC", for: indexPath) as! MembersInfoTableViewCell
                    cell.removeMemberButton.isHidden = true
                    cell.secondaryUserLabel.text = rowValue
                    return cell
                default:
                    rowValue = "Not Available"
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "membersInfoTVC", for: indexPath) as! MembersInfoTableViewCell
                cell.removeMemberButton.isHidden = true
                cell.secondaryUserLabel.text = rowValue
                return cell
            }
        }
        
        let sectionValue = dataSource[indexPath.section][0]
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *) {
            if sectionValue == enablePairingMode {
                return getTableViewCellForEnablePairingMode(forIndexPath: indexPath)
            } else if sectionValue == bindingAction {
                return getTableViewCellForBinding(forIndexPath: indexPath)
            }
        }
        #endif
        if sectionValue == systemServices {
            let cell = tableView.dequeueReusableCell(withIdentifier: SystemServicesTableViewCell.reuseIdentifier, for: indexPath) as! SystemServicesTableViewCell
            cell.paramName = dataSource[indexPath.section][indexPath.row*2 + 1]
            cell.paramType = dataSource[indexPath.section][indexPath.row*2 + 2]
            cell.resetButton.setTitle(cell.paramName, for: .normal)
            cell.node = currentNode
            cell.delegate = self
            
            // Check if device is connected
            if currentNode.isConnected {
                cell.alpha = 1.0
                cell.resetButton.alpha = 1.0
                cell.resetButton.isEnabled = true
            } else {
                cell.alpha = 0.5
                cell.resetButton.alpha = 0.5
                cell.resetButton.isEnabled = false
            }
            return cell
        } else if sectionValue == firmwareUpdate {
            let cell = tableView.dequeueReusableCell(withIdentifier: firmwareUpdate, for: indexPath)
            cell.contentView.layer.borderWidth = 0.5
            cell.contentView.layer.cornerRadius = 10
            cell.contentView.layer.borderColor = UIColor.lightGray.cgColor
            cell.contentView.layer.masksToBounds = true
            return cell
        }
        
        let value = dataSource[indexPath.section][indexPath.row + 1]
        if let firstIndex = value.firstIndex(of: ":") {
            let title = String(value[..<firstIndex])

            // Provide different cell for allowing timezone configuration
            if title == "Timezone" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "dropDownTableViewCell", for: indexPath) as! DropDownTableViewCell
                object_setClass(cell, TimeZoneTableViewCell.self)
                let timeZoneCell = cell as! TimeZoneTableViewCell
                timeZoneCell.node = currentNode
                timeZoneCell.param = timeZoneParam
                timeZoneCell.service = timeZoneService
                timeZoneCell.datasource = ESPTimezone.timezones
                timeZoneCell.currentValue = timeZoneParam.value as? String ?? ""
                timeZoneCell.controlName.text = "Time zone"
                timeZoneCell.controlValueLabel.text = timeZoneParam.value as? String ?? ""
                return timeZoneCell
            }

            // Generic node information cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "nodeDetailsTVC", for: indexPath) as! NodeDetailsTableViewCell
            cell.titleLabel.text = title
            cell.detailLabel.text = String(value.dropFirst(title.count + 1))
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "nodeDetailsTVC", for: indexPath) as! NodeDetailsTableViewCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionValue = dataSource[indexPath.section][0]
        if sectionValue == firmwareUpdate {
            let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
            let firmwareUpdateVC = deviceStoryboard.instantiateViewController(withIdentifier: firmwareUpdate) as! FirmwareUpdateViewController
            firmwareUpdateVC.currentNode = currentNode
            navigationController?.pushViewController(firmwareUpdateVC, animated: true)
        }
    }
}

extension NodeDetailsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
}

extension NodeDetailsViewController: SystemServiceTableViewCellDelegate {
    func systemServiceOperationPerformed() {
        Utility.showLoader(message: "", view: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Utility.hideLoader(view: self.view)
        }
    }
    
    func factoryResetPerformed() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            User.shared.updateDeviceList = true
            self.navigationController?.popToRootViewController(animated: false)
        }
    }
}

//MARK: Node deletion APIs
extension NodeDetailsViewController {
    
    /// Remove device information from group metadata
    /// Remove device from rainmaker cloud
    func removeDeviceInformation() {
        self.removeDeviceFromRainmaker { result in
            if result {
                self.removeDeviceInfoFromGroupMetadata { _ in
                    self.nodeDeletionSuccessful()
                }
            } else {
                self.showErrorAlert(title: ESPMatterConstants.failureTxt,
                                    message: ESPMatterConstants.operationFailedMsg,
                                    buttonTitle: ESPMatterConstants.okTxt,
                                    callback: {})
            }
        }
    }
    
    /// Remove device information from group metadata
    /// - Parameter completion: completion with result
    func removeDeviceInfoFromGroupMetadata(completion: @escaping (Bool) -> Void) {
        if let group = self.group, let grpId = group.groupID, let currentNode = self.currentNode, let id = currentNode.node_id {
            let service = ESPNodeGroupMetadataService()
            if currentNode.isOnOffServerSupported.0 {
                service.removeDestinationNodeFromGroupMetadata(groupId: grpId, destinationNodeId: id) { result in
                    completion(result)
                    return
                }
            } else if currentNode.isOnOffClientSupported {
                service.removeSourceNodeFromGroupMetadata(groupId: grpId, node: currentNode) { result in
                    completion(result)
                    return
                }
            }
        }
        completion(false)
    }
    
    /// Remove device from rainmaker
    /// - Parameter completion: completion handler with response
    func removeDeviceFromRainmaker(completion: @escaping (Bool) -> Void) {
        if let nodeId = self.currentNode.node_id {
            let parameters = ["user_id": User.shared.userInfo.userID,
                              "node_id": nodeId,
                              "secret_key": "",
                              "operation": "remove"]
            // Call method to dissociate node from user
            NetworkManager.shared.addDeviceToUser(parameter: parameters) { requestId, error in
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                }
                guard let removeNodeError = error else {
                    completion(true)
                    return
                }
                DispatchQueue.main.async {
                    if !ESPNetworkMonitor.shared.isConnectedToNetwork {
                        Utility.showToastMessage(view: self.view, message: self.nodeRemovalFailedMsg)
                    } else {
                        Utility.showToastMessage(view: self.view, message: removeNodeError.description)
                    }
                }
                completion(false)
            }
        } else {
            completion(false)
        }
    }
    
    /// Node deletion success action
    func nodeDeletionSuccessful() {
        User.shared.associatedNodeList?.removeAll(where: { node -> Bool in
            node.node_id == self.currentNode.node_id
        })
        self.updateDeviceListAndNavigateToHomeScreen()
    }
}
