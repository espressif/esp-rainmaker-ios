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
//  DevicesBindingViewController.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import UIKit
import Alamofire
import Matter

@available(iOS 16.4, *)
class DevicesBindingViewController: UIViewController {
    
    static let storyboardId = "DevicesBindingViewController"
    
    @IBOutlet weak var topBarTitle: BarTitle!
    @IBOutlet weak var editButton: BarButton!
    @IBOutlet weak var bindingTable: UITableView!
    @IBOutlet weak var noDeviceImage: UIImageView!
    @IBOutlet weak var noDeviceLabel: UILabel!
    var device: String!
    var isEditModeOn: Bool = true
    var group: ESPNodeGroup?
    var nodes: [ESPNodeDetails]?
    var sourceNode: ESPNodeDetails?
    var linkedNodes: [ESPNodeDetails] = [ESPNodeDetails]()
    var unlinkedNodes: [ESPNodeDetails] = [ESPNodeDetails]()
    var endpointClusterId: [String: UInt]?
    var isUserActionAllowed: Bool = true
    var service: ESPNodeGroupMetadataService?
    let apiWorker = ESPAPIWorker()
    var switchIndex: Int?
    let fabricDetails = ESPMatterFabricDetails.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.addCustomBottomLine(color: .lightGray, height: 0.5)
        if let group = group, let groupId = group.groupID, let sourceNode = sourceNode, let matterNodeId = sourceNode.getMatterNodeId(), let sourceDeviceid = matterNodeId.hexToDecimal {
            if let linkedNodes = self.fabricDetails.getLinkedDevices(groupId: groupId, deviceId: sourceDeviceid, endpointClusterId: self.endpointClusterId) {
                self.linkedNodes = linkedNodes
            }
            if let unlinkedNodes = self.fabricDetails.getUnlinkedDevices(groupId: groupId, deviceId: sourceDeviceid, endpointClusterId: self.endpointClusterId) {
                self.unlinkedNodes = unlinkedNodes
            }
            self.setupUI()
            self.editDevices()
            if !isUserActionAllowed {
                self.view.isUserInteractionEnabled = false
                return
            }
            self.checkingLinkingStatusAndSetupUI()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func appEnterForeground() {
        ESPMTRCommissioner.shared.shutDownController()
        if let group = self.group, let groupId = group.groupID, let userNOCDetails = self.fabricDetails.getUserNOCDetails(groupId: groupId) {
            ESPMTRCommissioner.shared.group = group
            ESPMTRCommissioner.shared.initializeMTRControllerWithUserNOC(matterFabricData: group, userNOCData: userNOCDetails)
        }
    }
    
    /// Setup UI
    func setupUI() {
        self.topBarTitle.text = ESPMatterConstants.deviceLinks
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: ESPMatterConstants.edit, style: .plain, target: self, action: #selector(editDevices))
        self.bindingTable.delegate = self
        self.bindingTable.dataSource = self
        if self.linkedNodes.count > 0 || self.unlinkedNodes.count > 0 {
            self.hideTable(false)
        } else {
            self.hideTable(true)
        }
    }
    
    /// Back button pressed
    /// - Parameter sender: button pressed
    @IBAction func backButtonPressed(_ sender: Any) {
        self.goBack()
    }
    
    /// Edit button pressed
    /// - Parameter sender: button pressed
    @IBAction func editButtonPressed(_ sender: Any) {
        self.editDevices()
    }
    
    /// Edit devices button tapped
    @objc func editDevices() {
        isEditModeOn = !isEditModeOn
        if isEditModeOn {
            navigationItem.rightBarButtonItem?.title = ESPMatterConstants.doneTxt
        } else {
            navigationItem.rightBarButtonItem?.title = ESPMatterConstants.edit
        }
        self.bindingTable.reloadData()
    }
    
    /// Check linking status and setup UI
    func checkingLinkingStatusAndSetupUI() {
        Utility.showLoader(message: ESPMatterConstants.fetchBindingMsg, view: self.view)
        self.checkNodesLinkingStatus() {
            Utility.hideLoader(view: self.view)
            if let group = self.group, let groupId = group.groupID, let node = self.sourceNode, let matterNodeId = node.getMatterNodeId(), let sourceDeviceId = matterNodeId.hexToDecimal {
                self.fabricDetails.saveBindingData(groupId: groupId, deviceId: sourceDeviceId, linkedNodes: self.linkedNodes, unlinkedNodes: self.unlinkedNodes, endpointClusterId: self.endpointClusterId)
                self.setupUI()
                self.editDevices()
            }
        }
    }
    
    /// Check linking status of source nodes with all other nodes
    /// - Parameter completionHandler: callback
    func checkNodesLinkingStatus(completionHandler: @escaping () -> Void) {
        self.linkedNodes.removeAll()
        self.unlinkedNodes.removeAll()
        if let sourceNode = sourceNode, let nodes = nodes, nodes.count > 1 {
            self.areDevicesLinked(sourceNode: sourceNode, nodes: nodes, index: 0, completionHandler: completionHandler)
        } else {
            completionHandler()
        }
    }
    
    /// Find out if devices are linked
    /// - Parameters:
    ///   - sourceNode: source node
    ///   - nodes: all nodes
    ///   - index: index
    ///   - completionHandler: callback
    func areDevicesLinked(sourceNode: ESPNodeDetails, nodes: [ESPNodeDetails], index: Int, completionHandler: @escaping () -> Void) {
        if index < nodes.count {
            let destinationNode = nodes[index]
            if let destinationNodeId = destinationNode.getMatterNodeId(), let sourceNodeId = sourceNode.getMatterNodeId(), destinationNodeId != sourceNodeId, let destinationDeviceId = destinationNodeId.hexToDecimal {
                if let group = self.group, let groupId = group.groupID {
                    if !ESPMatterClusterUtil.shared.isOnOffServerSupported(groupId: groupId, deviceId: destinationDeviceId).0 {
                        self.areDevicesLinked(sourceNode: sourceNode, nodes: nodes, index: index+1, completionHandler: completionHandler)
                        return
                    }
                }
                if let sourceId = sourceNode.nodeID, let node = User.shared.getNode(id: sourceId), let dId = destinationNode.nodeID, let groupId = node.groupId, let metadata = self.fabricDetails.getGroupMetadata(groupId: groupId), let linked = metadata[sourceId] as? String, linked.contains(dId) {
                    if let index = self.switchIndex {
                        if linked.contains("\(dId).\(index)") {
                            self.linkedNodes.append(destinationNode)
                        } else {
                            self.unlinkedNodes.append(destinationNode)
                        }
                    } else {
                        self.linkedNodes.append(destinationNode)
                    }
                } else {
                    self.unlinkedNodes.append(destinationNode)
                }
                self.areDevicesLinked(sourceNode: sourceNode, nodes: nodes, index: index+1, completionHandler: completionHandler)
            } else {
                self.areDevicesLinked(sourceNode: sourceNode, nodes: nodes, index: index+1, completionHandler: completionHandler)
            }
        } else {
            completionHandler()
        }
    }

    /// Hide table
    /// - Parameter flag: flag
    func hideTable(_ flag: Bool) {
        bindingTable.isHidden = flag
        noDeviceImage.isHidden = !flag
        noDeviceLabel.isHidden = !flag
    }
    
    /// Check destination node ACL
    /// - Parameters:
    ///   - destinationNode: destination node
    ///   - sourceDeviceId: source node device id
    ///   - accessControlEntries: ACL of destination node
    func checkDestinationNodeACL(forDestinationNode destinationNode: ESPNodeDetails,
                                 withSourceId sourceDeviceId: UInt64,
                                 accessControlEntries: MTRAccessControlClusterAccessControlEntryStruct?) {
        if let accessControlEntries = accessControlEntries, let subjects = accessControlEntries.subjects as? [NSNumber] {
            var areDevicesLinked = false
            for subject in subjects {
                let id = subject.int64Value
                if id == sourceDeviceId {
                    //devices are linked
                    areDevicesLinked = true
                    break
                }
            }
            if areDevicesLinked {
                self.linkedNodes.append(destinationNode)
            } else {
                self.unlinkedNodes.append(destinationNode)
            }
        }
    }
    
    /// Reload linked and unlinked data sources
    func reloadDataSource() {
        if let group = self.group, let groupId = group.groupID, let sourceNode = self.sourceNode, let matterId = sourceNode.getMatterNodeId(), let deviceId = matterId.hexToDecimal {
            self.fabricDetails.saveBindingData(groupId: groupId, deviceId: deviceId, linkedNodes: self.linkedNodes, unlinkedNodes: self.unlinkedNodes, endpointClusterId: self.endpointClusterId)
            self.bindingTable.reloadData()
        }
    }
    
    /// Configure cell
    /// - Parameters:
    ///   - cell: binding cell
    ///   - action: action
    ///   - destinationNode: destination node
    func configureCell(cell: inout BindingTableViewCell, action: Action, destinationNode: ESPNodeDetails) {
        if let destinationDeviceMatterNodeID = destinationNode.getMatterNodeId() {
            if let group = self.group, let groupId = group.groupID {
                if let deviceId = destinationDeviceMatterNodeID.hexToDecimal, let deviceName = self.fabricDetails.getNodeLabel(groupId: groupId, deviceId: deviceId) {
                    cell.deviceName.text = deviceName
                    cell.name = deviceName
                } else if let deviceName = self.fabricDetails.getDeviceName(groupId: groupId, matterNodeId: destinationDeviceMatterNodeID) {
                    cell.deviceName.text = deviceName
                    cell.name = deviceName
                } else {
                    cell.deviceName.text = destinationDeviceMatterNodeID
                    cell.name = destinationDeviceMatterNodeID
                }
            }
        }
        cell.action = action
        if self.isEditModeOn {
            switch action {
            case .add:
                cell.actionImage.image = UIImage(named: ESPMatterConstants.add)
            case .delete:
                cell.actionImage.image = UIImage(named: ESPMatterConstants.delete)
            default:
                break
            }
            cell.actionImageLeadingConstraint.constant = 15
            cell.actionImageProportionalHeight.constant = cell.frame.height/2
        } else {
            cell.actionImage.image = nil
            cell.actionImageLeadingConstraint.constant = 0
            cell.actionImageProportionalHeight.constant = 0
        }
    }
}

@available(iOS 16.4, *)
extension DevicesBindingViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header: DeviceBindingHeaderView = UIView.fromNib()
        header.deviceHeader.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        if section == 0 {
            header.deviceHeader.text = ESPMatterConstants.linkedDevices
        } else if section == 1 {
            header.deviceHeader.text = ESPMatterConstants.unlinkedDevices
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.linkedNodes.count
        }
        return self.unlinkedNodes.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (indexPath.section == 0 && indexPath.row < self.linkedNodes.count) || (indexPath.section == 1 && indexPath.row < self.unlinkedNodes.count), var cell = tableView.dequeueReusableCell(withIdentifier: BindingTableViewCell.reuseIdentifier, for: indexPath) as? BindingTableViewCell {
            UIView.animate(withDuration: 0.5) {
                if indexPath.section == 0 {
                    if indexPath.row < self.linkedNodes.count {
                        cell.deviceName.font = UIFont.systemFont(ofSize: cell.frame.height/2.4, weight: .semibold)
                        let linkedNode = self.linkedNodes[indexPath.row]
                        cell.destinationNode = linkedNode
                        self.configureCell(cell: &cell, action: .delete, destinationNode: linkedNode)
                    }
                } else if indexPath.section == 1 {
                    if indexPath.row < self.unlinkedNodes.count {
                        cell.deviceName.font = UIFont.systemFont(ofSize: cell.frame.height/2.4, weight: .semibold)
                        let unlinkedNode = self.unlinkedNodes[indexPath.row]
                        cell.destinationNode = unlinkedNode
                        self.configureCell(cell: &cell, action: .add, destinationNode: unlinkedNode)
                    }
                }
                self.view.layoutIfNeeded()
            }
            cell.indexPath = indexPath
            cell.delegate = self
            return cell
        }
        return UITableViewCell()
    }
}

@available(iOS 16.4, *)
extension DevicesBindingViewController: BindingTableViewCellDelegate {
    
    /// Execute linking action
    /// - Parameters:
    ///   - node: node to be linked
    ///   - action: action
    func executeLinkingAction(node: ESPNodeDetails?, action: Action) {
        if let sourceNode = self.sourceNode, let sourceNodeId = sourceNode.nodeID, let destinationNode = node, let destinationNodeId = destinationNode.nodeID, let sourceDeviceId = sourceNode.getMatterNodeId()?.hexToDecimal, let destinationDeviveId = node?.getMatterNodeId()?.hexToDecimal {
            guard let destMatterNodeId = destinationNode.matterNodeID, User.shared.isMatterNodeConnected(matterNodeId: destMatterNodeId) else {
                Utility.showToastMessage(view: self.view, message: ESPMatterConstants.deviceNotReachableMsg)
                return
            }
            if action == .add {
                Utility.showLoader(message: ESPMatterConstants.linkingDevicesMeg, view: self.view)
                ESPMTRCommissioner.shared.linkDevice(endpointClusterId: self.endpointClusterId, sourceDeviceId: sourceDeviceId, destinationDeviveId: destinationDeviveId) { result in
                    DispatchQueue.main.async {
                        Utility.hideLoader(view: self.view)
                        if result {
                            var rainmakerNode: Node?
                            let nodes = User.shared.associatedNodeList ?? []
                            for node in nodes {
                                if let nodeId = node.node_id, nodeId == sourceNodeId {
                                    rainmakerNode = node
                                    break
                                }
                            }
                            if let node = rainmakerNode {
                                Utility.showLoader(message: ESPMatterConstants.linkingDevicesMeg, view: self.view)
                                self.service = ESPNodeGroupMetadataService(switchIndex: self.switchIndex)
                                self.service?.bindDevice(node: node, destinationNodeId: destinationNodeId) { result in
                                    for index in 0..<self.unlinkedNodes.count {
                                        let dest = self.unlinkedNodes[index]
                                        if let id = destinationNode.getMatterNodeId(), dest.getMatterNodeId() == id {
                                            self.linkedNodes.append(dest)
                                            self.unlinkedNodes.remove(at: index)
                                            break
                                        }
                                    }
                                    Utility.hideLoader(view: self.view)
                                    self.reloadDataSource()
                                }
                            }
                        } else {
                            self.showAlertWithOptions(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.bindingFailureMsg, actions: [UIAlertAction(title: ESPMatterConstants.okTxt, style: .default, handler: nil)])
                        }
                    }
                }
            } else {
                Utility.showLoader(message: ESPMatterConstants.unlinkingDevicesMsg, view: self.view)
                ESPMTRCommissioner.shared.unlinkDevice(endpointClusterId: self.endpointClusterId, sourceDeviceId: sourceDeviceId, destinationDeviveId: destinationDeviveId) { result in
                    DispatchQueue.main.async {
                        Utility.hideLoader(view: self.view)
                        if result {
                            var rainmakerNode: Node?
                            let nodes = User.shared.associatedNodeList ?? []
                            for node in nodes {
                                if let nodeId = node.node_id, nodeId == sourceNodeId {
                                    rainmakerNode = node
                                    break
                                }
                            }
                            if let node = rainmakerNode {
                                Utility.showLoader(message: ESPMatterConstants.unlinkingDevicesMsg, view: self.view)
                                self.service = ESPNodeGroupMetadataService(switchIndex: self.switchIndex)
                                self.service?.unbindDevice(node: node, destinationNodeId: destinationNodeId) { result in
                                    for index in 0..<self.linkedNodes.count {
                                        let dest = self.linkedNodes[index]
                                        if let id = destinationNode.getMatterNodeId(), dest.getMatterNodeId() == id {
                                            self.unlinkedNodes.append(dest)
                                            self.linkedNodes.remove(at: index)
                                            break
                                        }
                                    }
                                    Utility.hideLoader(view: self.view)
                                    self.reloadDataSource()
                                }
                            }
                        } else {
                            self.showAlertWithOptions(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.unbindingFailureMsg, actions: [UIAlertAction(title: ESPMatterConstants.okTxt, style: .default, handler: nil)])
                        }
                    }
                }
            }
        }
    }
}
#endif
