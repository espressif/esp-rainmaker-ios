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
    var isDelete: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.restartMatterController()
        if let deviceName = self.deviceName {
            title = deviceName
        } else {
            title = ESPMatterConstants.deviceTxt
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
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
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

    /// Restart matter controller
    func restartMatterController() {
        if let group = self.group, let groupId = group.groupID, let userNOCDetails = ESPMatterFabricDetails.shared.getUserNOCDetails(groupId: groupId) {
            ESPMTRCommissioner.shared.shutDownController()
            ESPMTRCommissioner.shared.group = self.group
            ESPMTRCommissioner.shared.initializeMTRControllerWithUserNOC(matterFabricData: group, userNOCData: userNOCDetails)
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
        navigationController?.pushViewController(destination, animated: true)
    }
    
    
    
    /// show binding button in right bar button item
    func showRightBarButtons(showInfo: Bool) {
        var buttons = [UIBarButtonItem]()
        if showInfo {
            let infoButton = UIBarButtonItem(image: UIImage(named: "info_icon"), style: .done, target: self, action: #selector(showNodeInfo))
            infoButton.tintColor = .darkGray
            buttons.append(infoButton)
        }
        if let group = group, let groupId = group.groupID, let matterNodeId = matterNodeId, let deviceId = matterNodeId.hexToDecimal {
            if ESPMatterClusterUtil.shared.isOnOffClientSupported(groupId: groupId, deviceId: deviceId) {
                let clients = ESPMatterClusterUtil.shared.fetchBindingServers(groupId: groupId, deviceId: deviceId)
                if clients.count > 0, !self.isDelete {
                    let bindingButton = UIBarButtonItem(image: UIImage(named: ESPMatterConstants.binding), style: .plain, target: self, action: #selector(openBindingWindow))
                    bindingButton.tintColor = .darkGray
                    buttons.append(bindingButton)
                }
            }
        }
        self.navigationItem.rightBarButtonItems = buttons
    }
    
    /// Register cells
    func registerCells() {
        self.deviceTableView.register(UINib(nibName: SliderTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: SliderTableViewCell.reuseIdentifier)
        self.generateCells()
    }
    
    /// Generate cells
    func generateCells() {
        cellInfo.removeAll()
        if let group = group, let groupId = group.groupID, let matterNodeId = matterNodeId, let deviceId = matterNodeId.hexToDecimal {
            if ESPMatterClusterUtil.shared.isOnOffServerSupported(groupId: groupId, deviceId: deviceId).0 {
                cellInfo.append(ESPMatterConstants.onOff)
            }
            if ESPMatterClusterUtil.shared.isLevelControlServerSupported(groupId: groupId, deviceId: deviceId).0 {
                cellInfo.append(ESPMatterConstants.levelControl)
            }
            if ESPMatterClusterUtil.shared.isColorControlServerSupported(groupId: groupId, deviceId: deviceId).0 {
                cellInfo.append(ESPMatterConstants.colorControl)
            }
            if ESPMatterClusterUtil.shared.isOpenCommissioningWindowSupported(groupId: groupId, deviceId: deviceId).0 {
                cellInfo.append(ESPMatterConstants.openCW)
            }
            if ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: groupId, deviceId: deviceId).0 {
                cellInfo.append(ESPMatterConstants.rainmakerController)
            }
            if !self.isDelete {
                ESPMTRCommissioner.shared.readAllACLAttributes(deviceId: deviceId) { _ in }
            }
        }
        /*
         cellInfo.append(ESPMatterConstants.delete)
         */
        self.deviceTableView.isUserInteractionEnabled = !self.isDelete
        self.setupOfflineUI()
        self.deviceTableView.reloadData()
    }
    
    /// Setup offline UI
    func setupOfflineUI() {
        if self.isDelete {
            self.offlineView.isHidden = false
            self.offlineViewHeight.constant = 17.0
        } else {
            self.offlineView.isHidden = true
            self.offlineViewHeight.constant = 0.0
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
        let serversData = ESPMatterFabricDetails.shared.fetchServersData(groupId: groupId, deviceId: deviceId)
        let clientsData = ESPMatterFabricDetails.shared.fetchClientsData(groupId: groupId, deviceId: deviceId)
        let endpointsData = ESPMatterFabricDetails.shared.fetchEndpointsData(groupId: groupId, deviceId: deviceId)
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
