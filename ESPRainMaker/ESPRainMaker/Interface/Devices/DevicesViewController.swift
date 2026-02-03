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
//  DevicesViewController.swift
//  ESPRainMaker
//

import Alamofire
import Foundation
import JWTDecode
import MBProgressHUD
import UIKit

enum NodeConnectionStatus {
    case local
    case remote
    case offline
    case controller
    
    var description: String {
        switch self {
        case .local:
            return "Local"
        case .remote:
            return "Remote"
        case .controller:
            return "Controller"
        case .offline:
            return "Offline"
        }
    }
}

class DevicesViewController: UIViewController {
    
    // IB outlets
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var addButton: UIButton!
    @IBOutlet var initialView: UIView!
    @IBOutlet var emptyListIcon: UIImageView!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var networkIndicator: UIView!
    @IBOutlet var loadingIndicator: SpinnerView!
    @IBOutlet var segmentControl: UISegmentedControl!
    @IBOutlet var dropDownMenu: UIView!
    @IBOutlet var segmentControlLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var groupMenuButton: UIButton!

    let controlStoryBoard = UIStoryboard(name: "DeviceDetail", bundle: nil)
    let localStorageHandler = ESPLocalStorageHandler()
    var checkDeviceAssociation = false
    private var currentPage = 0
    private var absoluteSegmentPosition: [CGFloat] = []
    var groups: [ESPNodeGroup]?
    var nodeGroups: [NodeGroup]?
    let fabricDetails = ESPMatterFabricDetails.shared
    
    // MARK: - UI Optimization Properties
    ///
    /// COMPREHENSIVE UI OPTIMIZATION STRATEGY:
    /// 1. Smart API Calls: Only call getNodes when explicitly needed (login, pull-to-refresh, app launch, updateDeviceList=true)
    /// 2. Smart Collection View Reloads: Use targeted cell updates instead of full reloads when possible
    /// 3. Cooldown Periods: Prevent excessive API calls with 30-second cooldown
    /// 4. Change Tracking: Track what data changed to determine appropriate update strategy
    /// 5. Performance Monitoring: Log all optimization decisions for debugging
    ///
    /// Smart refresh management to reduce unnecessary API calls and full reloads
    /// This prevents flickering and improves performance by only reloading what's necessary
    private var lastAPICallTimestamp: TimeInterval = 0
    private var lastFullReloadTimestamp: TimeInterval = 0
    private let apiCallCooldown: TimeInterval = 30.0 // 30 seconds between API calls
    private let fullReloadCooldown: TimeInterval = 5.0 // 5 seconds between full reloads
    
    /// Track what data has changed to determine update strategy
    /// This allows us to reload only specific cells instead of the entire collection view
    private var dataChangeFlags: Set<DataChangeType> = []
    
    /// Enum to track different types of data changes
    /// This helps determine whether we need a full reload or just cell updates
    enum DataChangeType: String, CaseIterable {
        case connectionStatus = "connection_status"
        case deviceParameters = "device_parameters" 
        case nodeList = "node_list"
        case matterController = "matter_controller"
        case localNetwork = "local_network"
    }
    
    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if user session is valid
        let service = ESPExtendSessionService(presenter: self)
        service.validateUserSession()
        
        // Get info of user from user default
        if User.shared.isUserSessionActive {
            collectionView.isUserInteractionEnabled = false
            collectionView.isHidden = false
            // Fetch associated nodes from local storage
            User.shared.associatedNodeList = localStorageHandler.fetchNodeDetails()
            if Configuration.shared.appConfiguration.supportGrouping {
                NodeGroupManager.shared.nodeGroups = localStorageHandler.fetchNodeGroups() ?? []
            }
            User.shared.associatedNodeList = localStorageHandler.fetchNodeDetails()
            // Force API refresh for app launch with authenticated user
            // This ensures we get fresh data on app launch as required
            forceAPIRefresh()
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.configureRemoteNotifications()
        } else {
            refresh()
        }

        dropDownMenu.dropShadow()

        NotificationCenter.default.addObserver(self, selector: #selector(updateUIView), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
        // Register nib
        collectionView.register(UINib(nibName: "DeviceGroupEmptyDeviceCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "deviceGroupEmptyDeviceCVC")

        // Add gesture to hide Group DropDown menu
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideDropDown))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        if !Configuration.shared.appConfiguration.supportGrouping {
            segmentControl.isHidden = true
            groupMenuButton.isHidden = true
        } else {
            configureSegmentControl()
        }
        
        setTabBarControllerViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        checkNetworkUpdate()
        if User.shared.updateUserInfo {
            User.shared.updateUserInfo = false
            updateUserInfo()
        }
        if User.shared.isUserSessionActive {
            if User.shared.updateDeviceList {
                // Force API refresh when updateDeviceList flag is true
                // This ensures we make API call when explicitly requested
                forceAPIRefresh()
            }
        }
        setViewForNoNodes()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addButton?.setImage(UIImage(named: "add_icon"), for: .normal)
        dropDownMenu?.isHidden = true
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkNetworkUpdate), name: Notification.Name(Constants.networkUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(localNetworkUpdate), name: Notification.Name(Constants.localNetworkUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCollectionView), name: Notification.Name(Constants.reloadCollectionView), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDeviceList), name: Notification.Name(Constants.refreshDeviceList), object: nil)
        #if ESPRainMakerMatter
        NotificationCenter.default.addObserver(self, selector: #selector(controllerParamUpdateReceived), name: Notification.Name(Constants.controllerParamUpdate), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(matterDeviceConnectivityUpdate), name: Notification.Name(Constants.matterDeviceConnectivityUpdate), object: nil)
        #endif
        tabBarController?.tabBar.isHidden = false
        
        // Defer initial refresh to avoid conflict with upcoming API refresh after node deletion
        if User.shared.updateDeviceList {
            // Skip immediate refresh when API refresh is pending to prevent flicker
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.forceRefreshVisibleCells()
            }
        } else {
            // Force refresh all visible cells to ensure UI state is synchronized
            forceRefreshVisibleCells()
        }
    }
    
    /// Force refresh all visible cells to ensure UI state is synchronized
    private func forceRefreshVisibleCells() {
        
        // Reload all visible cells to ensure fresh state
        for cell in collectionView.visibleCells {
            #if ESPRainMakerMatter
            if #available(iOS 16.4, *) {
                if let deviceCell = cell as? DeviceCollectionViewCell {
                    // Force cell to update its UI state
                    deviceCell.setNeedsLayout()
                    deviceCell.layoutIfNeeded()
                    
                    // Refresh connection status UI
                    deviceCell.setConnectionStatusUI(status: deviceCell.connectionStatus)
                    
                    // Ensure cell reflects current state from UserDefaults
                    deviceCell.refreshFromCurrentState()
                }
            }
            #endif
        }
        
        // Also reload the entire collection view to ensure all cells are fresh
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }

    // MARK: - Observer functions

    @objc func hideDropDown() {
        dropDownMenu.isHidden = true
    }

    /// Handles collection view reload notifications from push notification updates.
    /// This method ensures that device state changes from push notifications are immediately reflected in the UI.
    /// It refreshes the datasource for all visible cells and forces a full collection view reload.
    @objc func reloadCollectionView() {
        // Refresh datasource for all visible cells to ensure fresh data from push notifications
        refreshVisibleCellDataSources()
        
        // Force full reload for push notifications to ensure UI updates
        // This ensures that all cells get reconfigured with fresh data
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    // MARK: - UI Optimization Methods
    
    /// Refresh datasource for all visible cells to ensure fresh data from push notifications.
    /// This ensures that when push notifications update User.shared.associatedNodeList,
    /// the visible cells get the updated data instead of stale cached data.
    private func refreshVisibleCellDataSources() {
        for cell in collectionView.visibleCells {
            if let deviceGroupCell = cell as? DeviceGroupCollectionViewCell {
                // Refresh the datasource with latest data from User.shared.associatedNodeList
                if let indexPath = collectionView.indexPath(for: cell) {
                    if indexPath.item == 0 {
                        // Single device nodes - use fresh data from User.shared.associatedNodeList
                        deviceGroupCell.datasource = User.shared.associatedNodeList ?? []
                        
                        // Force reload the nested collection view to ensure cells are reconfigured
                        deviceGroupCell.collectionView.reloadData()
                    } else {
                        // Group nodes - refresh with latest data
                        let nodeList = NodeGroupManager.shared.nodeGroups[indexPath.item - 1].nodeList
                        if let nodeList = nodeList, nodeList.count > 0 {
                            var finalNodeLst = nodeList
                            for index in 0..<nodeList.count {
                                let indexNode = nodeList[index]
                                if let indexNodeId = indexNode.node_id, let nodes = User.shared.associatedNodeList {
                                    for node in nodes {
                                        if let nodeId = node.node_id, indexNodeId == nodeId {
                                            finalNodeLst[index] = node
                                            break
                                        }
                                    }
                                }
                            }
                            deviceGroupCell.datasource = finalNodeLst
                            
                            // Force reload the nested collection view to ensure cells are reconfigured
                            deviceGroupCell.collectionView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    /// Check if we can avoid a full collection view reload
    /// This prevents excessive reloads that cause flickering
    private func canAvoidFullReload() -> Bool {
        let timeSinceLastReload = Date().timeIntervalSince1970 - lastFullReloadTimestamp
        
        // Allow full reload if:
        // 1. It's been more than 5 seconds since last reload, OR
        // 2. We have significant data changes that require full reload
        let hasSignificantChanges = dataChangeFlags.contains(.nodeList) ||
                                  dataChangeFlags.contains(.matterController)
        
        return timeSinceLastReload < fullReloadCooldown && !hasSignificantChanges
    }
    
    /// Perform targeted updates to specific cells instead of full reload
    /// This is much more efficient and prevents flickering
    private func performTargetedCellUpdates() {
        
        // Use performBatchUpdates for smooth transitions
        collectionView.performBatchUpdates({
            // Update only visible cells that need updates
            for cell in collectionView.visibleCells {
                updateCellIfNeeded(cell)
            }
        }, completion: { _ in
            // Clear change flags after successful update
            self.dataChangeFlags.removeAll()
        })
    }
    
    /// Smart collection view reload that only reloads what's necessary
    /// This prevents unnecessary full reloads that cause flickering
    func smartReloadCollectionView(for changeType: DataChangeType? = nil) {
        // Track what type of data changed
        if let changeType = changeType {
            dataChangeFlags.insert(changeType)
        }
        
        // Check if we can avoid a full reload
        if canAvoidFullReload() {
            performTargetedCellUpdates()
        } else {
            // Full reload is necessary, but track it
            lastFullReloadTimestamp = Date().timeIntervalSince1970
            collectionView.reloadData()
        }
    }
    
    /// Update a specific cell if it needs updates based on change flags
    /// This prevents unnecessary cell updates that cause flickering
    private func updateCellIfNeeded(_ cell: UICollectionViewCell) {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *) {
            if let deviceCell = cell as? DeviceCollectionViewCell {
                // Only update if connection status changed
                if dataChangeFlags.contains(.connectionStatus) {
                    deviceCell.setConnectionStatusUI(status: deviceCell.connectionStatus)
                }
                
                // Only update if device parameters changed
                if dataChangeFlags.contains(.deviceParameters) {
                    deviceCell.refreshFromCurrentState()
                }
            }
        }
        #endif
        
        // Handle regular device cells
        if let deviceCell = cell as? DevicesCollectionViewCell {
            // Update device cell if needed
            if dataChangeFlags.contains(.deviceParameters) {
                deviceCell.refresh()
            }
        }
    }
    
    // MARK: - Targeted Node Update Methods
    
    /// Update only specific nodes instead of entire collection view
    /// This dramatically improves performance for notification-based updates
    private func updateSpecificNodes(nodeIds: [String], changeType: DataChangeType) {
        
        // Track the specific change type
        dataChangeFlags.insert(changeType)
        
        // Collect cells that need updates
        var cellsToUpdate: [DeviceGroupCollectionViewCell] = []
        for cell in collectionView.visibleCells {
            if let deviceGroupCell = cell as? DeviceGroupCollectionViewCell {
                let containsAffectedNodes = deviceGroupCell.datasource.contains { node in
                    guard let nodeId = node.node_id else { return false }
                    return nodeIds.contains(nodeId)
                }
                if containsAffectedNodes {
                    cellsToUpdate.append(deviceGroupCell)
                }
            }
        }
        
        // Update datasources first (outside batch updates to avoid conflicts)
        for cell in cellsToUpdate {
            if changeType == .connectionStatus || changeType == .localNetwork {
                if let indexPath = collectionView.indexPath(for: cell) {
                    if indexPath.item == 0 {
                        cell.datasource = User.shared.associatedNodeList ?? []
                    } else {
                        if let nodeList = NodeGroupManager.shared.nodeGroups[indexPath.item - 1].nodeList, nodeList.count > 0 {
                            var finalNodeLst = nodeList
                            for index in 0..<nodeList.count {
                                let indexNode = nodeList[index]
                                if let indexNodeId = indexNode.node_id, let nodes = User.shared.associatedNodeList {
                                    for node in nodes {
                                        if let nodeId = node.node_id, indexNodeId == nodeId {
                                            finalNodeLst[index] = node
                                            break
                                        }
                                    }
                                }
                            }
                            cell.datasource = finalNodeLst
                        }
                    }
                }
            }
        }
        
        // CRITICAL: Always use reloadData() for nested collection views when datasource changes
        // This is the safest approach and avoids all batch update conflicts
        // The performance impact is minimal since we're only updating specific cells
        DispatchQueue.main.async {
            for cell in cellsToUpdate {
                // Always reload when datasource is updated to avoid any index mismatches
                cell.collectionView.reloadData()
            }
            // Clear change flags after successful update
            self.dataChangeFlags.removeAll()
        }
    }
    
    /// Update connection status for specific nodes only
    /// This is much more efficient than reloading the entire collection view
    private func updateConnectionStatusForNodes(nodeIds: [String]) {
        
        // Update only the specific nodes that changed connection status
        updateSpecificNodes(nodeIds: nodeIds, changeType: .connectionStatus)
    }
    
    /// Update Matter controller data for specific nodes only
    /// This prevents unnecessary full reloads for controller parameter updates
    private func updateMatterControllerForNodes(nodeIds: [String]) {
        
        // Update only the specific nodes that have controller changes
        updateSpecificNodes(nodeIds: nodeIds, changeType: .matterController)
    }
    
    /// Update device parameters for specific nodes only
    /// This prevents unnecessary full reloads for device state changes
    private func updateDeviceParametersForNodes(nodeIds: [String]) {
        
        // Update only the specific nodes that have parameter changes
        updateSpecificNodes(nodeIds: nodeIds, changeType: .deviceParameters)
    }
    
    /// Handle notification-based updates for specific nodes
    /// This is the main entry point for all notification-based UI updates
    private func handleNotificationUpdate(for nodeIds: [String], changeType: DataChangeType) {
        switch changeType {
        case .connectionStatus:
            updateConnectionStatusForNodes(nodeIds: nodeIds)
        case .deviceParameters:
            updateDeviceParametersForNodes(nodeIds: nodeIds)
        case .matterController:
            updateMatterControllerForNodes(nodeIds: nodeIds)
        case .nodeList:
            // For node list changes, we still need full reload
            smartReloadCollectionView(for: .nodeList)
        case .localNetwork:
            // For local network changes, use connection status update
            updateConnectionStatusForNodes(nodeIds: nodeIds)
        }
    }

    @objc func controllerParamUpdateReceived() {
        if let nodeId = ESPMatterEcosystemInfo.shared.getControllerNotificationNodeId() {
            ESPMatterEcosystemInfo.shared.removeControllerNotificationNodeId()
            NetworkManager.shared.getNodeInfo(nodeId: nodeId) { node, _ in
                if let updatedNode = node {
                    // Update the controller node in associatedNodeList
                    if let index = User.shared.associatedNodeList?.firstIndex(where: { $0.node_id == nodeId }) {
                        User.shared.associatedNodeList![index] = updatedNode
                        
                        DispatchQueue.main.async {
                            // Update only the specific node that received controller updates
                            // This prevents unnecessary full reloads and dramatically improves performance
                            self.updateMatterControllerForNodes(nodeIds: [nodeId])
                            
                            // Save updated node details to local storage
                            ESPLocalStorageHandler().saveNodeDetails(nodes: User.shared.associatedNodeList)
                        }
                    }
                }
            }
        }
    }

    @objc func appEnterForeground() {
        refreshDeviceList()
    }

    @objc func checkNetworkUpdate() {
        DispatchQueue.main.async {
            if ESPNetworkMonitor.shared.isConnectedToNetwork {
                self.networkIndicator.isHidden = true
            } else {
                self.networkIndicator.isHidden = false
            }
        }
    }

    @objc func localNetworkUpdate() {
        // Update only nodes that actually changed connection status
        // This prevents unnecessary full reloads and dramatically improves performance
        let changedNodeIds = getNodesWithChangedConnectionStatus()
        
        if !changedNodeIds.isEmpty {
            updateConnectionStatusForNodes(nodeIds: changedNodeIds)
        }
    }
    
    /// Handle Matter device connectivity updates (mDNS discovery changes)
    /// When WiFi changes, Matter nodes are discovered/removed, so we need to update all Matter nodes
    @objc func matterDeviceConnectivityUpdate() {
        // When Matter discovery changes (WiFi change), include ALL Matter nodes
        // because their connection status (local/offline) may have changed
        guard let nodes = User.shared.associatedNodeList else { return }
        
        var matterNodeIds: [String] = []
        for node in nodes {
            if let nodeId = node.node_id, node.matter_node_id != nil {
                matterNodeIds.append(nodeId)
            }
        }
        
        if !matterNodeIds.isEmpty {
            updateConnectionStatusForNodes(nodeIds: matterNodeIds)
        }
    }
    
    /// Identify which specific nodes changed connection status
    /// This allows us to update only the affected nodes instead of the entire collection view
    private func getNodesWithChangedConnectionStatus() -> [String] {
        var changedNodeIds: [String] = []
        
        guard let nodes = User.shared.associatedNodeList else { return changedNodeIds }
        
        for node in nodes {
            guard let nodeId = node.node_id else { continue }
            
            // Check if this node's connection status has changed
            let currentIsLocal = node.localNetwork
            let currentIsConnected = node.isConnected
            
            // For Matter nodes, also check if they're discovered on local network
            if let matterNodeId = node.matter_node_id {
                let isMatterConnected = User.shared.isMatterNodeConnected(matterNodeId: matterNodeId)
                
                // If Matter connection status changed, include this node
                if isMatterConnected != currentIsLocal {
                    changedNodeIds.append(nodeId)
                }
            } else {
                // For Rainmaker (non-Matter) nodes, the localNetworkUpdateNotification is only sent when status changes
                // Include all Rainmaker nodes to ensure UI reflects current state
                    changedNodeIds.append(nodeId)
            }
        }
        
        return changedNodeIds
    }

    @objc func updateUIView() {
        for subview in view.subviews {
            subview.setNeedsDisplay()
        }
    }
    
    @objc func refreshDeviceList() {
        // Only make getNodes API call when explicitly needed
        // This prevents excessive API calls and improves performance
        let shouldMakeAPICall = shouldRefreshFromAPI()
        
        if shouldMakeAPICall {
            showLoader()
            #if ESPRainMakerMatter
            if #available(iOS 16.4, *) {
                // Shut down all commissioner instances
                let allCommissioners = ESPMTRCommissionerManager.shared.getAllCommissioners()
                for (_, commissioner) in allCommissioners {
                    commissioner.shutDownController()
                }
            }
            #endif
            collectionView.isUserInteractionEnabled = false
            segmentControl.isUserInteractionEnabled = false
            User.shared.updateDeviceList = false
            if Configuration.shared.appConfiguration.supportGrouping {
                self.setupGroupsUI()
            } else {
                self.getNodes {
                    self.searchForDevicesOnWLAN()
                    self.prepareView()
                }
            }
        } else {
            // Use targeted cell updates instead of full refresh
            smartReloadCollectionView(for: .connectionStatus)
        }
    }
    
    /// Determine if we need to make an API call or can use cached data
    /// This reduces unnecessary API calls and improves performance
    private func shouldRefreshFromAPI() -> Bool {
        // Always make API call for these scenarios (as per requirements):
        // 1. Pull-to-refresh (user-initiated)
        // 2. App launch for authenticated user
        // 3. Successful login
        // 4. When updateDeviceList flag is true
        
        if User.shared.updateDeviceList {
            return true // Explicit flag to refresh
        }
        
        // Check if this is a user-initiated refresh (pull-to-refresh or refresh button)
        if let _ = self.presentedViewController {
            return true // Likely user-initiated
        }
        
        // For other cases, check if we have recent data
        let currentTime = Date().timeIntervalSince1970
        let timeSinceLastCall = currentTime - lastAPICallTimestamp
        
        // Make API call if it's been more than 30 seconds
        return timeSinceLastCall > 30.0
    }
    
    /// Set groups UI
    /// Invoked Node groups API
    /// Fetch matter node group details
    /// Fetch User NOCs
    /// Fetch nodes and update UI
    private func setupGroupsUI() {
        //get node groups data
        NodeGroupManager.shared.getNodeGroups { groups, error in
            if let groups = groups {
                self.nodeGroups = groups
                #if ESPRainMakerMatter
                if #available(iOS 16.4, *) {
                    // NON-BLOCKING: Load UI immediately, fetch Matter details in background
                    self.fetchNodesAndUpdateUI(groups: groups, error: error)
                    self.loadMatterDetailsInBackground(groups: groups)
                } else {
                    self.fetchNodesAndUpdateUI(groups: groups, error: error)
                }
                #else
                self.fetchNodesAndUpdateUI(groups: groups, error: error)
                #endif
            } else {
                self.fetchNodesAndUpdateUI(groups: groups, error: error)
            }
        }
    }
    
    private func fetchNodesAndUpdateUI(groups: [NodeGroup]?, error: ESPNetworkError?) {
        self.getNodes {
            DispatchQueue.main.async {
                NodeGroupManager.shared.updateNodeListInNodeGroup(nodeGroup: groups)
                self.discoverDevicesAndFormatUI(error: error)
            }
        }
    }
    
    #if ESPRainMakerMatter
    @available(iOS 16.4, *)
    /// Load Matter details in background without blocking UI
    /// This preserves all app behavior while making the operation non-blocking
    private func loadMatterDetailsInBackground(groups: [NodeGroup]) {
        // Use background queue for Matter operations
        DispatchQueue.global(qos: .userInitiated).async {
            // Step 1: Fetch Matter node group details in background
            self.getMatterNodeGroupDetailsInBackground(groups: groups) {
                // Step 2: Fetch User NOCs in background
                self.fetchUserNOCsInBackground(groups: groups) {
                    // Step 3: Update UI on main thread when complete
                    DispatchQueue.main.async {
                        self.updateUIWithMatterData()
                    }
                }
            }
        }
    }
    
    /// Background version of getMatterNodeGroupDetails
    private func getMatterNodeGroupDetailsInBackground(groups: [NodeGroup], completion: @escaping () -> Void) {
        let service = ESPMatterNodeDetailsService(groups: groups)
        service.getNodeDetails {
            completion()
        }
    }
    
    /// Background version of fetchUserNOCs
    private func fetchUserNOCsInBackground(groups: [NodeGroup], completion: @escaping () -> Void) {
        if #available(iOS 16.4, *) {
            let issueUserNOCService = ESPGetUserNOCService(groups: groups)
            issueUserNOCService.issueUserNOC {
                completion()
            }
        } else {
            completion()
        }
    }
    
    /// Update UI with Matter data when background loading completes
    private func updateUIWithMatterData() {
        // Update collection view to reflect Matter data changes
        self.smartReloadCollectionView(for: .matterController)
        
        // Start Matter device discovery first to identify locally reachable devices
        self.searchForMatterDevicesOnLocalNetwork() {
            // Setup device monitoring AFTER we know which devices are locally reachable
            self.setupMatterDeviceMonitoringAfterDiscovery()
        }
    }
    
    /// Setup Matter device monitoring after device discovery completes
    /// This ensures we only setup monitoring for devices that are actually reachable
    func setupMatterDeviceMonitoringAfterDiscovery() {
        // Only setup monitoring if we have the required data
        guard User.shared.associatedNodeList != nil else {
            return
        }
        
        // Setup device monitoring for all Matter fabrics
        // This is called AFTER device discovery so we know which devices are locally reachable
        if #available(iOS 16.4, *) {
            ESPMTRCommissionerManager.shared.setupDeviceMonitoringForAllFabrics()
        }
    }
    

    
    /// Background version of getNodeGroupMatterFabricDetails - non-blocking
    private func getNodeGroupMatterFabricDetailsInBackground() {
        // Use background queue for Matter fabric details
        DispatchQueue.global(qos: .userInitiated).async {
            let extendSessionWorker = ESPExtendUserSessionWorker()
            extendSessionWorker.checkUserSession { token, _ in
                if let token = token {
                    let url = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion
                    let service = ESPGetNodeGroupsService(presenter: self)
                    service.getNodeGroupsMatterFabricDetails(url: url, token: token)
                }
            }
        }
    }
    #endif
    
    private func getNodes(_ completion: @escaping () -> Void) {
        // Track API call timing to prevent excessive calls
        lastAPICallTimestamp = Date().timeIntervalSince1970
        
        NetworkManager.shared.getNodes { nodes, error in
            DispatchQueue.main.async {
                self.loadingIndicator.isHidden = true
                User.shared.associatedNodeList = nil
                if error != nil {
                    self.searchForDevicesOnWLAN()
                    self.unhideInitialView(error: error)
                    self.collectionView.isUserInteractionEnabled = true
                    completion()
                    return
                }
                User.shared.associatedNodeList = nodes
                // Mark that node list has changed for appropriate UI updates
                self.dataChangeFlags.insert(.nodeList)
                completion()
            }
        }
    }
    
    #if ESPRainMakerMatter
    func searchForMatterDevicesOnLocalNetwork(completion: @escaping () -> Void) {
        if #available(iOS 16.4, *) {
            DispatchQueue.main.async {
                self.stopMatterDiscovery()
                self.searchForMatterDevices { _ in
                    self.collectionView.reloadData()
                    completion()
                }
            }
        }
    }
    
    /// Reset matter controller
    /// - Parameters:
    ///   - matterFabricData: fabric data
    ///   - userNOCDetails: user noc data
    @available(iOS 16.4, *)
    func resetMatterController(matterFabricData: ESPNodeGroup, userNOCDetails: ESPIssueUserNOCResponse) {
        if let groupId = matterFabricData.groupID {
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
            commissioner.group = matterFabricData
            commissioner.initializeMTRControllerWithUserNOC(matterFabricData: matterFabricData, userNOCData: userNOCDetails)
        }
    }
    #endif
    
    private func discoverDevicesAndFormatUI(error: ESPNetworkError?) {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *) {
            if let nodes = User.shared.associatedNodeList, nodes.count > 0 {
                if let data = self.fabricDetails.getGroupsData(), let groups = data.groups, groups.count > 0 {
                    DispatchQueue.main.async {
                        // NON-BLOCKING: Format UI immediately without loader
                        self.formatUI(error: error)
                        // Start Matter fabric details in background
                        self.getNodeGroupMatterFabricDetailsInBackground()
                    }
                } else {
                    DispatchQueue.main.async {
                        // NON-BLOCKING: Format UI immediately without loader
                        self.formatUI(error: error)
                        // Start Matter fabric details in background
                        self.getNodeGroupMatterFabricDetailsInBackground()
                    }
                }
            } else {
                self.formatUI(error: error)
                self.getNodeGroupMatterFabricDetailsInBackground()
            }
        } else {
            self.formatUI(error: error)
        }
        #else
        self.formatUI(error: error)
        #endif
    }
    
    func formatUI(error: ESPNetworkError?) {
        self.searchForDevicesOnWLAN()
        if error != nil {
            Utility.showToastMessage(view: self.view, message: error!.description, duration: 5.0)
        }
        self.setupSegmentControl()
        segmentControl.isUserInteractionEnabled = true
        self.prepareView()
    }

    // MARK: - IB Actions
    @IBAction func clickedSegment(segment: UISegmentedControl) {
        print(segment.selectedSegmentIndex)
        if segment.selectedSegmentIndex > currentPage {
            collectionView.scrollToItem(at: IndexPath(row: segment.selectedSegmentIndex, section: 0), at: .right, animated: true)
        } else {
            collectionView.scrollToItem(at: IndexPath(row: segment.selectedSegmentIndex, section: 0), at: .left, animated: true)
        }
        adjustSegmentControlFor(currentIndex: segment.selectedSegmentIndex)
        currentPage = segment.selectedSegmentIndex
    }

    @IBAction func refreshClicked(_: Any) {
        // Force API refresh for user-initiated refresh button
        // This ensures immediate response for user actions
        forceAPIRefresh()
    }
    
    /// Force an API refresh - used for user-initiated actions
    /// This ensures we always make API calls for pull-to-refresh, login, etc.
    private func forceAPIRefresh() {
        User.shared.updateDeviceList = true // Ensure API call is made
        lastAPICallTimestamp = 0 // Reset cooldown for immediate API call
        refreshDeviceList()
    }

    @IBAction func dropDownClicked(_: Any) {
        dropDownMenu.isHidden = !dropDownMenu.isHidden
    }

    @IBAction func goToNodeGroups(_: Any) {
        let controlStoryBoard = UIStoryboard(name: "NodeGrouping", bundle: nil)
        let deviceTraitsVC = controlStoryBoard.instantiateViewController(withIdentifier: "nodeGroupsVC") as! NodeGroupsViewController
        navigationController?.pushViewController(deviceTraitsVC, animated: true)
    }

    @IBAction func addNodeGroup(_: Any) {
        let controlStoryBoard = UIStoryboard(name: "NodeGrouping", bundle: nil)
        let deviceTraitsVC = controlStoryBoard.instantiateViewController(withIdentifier: "createGroupVC") as! NewNodeGroupViewController
        navigationController?.pushViewController(deviceTraitsVC, animated: true)
    }

    @IBAction func addDeviceClicked(_: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        tabBarController?.tabBar.isHidden = true

        // Check if scan is enabled in ap
        if Configuration.shared.espProvSetting.scanEnabled {
            #if ESPRainMakerMatter
            if #available(iOS 16.4, *) {
                self.stopMatterDiscovery()
            }
            #endif
            let scannerVC = mainStoryboard.instantiateViewController(withIdentifier: "scannerVC") as! ScannerViewController
            navigationController?.pushViewController(scannerVC, animated: true)
        } else {
            // If scan is not enabled check supported transport
            switch Configuration.shared.espProvSetting.transport {
            case .ble:
                // Go directly to BLE manual provisioning
                goToBleProvision()
            case .softAp:
                // Go directly to SoftAP manual provisioning
                goToSoftAPProvision()
            default:
                // If both BLE and SoftAP is supported. Present Action Sheet to give option to choose.
                let actionSheet = UIAlertController(title: "", message: "Choose Provisioning Transport", preferredStyle: .actionSheet)
                let bleAction = UIAlertAction(title: "BLE", style: .default) { _ in
                    self.goToBleProvision()
                }
                let softapAction = UIAlertAction(title: "SoftAP", style: .default) { _ in
                    self.goToSoftAPProvision()
                }
                let onNetworkAction = UIAlertAction(title: "On Network", style: .default) { _ in
                    self.goToOnNetworkDiscovery()
                }
                actionSheet.addAction(bleAction)
                actionSheet.addAction(softapAction)
                actionSheet.addAction(onNetworkAction)
                actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                // Configure for iPad
                if let popover = actionSheet.popoverPresentationController {
                    popover.sourceView = self.view
                    popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                present(actionSheet, animated: true, completion: nil)
            }
        }
    }

    // MARK: - Private Methods
    private func searchForDevicesOnWLAN() {
        DispatchQueue.main.async {
            // Start local discovery if its enabled
            if Configuration.shared.appConfiguration.supportLocalControl {
                User.shared.startServiceDiscovery()
            }
        }
    }

    private func goToBleProvision() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let bleLandingVC = mainStoryboard.instantiateViewController(withIdentifier: "bleLandingVC") as! BLELandingViewController
        navigationController?.pushViewController(bleLandingVC, animated: true)
    }

    private func goToSoftAPProvision() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let softLandingVC = mainStoryboard.instantiateViewController(withIdentifier: "provisionLanding") as! ProvisionLandingViewController
        navigationController?.pushViewController(softLandingVC, animated: true)
    }
    
    private func goToOnNetworkDiscovery() {
        let onNetworkVC = OnNetworkDiscoveryViewController()
        navigationController?.pushViewController(onNetworkVC, animated: true)
    }

    private func prepareView() {
        if User.shared.associatedNodeList == nil || User.shared.associatedNodeList?.count == 0 {
            // For empty state, we can use direct reload since there's no content
            collectionView.reloadData()
            setViewForNoNodes()
        } else {
            initialView.isHidden = true
            collectionView.isHidden = false
            addButton.isHidden = false
            // Use smart reload when we have data
            // This prevents unnecessary full reloads when only minor changes occurred
            smartReloadCollectionView(for: .nodeList)
        }
        collectionView.isUserInteractionEnabled = true
        
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *) {
            // Setup subscriptions for all Matter devices
            ESPMTRCommissionerManager.shared.setupDeviceMonitoringForAllFabrics()
        }
        #endif
    }

    private func showLoader() {
        loadingIndicator.isHidden = false
        loadingIndicator.animate()
    }

    private func updateUserInfo() {
        let sessionWorker = ESPExtendUserSessionWorker()
        sessionWorker.checkUserSession() { _, error in
            if error == nil, let idToken = ESPTokenWorker.shared.idTokenString {
                if User.shared.userInfo.loggedInWith == .cognito {
                    self.getUserInfo(token: idToken, provider: .cognito)
                } else {
                    self.getUserInfo(token: idToken, provider: .other)
                }
            } else {
                Utility.hideLoader(view: self.view)
                self.refreshDeviceList()
            }
        }
    }
    
    private func getUserInfo(token: String, provider: ServiceProvider) {
        do {
            let json = try decode(jwt: token)
            User.shared.userInfo.username = json.body["cognito:username"] as? String ?? ""
            User.shared.userInfo.email = json.body["email"] as? String ?? ""
            User.shared.userInfo.userID = json.body["custom:user_id"] as? String ?? ""
            User.shared.userInfo.loggedInWith = provider
            User.shared.userInfo.saveUserInfo()
        } catch {
            print("error parsing token")
        }
        // Force API refresh after successful login
        // This ensures we get fresh data after authentication as required
        forceAPIRefresh()
    }
    
    private func refresh() {
        let service = ESPUserService(presenter: self)
        service.fetchUserDetails()
    }

    private func setViewForNoNodes() {
        if User.shared.associatedNodeList?.count == 0 || User.shared.associatedNodeList == nil {
            infoLabel.text = "No Device Added"
            emptyListIcon.image = UIImage(named: "no_device_icon")
            infoLabel.textColor = .white
            initialView.isHidden = false
            collectionView.isHidden = true
            addButton.isHidden = true
        } else {
            // Use smart reload when transitioning from empty to having devices
            self.smartReloadCollectionView(for: .nodeList)
            #if ESPRainMakerMatter
            if #available(iOS 16.4, *) {
                self.stopMatterDiscovery()
            }
            self.searchForMatterDevicesOnLocalNetwork() {}
            #endif
        }
    }

    private func setupSegmentControl() {
        segmentControlLeadingConstraint.constant = 0
        segmentControl.layoutIfNeeded()
        segmentControl.removeAllSegments()
        absoluteSegmentPosition = []

        var segmentPosition: CGFloat = 0
        for i in 0 ... NodeGroupManager.shared.nodeGroups.count {
            var stringBoundingbox: CGSize = .zero
            if i == 0 {
                stringBoundingbox = "All Devices".size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.5, weight: .semibold)])
                segmentControl.insertSegment(withTitle: "All Devices", at: i, animated: false)
            } else {
                let groupName = NodeGroupManager.shared.nodeGroups[i - 1].group_name ?? ""
                stringBoundingbox = (groupName as NSString).size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.5, weight: .semibold)])
                segmentControl.insertSegment(withTitle: groupName, at: i, animated: false)
            }
            segmentPosition = segmentPosition + stringBoundingbox.width + 20
            absoluteSegmentPosition.append(segmentPosition)
            segmentControl.setWidth(stringBoundingbox.width + 20, forSegmentAt: i)
        }
        if currentPage > NodeGroupManager.shared.nodeGroups.count {
            segmentControl.selectedSegmentIndex = NodeGroupManager.shared.nodeGroups.count
        } else {
            segmentControl.selectedSegmentIndex = currentPage
        }
    }

    private func getFontWidthForString(text: NSString) -> CGSize {
        return text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.5, weight: .semibold)])
    }

    private func getSingleDeviceNodeCount(forNodeList: [Node]?) -> Int {
        var singleDeviceNodeCount = 0
        if let nodeList = forNodeList {
            for item in nodeList {
                if item.devices?.count == 1 {
                    singleDeviceNodeCount += 1
                }
            }
        }
        return singleDeviceNodeCount
    }

    // Helper method to customise UISegmentControl
    private func configureSegmentControl() {
        let currentBGColor = UIColor(hexString: "#8265E3")
        segmentControl.removeBorder()
        segmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white as Any, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.0, weight: .regular)], for: .normal)
        segmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white as Any, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.5, weight: .semibold), NSAttributedString.Key.underlineStyle: NSUnderlineStyle.thick.rawValue], for: .selected)
        segmentControl.changeUnderlineColor(color: currentBGColor)
        let allDeviceSize = getFontWidthForString(text: "All Devices")
        segmentControl.setWidth(allDeviceSize.width + 40, forSegmentAt: 0)
    }

    private func unhideInitialView(error: ESPNetworkError?) {
        User.shared.associatedNodeList = localStorageHandler.fetchNodeDetails()
        if User.shared.associatedNodeList?.count == 0 || User.shared.associatedNodeList == nil {
            infoLabel.text = "No devices to show\n" + (error?.description ?? "Something went wrong!!")
            emptyListIcon.image = nil
            infoLabel.textColor = .red
            initialView.isHidden = false
            collectionView.isHidden = true
            addButton.isHidden = true
        } else {
            collectionView.reloadData()
            initialView.isHidden = true
            collectionView.isHidden = false
            addButton.isHidden = false
            Utility.showToastMessage(view: view, message: "Network error: \(error?.description ?? "Something went wrong!!")")
        }
        if Configuration.shared.appConfiguration.supportGrouping {
            NodeGroupManager.shared.nodeGroups = localStorageHandler.fetchNodeGroups() ?? []
            setupSegmentControl()
            prepareView()
        }
    }

    private func preparePopover(contentController: UIViewController,
                                sender: UIView,
                                delegate: UIPopoverPresentationControllerDelegate?)
    {
        contentController.modalPresentationStyle = .popover
        contentController.popoverPresentationController!.sourceView = sender
        contentController.popoverPresentationController!.sourceRect = sender.bounds
        contentController.preferredContentSize = CGSize(width: 182.0, height: 112.0)
        contentController.popoverPresentationController!.delegate = delegate
    }

    private func adjustSegmentControlFor(currentIndex: Int) {
        if absoluteSegmentPosition[currentIndex] > UIScreen.main.bounds.size.width - 100 {
            UIView.animate(withDuration: 0.5) {
                self.segmentControlLeadingConstraint.constant = UIScreen.main.bounds.size.width - 80 - 20 - self.absoluteSegmentPosition[currentIndex]
                self.segmentControl.layoutIfNeeded()
            }
        } else {
            if segmentControlLeadingConstraint.constant != 0 {
                UIView.animate(withDuration: 0.5) {
                    self.segmentControlLeadingConstraint.constant = 0
                    self.segmentControl.layoutIfNeeded()
                }
            }
        }
    }
    
    private func setTabBarControllerViews() {
        if !Configuration.shared.appConfiguration.supportDeviceAutomation {
            tabBarController?.viewControllers?.remove(at: 3)
        }
        if !Configuration.shared.appConfiguration.supportScene {
            tabBarController?.viewControllers?.remove(at: 2)
        }
        if !Configuration.shared.appConfiguration.supportSchedule {
            tabBarController?.viewControllers?.remove(at: 1)
        }
    }
}

extension DevicesViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        let w = scrollView.bounds.size.width
        let currentPage = Int(ceil(x / w))
        self.currentPage = currentPage
        segmentControl.selectedSegmentIndex = currentPage
        adjustSegmentControlFor(currentIndex: currentPage)
    }
}

extension DevicesViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        if Configuration.shared.appConfiguration.supportGrouping {
            if NodeGroupManager.shared.nodeGroups.count == 0 {
                if User.shared.associatedNodeList == nil || User.shared.associatedNodeList?.count == 0 {
                    return 0
                } else {
                    return 1
                }
            }
            return NodeGroupManager.shared.nodeGroups.count + 1
        }
        return 1
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item > 0 {
            let group = NodeGroupManager.shared.nodeGroups[indexPath.item - 1]
            if group.nodes?.count ?? 0 < 1 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "deviceGroupEmptyDeviceCVC", for: indexPath) as! DeviceGroupEmptyDeviceCollectionViewCell
                cell.addDeviceButtonAction = {
                    let nodeGroupStoryBoard = UIStoryboard(name: "NodeGrouping", bundle: nil)
                    let editNodeGroupVC = nodeGroupStoryBoard.instantiateViewController(withIdentifier: "editNodeGroupVC") as! EditNodeGroupViewController
                    editNodeGroupVC.currentNodeGroup = group
                    self.navigationController?.pushViewController(editNodeGroupVC, animated: true)
                }
                return cell
            }
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "deviceGroupCollectionViewCell", for: indexPath) as! DeviceGroupCollectionViewCell
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *) {
            cell.collectionView.register(UINib(nibName: DeviceCollectionViewCell.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: DeviceCollectionViewCell.reuseIdentifier)
        }
        #endif
        cell.delegate = self
        if indexPath.item == 0 {
            cell.singleDeviceNodeCount = getSingleDeviceNodeCount(forNodeList: User.shared.associatedNodeList)
            // Always use fresh data from User.shared.associatedNodeList for push notification updates
            cell.datasource = User.shared.associatedNodeList ?? []
        } else {
            let nodeList = NodeGroupManager.shared.nodeGroups[indexPath.item - 1].nodeList
            cell.singleDeviceNodeCount = getSingleDeviceNodeCount(forNodeList: nodeList)
            if let nodeList = nodeList, nodeList.count > 0 {
                var finalNodeLst = nodeList
                // Always refresh with latest data from User.shared.associatedNodeList
                for index in 0..<nodeList.count {
                    let indexNode = nodeList[index]
                    if let indexNodeId = indexNode.node_id, let nodes = User.shared.associatedNodeList {
                        for node in nodes {
                            if let nodeId = node.node_id, indexNodeId == nodeId {
                                finalNodeLst[index] = node
                                break
                            }
                        }
                    }
                }
                cell.datasource = finalNodeLst
            } else {
                cell.datasource = []
            }
        }
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(cell, action: #selector(refreshDeviceList), for: .valueChanged)
        refreshControl.tintColor = .clear
        cell.collectionView.refreshControl = refreshControl
        cell.refreshAction = {
            refreshControl.endRefreshing()
            // Force API refresh for pull-to-refresh action
            // This ensures pull-to-refresh always makes API call as required
            self.forceAPIRefresh()
        }
        // CRITICAL: Always reload nested collection view when datasource is set in cellForItemAt
        // This ensures the nested collection view matches the datasource, especially when switching groups
        // Using reloadData() is safe here because cellForItemAt is called during cell configuration,
        // not during batch updates, so there's no conflict
        cell.collectionView.reloadData()
        return cell
    }
}

extension DevicesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let frame = collectionView.frame
        return CGSize(width: frame.width, height: frame.height)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        return 0
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return 0
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

extension DevicesViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_: UIPopoverPresentationController) {}

    func popoverPresentationControllerShouldDismissPopover(_: UIPopoverPresentationController) -> Bool {
        return false
    }
}

extension DevicesViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view == groupMenuButton {
            return false
        }

        return true
    }
}


extension DevicesViewController: ESPExtendSessionPresentationLogic {
    
    func sessionValidated(withError error: ESPAPIError?) {
        if error != nil {
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            if let nav = storyboard.instantiateViewController(withIdentifier: "signInController") as? UINavigationController {
                if let _ = nav.viewControllers.first as? SignInViewController, let tab = self.tabBarController {
                    nav.modalPresentationStyle = .fullScreen
                    tab.present(nav, animated: true, completion: nil)
                }
            }
        }
    }
}

extension DevicesViewController: ESPUserPresentationLogic {
    
    func userDetailsFetched(error: ESPAPIError?) {
        if error == nil {
            DispatchQueue.main.async {
                self.updateUserInfo()
            }
        }
    }
}
