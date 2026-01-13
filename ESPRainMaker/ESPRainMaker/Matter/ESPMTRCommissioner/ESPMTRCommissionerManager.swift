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
//  ESPMTRCommissionerManager.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
class ESPMTRCommissionerManager: NSObject {
    
    static let shared = ESPMTRCommissionerManager()
    
    // Dictionary to store commissioner instances by fabric ID
    private var commissionerInstances: [String: ESPMTRCommissioner] = [:]
    private let fabricDetails = ESPMatterFabricDetails.shared
    
    override init() {
        super.init()
    }
    
    /// Get or create commissioner instance for a specific group
    /// - Parameter groupId: Group ID
    /// - Returns: ESPMTRCommissioner instance
    func getCommissioner(for groupId: String) -> ESPMTRCommissioner {
        if let existingCommissioner = commissionerInstances[groupId] {
            return existingCommissioner
        } else {
            let newCommissioner = ESPMTRCommissioner()
            commissionerInstances[groupId] = newCommissioner
            return newCommissioner
        }
    }
    
    /// Get all active commissioner instances
    /// - Returns: Dictionary of fabric ID to commissioner instances
    func getAllCommissioners() -> [String: ESPMTRCommissioner] {
        return commissionerInstances
    }
    
    /// Get commissioner for commissioning process
    /// - Parameter groupId: Group ID
    /// - Returns: ESPMTRCommissioner instance
    func getCommissionerForCommissioning(_ groupId: String) -> ESPMTRCommissioner {
        return getCommissioner(for: groupId)
    }
    
    /// Get commissioner for device control
    /// - Parameter groupId: Group ID
    /// - Returns: ESPMTRCommissioner instance
    func getCommissionerForDeviceControl(_ groupId: String) -> ESPMTRCommissioner {
        return getCommissioner(for: groupId)
    }
    
    /// Get commissioner for existing code (backward compatibility)
    /// - Parameter groupId: Group ID
    /// - Returns: ESPMTRCommissioner instance
    func getCommissionerForExistingCode(_ groupId: String) -> ESPMTRCommissioner {
        return getCommissioner(for: groupId)
    }
    

    
    /// Set the shared commissioner instance for commissioning process
    /// This ensures the commissioning process uses the same instance throughout
    /// - Parameter groupId: Group ID for the fabric
    func setSharedCommissionerForCommissioning(groupId: String) {
        // This method is kept for backward compatibility but no longer needed
        // since we're removing the singleton pattern
        _ = getCommissioner(for: groupId)
    }
    

    

    
    /// Initialize commissioners for all available fabrics
    func initializeCommissionersForAllFabrics() {
        guard let groups = User.shared.associatedNodeList?.compactMap({ $0.groupId }).unique() else {
            return
        }
        
        for groupId in groups {
            _ = getCommissioner(for: groupId)
        }
    }
    
    /// Setup device monitoring for all fabrics
    func setupDeviceMonitoringForAllFabrics() {
        guard let nodes = User.shared.associatedNodeList else {
            return
        }
        
        // Group nodes by fabric/groupId
        let nodesByFabric = Dictionary(grouping: nodes) { node in
            return node.groupId ?? "default"
        }
        
        for (groupId, fabricNodes) in nodesByFabric {
            let commissioner = getCommissioner(for: groupId)
            setupDeviceMonitoring(for: commissioner, nodes: fabricNodes)
        }
    }
    
    /// Setup device monitoring for a specific commissioner
    /// - Parameters:
    ///   - commissioner: ESPMTRCommissioner instance
    ///   - nodes: Nodes in this fabric
    func setupDeviceMonitoring(for commissioner: ESPMTRCommissioner, nodes: [Node]) {
        // Initialize controller for this fabric if needed
        if commissioner.sController == nil {
            if let firstNode = nodes.first,
               let groupId = firstNode.groupId,
               let group = getGroup(for: groupId),
               let userNOCDetails = fabricDetails.getUserNOCDetails(groupId: groupId) {
                commissioner.group = group
                commissioner.initializeMTRControllerWithUserNOC(matterFabricData: group, userNOCData: userNOCDetails)
            } else {
                return
            }
        }
        
        var onOffSupportedCount = 0
        for node in nodes {
            // Check if device supports on/off cluster
            if node.isOnOffServerSupported.0 {
                onOffSupportedCount += 1
                setupOnOffMonitoring(for: commissioner, node: node)
            }
        }
    }
    
    /// Setup on/off monitoring for a specific node
    /// - Parameters:
    ///   - commissioner: ESPMTRCommissioner instance
    ///   - node: Node to monitor
    func setupOnOffMonitoring(for commissioner: ESPMTRCommissioner, node: Node) {
        guard let groupId = node.groupId,
              let matterNodeId = node.matter_node_id,
              let deviceId = matterNodeId.hexToDecimal else {
            return
        }
        
        // Subscribe to on/off attribute changes
        commissioner.subscribeToOnOffValue(groupId: groupId, deviceId: deviceId) { isOn in
            DispatchQueue.main.async {
                self.handleOnOffValueChange(node: node, isOn: isOn)
            }
        }
    }
    
    /// Handle on/off value changes
    /// - Parameters:
    ///   - node: Node that changed
    ///   - isOn: New on/off state
    func handleOnOffValueChange(node: Node, isOn: Bool) {
        if let nodeId = node.node_id, let matterNodeId = node.matter_node_id, let deviceId = matterNodeId.hexToDecimal {
            // Note: Node class doesn't have setMatterLightOnStatus method
            // The UI will be updated via notification, and the actual device state
            // will be reflected when the device is next queried
            
            // Send targeted notification with device info
            NotificationCenter.default.post(
                name: Notification.Name("MatterDeviceOnOffChanged"),
                object: nil,
                userInfo: ["nodeId": nodeId, "deviceId": deviceId, "isOn": isOn]
            )
        }
    }
    
    /// Get group for a specific group ID
    /// - Parameter groupId: Group ID
    /// - Returns: ESPNodeGroup if found
    func getGroup(for groupId: String) -> ESPNodeGroup? {
        return fabricDetails.getGroupData(groupId: groupId)
    }
    
    /// Cleanup commissioner for a specific fabric
    /// - Parameter fabricId: Fabric ID to cleanup
    func cleanupCommissioner(for fabricId: String) {
        if let commissioner = commissionerInstances[fabricId] {
            commissioner.shutDownController()
            commissionerInstances.removeValue(forKey: fabricId)
        }
    }
    
    /// Cleanup all commissioners
    func cleanupAllCommissioners() {
        for (fabricId, commissioner) in commissionerInstances {
            commissioner.shutDownController()
        }
        commissionerInstances.removeAll()
    }
    
    /// Handle app lifecycle events
    func handleAppWillEnterForeground() {
        // Re-initialize commissioners when app comes to foreground
        initializeCommissionersForAllFabrics()
        setupDeviceMonitoringForAllFabrics()
    }
    
    /// Retry monitoring setup when groups are loaded
    /// This is called when group data becomes available
    func retryMonitoringSetupWhenGroupsLoaded() {
        setupDeviceMonitoringForAllFabrics()
    }
    

    

    
    /// Handle app will resign active
    func handleAppWillResignActive() {
        // Cleanup commissioners when app goes to background
        cleanupAllCommissioners()
    }
    

}

// MARK: - Array extension for unique values
extension Array where Element: Hashable {
    func unique() -> [Element] {
        return Array(Set(self))
    }
}
#endif
