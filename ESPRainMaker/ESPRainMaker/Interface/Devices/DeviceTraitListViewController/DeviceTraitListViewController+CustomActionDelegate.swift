// Copyright 2024 Espressif Systems
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
//  DeviceTraitListViewController+CustomActionDelegate.swift
//  ESPRainMaker
//

extension DeviceTraitListViewController: ParamCustomActionDelegate {
    
    /// Launch Rainmaker controller flow for the device
    func launchRainmakerController() {
        if let device = self.device, let node = device.node {
            self.enterRmakerControllerFlow(node: node)
        }
    }
    
    /// Launch appropriate controller based on device capabilities
    /// Checks if device supports client-only controller or Rainmaker controller flow
    func launchController() {
        if let device = self.device, let node = device.node {
            if node.rmakerControllerGroupParam != nil || node.clientOnlyControllerRmakerGroupParam != nil {
                DispatchQueue.main.async {
                    self.showGroupSelectionScreen()
                }
            } else {
                DispatchQueue.main.async {
                    self.showRainmakerLoginScreen()
                }
            }
        }
    }
    
    func updateDeviceList() {
        if let node = self.device.node {
            DispatchQueue.main.async {
                Utility.showLoader(message: "Updating device list...", view: self.view)
            }
            self.updateDeviceList(node: node) { status in
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                }
            }
        }
    }
    
    /// If base URL and user token are set then call the update device list API
    /// This is for rmaker controller devices
    /// - Parameter node: node
    private func enterRmakerControllerFlow(node: Node) {
        self.showRainmakerLoginScreen()
    }

    /// Update thread dataset - currently empty implementation
    func updateThreadDataset() {}
    
    /// Set active thread dataset
    /// Fetch thread operational dataset from iOS if present.
    /// Else create a new thread dataset
    func setActiveThreadDataset() {
        if #available(iOS 15.0, *) {
            if let node = self.device.node, let nodeId = node.node_id {
                
                if !self.isTBRActiveDatasetSet(forNode: node) {
                    
                    /// We first check if the ESP thread BR has an active dataset or not
                    /// If it does not, then we try to set homepod active dataset to it if available
                    /// We set the homepod data using the following command: ["ActiveDataset": {Homepod Data}]
                    /// If the homepod active dataset is not available we create a new dataset for the device.
                    self.setHomepodThreadDataset(node: node,
                                                 nodeId: nodeId,
                                                 withDataNotSetCallback: {
                        
                        /// Create a new thread dataset using [ThreadCmd: 1] command
                        self.createNewThreadDataset(node: node, nodeId: nodeId)
                    })
                } else {
                    
                    /// ESP thread BR already configured
                    self.espThreadAlreadyConfigured()
                }
            }
        } else {
            
            /// iOS needs upgrade
            self.upgradeiOSVersionForThread()
        }
    }
    
    /// Merge the homepod active dataset with
    func mergeThreadDataset() {
        if #available(iOS 15.0, *) {
            if let node = self.device.node, let nodeId = node.node_id {
                
                if self.isTBRActiveDatasetSet(forNode: node) {
                    
                    if let espActiveDataset = self.getESPThreadConfig() {
                        
                        /// Fetch thread operational dataset
                        ThreadCredentialsManager.shared.fetchThreadOperationalDataset { activeOperationalDataSet in
                            
                            if var homepodActiveDataset = activeOperationalDataSet {
                                
                                /// Check if homepod dataset can be merged with ESP thread BR dataset
                                /// If possible we use write the homepod dataset to the thread BR service
                                /// using the ["PendingDataset": {homepod dataset}] command
                                let updateHomepodParams = ThreadBRDatasetWorker.shared.shouldUpdateHomepodDataset(homepodDataset: homepodActiveDataset, espDataset: espActiveDataset)
                                if updateHomepodParams.shouldUpdate {
                                    
                                    let delayTimer: UInt32 = 60000
                                    ThreadBRDatasetWorker.shared.addDelayTimer(to: &homepodActiveDataset, delay: delayTimer)
                                    /// If homepod active timestamp is greater than esp active timestamp
                                    /// write the homepod data to esp thread dataset
                                    self.updateESPThreadBRData(nodeId: nodeId, homepodActiveDataset: homepodActiveDataset)
                                } else {
                                    
                                    /// Should increase homepod dataset
                                    if updateHomepodParams.timestampDifference > 0 {
                                        ThreadBRDatasetWorker.shared.increaseHomepodActiveTimestamp(in: &homepodActiveDataset, byValue: updateHomepodParams.timestampDifference)
                                    }
                                    /// If homepod active timestamp is lower than esp active timestamp
                                    /// increase the homepod active dataset
                                    /// write the homepod data to esp thread dataset
                
                                    let delayTimer: UInt32 = 60000
                                    ThreadBRDatasetWorker.shared.addDelayTimer(to: &homepodActiveDataset, delay: delayTimer)
                                    self.updateESPThreadBRData(nodeId: nodeId, homepodActiveDataset: homepodActiveDataset)
                                }
                            } else {
                                
                                /// Homepod dataset is not available to the user
                                self.homepodDatasetNotAvailable()
                            }
                        }
                    }
                } else {
                    self.espTBRNotConfigured()
                }
            }
        }  else {
            self.upgradeiOSVersionForThread()
        }
    }
    
    /// Check if Thread Border Router active dataset is already set for the given node
    /// - Parameter node: The node to check
    /// - Returns: True if active dataset is set, false otherwise
    private func isTBRActiveDatasetSet(forNode node: Node) -> Bool {
        if let tAD = node.getServiceParam(forServiceType: Constants.threadBRService, andParamType: Constants.threadActiveDataset)?.value as? String, tAD.count > 0 {
            return true
        }
        return false
    }
    
    /// Update ESP thread border router data
    /// - Parameters:
    ///   - nodeId: node id
    ///   - homepodActiveDataset: homepod active dataset
    private func updateESPThreadBRData(nodeId: String, homepodActiveDataset: Data) {
        
        /// Write the homepod dataset  to Thread BR activedataset param
        /// using the ["PendingDataset": {homepod active dataset}] command
        self.updateHomepodDataToEspBR(homepodActiveDataset: homepodActiveDataset) { result in
            if let result = result {
                if result {
                    self.newThreadDatasetCreated(nodeId: nodeId)
                } else {
                    
                    /// Thread dataset update failed
                    self.cannotUpdateHomepodDataset()
                }
            } else {
                
                /// Thread dataset creation failed
                self.serviceNotSupported()
            }
        }
    }
    
    /// Get ESP Thread BR Configuration
    /// - Returns: (ESP Thread BR Dataset)
    private func getESPThreadConfig() -> Data? {
        if let node = self.device.node, let tADParam = node.getServiceParam(forServiceType: Constants.threadBRService, andParamType: Constants.threadActiveDataset), let tAD = tADParam.value as? String, tAD.count > 0, let espActiveDataset = tAD.hexadecimal {
            return espActiveDataset
        }
        return nil
    }
    
    /// Update homepod active dataset
    /// - Parameters:
    ///   - homepodActiveDataset: Homepod active dataset
    ///   - completion: completion
    private func updateHomepodDataToEspBR(homepodActiveDataset: Data, completion: @escaping (Bool?) -> Void) {
        let pendingOperationalDataset = homepodActiveDataset.hexadecimalString
        if let node = self.device.node, let nodeId = node.node_id, let serviceName = node.getServiceName(forServiceType: Constants.threadBRService) {
            self.tbrService.mergeThreadNetwork(node: node, nodeId: nodeId, serviceName: serviceName, pendingDataset: pendingOperationalDataset) { status in
                completion(status)
            }
        } else {
            completion(nil)
        }
    }
    
    /// Create new thread dataset using [ThreadCmd: 1] command
    /// - Parameters:
    ///   - node: thread BR node
    ///   - nodeId: node id
    private func createNewThreadDataset(node: Node, nodeId: String) {
        if let _ = node.getServiceParam(forServiceType: Constants.threadBRService, andParamType: Constants.threadCommand), let tAD = node.getServiceParam(forServiceType: Constants.threadBRService, andParamType: Constants.threadActiveDataset)?.value as? String, tAD.count == 0, let serviceName = node.getServiceName(forServiceType: Constants.threadBRService) {
            
            self.tbrService.createNewThreadNetwork(node: node, nodeId: nodeId, serviceName: serviceName) { result in
                if result {
                    self.newThreadDatasetCreated(nodeId: nodeId)
                } else {
                    self.threadDatasetCreationFailed()
                }
            }
        }
    }
    
    /// Set homepod active dataset to the ESP thread BR
    /// - Parameters:
    ///   - node: thread BR node
    ///   - nodeId: thread BR node id
    ///   - completion: callback invoked if for some reason the homepod data could not be set
    private func setHomepodThreadDataset(node: Node, nodeId: String, withDataNotSetCallback completion: @escaping () -> Void) {
        if #available(iOS 15.0, *) {
            ThreadCredentialsManager.shared.fetchThreadOperationalDataset { data in
                if let data = data {
                    let datasetStr = data.hexadecimalString
                    if let serviceName = node.getServiceName(forServiceType: Constants.threadBRService) {
                        self.tbrService.setActiveDataset(node: node, nodeId: nodeId, serviceName: serviceName, activeDataset: datasetStr) { result in
                            if result {
                                self.newThreadDatasetCreated(nodeId: nodeId)
                            } else {
                                completion()
                            }
                        }
                    }
                } else {
                    completion()
                }
            }
        }
    }
    
    /// Show new thread dataset created alert
    /// - Parameter nodeId: node id
    private func newThreadDatasetCreated(nodeId: String) {
        DispatchQueue.main.async {
            self.alertUser(title: ThreadBRMessages.success.rawValue, message: ThreadBRMessages.newThreadActiveDatasetCreated.rawValue, buttonTitle: ThreadBRMessages.ok.rawValue) {
                self.updateRainmakerNode(nodeId: nodeId)
            }
        }
    }
    
    /// Call update rainmaker node API
    /// - Parameter nodeId: node id
    private func updateRainmakerNode(nodeId: String) {
        User.shared.updateDeviceList = true
        self.updateNodesInfo(nodeId: nodeId) { status, updatedNode in
            if status, let updatedNode = updatedNode {
                self.device.node = updatedNode
            }
        }
    }
    
    /// Update nodes information
    /// - Parameter completion: completion
    private func updateNodesInfo(nodeId: String, completion: @escaping (Bool, Node?) -> Void) {
        NetworkManager.shared.getNodes { nodes, error in
            guard let _ = error else {
                if let nodes = nodes {
                    for n in nodes {
                        if let id = n.node_id, id == nodeId {
                            completion(true, n)
                            break
                        }
                    }
                }
                return
            }
            completion(false, nil)
        }
    }
    
    /// Update local thread data
    /// - Parameter node: thread BR node
    private func updateLocalThreadData(node: Node) {
        if #available(iOS 16.4, *) {
            if let tADParam = node.getServiceParam(forServiceType: Constants.threadBRService, andParamType: Constants.threadActiveDataset), let bIdParam = node.getServiceParam(forServiceType: Constants.threadBRService, andParamType: Constants.threadActiveDataset), let activeDataset = tADParam.value as? String, let bId = bIdParam.value as? String, let aDData = activeDataset.hexadecimal, let bIdData = bId.hexadecimal {
                
                ThreadCredentialsManager.shared.saveThreadOperationalCredentials(activeOpsDataset: aDData, borderAgentId: bIdData) { result in
                    
                    if result {
                        self.addThreadCredsSuccess()
                    } else {
                        self.addThreadCredsFailure()
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            self.upgradeiOSVersionForThread()
        }
    }
    
    /// This is invoked if user tries to configure the dataset on a thread BR but,
    /// the dataset is already configured
    private func espTBRNotConfigured() {
        DispatchQueue.main.async {
            self.alertUser(title: ThreadBRMessages.failure.rawValue,
                           message: ThreadBRMessages.espActiveDatasetNotConfigured.rawValue,
                           buttonTitle: ThreadBRMessages.ok.rawValue) {}
        }
    }
    
    /// This is invoked if user tries to configure the dataset on a thread BR but,
    /// the dataset is already configured
    private func espThreadAlreadyConfigured() {
        DispatchQueue.main.async {
            self.alertUser(title: ThreadBRMessages.failure.rawValue,
                           message: ThreadBRMessages.espActiveDatasetAlreadyConfigured.rawValue,
                           buttonTitle: ThreadBRMessages.ok.rawValue) {}
        }
    }
    
    /// This function is invoked when iOS version does not support thread operations
    private func upgradeiOSVersionForThread() {
        DispatchQueue.main.async {
            self.alertUser(title: Constants.notice,
                           message: AppMessages.upgradeOS15VersionMsg,
                           buttonTitle: ThreadBRMessages.ok.rawValue) {}
        }
    }
    
    /// Failed to create thread dataset
    private func threadDatasetCreationFailed() {
        DispatchQueue.main.async {
            self.alertUser(title: ThreadBRMessages.failure.rawValue,
                           message: ThreadBRMessages.activeDatasetCreationFailed.rawValue,
                           buttonTitle: ThreadBRMessages.ok.rawValue) {}
        }
    }
    
    /// Service not supported
    private func serviceNotSupported() {
        DispatchQueue.main.async {
            self.alertUser(title: ThreadBRMessages.failure.rawValue,
                           message: ThreadBRMessages.serviceNotSupported.rawValue,
                           buttonTitle: ThreadBRMessages.ok.rawValue) {}
        }
    }
    
    /// Operation not supported
    private func operationNotSupported() {
        DispatchQueue.main.async {
            self.alertUser(title: ThreadBRMessages.failure.rawValue,
                           message: ThreadBRMessages.operationNotSupported.rawValue,
                           buttonTitle: ThreadBRMessages.ok.rawValue) {}
        }
    }
    
    /// Homepod active dataset not available
    private func homepodDatasetNotAvailable() {
        DispatchQueue.main.async {
            self.alertUser(title: ThreadBRMessages.failure.rawValue,
                           message: ThreadBRMessages.homepodDatasetNotAvailable.rawValue,
                           buttonTitle: ThreadBRMessages.ok.rawValue) {}
        }
    }
    
    /// Cannot set homepod dataset
    private func cannotUpdateHomepodDataset() {
        DispatchQueue.main.async {
            self.alertUser(title: ThreadBRMessages.failure.rawValue,
                           message: ThreadBRMessages.setPendingDatasetFailed.rawValue,
                           buttonTitle: ThreadBRMessages.ok.rawValue) {}
        }
    }
    
    /// Add thread credentials success
    private func addThreadCredsSuccess() {
        DispatchQueue.main.async {
            self.alertUser(title: ThreadBRMessages.success.rawValue,
                           message: ThreadBRMessages.addthreadCredsSuccess.rawValue,
                           buttonTitle: ThreadBRMessages.ok.rawValue) {}
        }
    }
    
    /// Add thread credentials failure
    private func addThreadCredsFailure() {
        DispatchQueue.main.async {
            self.showErrorAlert(title: ThreadBRMessages.failure.rawValue,
                                message: ThreadBRMessages.addthreadCredsFailure.rawValue,
                                buttonTitle: ThreadBRMessages.ok.rawValue) {}
        }
    }
}

//MARK: Client-Only-Controller
extension DeviceTraitListViewController: ClientOnlyControllerCredentialsDelegate {
    
    /// Show group selection screen for client-only controller flow
    func showGroupSelectionScreen() {
        #if ESPRainMakerMatter
        let storyBrd = UIStoryboard(name: ESPMatterConstants.matterStoryboardId, bundle: nil)
        let fabricSelectionVC = storyBrd.instantiateViewController(withIdentifier: ESPFabricSelectionVC.storyboardId) as! ESPFabricSelectionVC
        fabricSelectionVC.isClientOnlyContoller = true
        fabricSelectionVC.clientOnlyControllerDelegate = self
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.pushViewController(fabricSelectionVC, animated: true)
        #endif
    }
    
    /// Show Rainmaker Login Screen
    func showRainmakerLoginScreen(groupId: String? = nil) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        if let nav = storyboard.instantiateViewController(withIdentifier: "signInController") as? UINavigationController {
            if let signInVC = nav.viewControllers.first as? SignInViewController, let tab = self.tabBarController {
                DispatchQueue.main.async {
                    signInVC.setClientOnlyControllerFlow(isRainmakerControllerFlow: true,
                                                         isClientOnlyControllerFlow: true,
                                                         groupId: groupId)
                    signInVC.clientOnlyControllerDelegate = self
                    self.navigationController?.pushViewController(signInVC, animated: true)
                }
            }
        }
    }
    
    /// Handle completion of login for client-only controller flow
    /// - Parameters:
    ///   - cloudResponse: Response from cloud authentication
    ///   - groupId: Optional group ID for the controller
    func loginCompleted(cloudResponse: ESPSessionResponse, groupId: String?) {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
        let baseURL = Configuration.shared.awsConfiguration.baseURL ?? ""
        let refreshToken = cloudResponse.refreshToken ?? ""
    
        if let node = self.device.node {
            if node.isRmakerControllerSupported {
                NodeControllerParamUpdater.updateRmakerControllerParams(node: node, baseURL: baseURL, refreshToken: refreshToken, groupId: groupId, delegate: self) {}
            }
            if node.isClientOnlyControllerSupported {
                NodeControllerParamUpdater.updateClientOnlyControllerParams(node: node, baseURL: baseURL, refreshToken: refreshToken, groupId: groupId, delegate: self) {}
            }
        }
    }
    
    /// Update device list by triggering the update command on the controller
    /// - Parameters:
    ///   - node: The node to update
    ///   - completion: Completion handler with status
    private func updateDeviceList(node: Node, completion: @escaping (ESPCloudResponseStatus?) -> Void) {
        var clientOnlyServiceName = ""
        var clientOnlyUpdateCommandParam: Param?
        if node.isClientOnlyControllerSupported, let service = node.getServiceName(forServiceType: Constants.matterControllerServiceType) {
            clientOnlyServiceName = service
            clientOnlyUpdateCommandParam = node.clientOnlyControllerUpdateDeviceListCommandParam
        }
        
        var rmakerServiceName = ""
        var rmakerUpdateCommandParam: Param?
        if node.isRmakerControllerSupported, let service = node.getServiceName(forServiceType: RainmakerControllerConstants.rmakerControllerServiceType) {
            rmakerServiceName = service
            rmakerUpdateCommandParam = node.rmakerControllerUpdateDeviceListCommandParam
        }
        
        if clientOnlyServiceName.count > 0, let nodeId = node.node_id, let mtrCtlCmdName = clientOnlyUpdateCommandParam?.name {
            let params: [String: Any] = [clientOnlyServiceName : [mtrCtlCmdName: 2] as Any]
            DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: params, delegate: self) { clientOnlyStatus in
                if rmakerServiceName.count > 0, let nodeId = node.node_id, let mtrCtlCmdName = rmakerUpdateCommandParam?.name {
                    let params: [String: Any] = [rmakerServiceName : [mtrCtlCmdName: 2] as Any]
                    DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: params, delegate: self) { status in
                        completion(status)
                    }
                } else {
                    completion(clientOnlyStatus)
                }
            }
        } else if rmakerServiceName.count > 0, let nodeId = node.node_id, let mtrCtlCmdName = rmakerUpdateCommandParam?.name {
            let params: [String: Any] = [rmakerServiceName : [mtrCtlCmdName: 2] as Any]
            DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: params, delegate: self) { status in
                completion(status)
            }
        } else {
            completion(nil)
        }
    }
}

#if ESPRainMakerMatter
extension DeviceTraitListViewController: ClientOnlyControllerGroupSelectionDelegate {
    /// Handle group selection for client-only controller flow
    /// - Parameter groupId: The selected group ID
    func groupSelected(groupId: String) {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
            if groupId.count > 0 {
                self.showRainmakerLoginScreen(groupId: groupId)
            }
        }
    }
}
#endif
