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
//  DeviceViewController.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import UIKit
import AVFAudio
import Matter

@available(iOS 16.4, *)
class DeviceViewController: UIViewController {
    
    static let storyboardId = "DeviceViewController"
    
    @IBOutlet weak var topBarTitle: BarTitle!
    @IBOutlet weak var infoButton: BarButton!
    @IBOutlet weak var bindingButton: BarButton!
    
    @IBOutlet weak var offlineView: UIView!
    @IBOutlet weak var offlineViewHeight: NSLayoutConstraint!
    @IBOutlet weak var deviceTableView: UITableView!
    @IBOutlet weak var betaLabel: UILabel!
    @IBOutlet weak var betaLabelHeightConstraint: NSLayoutConstraint!
    var group: ESPNodeGroup?
    var node: ESPNodeDetails?
    var allNodes: [ESPNodeDetails]?
    var matterNodeId: String?
    var device: String!
    var cellInfo: [String] = [String]()
    var endPoint: UInt16 = 1
    var sharingTextField: UITextField?
    var endpointClusterId: [String: UInt]?
    var rainmakerNodes: [Node]?
    var rainmakerNode: Node?
    var deviceName: String?
    var switchIndex: Int?
    var isDeviceOffline: Bool = false
    let fabricDetails = ESPMatterFabricDetails.shared

    //badge
    var nameField: UITextField?
    var companyNameField: UITextField?
    var emailField: UITextField?
    var contactField: UITextField?
    var eventNameField: UITextField?
    var nodeConnectionStatus: NodeConnectionStatus = .local
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.restartMatterController()
        if let node = self.rainmakerNode, let deviceName = node.rainmakerDeviceName {
            self.topBarTitle.text = deviceName
        } else if let node = self.rainmakerNode, let groupId = node.groupId, let deviceId = node.matter_node_id?.hexToDecimal, let name = self.fabricDetails.getNodeLabel(groupId: groupId, deviceId: deviceId) {
            self.topBarTitle.text = name
        } else if let deviceName = self.deviceName {
            self.topBarTitle.text = deviceName
        } else {
            self.topBarTitle.text = ESPMatterConstants.deviceTxt
        }
        
        self.navigationController?.view.backgroundColor = .white
        self.navigationController?.addCustomBottomLine(color: .lightGray, height: 0.5)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        view.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
        self.setNavigationTextAttributes(color: .darkGray)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: ESPMatterConstants.backTxt, style: .plain, target: self, action: #selector(goBack))
        self.navigationItem.leftBarButtonItem?.tintColor = .systemBlue
        self.view.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        self.deviceTableView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        self.deviceTableView.delegate = self
        self.deviceTableView.dataSource = self
        if let rainmakerNodes = self.rainmakerNodes {
            for rmakeNode in rainmakerNodes {
                if let node = node, let id = node.nodeID, let nodeId = rmakeNode.node_id, id == nodeId {
                    self.rainmakerNode = rmakeNode
                    break
                }
            }
        }
        self.showRightBarButtons(showInfo: true)
        self.showBetaLabel()
        self.registerCells()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setNavigationTextAttributes(color: .darkGray)
        tabBarController?.tabBar.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func appEnterForeground() {
        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
        ESPMTRCommissioner.shared.shutDownController()
        self.restartMatterController()
        DispatchQueue.main.async {
            self.deviceTableView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now()+2.0) {
                Utility.hideLoader(view: self.view)
            }
        }
    }
    
    /// Show beta label
    func showBetaLabel() {
        if let group = group, let groupId = group.groupID, let matterNodeId = matterNodeId, let deviceId = matterNodeId.hexToDecimal, ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: groupId, deviceId: deviceId).0 {
            DispatchQueue.main.async {
                self.betaLabel.text = "Beta"
                self.betaLabelHeightConstraint.constant = 16.0
            }
            return
        }
        DispatchQueue.main.async {
            self.betaLabel.text = ""
            self.betaLabelHeightConstraint.constant = 0.0
        }
    }
    
    /// Back button pressed
    /// - Parameter sender: button pressed
    @IBAction func backButtonPressed(_ sender: Any) {
        self.goBack()
    }
    
    /// Restart matter controller
    func restartMatterController() {
        if let group = self.group, let groupId = group.groupID, let userNOCDetails = self.fabricDetails.getUserNOCDetails(groupId: groupId) {
            if let grp = ESPMTRCommissioner.shared.group, let grpId = grp.groupID, grpId != groupId {
                ESPMTRCommissioner.shared.shutDownController()
            }
            if ESPMTRCommissioner.shared.sController == nil {
                ESPMTRCommissioner.shared.group = self.group
                ESPMTRCommissioner.shared.initializeMTRControllerWithUserNOC(matterFabricData: group, userNOCData: userNOCDetails)
            }
        }
    }
    
    /// Hide keyboard
    @objc private func hideKeyBoard() {
        view.endEditing(true)
    }
    
    /// Open binding window
    @objc func openBindingWindow() {
        if let node = self.node {
            let storyboard = UIStoryboard(name: ESPMatterConstants.matterStoryboardId, bundle: nil)
            let devicesBindingVC = storyboard.instantiateViewController(withIdentifier: DevicesBindingViewController.storyboardId) as! DevicesBindingViewController
            devicesBindingVC.group = self.group
            devicesBindingVC.nodes = self.allNodes
            devicesBindingVC.sourceNode = node
            devicesBindingVC.switchIndex = self.switchIndex
            devicesBindingVC.endpointClusterId = self.endpointClusterId
            self.navigationController?.pushViewController(devicesBindingVC, animated: true)
        }
    }
    
    //TODO: Show node info screen
    @objc func showNodeInfo() {
        let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
        let destination = deviceStoryboard.instantiateViewController(withIdentifier: "nodeDetailsVC") as! NodeDetailsViewController
        destination.currentNode = self.rainmakerNode
        destination.group = self.group
        destination.allNodes = self.allNodes
        destination.endpointClusterId = endpointClusterId
        destination.switchIndex = self.switchIndex
        destination.sourceNode = self.node
        navigationController?.pushViewController(destination, animated: true)
    }
    
    
    
    /// show binding button in right bar button item
    func showRightBarButtons(showInfo: Bool) {
        if showInfo {
            if let infoImage = UIImage(named: "info_icon") {
                self.infoButton.imageView?.image = infoImage
            }
            self.infoButton.addTarget(self, action: #selector(showNodeInfo), for: .touchUpInside)
        }
    }
    
    /// Register cells
    func registerCells() {
        self.deviceTableView.register(UINib(nibName: SliderTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: SliderTableViewCell.reuseIdentifier)
        self.deviceTableView.register(UINib(nibName: "DropDownTableViewCell", bundle: nil), forCellReuseIdentifier: "dropDownTableViewCell")
        self.deviceTableView.register(UINib(nibName: DeviceInfoCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: DeviceInfoCell.reuseIdentifier)
        self.deviceTableView.register(UINib(nibName: CustomInfoCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: CustomInfoCell.reuseIdentifier)
        self.deviceTableView.register(UINib(nibName: ParticipantDataCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: ParticipantDataCell.reuseIdentifier)
        self.generateCells()
    }
    
    /// Generate cells
    func generateCells() {
        self.cellInfo.removeAll()
        if let group = group, let groupId = group.groupID, let matterNodeId = matterNodeId, let deviceId = matterNodeId.hexToDecimal {
            if let node = self.rainmakerNode, let _ = node.rainmakerDeviceName, node.isRainmaker {
                self.cellInfo.append(ESPMatterConstants.deviceName)
                self.addClusterUtilCells(groupId: groupId, deviceId: deviceId)
                self.setupTableUI()
            } else {
                if let _ = self.fabricDetails.getNodeLabel(groupId: groupId, deviceId: deviceId) {
                    self.cellInfo.append(ESPMatterConstants.nodeLabel)
                    let badgeFlag = ESPMatterClusterUtil.shared.isParticipantDataSupported(groupId: groupId, deviceId: deviceId)
                    if badgeFlag.0 {
                        if let _ = self.fabricDetails.fetchParticipantData(groupId: groupId, deviceId: deviceId) {
                            self.addClusterUtilCells(groupId: groupId, deviceId: deviceId)
                            self.setupTableUI()
                        } else {
                            if let key = badgeFlag.1, let endpoint = UInt16(key) {
                                if self.isDeviceOffline {
                                    self.addClusterUtilCells(groupId: groupId, deviceId: deviceId)
                                    self.setupTableUI()
                                } else {
                                    DispatchQueue.main.async {
                                        Utility.showLoader(message: "", view: self.view)
                                    }
                                    ESPMTRCommissioner.shared.readParticipantData(deviceId: deviceId, endpoint: endpoint) { data in
                                        DispatchQueue.main.async {
                                            Utility.hideLoader(view: self.view)
                                        }
                                        if let data = data {
                                            self.fabricDetails.saveParticipantData(groupId: groupId, deviceId: deviceId, participantData: data)
                                        } else {
                                            let details = ESPParticipantData(eventName: "CSA MM Nov '23")
                                            self.fabricDetails.saveParticipantData(groupId: groupId, deviceId: deviceId, participantData: details)
                                        }
                                        self.addClusterUtilCells(groupId: groupId, deviceId: deviceId)
                                        self.setupTableUI()
                                    }
                                }
                            } else {
                                self.addClusterUtilCells(groupId: groupId, deviceId: deviceId)
                                self.setupTableUI()
                            }
                        }
                    } else {
                        self.addClusterUtilCells(groupId: groupId, deviceId: deviceId)
                        self.setupTableUI()
                    }
                } else if !self.isDeviceOffline {
                    ESPMTRCommissioner.shared.shutDownController()
                    switch self.nodeConnectionStatus {
                    case .local:
                        if let _ = self.fabricDetails.getNodeLabel(groupId: groupId, deviceId: deviceId) {
                            self.cellInfo.append(ESPMatterConstants.nodeLabel)
                            self.addClusterUtilCells(groupId: groupId, deviceId: deviceId)
                            self.setupTableUI()
                        } else {
                            self.restartMatterController()
                            ESPMTRCommissioner.shared.getNodeLabel(deviceId: deviceId) { nodeLabel in
                                if let nodeLabel = nodeLabel {
                                    ESPMatterFabricDetails.shared.saveNodeLabel(groupId: groupId, deviceId: deviceId, nodeLabel: nodeLabel)
                                    self.cellInfo.append(ESPMatterConstants.nodeLabel)
                                }
                                self.addClusterUtilCells(groupId: groupId, deviceId: deviceId)
                                self.setupTableUI()
                            }
                        }
                    case .controller:
                        self.addClusterUtilCells(groupId: groupId, deviceId: deviceId)
                        self.setupTableUI()
                    default:
                        break
                    }
                }
            }
        } else {
            self.setupTableUI()
        }
    }
    
    /// Add cells for cluster commands
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    func addClusterUtilCells(groupId: String, deviceId: UInt64) {
        if ESPMatterClusterUtil.shared.isOnOffServerSupported(groupId: groupId, deviceId: deviceId).0 {
            cellInfo.append(ESPMatterConstants.onOff)
        }
        if ESPMatterClusterUtil.shared.isLevelControlServerSupported(groupId: groupId, deviceId: deviceId).0 {
            cellInfo.append(ESPMatterConstants.levelControl)
        }
        if ESPMatterClusterUtil.shared.isColorControlServerSupported(groupId: groupId, deviceId: deviceId).0 {
            cellInfo.append(ESPMatterConstants.colorControl)
            cellInfo.append(ESPMatterConstants.saturationControl)
        }
        if ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: groupId, deviceId: deviceId).0 {
            cellInfo.append(ESPMatterConstants.rainmakerController)
        }
        if ESPMatterClusterUtil.shared.isParticipantDataSupported(groupId: groupId, deviceId: deviceId).0 {
            cellInfo.append(ESPMatterConstants.participantData)
        }
        if ESPMatterClusterUtil.shared.isAirConditionerSupported(groupId: groupId, deviceId: deviceId).0 {
            cellInfo.append(ESPMatterConstants.localTemperature)
            cellInfo.append(ESPMatterConstants.occupiedCoolingSetpoint)
            cellInfo.append(ESPMatterConstants.systemMode)
        }
    }
    
    /// Setup tableview UI
    func setupTableUI() {
        DispatchQueue.main.async {
            self.setupOfflineUI()
            self.deviceTableView.reloadData()
        }
    }
    
    /// Setup offline UI
    func setupOfflineUI() {
        DispatchQueue.main.async {
            self.offlineView.isHidden = !self.isDeviceOffline
            self.offlineViewHeight.constant = self.isDeviceOffline ? 17.0 : 0.0
        }
    }
    
    
    /// Check matter connection
    func checkMatterConnection() {
        if let group = group, let id = group.groupID, let matterNodeId = matterNodeId, let deviceId = matterNodeId.hexToDecimal {
            Utility.showLoader(message: ESPMatterConstants.fetchingRainmakerDataMsg, view: self.view)
            ESPMTRCommissioner.shared.isConnectedToMatter(timeout: 10.0, deviceId: deviceId) { result in
                Utility.hideLoader(view: self.view)
                if result {
                    self.fetchDeviceDetails(groupId: id, deviceId: deviceId)
                }
            }
        }
    }
    
    /// Fetch device details
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    func fetchDeviceDetails(groupId: String, deviceId: UInt64) {
        let serversData = self.fabricDetails.fetchServersData(groupId: groupId, deviceId: deviceId)
        let clientsData = self.fabricDetails.fetchClientsData(groupId: groupId, deviceId: deviceId)
        let endpointsData = self.fabricDetails.fetchEndpointsData(groupId: groupId, deviceId: deviceId)
        if serversData.count == 0, clientsData.count == 0, endpointsData.count == 0 {
            Utility.showLoader(message: ESPMatterConstants.fetchingEndpointsMsg, view: self.view)
            ESPMTRCommissioner.shared.addDeviceDetails(groupId: groupId, deviceId: deviceId) {
                Utility.hideLoader(view: self.view)
                self.registerCells()
            }
        }
    }
    
    /// Fetch endpoint cluster ids
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - value: value
    /// - Returns: [endpoint id: cluster id]
    func fetchEndpointClusterIds(groupId: String, deviceId: UInt64, value: String) -> (String, [String: UInt]?)? {
        let clients = ESPMatterClusterUtil.shared.fetchBindingServers(groupId: groupId, deviceId: deviceId)
        let keys = clients.keys.sorted {
            return $0 < $1
        }
        let indexStr = value.replacingOccurrences(of: ESPMatterConstants.binding, with: "")
        if let index = Int(indexStr), index < keys.count {
            let key = keys[index]
            if let clientCluster = clients[key] {
                if clients.count > 1 {
                    return ("\(ESPMatterConstants.deviceBindingTxt) (\(ESPMatterConstants.switchTxt)\(index))", [key: clientCluster])
                } else {
                    return (ESPMatterConstants.deviceBindingTxt, [key: clientCluster])
                }
            }
        }
        return (ESPMatterConstants.deviceBindingTxt, nil)
    }
}

@available(iOS 16.4, *)
extension DeviceViewController {
    
    /// Share device
    func shareDevice() {
        let alert = UIAlertController(title: ESPMatterConstants.shareNodeMsg, message: ESPMatterConstants.shareGroupEmailMessage, preferredStyle: .alert)
        alert.addTextField() { textfield in
            textfield.placeholder = ESPMatterConstants.emailIdTxt
            self.sharingTextField = textfield
        }
        alert.addAction(UIAlertAction(title: ESPMatterConstants.shareTxt, style: .default) { _ in
            if let textField = self.sharingTextField, let email = textField.text, email.count > 0 {
                //TODO: Add code to share individual device
            }
        })
        alert.addAction(UIAlertAction(title: ESPMatterConstants.cancelTxt, style: .destructive) {_ in})
        self.present(alert, animated: true)
    }
}
#endif
