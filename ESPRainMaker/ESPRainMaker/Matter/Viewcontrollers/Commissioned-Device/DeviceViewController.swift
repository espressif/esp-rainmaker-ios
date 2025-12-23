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
    @IBOutlet weak var offlineView: UIView!
    @IBOutlet var connectionStatusLabel: UILabel!
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
    var bindingEndpointClusterId: [String: UInt]?
    var rainmakerNodes: [Node]?
    var rainmakerNode: Node?
    var deviceName: String?
    var switchIndex: Int?
    var isDeviceOffline: Bool = false
    var showDefaultUI: Bool = false
    let fabricDetails = ESPMatterFabricDetails.shared
    
    var hideOCS: Bool = false
    var hideOHS: Bool = false

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
        } else if let node = self.rainmakerNode, let matterDeviceName = node.matterDeviceName {
            self.topBarTitle.text = matterDeviceName
        } else if let node = self.rainmakerNode, let groupId = node.groupId, let matterNodeId = node.matter_node_id, let name = self.fabricDetails.getDeviceName(groupId: groupId, matterNodeId: matterNodeId) {
            self.topBarTitle.text = name
        } else if let deviceName = self.deviceName, deviceName.count > 0 {
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
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor(hexString: ESPMatterConstants.customBackgroundColor)
        self.view.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        self.deviceTableView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        self.deviceTableView.delegate = self
        self.deviceTableView.dataSource = self
        if let rainmakerNodes = self.rainmakerNodes {
            for rMakerNode in rainmakerNodes {
                if let node = node, let id = node.nodeID, let nodeId = rMakerNode.node_id, id == nodeId {
                    self.rainmakerNode = rMakerNode
                    break
                }
            }
        }
        self.showRightBarButtons()
        self.showBetaLabel()
        self.registerCells()
        
        // Performance optimizations
        self.deviceTableView.estimatedRowHeight = 70.0
        self.deviceTableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setNavigationTextAttributes(color: .darkGray)
        tabBarController?.tabBar.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateConnectionStatus), name: Notification.Name(Constants.localNetworkUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateConnectionStatus), name: Notification.Name(Constants.matterDeviceConnectivityUpdate), object: nil)
        
        // Update connection status when view appears
        updateConnectionStatus()
        
        // Listen for controller parameter updates when in controller mode
        if nodeConnectionStatus == .controller {
            NotificationCenter.default.addObserver(self, selector: #selector(controllerParamUpdateReceived), name: Notification.Name(Constants.controllerParamUpdate), object: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(Constants.localNetworkUpdateNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(Constants.matterDeviceConnectivityUpdate), object: nil)
        
        #if ESPRainMakerMatter
        if nodeConnectionStatus == .controller {
            NotificationCenter.default.removeObserver(self, name: Notification.Name(Constants.controllerParamUpdate), object: nil)
        }
        #endif
    }
    
    @objc func appEnterForeground() {
        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
        if let group = self.group, let groupId = group.groupID {
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
            commissioner.shutDownController()
        }
        self.restartMatterController()
        self.showDefaultUI = false
        DispatchQueue.main.async {
            self.deviceTableView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now()+2.0) {
                Utility.hideLoader(view: self.view)
            }
        }
        // Update connection status when app enters foreground (WiFi might have changed)
        updateConnectionStatus()
    }
    
    @objc func controllerParamUpdateReceived() {
        // Update local rainmakerNode object from updated associatedNodeList
        if let rainmakerNode = self.rainmakerNode, let nodeId = rainmakerNode.node_id {
            // Find the updated node in associatedNodeList
            if let updatedNode = User.shared.associatedNodeList?.first(where: { $0.node_id == nodeId }) {
                self.rainmakerNode = updatedNode
                
                // Reload the device table view on main thread
                DispatchQueue.main.async {
                    if self.presentedViewController == nil {
                        self.deviceTableView.reloadData()
                    }
                }
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
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
            if let grp = commissioner.group, let grpId = grp.groupID, grpId != groupId {
                commissioner.shutDownController()
            }
            if commissioner.sController == nil {
                commissioner.group = self.group
                commissioner.initializeMTRControllerWithUserNOC(matterFabricData: group, userNOCData: userNOCDetails)
            }
        }
    }
    
    /// Hide keyboard
    @objc private func hideKeyBoard() {
        view.endEditing(true)
    }
    
    //TODO: Show node info screen
    @objc func showNodeInfo() {
        let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
        guard let destination = deviceStoryboard.instantiateViewController(withIdentifier: "nodeDetailsVC") as? NodeDetailsViewController else { return }
        destination.currentNode = self.rainmakerNode
        destination.group = self.group
        destination.allNodes = self.allNodes
        destination.bindingEndpointClusterId = bindingEndpointClusterId
        destination.switchIndex = self.switchIndex
        destination.sourceNode = self.node
        navigationController?.pushViewController(destination, animated: true)
    }
    
    /// show binding button in right bar button item
    func showRightBarButtons() {
        if let infoImage = UIImage(named: "info_icon") {
            self.infoButton.imageView?.image = infoImage
        }
        self.infoButton.addTarget(self, action: #selector(showNodeInfo), for: .touchUpInside)
    }
    
    /// Register cells
    func registerCells() {
        registerProgrammaticCells()
        registerMatterInfoCells()
        self.generateCells()
    }
    
    /// Register programmatic cells
    private func registerProgrammaticCells() {
        deviceTableView.register(ParamSliderCell.self, forCellReuseIdentifier: ParamSliderCell.reuseIdentifier)
        deviceTableView.register(ParamHueSliderCell.self, forCellReuseIdentifier: ParamHueSliderCell.reuseIdentifier)
        deviceTableView.register(ParamDropDownCell.self, forCellReuseIdentifier: ParamDropDownCell.reuseIdentifier)
        deviceTableView.register(ParamGenericCell.self, forCellReuseIdentifier: ParamGenericCell.reuseIdentifier)
        deviceTableView.register(ParamCustomActionCell.self, forCellReuseIdentifier: ParamCustomActionCell.reuseIdentifier)
    }
    
    /// Register Matter-specific info cells (XIB-based, to be migrated later)
    private func registerMatterInfoCells() {
        let matterCells = [DeviceInfoCell.reuseIdentifier, CustomInfoCell.reuseIdentifier,
                         ParticipantDataCell.reuseIdentifier]
        matterCells.forEach { identifier in
            deviceTableView.register(UINib(nibName: identifier, bundle: nil), forCellReuseIdentifier: identifier)
        }
    }
    
    /// Read participant
    /// - Parameters:
    ///   - isParticipantDataSupported: is participant data supported
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func readParticipantData(isParticipantDataSupported: (Bool, String?), groupId: String, deviceId: UInt64, completion: @escaping (Bool) -> Void) {
        if !isParticipantDataSupported.0 {
            completion(false)
        }
        if let _ = self.fabricDetails.fetchParticipantData(groupId: groupId, deviceId: deviceId) {
            completion(false)
        } else {
            switch self.nodeConnectionStatus {
            case .local:
                if let key = isParticipantDataSupported.1, let endpoint = UInt16(key) {
                    let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
                    commissioner.readParticipantData(deviceId: deviceId, endpoint: endpoint) { data in
                        if let data = data {
                            self.fabricDetails.saveParticipantData(groupId: groupId, deviceId: deviceId, participantData: data)
                        } else {
                            let details = ESPParticipantData(eventName: "CSA MM Nov '23")
                            self.fabricDetails.saveParticipantData(groupId: groupId, deviceId: deviceId, participantData: details)
                        }
                        completion(true)
                    }
                } else {
                    completion(false)
                }
            default:
                completion(false)
            }
        }
    }
    
    /// Generate cells
    func generateCells() {
        self.cellInfo.removeAll()
        if let group = group, let groupId = group.groupID, let matterNodeId = matterNodeId, let deviceId = matterNodeId.hexToDecimal {
            self.cellInfo.append(ESPMatterConstants.matterDeviceName)
            if let node = self.rainmakerNode, let _ = node.rainmakerDeviceName, node.isRainmakerMatter {
                //Setup UI for a rainmaker+matter node
                self.addClusterUtilCells(groupId: groupId, deviceId: deviceId, forNode: node)
                self.setupTableUI(showDefaultUI: false)
            } else {
                //Setup UI for a matter node
                let isBadgeSupported = ESPMatterClusterUtil.shared.isParticipantDataSupported(groupId: groupId, deviceId: deviceId)
                if isBadgeSupported.0 {
                    self.cellInfo.append(ESPMatterConstants.participantData)
                }
                self.addClusterUtilCells(groupId: groupId, deviceId: deviceId, forNode: self.rainmakerNode)
                DispatchQueue.main.async {
                    self.setupTableUI(showDefaultUI: true)
                    Utility.showLoader(message: "", view: self.view)
                }
                self.readParticipantData(isParticipantDataSupported: isBadgeSupported, groupId: groupId, deviceId: deviceId) { isBadgeUpdateRequired in
                    DispatchQueue.main.async {
                        Utility.hideLoader(view: self.view)
                        if isBadgeUpdateRequired {
                            self.setupTableUI(showDefaultUI: false)
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.setupTableUI(showDefaultUI: false)
            }
        }
    }
    
    /// Add cells for cluster commands
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    func addClusterUtilCells(groupId: String, deviceId: UInt64, forNode node: Node? = nil) {
        if ESPMatterClusterUtil.shared.isOnOffServerSupported(groupId: groupId, deviceId: deviceId).0 {
            if ESPMatterClusterUtil.shared.isOnOffAttributeSupported(groupId: groupId, deviceId: deviceId) {
                cellInfo.append(ESPMatterConstants.onOff)
            }
        }
        if ESPMatterClusterUtil.shared.isLevelControlServerSupported(groupId: groupId, deviceId: deviceId).0 {
            if ESPMatterClusterUtil.shared.isCurrentLevelAttributeSupported(groupId: groupId, deviceId: deviceId) {
                cellInfo.append(ESPMatterConstants.levelControl)
            }
        }
        if ESPMatterClusterUtil.shared.isColorControlServerSupported(groupId: groupId, deviceId: deviceId).0 {
            if ESPMatterClusterUtil.shared.isCurrentHueAttributeSupported(groupId: groupId, deviceId: deviceId) {
                cellInfo.append(ESPMatterConstants.colorControl)
            }
            if ESPMatterClusterUtil.shared.isCurrentSaturationAttributeSupported(groupId: groupId, deviceId: deviceId) {
                cellInfo.append(ESPMatterConstants.saturationControl)
            }
            if ESPMatterClusterUtil.shared.isCCTAttributeSupported(groupId: groupId, deviceId: deviceId) {
                cellInfo.append(ESPMatterConstants.cctControl)
            }
        }
        if ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: groupId, deviceId: deviceId).0 {
            cellInfo.append(ESPMatterConstants.rainmakerController)
        }
        if ESPMatterClusterUtil.shared.isThermostatConditionerSupported(groupId: groupId, deviceId: deviceId).0 {
            cellInfo.append(ESPMatterConstants.systemMode)
            if ESPMatterClusterUtil.shared.isLocalTemperatureAttributeSupported(groupId: groupId, deviceId: deviceId) {
                cellInfo.append(ESPMatterConstants.localTemperature)
            }
            cellInfo.append(ESPMatterConstants.occupiedCoolingSetpoint)
            cellInfo.append(ESPMatterConstants.occupiedHeatingSetpoint)
        }
        if ESPMatterClusterUtil.shared.isBRSupported(groupId: groupId, deviceId: deviceId).0 {
            cellInfo.append(ESPMatterConstants.borderRouter)
        }
        if ESPMatterClusterUtil.shared.isTBRMSupported(groupId: groupId, deviceId: deviceId).0 {
            cellInfo.append(ESPMatterConstants.borderRouter)
        }
        if ESPMatterClusterUtil.shared.isTempMeasurementSupported(groupId: groupId, deviceId: deviceId).0 {
            if ESPMatterClusterUtil.shared.isMeasuredValueAttributeSupported(groupId: groupId, deviceId: deviceId) {
                cellInfo.append(ESPMatterConstants.measuredTemperature)
            }
        }
    }
    
    /// Setup tableview UI
    func setupTableUI(showDefaultUI: Bool) {
        self.showDefaultUI = showDefaultUI
        DispatchQueue.main.async {
            self.setupOfflineUI()
            self.deviceTableView.reloadData()
        }
    }
    
    /// Update connection status from rainmakerNode and refresh UI
    @objc func updateConnectionStatus(_ notification: Notification? = nil) {
        // Update rainmakerNode from global list (connection status might have changed)
        if let rainmakerNode = self.rainmakerNode, let nodeId = rainmakerNode.node_id {
            // Find the updated node in associatedNodeList
            if let updatedNode = User.shared.associatedNodeList?.first(where: { $0.node_id == nodeId }) {
                let previousStatus = self.nodeConnectionStatus
                self.rainmakerNode = updatedNode
                
                // Update connection status from rainmakerNode
                // CRITICAL: Force fresh read of connection status by checking discoveredNodes directly
                // This ensures we get the latest state even if node reference is stale
                if let node = self.rainmakerNode {
                    var newStatus: NodeConnectionStatus = .offline
                    
                    // Check Matter discovery status directly (most up-to-date source)
                    if let matterNodeId = node.matter_node_id {
                        if User.shared.isMatterNodeConnected(matterNodeId: matterNodeId) {
                            newStatus = .local
                        } else if node.isRainmakerMatter, node.isConnected {
                            // Matter+Rainmaker device that's remote - treat as offline for DeviceViewController
                            newStatus = .offline
                        } else {
                            newStatus = .offline
                        }
                    } else {
                        // Not a Matter device - use node.connectionStatus
                        newStatus = node.connectionStatus
                    }
                    
                    // Check for controller mode separately (connectionStatus doesn't return .controller)
                    // DeviceViewController does NOT support remote mode - only local, controller, and offline
                    if newStatus == .offline {
                        // Check if device is reachable via controller
                        if let matterNodeId = node.matter_node_id, let controller = node.matterControllerNode, let controllerNodeId = controller.node_id {
                            let controllerStatus = controller.connectionStatus
                            if controllerStatus == .remote, let matterNodeData = MatterControllerParser.shared.getMatterNodeData(controllerNodeId: controllerNodeId, matterNodeId: matterNodeId), let enabled = matterNodeData.enabled, let reachable = matterNodeData.reachable, enabled, reachable {
                                newStatus = .controller
                            }
                        }
                    }
                    
                    // If status is remote, treat as offline (DeviceViewController doesn't support remote mode)
                    if newStatus == .remote {
                        newStatus = .offline
                    }
                    
                    self.nodeConnectionStatus = newStatus
                    self.isDeviceOffline = (newStatus == .offline)
                } else {
                    self.nodeConnectionStatus = .offline
                    self.isDeviceOffline = true
                }
            }
        }
        
        // Update UI
        DispatchQueue.main.async {
            self.setupOfflineUI()
            
            // Update visible cells directly to reflect connection status change
            // This ensures cells are updated even if reloadData() is skipped
            if let visibleIndexPaths = self.deviceTableView.indexPathsForVisibleRows {
                for indexPath in visibleIndexPaths {
                    if let cell = self.deviceTableView.cellForRow(at: indexPath) {
                        // Update cell alpha and enabled state based on connection status
                        let alpha: CGFloat = self.isDeviceOffline ? 0.5 : 1.0
                        cell.alpha = alpha
                        cell.isUserInteractionEnabled = !self.isDeviceOffline
                        
                        // Update specific cell types that have connection status-dependent UI
                        if let deviceNameCell = cell as? DeviceInfoCell {
                            deviceNameCell.isUserInteractionEnabled = !self.isDeviceOffline
                            deviceNameCell.editButton.isEnabled = !self.isDeviceOffline
                            deviceNameCell.alpha = alpha
                            deviceNameCell.deviceName.alpha = alpha
                            if let propertyName = deviceNameCell.propertyName {
                                propertyName.alpha = alpha
                            }
                        } else if let onOffCell = cell as? DeviceOnOffCell {
                            onOffCell.nodeConnectionStatus = self.nodeConnectionStatus
                            onOffCell.toggleSwitch.isEnabled = !self.isDeviceOffline
                            onOffCell.isUserInteractionEnabled = !self.isDeviceOffline
                            onOffCell.alpha = alpha
                            onOffCell.onOffStatus.alpha = alpha
                            onOffCell.toggleSwitch.alpha = alpha
                        } else if let sliderCell = cell as? ParamSliderCell {
                            // Update Matter slider cells
                            sliderCell.isDeviceOffline = self.isDeviceOffline
                            sliderCell.nodeConnectionStatus = self.nodeConnectionStatus
                            sliderCell.updateConnectionState()
                        } else if let hueSliderCell = cell as? ParamHueSliderCell {
                            // Update Matter hue slider cells
                            hueSliderCell.isDeviceOffline = self.isDeviceOffline
                            hueSliderCell.nodeConnectionStatus = self.nodeConnectionStatus
                            hueSliderCell.updateConnectionState()
                        }
                    }
                }
            }
            
            // Reload table view to update cell alpha values and connection status
            if self.presentedViewController == nil {
                self.deviceTableView.reloadData()
            }
        }
    }
    
    /// Setup offline UI
    func setupOfflineUI() {
        DispatchQueue.main.async {
            // Show connection status label for all states
            self.offlineView.isHidden = false
            self.offlineViewHeight.constant = 17.0
            
            switch self.nodeConnectionStatus {
            case .offline:
                if let node = self.rainmakerNode, node.isMatter, node.isRainmakerMatter, node.timestamp.getShortDate().count > 0 {
                    self.connectionStatusLabel.text = "Offline at \(node.timestamp.getShortDate())"
                } else {
                    self.connectionStatusLabel.text = ESPMatterConstants.offlineMode
                }
            case .local:
                // Device is online locally
                if let node = self.rainmakerNode, node.supportsEncryption {
                    self.connectionStatusLabel.text = "🔒 Reachable on WLAN"
                } else {
                    self.connectionStatusLabel.text = "Reachable on WLAN"
                }
            case .controller:
                // Device is online via controller
                self.connectionStatusLabel.text = "Controller"
            case .remote:
                // DeviceViewController does NOT support remote mode - treat as offline
                if let node = self.rainmakerNode, node.isMatter, node.isRainmakerMatter, node.timestamp.getShortDate().count > 0 {
                    self.connectionStatusLabel.text = "Offline at \(node.timestamp.getShortDate())"
                } else {
                    self.connectionStatusLabel.text = ESPMatterConstants.offlineMode
                }
            }
        }
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
