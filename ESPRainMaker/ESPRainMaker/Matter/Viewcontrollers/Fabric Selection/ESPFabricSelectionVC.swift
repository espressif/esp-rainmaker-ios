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
//  ESPFabricSelectionVC.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import UIKit

@available(iOS 16.4, *)
class ESPFabricSelectionVC: UIViewController {
    
    // UI elements
    @IBOutlet weak var topBarTitle: UILabel!
    @IBOutlet weak var addGroupNavBarButton: UIButton!
    @IBOutlet weak var addGroupButton: PrimaryButton!
    @IBOutlet weak var noGroupIcon: UIImageView!
    @IBOutlet weak var noGroupAddedLabel: UILabel!
    @IBOutlet var fabricTableView: UITableView!
    
    var addGroupNavbarButton: UIBarButtonItem?
    static let storyboardId = "ESPFabricSelectionVC"
    var nodeGroups: [NodeGroup]?
    var matterFabrics: [ESPNodeGroup]?
    var groupId: String?
    var onboardingPayload: String? = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBar()
        self.registerCells()
        self.getNodeGroups()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setNavigationTextAttributes(color: .white)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setNavigationTextAttributes(color: .white)
    }
    
    /// Setup navigation bar
    func setupNavigationBar() {
        self.topBarTitle.text = ESPMatterConstants.selectGroupTxt
        self.addGroupButton.setTitle(ESPMatterConstants.addGroupTxt, for: .normal)
        self.addGroupButton.isHidden = true
    }
    
    
    /// Back button pressed
    /// - Parameter sender: button pressed
    @IBAction func backButtonPressed(_ sender: Any) {
        self.goBack()
    }
    
    /// Add group button pressed
    /// - Parameter sender: button pressed
    @IBAction func addGroupButtonPressed(_ sender: Any) {
        self.addGroup()
    }
    
    /// Register cells
    func registerCells() {
        DispatchQueue.main.async {
            self.fabricTableView.isHidden = false
            self.fabricTableView.register(UINib(nibName: ESPFabricCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: ESPFabricCell.reuseIdentifier)
        }
    }
    
    /// Setup UI
    func setupUI() {
        DispatchQueue.main.async {
            if let grps = self.nodeGroups, grps.count > 0 {
                self.setNoGroupsUI(isHidden: true)
                self.fabricTableView.reloadData()
                if let _ = self.groupId {
                    self.goToMatterCommissioning()
                }
            } else {
                self.setNoGroupsUI(isHidden: false)
            }
        }
    }
    
    /// Setup no groups UI
    /// - Parameter isHidden: isHidden
    func setNoGroupsUI(isHidden: Bool) {
        self.addGroupButton.isHidden = isHidden
        self.noGroupIcon.isHidden = isHidden
        self.noGroupAddedLabel.isHidden = isHidden
        self.addGroupNavbarButton?.isHidden = !isHidden
        self.fabricTableView.isHidden = !isHidden
    }
}

//MARK: Matter fabric updation
@available(iOS 16.4, *)
extension ESPFabricSelectionVC {
    
    /// Go to matter commissioning
    func goToMatterCommissioning() {
        let storyBrd = UIStoryboard(name: ESPMatterConstants.matterStoryboardId, bundle: nil)
        let matterCommissioningVC = storyBrd.instantiateViewController(withIdentifier: ESPMatterCommissioningVC.storyboardId) as! ESPMatterCommissioningVC
        matterCommissioningVC.groupId = self.groupId
        matterCommissioningVC.onboardingPayload = self.onboardingPayload
        if let fabrics = self.matterFabrics {
            for fabric in fabrics {
                if let groupId = fabric.groupID, let id = self.groupId, id == groupId {
                    matterCommissioningVC.group = fabric
                    navigationController?.pushViewController(matterCommissioningVC, animated: true)
                    break
                }
            }
        }
    }
    
    /// Create matter fabric
    @objc func addGroup() {
        let alertController = UIAlertController(title: ESPMatterConstants.createGroupTxt, message: "", preferredStyle: .alert)
        alertController.addTextField() { textField in
            textField.placeholder = ESPMatterConstants.enterGroupNameTxt
        }
        alertController.addAction(UIAlertAction(title: ESPMatterConstants.createTxt, style: .default) { action in
            let textFields = alertController.textFields
            if let textFields = textFields, textFields.count > 0 {
                let field = textFields[0]
                if let groupName = field.text, groupName.count > 0 {
                    self.createMatterFabric(groupName: groupName)
                } else {
                    self.addGroup()
                }
            }
        })
        alertController.addAction(UIAlertAction(title: ESPMatterConstants.cancelTxt, style: .cancel) { _ in })
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// Dialog to convert node group to matter fabric
    /// - Parameter groupId: group id
    func updateNodeGroupToMatterFabric(groupId: String) {
        let alertController = UIAlertController(title: ESPMatterConstants.updateGroupTxt, message: ESPMatterConstants.updateNodeGroupMsg, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: ESPMatterConstants.updateTxt, style: .default) { action in
            self.convertGroupToMatterFabric(groupId: groupId)
        })
        alertController.addAction(UIAlertAction(title: ESPMatterConstants.cancelTxt, style: .cancel) { _ in })
        self.present(alertController, animated: true, completion: nil)
    }
}

//MARK: API layer
@available(iOS 16.4, *)
extension ESPFabricSelectionVC {
    /// Convert group to matter fabric
    func convertGroupToMatterFabric(groupId: String) {
        let extendSessionWorker = ESPExtendUserSessionWorker()
        extendSessionWorker.checkUserSession { token, _ in
            if let token = token {
                DispatchQueue.main.async {
                    Utility.showLoader(message: ESPMatterConstants.updatingNodeGroupMsg, view: self.view)
                }
                let url = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion
                let service = ESPConvertGroupToMatterFabricService(presenter: self)
                service.convertNodeGroupToMatterFabric(url: url, groupId: groupId, token: token)
            }
        }
    }
    
    /// Get node groups
    func getNodeGroups() {
        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
        NodeGroupManager.shared.getNodeGroups { nodeGroups, error in
            guard let _ = error else {
                if let nodeGroups = nodeGroups {
                    let service = ESPMatterNodeDetailsService(groups: nodeGroups)
                    service.getNodeDetails {
                        DispatchQueue.main.async {
                            Utility.hideLoader(view: self.view)
                        }
                        self.nodeGroups = nodeGroups
                        self.getMatterFabrics()
                    }
                } else {
                    Utility.hideLoader(view: self.view)
                    self.nodeGroups = nil
                }
                return
            }
            Utility.hideLoader(view: self.view)
        }
    }
    /// Get matter groups
    func getMatterFabrics() {
        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
        let extendSessionWorker = ESPExtendUserSessionWorker()
        extendSessionWorker.checkUserSession { token, _ in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
            }
            if let token = token {
                let url = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion
                let service = ESPGetNodeGroupsService(presenter: self)
                service.getNodeGroupsMatterFabricDetails(url: url, token: token)
                DispatchQueue.main.async {
                    Utility.showLoader(message: ESPMatterConstants.fetchingGroupsDataMsg, view: self.view)
                }
            }
        }
    }
}

//MARK: Received node groups data
@available(iOS 16.4, *)
extension ESPFabricSelectionVC: ESPGetNodeGroupsPresentationLogic {
    
    /// Received node groups data
    /// - Parameters:
    ///   - data: groups data
    ///   - error: error
    func receivedNodeGroupsData(data: ESPNodeGroups?, error: Error?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
        }
        if let data = data, let groups = data.groups, groups.count > 0 {
            ESPMatterFabricDetails.shared.saveGroupsData(groups: data)
            self.matterFabrics?.removeAll()
            self.matterFabrics = data.groups
            DispatchQueue.main.async {
                if let grps = self.nodeGroups, grps.count > 0 {
                    self.setNoGroupsUI(isHidden: true)
                    self.fabricTableView.reloadData()
                    if let _ = self.groupId {
                        self.goToMatterCommissioning()
                    }
                } else {
                    self.setNoGroupsUI(isHidden: false)
                }
            }
        } else {
            DispatchQueue.main.async {
                if let grps = self.nodeGroups, grps.count > 0 {
                    self.setNoGroupsUI(isHidden: true)
                    self.fabricTableView.reloadData()
                } else {
                    self.setNoGroupsUI(isHidden: false)
                }
            }
        }
    }
    
    /// Received node groups details
    /// - Parameters:
    ///   - data: node group details
    ///   - error: error
    func receivedNodeGroupDetailsData(data: ESPNodeGroupDetails?, error: Error?) {}
}

//MARK: Node group converted to matter fabric
@available(iOS 16.4, *)
extension ESPFabricSelectionVC: ESPConvertGroupToMatterFabricPresentationLogic {
    
    /// Node group converted to matter fabric
    /// - Parameters:
    ///   - data: data
    ///   - error: error
    func matterFabricUpdated(data: ESPCreateMatterFabricResponse?, error: Error?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
        }
        guard let _ = error else {
            if let data = data, let grpid = data.groupId {
                self.groupId = grpid
            }
            self.getNodeGroups()
            return
        }
    }
}

//MARK: Matter fabric created
@available(iOS 16.4, *)
extension ESPFabricSelectionVC: ESPCreateMatterFabricPresentationLogic {
    
    /// Matter fabric created
    /// - Parameter groupName: group name
    func createMatterFabric(groupName: String) {
        let createMatterFabricService = ESPCreateMatterFabricService(presenter: self)
        let nodeGroupURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion
        createMatterFabricService.createMatterFabric(url: nodeGroupURL, groupName: groupName, type: ESPMatterConstants.matter, mutuallyExclusive: true, description: ESPMatterConstants.matter, isMatter: true)
    }
    
    /// Matter fabric created
    /// - Parameters:
    ///   - data: data
    ///   - error: error
    func matterFabricCreated(data: ESPCreateMatterFabricResponse?, error: Error?) {
        guard let _ = error else {
            User.shared.updateDeviceList = true
            if let data = data, let grpid = data.groupId {
                self.groupId = grpid
            }
            self.getNodeGroups()
            return
        }
    }
}

@available(iOS 16.4, *)
extension ESPFabricSelectionVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let nodeGroups = self.nodeGroups {
            return nodeGroups.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let nodeGroups = self.nodeGroups, indexPath.row < nodeGroups.count, let cell = tableView.dequeueReusableCell(withIdentifier: ESPFabricCell.reuseIdentifier, for: indexPath) as? ESPFabricCell {
            let nodeGroup = nodeGroups[indexPath.row]
            if let groupName = nodeGroup.group_name {
                cell.deviceName.text = groupName
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let nodeGroups = self.nodeGroups, indexPath.row < nodeGroups.count {
            let nodeGroup = nodeGroups[indexPath.row]
            if let groupId = nodeGroup.group_id {
                self.groupId = groupId
                if let isMatter = nodeGroup.is_matter, isMatter {
                    self.goToMatterCommissioning()
                } else {
                    self.updateNodeGroupToMatterFabric(groupId: groupId)
                }
            }
        }
    }
}
#endif
