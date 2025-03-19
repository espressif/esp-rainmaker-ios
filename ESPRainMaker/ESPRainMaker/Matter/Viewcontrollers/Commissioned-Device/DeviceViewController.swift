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
        self.showDefaultUI = false
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
    
    //TODO: Show node info screen
    @objc func showNodeInfo() {
        let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
        let destination = deviceStoryboard.instantiateViewController(withIdentifier: "nodeDetailsVC") as! NodeDetailsViewController
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
        self.deviceTableView.register(UINib(nibName: "GenericControlTableViewCell", bundle: nil), forCellReuseIdentifier: "genericControlCell")
        self.deviceTableView.register(UINib(nibName: SliderTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: SliderTableViewCell.reuseIdentifier)
        self.deviceTableView.register(UINib(nibName: "DropDownTableViewCell", bundle: nil), forCellReuseIdentifier: "dropDownTableViewCell")
        self.deviceTableView.register(UINib(nibName: ESPMTRLevelSliderTVC.reuseIdentifier, bundle: nil), forCellReuseIdentifier: ESPMTRLevelSliderTVC.reuseIdentifier)
        self.deviceTableView.register(UINib(nibName: ESPMTRSaturationSliderTVC.reuseIdentifier, bundle: nil), forCellReuseIdentifier: ESPMTRSaturationSliderTVC.reuseIdentifier)
        self.deviceTableView.register(UINib(nibName: ESPMTRCCTSliderTVC.reuseIdentifier, bundle: nil), forCellReuseIdentifier: ESPMTRCCTSliderTVC.reuseIdentifier)
        self.deviceTableView.register(UINib(nibName: ESPMTROCSSliderTVC.reuseIdentifier, bundle: nil), forCellReuseIdentifier: ESPMTROCSSliderTVC.reuseIdentifier)
        self.deviceTableView.register(UINib(nibName: ESPMTROHSSliderTVC.reuseIdentifier, bundle: nil), forCellReuseIdentifier: ESPMTROHSSliderTVC.reuseIdentifier)
        self.deviceTableView.register(UINib(nibName: DeviceInfoCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: DeviceInfoCell.reuseIdentifier)
        self.deviceTableView.register(UINib(nibName: CustomInfoCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: CustomInfoCell.reuseIdentifier)
        self.deviceTableView.register(UINib(nibName: ParticipantDataCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: ParticipantDataCell.reuseIdentifier)
        self.deviceTableView.register(UINib(nibName: CustomActionCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: CustomActionCell.reuseIdentifier)
        self.generateCells()
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
                    ESPMTRCommissioner.shared.readParticipantData(deviceId: deviceId, endpoint: endpoint) { data in
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
            if let node = self.rainmakerNode, let _ = node.rainmakerDeviceName, node.isRainmaker {
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
    
    /// Setup offline UI
    func setupOfflineUI() {
        DispatchQueue.main.async {
            self.offlineView.isHidden = !self.isDeviceOffline
            self.offlineViewHeight.constant = self.isDeviceOffline ? 17.0 : 0.0
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
