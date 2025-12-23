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
//  DeviceTraitListViewController.swift
//  ESPRainMaker
//

import Alamofire
import FlexColorPicker
import MBProgressHUD
import UIKit

class DeviceTraitListViewController: UIViewController {
    
    // Constant keys
    let timeSeriesProperty = "time_series"
    let simpleTimeSeriesProperty = "simple_ts"
    
    var device: Device!
    var pollingTimer: Timer!
    var skipNextAttributeUpdate = false
    
    // NEW: Notification-aware polling system
    private var isNotificationUpdateInProgress = false
    private var pendingPollingUpdate = false
    private var lastNotificationTimestamp: Date = Date.distantPast // Initialize to distant past so polling works immediately
    private let notificationUpdateTimeout: TimeInterval = 3.0 // 2 seconds timeout for notification updates

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var offlineLabel: UILabel!
    @IBOutlet var networkIndicator: UIView!
    @IBOutlet weak var betaLabel: UILabel!
    @IBOutlet weak var betaLabelHeightConstraint: NSLayoutConstraint!
    
    var deviceName: String?
    var group: ESPNodeGroup?
    var node: ESPNodeDetails?
    var allNodes: [ESPNodeDetails]?
    var dataSource: [Param] = []
    var foundCentralParam = false
    var isSwitch: Bool = false
    var bindingEndpointClusterId: [String: UInt]?
    var switchIndex: Int?
    var matterNodeId: String?
    var isInitialLoadingComplete: Bool = false

    /// Thread Border Router service
    let tbrService = ThreadBRUpdateService()
    var channel: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        #if ESPRainMakerMatter
        self.setupBetaView()
        #endif
        tableView.tableFooterView = UIView()
        
        // Register ALL new programmatic cells (no XIB, no runtime class swizzling)
        registerProgrammaticCells()

        titleLabel.text = device?.getDeviceName() ?? "Details"
        tableView.estimatedRowHeight = 70.0
        tableView.rowHeight = UITableView.automaticDimension
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        tableView.contentInset = insets
        
        // Setup pull to refresh
        setupPullToRefresh()

        // Check if device data already exists before showing loader
        if device?.isReachable() ?? false {
            if ESPNetworkMonitor.shared.isConnectedToWifi || ESPNetworkMonitor.shared.isConnectedToNetwork {
                // Check if we already have device parameters
                if let deviceParams = device?.params, !deviceParams.isEmpty {
                    // Data exists - render immediately, no loader needed
                    checkForCentralParam()
                    tableView.reloadData()
                    
                    // Start background refresh for latest data (silent)
                    startBackgroundDataRefresh()
                } else {
                    // No data - show loader and fetch
                    showLoader(message: "Getting info")
                    updateDeviceAttributes()
                }
            }
        } else {
            checkForCentralParam()
        }
        checkOfflineStatus()
    }
    
    func setupCamera() {
        if let node = self.device.node, let channel = node.channelParamValue, let nodeId = node.node_id {
            self.channel = channel
            DispatchQueue.main.async {
                Utility.showLoader(message: "Fetching Assume Role creedentials...", view: self.view)
            }
            ESPAssumeRoleCredentialManager.shared.getAssumeRoleCredentials(nodeId: nodeId) { _, _ in
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                }
            }
        }
    }
    
    /// Setup beta view
    func setupBetaView() {
        if let node = self.device.node, node.isMatter, node.isRainmakerControllerSupported.0 {
            DispatchQueue.main.async {
                self.betaLabel.text = "Beta"
                self.betaLabelHeightConstraint.constant = 16.0
            }
        } else {
            DispatchQueue.main.async {
                self.betaLabel.text = ""
                self.betaLabelHeightConstraint.constant = 0.0
            }
        }
    }
    
    // Method to show central param based on UI type
    private func checkForCentralParam() {
        isInitialLoadingComplete = true
        dataSource.removeAll()
        foundCentralParam = false
        // Check if UI type is of hue circle. Verify if bounds are in valid region.
        for param in device?.params ?? [] {
            if param.uiType == Constants.hueCircle, let bounds = param.bounds, bounds["min"] as? Int ?? 0 == 0, bounds["max"] as? Int ?? 360 == 360 {
                dataSource.insert(param, at: 0)
                foundCentralParam = true
                continue
            }
            dataSource.append(param)
        }
        if !foundCentralParam {
            dataSource = []
            for param in device?.params ?? [] {
                // Check if UI type is of big Switch.
                if param.uiType == Constants.bigSwitch, param.dataType?.lowercased() == "bool" {
                    foundCentralParam = true
                    dataSource.insert(param, at: 0)
                } else {
                    dataSource.append(param)
                }
            }
        }
        if let node = device.node {
            if let service = node.getService(forServiceType: Constants.threadBRService), let params = service.params {
                for param in params {
                    if let type = param.type, [Constants.threadPendingDataset,
                                               Constants.threadActiveDataset].contains(type) {
                        dataSource.append(param)
                    }
                }
            }
            var isFound = false
            if let service = node.getService(forServiceType: MatterControllerConstants.serviceType),
               let params = service.params {
                isFound = true
                let param = Param()
                param.type = ClientOnlyControllerConstants.defaultType
                dataSource.append(param)
                for param in params {
                    if let type = param.type, type == ClientOnlyControllerConstants.paramMatterCtlCmd {
                        dataSource.append(param)
                        break
                    }
                }
            } else if node.isMatterControllerSetupSupported,
                      let service = node.getService(forServiceType: ClientOnlyControllerConstants.setupServiceType),
                      let params = service.params {
                isFound = true
                let param = Param()
                param.type = ClientOnlyControllerConstants.defaultType
                dataSource.append(param)
                for param in params {
                    if let type = param.type, type == ClientOnlyControllerConstants.paramMatterCtlCmd {
                        dataSource.append(param)
                        break
                    }
                }
            }
            if (node.isRmakerControllerSupported || node.isRmControllerSupported), !isFound {
                let param = Param()
                param.type = RainmakerControllerConstants.defaultType
                dataSource.append(param)
            }
            if node.isGroupsServiceSupported && node.isGroupsGroupIdEmpty {
                let param = Param()
                param.type = RainmakerControllerConstants.groupsServiceDefaultType
                dataSource.append(param)
            }
        }
        // Remove hidden UI type parameters from list.
        dataSource = dataSource.filter({ $0.uiType != Constants.hidden })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkNetworkUpdate()
        checkOfflineStatus() // Update connection status when view appears
        tabBarController?.tabBar.isHidden = true
        
        // Start polling only after UI is ready
        // This ensures UI renders first, then polling begins
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startPolling()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paramUpdated), name: Notification.Name(Constants.paramUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkNetworkUpdate), name: Notification.Name(Constants.networkUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkOfflineStatus), name: Notification.Name(Constants.localNetworkUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(localNetworkUpdateReceived), name: Notification.Name(Constants.localNetworkUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadParamTableView), name: Notification.Name(Constants.reloadParamTableView), object: nil)
        self.setupCamera()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.reloadTableView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop polling when view disappears
        if let timer = pollingTimer, timer.isValid {
            timer.invalidate()
            pollingTimer = nil
        }
        NotificationCenter.default.removeObserver(self)
    }

    @objc func localNetworkUpdateReceived() {
    }
    
    @objc func reloadParamTableView() {
        // Mark notification update as in progress
        isNotificationUpdateInProgress = true
        lastNotificationTimestamp = Date()
        
        // Update local device object with latest parameter values from global node list
        // The notification handler has already updated param.value in the global node list
        updateLocalDeviceFromGlobalNodeList()
        
        // CRITICAL: Update connection status when reloadParamTableView is received
        // This handles cases where device goes offline (nodeDisconnected notification)
        // which posts reloadParamTableView but not localNetworkUpdateNotification
        checkOfflineStatus()
        
        // Refresh the dataSource array with updated parameter values
        checkForCentralParam()
        
        // Skip next attribute update to prevent polling timer from overwriting silent notification updates
        skipNextAttributeUpdate = true
        
        // Check if alert view is presented before trying to reload the param values.
        guard self.presentedViewController == nil else { return }
        
        // CRITICAL: Update visible cells directly
        // The notification handler has already updated param.value in the global node list
        // The cell's param property points to the same param object, so param.value is already updated
        // We just need to refresh the UI by calling updateUI() on all visible cells
        var sectionsToReload: IndexSet = []
        
        // Update all visible cells - their param.value is already updated by notification handler
        for (index, param) in dataSource.enumerated() {
            let paramName = param.name ?? ""
            let indexPath = IndexPath(row: 0, section: index)
            
            // Try to update the visible cell directly if it exists
            if let cell = tableView.cellForRow(at: indexPath) {
                // Update the cell - param.value is already updated, just refresh UI
                if let sliderCell = cell as? ParamSliderCell {
                    // Set param to trigger didSet, then updateUI to ensure UI reflects current param.value
                    sliderCell.param = param
                    sliderCell.updateUI()
                } else if let hueSliderCell = cell as? ParamHueSliderCell {
                    hueSliderCell.param = param
                    hueSliderCell.updateUI()
                } else if let switchCell = cell as? ParamSwitchCell {
                    switchCell.param = param
                    switchCell.updateUI()
                } else if let genericCell = cell as? ParamGenericCell {
                    genericCell.param = param
                    genericCell.updateUI()
                } else if let staticCell = cell as? ParamStaticCell {
                    staticCell.attribute = device?.attributes?.first(where: { $0.name == paramName })
                    staticCell.updateUI()
                } else if let dropdownCell = cell as? ParamDropDownCell {
                    dropdownCell.param = param
                    dropdownCell.updateUI()
                } else if let triggerCell = cell as? ParamTriggerCell {
                    triggerCell.param = param
                    triggerCell.updateUI()
                } else if let actionCell = cell as? ParamActionCell {
                    actionCell.param = param
                    actionCell.updateUI()
                } else if let customActionCell = cell as? ParamCustomActionCell {
                    customActionCell.param = param
                    customActionCell.device = device
                    // Custom action cell workflow is determined by param.type during configuration, not by param.value
                } else if let roundHueSliderCell = cell as? ParamRoundHueSliderCell {
                    roundHueSliderCell.param = param
                    roundHueSliderCell.updateUI()
                }
            } else {
                // Cell is not visible, mark section for reload when it becomes visible
                sectionsToReload.insert(index)
            }
        }
        
        // Only reload sections for cells that aren't visible (they'll be updated when scrolled into view)
        // This prevents flickering from unnecessary reloads
        if !sectionsToReload.isEmpty {
            self.tableView.reloadSections(sectionsToReload, with: .none)
        }
        
        // Mark notification update as complete
        isNotificationUpdateInProgress = false
        
        // Resume polling if there was a pending update
        if pendingPollingUpdate {
            pendingPollingUpdate = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.fetchNodeInfo()
            }
        }
    }
    
    /// Helper to compare param values of different types
    private func areValuesEqual(_ value1: Any?, _ value2: Any?) -> Bool {
        // Both nil
        if value1 == nil && value2 == nil {
            return true
        }
        
        // One is nil, other isn't
        guard let val1 = value1, let val2 = value2 else {
            return false
        }
        
        // Same type comparison
        if let int1 = val1 as? Int, let int2 = val2 as? Int {
            return int1 == int2
        }
        if let float1 = val1 as? Float, let float2 = val2 as? Float {
            return abs(float1 - float2) < 0.001 // Small epsilon for float comparison
        }
        if let double1 = val1 as? Double, let double2 = val2 as? Double {
            return abs(double1 - double2) < 0.001
        }
        if let bool1 = val1 as? Bool, let bool2 = val2 as? Bool {
            return bool1 == bool2
        }
        if let str1 = val1 as? String, let str2 = val2 as? String {
            return str1 == str2
        }
        
        // Fallback: convert to string and compare
        return "\(val1)" == "\(val2)"
    }

    /// Update local device object with latest parameter values from global node list
    private func updateLocalDeviceFromGlobalNodeList() {
        updateDeviceNodeFromGlobalList()
    }

    @objc func appEnterForeground() {
        isInitialLoadingComplete = true
        // Restart polling when app comes to foreground
        startPolling()
        self.setupCamera()
    }

    @objc func appEnterBackground() {
        if let timer = pollingTimer, timer.isValid {
            timer.invalidate()
            pollingTimer = nil
        }
    }

    @objc func fetchNodeInfo() {
        // Smart polling that respects notification updates
        if isNotificationUpdateInProgress {
            pendingPollingUpdate = true
            return
        }
        
        if shouldSkipUpdate() {
            return
        }
        
        if device?.isReachable() ?? false {
            updateDeviceAttributesSilently()
        }
    }

    @objc func paramUpdated() {
        skipNextAttributeUpdate = true
    }

    @objc func checkNetworkUpdate() {
        DispatchQueue.main.async {
            if ESPNetworkMonitor.shared.isConnectedToNetwork {
                self.networkIndicator.isHidden = true
            } else {
                self.networkIndicator.isHidden = false
            }
            User.shared.startServiceDiscovery()
        }
    }

    func refreshDeviceAttributes() {
        guard device?.isReachable() ?? false, !shouldSkipUpdate() else { return }
        
        NetworkManager.shared.getDeviceParam(device: device) { [weak self] error in
            guard let self = self, error == nil else { return }
            DispatchQueue.main.async {
                guard !self.shouldSkipUpdate() else { return }
                self.checkForCentralParam()
                self.tableView.reloadData()
            }
        }
    }
    
    func reloadTableView() {
        // Reload view if last param update was more than 5 seconds ago.
        if Date().seconds(from: DeviceControlHelper.shared.latestRequestTimestamp) > 5 {
            // Check if alert view is presented before trying to reload the param values.
            if self.presentedViewController == nil {
                self.tableView.reloadData()
            }
        }
    }

    func updateDeviceAttributes() {
        updateDeviceAttributes(completion: nil)
    }
    
    func updateDeviceAttributes(completion: (() -> Void)?) {
        guard let nodeId = device?.node?.node_id else {
            completion?()
            return
        }
        
        NetworkManager.shared.getNodeInfo(nodeId: nodeId) { node, error in
            if let error = error {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error!!",
                                                            message: error.description,
                                                            preferredStyle: .alert)
                    let retryAction = UIAlertAction(title: "Ok", style: .default) { _ in
                        Utility.hideLoader(view: self.view)
                        completion?()
                    }
                    alertController.addAction(retryAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            } else if let node = node, let nodeList = User.shared.associatedNodeList,
                      let index = nodeList.firstIndex(where: { $0.node_id == nodeId }) {
                let oldNode = nodeList[index]
                node.localNetwork = oldNode.localNetwork
                User.shared.associatedNodeList?[index] = node
                if let currentDevice = node.devices?.first(where: { $0.name == self.device?.name }) {
                    self.device = currentDevice
                }
            }
            self.checkForCentralParam()
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.tableView.reloadData()
                completion?()
            }
        }
    }
    
    /// Setup pull to refresh control
    private func setupPullToRefresh() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
        updateRefreshControlState()
    }
    
    /// Update refresh control enabled state based on device connectivity
    private func updateRefreshControlState() {
        let isOnline = isDeviceAccessible()
        tableView.refreshControl?.isEnabled = isOnline
    }
    
    /// Check if device is accessible (remotely or locally)
    private func isDeviceAccessible() -> Bool {
        guard let device = device else { return false }
        
        // Check if device is reachable
        if device.isReachable() {
            return true
        }
        
        // Check if device is connected remotely or on local network
        if let node = device.node {
            return node.isConnected || node.localNetwork
        }
        
        return false
    }
    
    /// Handle pull to refresh action
    @objc private func handlePullToRefresh(_ refreshControl: UIRefreshControl) {
        // Double-check device is accessible before refreshing
        guard isDeviceAccessible() else {
            refreshControl.endRefreshing()
            return
        }
        
        updateDeviceAttributes {
            DispatchQueue.main.async {
                refreshControl.endRefreshing()
            }
        }
    }

    @objc func checkOfflineStatus() {
        updateNwChangeDeviceNode()
        DispatchQueue.main.async {
            let nodeId = self.device?.node?.node_id ?? "unknown"
            let localNetwork = self.device?.node?.localNetwork ?? false
            let isConnected = self.device?.node?.isConnected ?? false
            let isMatter = (self.device?.node as? Node)?.isMatter ?? false
            
            // Check if this is a Matter device and use Node.connectionStatus
            if let node = self.device?.node as? Node, node.isMatter {
                // Use Node.connectionStatus for Matter devices
                let connectionStatus = node.connectionStatus
                switch connectionStatus {
                case .local:
                    if node.supportsEncryption {
                        self.offlineLabel.text = "🔒 Reachable on WLAN"
                    } else {
                        self.offlineLabel.text = "Reachable on WLAN"
                    }
                    self.offlineLabel.isHidden = false
                case .remote:
                    self.offlineLabel.text = "Remote"
                    self.offlineLabel.isHidden = false
                case .controller:
                    self.offlineLabel.text = "Controller"
                    self.offlineLabel.isHidden = false
                case .offline:
                    let statusText = node.nodeStatus
                    self.offlineLabel.text = statusText.isEmpty ? "Offline" : statusText
                    self.offlineLabel.isHidden = false
                }
            } else {
                // For non-Matter devices, use existing logic
                if localNetwork {
                    if self.device.node?.supportsEncryption ?? false {
                        self.offlineLabel.text = "🔒 Reachable on WLAN"
                    } else {
                        self.offlineLabel.text = "Reachable on WLAN"
                    }
                    self.offlineLabel.isHidden = false
                } else if isConnected {
                    // Regular Rainmaker device - hide label when connected
                    self.offlineLabel.text = ""
                    self.offlineLabel.isHidden = true
                } else {
                    // Device is offline - always show the label
                    let statusText = self.device?.node?.nodeStatus ?? ""
                    self.offlineLabel.text = statusText.isEmpty ? "Offline" : statusText
                    self.offlineLabel.isHidden = false
                }
            }
            // Update refresh control state when connection status changes
            self.updateRefreshControlState()
        }
    }
    
    /// Update device node on network change
    func updateNwChangeDeviceNode() {
        updateDeviceNodeFromGlobalList()
    }
    
    /// Start background data refresh without showing loader
    private func startBackgroundDataRefresh() {
        // Refresh device attributes in background to get latest data
        // This ensures UI is responsive while keeping data fresh
        DispatchQueue.global(qos: .utility).async {
            self.updateDeviceAttributesSilently()
        }
    }
    
    /// Start polling timer for device updates
    private func startPolling() {
        // Start polling timer for regular device updates
        // This ensures UI is rendered before polling begins
        if pollingTimer == nil || !pollingTimer.isValid {
            pollingTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(fetchNodeInfo), userInfo: nil, repeats: true)
            // Test polling immediately to verify it's working
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.fetchNodeInfo()
            }
        }
    }
    
    /// Suspend polling during notification updates
    private func suspendPolling() {
        if let timer = pollingTimer, timer.isValid {
            timer.invalidate()
            pollingTimer = nil
        }
    }
    
    /// Resume polling after notification update completes
    private func resumePolling() {
        // Check if there's a pending polling update
        if pendingPollingUpdate {
            pendingPollingUpdate = false
            
            // Process the pending update immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.fetchNodeInfo()
            }
        }
        
        // Restart the polling timer
        if pollingTimer == nil || !pollingTimer.isValid {
            startPolling()
        }
    }
    
    /// Update device attributes silently (no loader, no UI blocking)
    private func updateDeviceAttributesSilently() {
        guard !shouldSkipUpdate(), let nodeId = device?.node?.node_id else { return }
        
        NetworkManager.shared.getNodeInfo(nodeId: nodeId) { [weak self] node, error in
            guard let self = self, error == nil, let node = node else { return }
            DispatchQueue.main.async {
                guard !self.shouldSkipUpdate(),
                      let nodeList = User.shared.associatedNodeList,
                      let index = nodeList.firstIndex(where: { $0.node_id == nodeId }) else { return }
                let oldNode = nodeList[index]
                node.localNetwork = oldNode.localNetwork
                User.shared.associatedNodeList?[index] = node
                
                if let currentDevice = node.devices?.first(where: { $0.name == self.device?.name }) {
                    // Store old dataSource to detect structural changes (params added/removed)
                    let oldDataSource = self.dataSource.map { ($0.name ?? "", $0.value) }
                    let oldParamNames = Set(self.dataSource.compactMap { $0.name })
                    
                    // Update device
                    self.device = currentDevice
                    
                    // Rebuild dataSource
                    self.checkForCentralParam()
                    
                    // Check for structural changes (params added/removed)
                    let newParamNames = Set(self.dataSource.compactMap { $0.name })
                    let hasStructuralChanges = oldParamNames != newParamNames
                    
                    // Check if alert view is presented before trying to reload the param values.
                    guard self.presentedViewController == nil else { return }
                    
                    if hasStructuralChanges {
                        // Structural change detected - need full reload
                        // This handles cases where params are added/removed from device config
                        self.tableView.reloadData()
                    } else {
                        // No structural changes - use smart update logic (same as notifications)
                        // This prevents flickering and preserves dragEndTimestamp
                        var sectionsToReload: IndexSet = []
                        
                        // First, try to update visible cells directly
                        for (index, param) in self.dataSource.enumerated() {
                            let paramName = param.name ?? ""
                            let indexPath = IndexPath(row: 0, section: index)
                            
                            // Check if this param's value changed
                            var valueChanged = false
                            if let oldParam = oldDataSource.first(where: { $0.0 == paramName }) {
                                let oldValue = oldParam.1
                                let newValue = param.value
                                valueChanged = !self.areValuesEqual(oldValue, newValue)
                            } else {
                                // New param (shouldn't happen if no structural changes, but handle it)
                                valueChanged = true
                            }
                            
                            if valueChanged {
                                // Try to update the visible cell directly if it exists
                                if let cell = self.tableView.cellForRow(at: indexPath) {
                                    // Update the cell directly without reloading
                                    if let sliderCell = cell as? ParamSliderCell {
                                        sliderCell.param = param
                                    } else if let hueSliderCell = cell as? ParamHueSliderCell {
                                        hueSliderCell.param = param
                                    } else if let switchCell = cell as? ParamSwitchCell {
                                        switchCell.param = param
                                    } else if let genericCell = cell as? ParamGenericCell {
                                        genericCell.param = param
                                    } else if let staticCell = cell as? ParamStaticCell {
                                        staticCell.attribute = self.device?.attributes?.first(where: { $0.name == paramName })
                                    } else if let dropdownCell = cell as? ParamDropDownCell {
                                        dropdownCell.param = param
                                    } else if let triggerCell = cell as? ParamTriggerCell {
                                        triggerCell.param = param
                                    } else if let actionCell = cell as? ParamActionCell {
                                        actionCell.param = param
                                    } else if let customActionCell = cell as? ParamCustomActionCell {
                                        customActionCell.param = param
                                    }
                                } else {
                                    // Cell is not visible, mark section for reload when it becomes visible
                                    sectionsToReload.insert(index)
                                }
                            }
                        }
                        
                        // Only reload sections for cells that aren't visible
                        if !sectionsToReload.isEmpty {
                            self.tableView.reloadSections(sectionsToReload, with: .none)
                        }
                    }
                }
            }
        }
    }

    func showLoader(message: String) {
        DispatchQueue.main.async {
            let loader = MBProgressHUD.showAdded(to: self.view, animated: true)
            loader.mode = MBProgressHUDMode.indeterminate
            loader.label.text = message
            loader.backgroundView.blurEffectStyle = .dark
            loader.bezelView.backgroundColor = UIColor.white
        }
    }

    // MARK: - IB Actions

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func infoButtonPressed(_: Any) {
        // Get current node by node ID
        guard let nodeList = User.shared.associatedNodeList,
              let nodeId = device?.node?.node_id,
              let index = nodeList.firstIndex(where: { $0.node_id == nodeId }) else { return }
        let currentNode = nodeList[index]
        goToNodeDetails(node: currentNode)
    }

    func goToNodeDetails(node: Node) {
        let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
        guard let destination = deviceStoryboard.instantiateViewController(withIdentifier: "nodeDetailsVC") as? NodeDetailsViewController else { return }
        destination.currentNode = node
        destination.group = self.group
        destination.allNodes = self.allNodes
        destination.bindingEndpointClusterId = self.bindingEndpointClusterId
        destination.switchIndex = self.switchIndex
        destination.sourceNode = self.node
        navigationController?.pushViewController(destination, animated: true)
    }

    func getTableViewGenericCell(attribute: Param, indexPath: IndexPath) -> UITableViewCell {
        // Use new programmatic ParamGenericCell - no runtime class swizzling
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamGenericCell.reuseIdentifier, for: indexPath) as? ParamGenericCell else {
            return UITableViewCell() // Fallback cell if dequeue fails
        }
        
        // CRITICAL: Set properties DIRECTLY in the same order as old implementation
        // This ensures synchronous property setting, not relying on didSet/updateUI() timing
        
        // 1. Set attributeKey FIRST (critical for cell reuse protection - matches old implementation)
        cell.attributeKey = attribute.name ?? ""
        
        // 2. Set controlName label DIRECTLY (matches old implementation)
        cell.controlNameLabel.text = attribute.name
        
        // 3. Set paramDelegate
        cell.paramDelegate = self
        
        // 4. Set controlValue property DIRECTLY (matches old implementation)
        if let value = attribute.value {
            cell.controlValue = "\(value)"
        }
        
        // 5. Set controlValueLabel DIRECTLY from controlValue (matches old implementation)
        cell.controlValueLabel.text = cell.controlValue
        
        // 6. Set editButton visibility DIRECTLY (matches old implementation)
        // Check both isConnected AND localNetwork (matches old GenericParamTableViewCell logic)
        if let properties = attribute.properties, properties.contains("write"),
           let currentDevice = device,
           let node = currentDevice.node,
           (node.isConnected || node.localNetwork) {
            cell.editButton.isHidden = false
            cell.editButton.setTitleColor(UIColor(hexString: Constants.customColor), for: .normal) // Matches old implementation
        } else {
            cell.editButton.isHidden = true
        }
        
        // 7. Set tapButton visibility DIRECTLY (matches old implementation)
        configureTimeSeriesButton(cell, for: attribute)
        
        // 8. Set dataType DIRECTLY (matches old implementation)
        if let data_type = attribute.dataType {
            cell.dataType = data_type
        }
        
        // 9. Set device
        cell.device = device
        
        // 10. Set param LAST (triggers updateUI() but properties are already set directly above)
        cell.param = attribute
        
        return cell
    }

    func getTableViewCellOfCentralParam(dynamicAttribute: Param, indexPath: IndexPath) -> UITableViewCell {
        if dynamicAttribute.uiType == Constants.hueCircle {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamRoundHueSliderCell.reuseIdentifier, for: indexPath) as? ParamRoundHueSliderCell else {
                return UITableViewCell()
            }
            configureParamUpdateCell(cell, param: dynamicAttribute)
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamCentralSwitchCell.reuseIdentifier, for: indexPath) as? ParamCentralSwitchCell else {
            return UITableViewCell()
        }
        configureParamUpdateCell(cell, param: dynamicAttribute)
        return cell
    }

    func getTableViewCellBasedOn(dynamicAttribute: Param, indexPath: IndexPath) -> UITableViewCell {
        if dynamicAttribute.type == RainmakerControllerConstants.paramBaseURL ||
            dynamicAttribute.type == RainmakerControllerConstants.defaultType {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamCustomActionCell.reuseIdentifier, for: indexPath) as? ParamCustomActionCell else {
                return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
            }
            configureCustomActionCell(cell, workflow: .launchRainmakerController, param: dynamicAttribute)
            return cell
        } else if dynamicAttribute.type == RainmakerControllerConstants.groupsServiceDefaultType {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamCustomActionCell.reuseIdentifier, for: indexPath) as? ParamCustomActionCell else {
                return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
            }
            configureCustomActionCell(cell, workflow: .addToGroup, param: dynamicAttribute)
            return cell
        } else if dynamicAttribute.type == ClientOnlyControllerConstants.paramMatterCtlCmd ||
                    dynamicAttribute.type == ClientOnlyControllerConstants.defaultType {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamCustomActionCell.reuseIdentifier, for: indexPath) as? ParamCustomActionCell else {
                return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
            }
            if dynamicAttribute.type == ClientOnlyControllerConstants.paramMatterCtlCmd {
                configureCustomActionCell(cell, workflow: .updateDeviceList, param: dynamicAttribute)
            } else {
                configureCustomActionCell(cell, workflow: .launchController, param: dynamicAttribute)
            }
            return cell
        } else if dynamicAttribute.type == Constants.threadPendingDataset || dynamicAttribute.type == Constants.threadActiveDataset {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamCustomActionCell.reuseIdentifier, for: indexPath) as? ParamCustomActionCell else {
                return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
            }
            let workflow: CustomAction = dynamicAttribute.type == Constants.threadPendingDataset ? .mergeThreadDataset : .setActiveThreadDataset
            configureCustomActionCell(cell, workflow: workflow, param: dynamicAttribute)
            return cell
        } else if dynamicAttribute.uiType == Constants.scanQRCode {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamActionCell.reuseIdentifier, for: indexPath) as? ParamActionCell else {
                return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
            }
            cell.delegate = self
            cell.device = device
            cell.param = dynamicAttribute
            return cell
        } else if dynamicAttribute.uiType == Constants.slider {
            if let cell = createSliderCell(for: dynamicAttribute, indexPath: indexPath) {
                return cell
            }
        } else if dynamicAttribute.uiType == Constants.toggle || dynamicAttribute.uiType == Constants.bigSwitch, dynamicAttribute.dataType?.lowercased() == "bool" {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamSwitchCell.reuseIdentifier, for: indexPath) as? ParamSwitchCell else {
                return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
            }
            configureParamUpdateCell(cell, param: dynamicAttribute)
            return cell
        } else if dynamicAttribute.uiType == Constants.hue || dynamicAttribute.uiType == Constants.hueCircle {
            if let cell = createHueSliderCell(for: dynamicAttribute, indexPath: indexPath) {
                return cell
            }
        } else if dynamicAttribute.uiType == Constants.dropdown {
            if let cell = createDropDownCell(for: dynamicAttribute, indexPath: indexPath) {
                return cell
            }
        } else if dynamicAttribute.uiType == Constants.trigger, dynamicAttribute.dataType?.lowercased() == "bool" {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamTriggerCell.reuseIdentifier, for: indexPath) as? ParamTriggerCell else {
                return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
            }
            configureParamUpdateCell(cell, param: dynamicAttribute)
            return cell
        } else if dynamicAttribute.type == Constants.channelParamType {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ParamCustomActionCell.reuseIdentifier, for: indexPath) as? ParamCustomActionCell else {
                return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
            }
            cell.channel = dynamicAttribute.value as? String
            configureCustomActionCell(cell, workflow: .launchKinesisVideo, param: dynamicAttribute, isReadOperation: true)
            return cell
        }

        return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
    }

    // Note: setIconsForSliderCell removed - icons are now handled in ParamSliderCell.setIconsForParam()
    
    // MARK: - Helper Methods
    
    /// Register all programmatic cells
    private func registerProgrammaticCells() {
        tableView.register(ParamSliderCell.self, forCellReuseIdentifier: ParamSliderCell.reuseIdentifier)
        tableView.register(ParamHueSliderCell.self, forCellReuseIdentifier: ParamHueSliderCell.reuseIdentifier)
        tableView.register(ParamRoundHueSliderCell.self, forCellReuseIdentifier: ParamRoundHueSliderCell.reuseIdentifier)
        tableView.register(ParamSwitchCell.self, forCellReuseIdentifier: ParamSwitchCell.reuseIdentifier)
        tableView.register(ParamDropDownCell.self, forCellReuseIdentifier: ParamDropDownCell.reuseIdentifier)
        tableView.register(ParamGenericCell.self, forCellReuseIdentifier: ParamGenericCell.reuseIdentifier)
        tableView.register(ParamCentralSwitchCell.self, forCellReuseIdentifier: ParamCentralSwitchCell.reuseIdentifier)
        tableView.register(ParamStaticCell.self, forCellReuseIdentifier: ParamStaticCell.reuseIdentifier)
        tableView.register(ParamTriggerCell.self, forCellReuseIdentifier: ParamTriggerCell.reuseIdentifier)
        tableView.register(ParamActionCell.self, forCellReuseIdentifier: ParamActionCell.reuseIdentifier)
        tableView.register(ParamCustomActionCell.self, forCellReuseIdentifier: ParamCustomActionCell.reuseIdentifier)
    }
    
    /// Check if device is online (connected or on local network)
    private func isDeviceOnline(for param: Param) -> Bool {
        if (param.type == ClientOnlyControllerConstants.defaultType
            || param.type == RainmakerControllerConstants.defaultType
            || param.type == RainmakerControllerConstants.groupsServiceDefaultType),
           let node = device.node {
            return node.isConnected || node.localNetwork
        }
        guard let properties = param.properties, properties.contains("write"),
              let node = device.node else { return false }
        return node.isConnected || node.localNetwork
    }
    
    /// Check if device is online for read operations
    private func isDeviceOnlineForRead(for param: Param) -> Bool {
        guard let properties = param.properties, properties.contains("read"),
              let node = device.node else { return false }
        return node.isConnected || node.localNetwork
    }
    
    /// Configure common cell properties (device, param, paramDelegate) - overloaded for each cell type
    private func configureParamUpdateCell(_ cell: ParamSliderCell, param: Param) {
        cell.device = device
        cell.param = param
        cell.paramDelegate = self
    }
    private func configureParamUpdateCell(_ cell: ParamSwitchCell, param: Param) {
        cell.device = device
        cell.param = param
        cell.paramDelegate = self
    }
    private func configureParamUpdateCell(_ cell: ParamDropDownCell, param: Param) {
        cell.device = device
        cell.param = param
        cell.paramDelegate = self
    }
    private func configureParamUpdateCell(_ cell: ParamTriggerCell, param: Param) {
        cell.device = device
        cell.param = param
        cell.paramDelegate = self
    }
    private func configureParamUpdateCell(_ cell: ParamRoundHueSliderCell, param: Param) {
        cell.device = device
        cell.param = param
        cell.paramDelegate = self
    }
    private func configureParamUpdateCell(_ cell: ParamCentralSwitchCell, param: Param) {
        cell.device = device
        cell.param = param
        cell.paramDelegate = self
    }
    private func configureParamUpdateCell(_ cell: ParamHueSliderCell, param: Param) {
        cell.device = device
        cell.param = param
        cell.paramDelegate = self
    }
    
    /// Configure ParamCustomActionCell with workflow and offline status
    private func configureCustomActionCell(_ cell: ParamCustomActionCell, workflow: CustomAction, param: Param, isReadOperation: Bool = false) {
        cell.delegate = self
        cell.topSpaceConstraint.constant = 0
        cell.bottomSpaceConstraint.constant = 0
        cell.setupWorkflow(workflow: workflow)
        let isOffline = isReadOperation ? !isDeviceOnlineForRead(for: param) : !isDeviceOnline(for: param)
        cell.setLaunchButtonConnectedStatus(isDeviceOffline: isOffline)
    }
    
    /// Create and configure slider cell
    private func createSliderCell(for param: Param, indexPath: IndexPath) -> ParamSliderCell? {
        guard let dataType = param.dataType?.lowercased(), (dataType == "int" || dataType == "float"),
              let bounds = param.bounds,
              let cell = tableView.dequeueReusableCell(withIdentifier: ParamSliderCell.reuseIdentifier, for: indexPath) as? ParamSliderCell else { return nil }
        
        let maxValue = bounds["max"] as? Float ?? 100
        let minValue = bounds["min"] as? Float ?? 0
        guard minValue < maxValue else { return nil }
        
        configureParamUpdateCell(cell, param: param)
        cell.isRainmaker = true
        cell.configuration = .standard(min: minValue, max: maxValue, step: bounds["step"] as? Float)
        return cell
    }
    
    /// Create and configure hue slider cell
    private func createHueSliderCell(for param: Param, indexPath: IndexPath) -> ParamHueSliderCell? {
        var minValue = 0
        var maxValue = 360
        if let bounds = param.bounds {
            minValue = bounds["min"] as? Int ?? 0
            maxValue = bounds["max"] as? Int ?? 360
        }
        guard minValue < maxValue,
              let cell = tableView.dequeueReusableCell(withIdentifier: ParamHueSliderCell.reuseIdentifier, for: indexPath) as? ParamHueSliderCell else { return nil }
        
        configureParamUpdateCell(cell, param: param)
        cell.isRainmaker = true
        return cell
    }
    
    /// Create and configure dropdown cell
    private func createDropDownCell(for param: Param, indexPath: IndexPath) -> ParamDropDownCell? {
        guard let dataType = param.dataType?.lowercased(), dataType == "int" || dataType == "string",
              let cell = tableView.dequeueReusableCell(withIdentifier: ParamDropDownCell.reuseIdentifier, for: indexPath) as? ParamDropDownCell else { return nil }
        
        configureParamUpdateCell(cell, param: param)
        cell.isRainmaker = true
        cell.type = .rainmaker
        
        var datasource: [String] = []
        if dataType == "int" {
            guard let bounds = param.bounds, let max = bounds["max"] as? Int, let min = bounds["min"] as? Int,
                  let step = bounds["step"] as? Int, max > min else {
                return nil
            }
            datasource = stride(from: min, to: max + 1, by: step).map { String($0) }
        } else {
            datasource = param.valid_strs ?? []
        }
        cell.datasource = datasource
        return cell
    }
    
    /// Configure time series button visibility and type
    private func configureTimeSeriesButton(_ cell: ParamGenericCell, for attribute: Param) {
        guard let properties = attribute.properties else {
            cell.tapButton.isHidden = true
            return
        }
        
        let hasTimeSeries = properties.contains(timeSeriesProperty)
        let hasSimpleTimeSeries = properties.contains(simpleTimeSeriesProperty)
        
        if hasTimeSeries || hasSimpleTimeSeries {
            cell.tapButton.isHidden = false
            cell.isSimpleTimeSeries = hasSimpleTimeSeries && !hasTimeSeries
        } else {
            cell.tapButton.isHidden = true
        }
    }
    
    /// Check if notification update is in progress or was recent
    private func shouldSkipUpdate() -> Bool {
        if isNotificationUpdateInProgress {
            return true
        }
        let timeSinceLastNotification = Date().timeIntervalSince(lastNotificationTimestamp)
        return timeSinceLastNotification < notificationUpdateTimeout
    }
    
    /// Update device node from global node list (consolidates duplicate logic)
    private func updateDeviceNodeFromGlobalList() {
        guard let nodes = User.shared.associatedNodeList,
              let nodeId = device.node?.node_id else { return }
        
        if let node = nodes.first(where: { $0.node_id == nodeId }) {
            device.node = node
            if let updatedDevice = node.devices?.first(where: { $0.name == device.name }) {
                self.device = updatedDevice
            }
        }
    }
}

extension DeviceTraitListViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0.0
        }
        return 5.0
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Use a plain transparent view so the 10pt header height acts purely as vertical spacing
        // between the visible card areas of cells. All per-cell top/bottom padding is 0, so
        // this makes the gap between every pair of cards identical.
        let spacer = UIView()
        spacer.backgroundColor = .clear
        return spacer
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if foundCentralParam {
            if indexPath.section == 0 {
                return 300.0
            }
        }
        return UITableView.automaticDimension
    }
}

extension DeviceTraitListViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func numberOfSections(in _: UITableView) -> Int {
        return (dataSource.count) + (device?.attributes?.count ?? 0)
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0, foundCentralParam {
            return getTableViewCellOfCentralParam(dynamicAttribute: dataSource[indexPath.section], indexPath: indexPath)
        }
        
        if indexPath.section >= dataSource.count {
            // Use new programmatic ParamStaticCell - no runtime class swizzling
            let index = indexPath.section - dataSource.count
            guard let attributes = device?.attributes, index < attributes.count,
                  let cell = tableView.dequeueReusableCell(withIdentifier: ParamStaticCell.reuseIdentifier, for: indexPath) as? ParamStaticCell else {
                return UITableViewCell()
            }
            cell.attribute = attributes[index]
            cell.isUserInteractionEnabled = true
            return cell
        } else {
            let control = dataSource[indexPath.section]
            let paramCell = getTableViewCellBasedOn(dynamicAttribute: control, indexPath: indexPath)
            paramCell.isUserInteractionEnabled = true
            return paramCell
        }
    }
}

extension DeviceTraitListViewController: ParamUpdateProtocol {
    func failureInUpdatingParam() {
        DispatchQueue.main.async {
            Utility.showToastMessage(view: self.view, message: "Fail to update parameter. Please check you network connection!!")
        }
    }
}

class SectionHeaderView: UIView {
    @IBOutlet var sectionTitle: UILabel!

    class func instanceFromNib() -> SectionHeaderView {
        guard let view = UINib(nibName: "ControlSectionHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil).first as? SectionHeaderView else {
            return SectionHeaderView() // Return empty view if instantiation fails
        }
        return view
    }
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count + 1))
    }
}

extension DeviceTraitListViewController: ParamActionCellDelegate {
    func actionInvoked(device: Device?, param: Param?, paramName: String) {
        let storyboard = UIStoryboard(name: "Scanner", bundle: nil)
        if let svc = storyboard.instantiateViewController(withIdentifier: String(describing: ESPScannerViewController.self)) as? ESPScannerViewController {
            svc.device = device
            svc.param = param
            svc.paramName = paramName
            self.navigationController?.pushViewController(svc, animated: true)
        }
    }
}

extension DeviceTraitListViewController: ESPAddNodeToMatterFabricPresentationLogic {
    
    /// Node NOC received callback
    /// - Parameters:
    ///   - groupId: group id
    ///   - response: response
    ///   - error: error
    func nodeNOCReceived(groupId: String, response: ESPAddNodeToFabricResponse?, error: Error?) {}
    
    /// Node removed callback
    /// - Parameters:
    ///   - status: status
    ///   - error: error
    func nodeRemoved(status: Bool, error: Error?) {
        User.shared.updateDeviceList = true
        Utility.hideLoader(view: self.view)
        self.navigationController?.popViewController(animated: true)
    }
}
