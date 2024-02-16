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
//  DevicesViewController+Navigation.swift
//  ESPRainMaker
//

import Foundation
import UIKit

extension DevicesViewController: DeviceGroupCollectionViewCellDelegate {
    
    /// Did select device
    /// - Parameter device: device
    func didSelectDevice(device: Device) {
        let deviceTraitsVC = controlStoryBoard.instantiateViewController(withIdentifier: Constants.deviceTraitListVCIdentifier) as! DeviceTraitListViewController
        deviceTraitsVC.device = device
        Utility.hideLoader(view: view)
        navigationController?.pushViewController(deviceTraitsVC, animated: true)
    }
    
    /// Did select node
    /// - Parameter node: node
    func didSelectNode(node: Node) {
        let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
        let destination = deviceStoryboard.instantiateViewController(withIdentifier: "nodeDetailsVC") as! NodeDetailsViewController
        destination.currentNode = node
        navigationController?.pushViewController(destination, animated: true)
    }
    
    /// Launch corresponding device screen
    /// - Parameters:
    ///   - isSingleDeviceNode: is single device node
    ///   - node: node
    ///   - matterNodeId: matter node id
    ///   - deviceId: device id
    ///   - indexPath: index path
    func launchDeviceScreen(isSingleDeviceNode: Bool, groupId: String, group: ESPNodeGroup, node: ESPNodeDetails, matterNodeId: String, deviceId: UInt64, indexPath: IndexPath, rNode: Node? = nil, nodeConnectionStatus: NodeConnectionStatus) {
        let result = ESPMatterClusterUtil.shared.isOnOffClientSupported(groupId: groupId, deviceId: deviceId)
        let clients = ESPMatterClusterUtil.shared.fetchBindingServers(groupId: groupId, deviceId: deviceId)
        var endpointClusterId: [String: UInt]?
        var switchIndex: Int?
        if isSingleDeviceNode, result, clients.count == 1 {
            endpointClusterId = clients
        } else if !isSingleDeviceNode, result, indexPath.item < clients.count {
            let sortedKeys = clients.keys.sorted { $0 < $1 }
            let key = sortedKeys[indexPath.item]
            switchIndex = indexPath.item
            if let value = clients[key] {
                endpointClusterId = [key: value]
            }
        }
        if let nodeId = node.nodeID, let rainmakerNode = User.shared.getNode(id: nodeId), !rainmakerNode.isRainmaker {
            self.showMatterDeviceVCWithNode(node: node, group: group, endpointClusterId: endpointClusterId, indexPath: indexPath, switchIndex: switchIndex, nodeConnectionStatus: nodeConnectionStatus)
        } else {
            if let rNode = rNode, let matterNodeId = rNode.matter_node_id, User.shared.isMatterNodeConnected(matterNodeId: matterNodeId) {
                self.showMatterDeviceVCWithNode(node: node, group: group, endpointClusterId: endpointClusterId, indexPath: indexPath, switchIndex: switchIndex, nodeConnectionStatus: nodeConnectionStatus)
            } else {
                self.showDeviceTraitListVC(node: node, group: group, endpointClusterId: endpointClusterId, indexPath: indexPath)
            }
        }
    }
    
    /// Show matter vc with node
    /// - Parameters:
    ///   - node: ESPNodeDetails
    ///   - group: ESPNodeGroup
    ///   - endpointClusterId: endpoint cluster id
    ///   - indexPath: indexpath
    func showMatterDeviceVCWithNode(node: ESPNodeDetails, group: ESPNodeGroup, endpointClusterId: [String: UInt]?, indexPath: IndexPath, switchIndex: Int?, nodeConnectionStatus: NodeConnectionStatus) {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *) {
            let storyboard = UIStoryboard(name: ESPMatterConstants.matterStoryboardId, bundle: nil)
            if let deviceScreen = storyboard.instantiateViewController(withIdentifier: DeviceViewController.storyboardId) as? DeviceViewController {
                deviceScreen.switchIndex = switchIndex
                deviceScreen.endpointClusterId = endpointClusterId
                deviceScreen.group = group
                deviceScreen.node = node
                deviceScreen.matterNodeId = node.matterNodeID
                deviceScreen.rainmakerNodes = User.shared.associatedNodeList
                deviceScreen.nodeConnectionStatus = nodeConnectionStatus
                if let id = node.nodeID, let rmakerNode = User.shared.getNode(id: id) {
                    deviceScreen.rainmakerNode = rmakerNode
                }
                if let groupId = group.groupID, let matterNodeId = node.matterNodeID, let deviceId = matterNodeId.hexToDecimal, let deviceName = ESPMatterFabricDetails.shared.getDeviceName(groupId: groupId, matterNodeId: matterNodeId) {
                    if let groups = ESPMatterFabricDetails.shared.getNodeGroupDetails(groupId: groupId)?.groups, groups.count > 0, let allNodes = groups[0].nodeDetails {
                        deviceScreen.allNodes = allNodes
                    }
                    let clients = ESPMatterClusterUtil.shared.fetchBindingServers(groupId: groupId, deviceId: deviceId)
                    if ESPMatterClusterUtil.shared.isOnOffClientSupported(groupId: groupId, deviceId: deviceId), clients.count > 1 {
                        deviceScreen.deviceName = "\(deviceName).\(indexPath.item)"
                    } else {
                        deviceScreen.deviceName = deviceName
                    }
                }
                #if ESPRainMakerMatter
                if #available(iOS 16.4, *) {
                    self.stopMatterDiscovery()
                }
                #endif
                self.navigationController?.pushViewController(deviceScreen, animated: true)
            }
        }
        #endif
    }
    
    /// Show device trait list VC
    /// - Parameters:
    ///   - node: ESPNodeDetails instance
    ///   - group: ESPNodeGroup
    ///   - endpointClusterId: endpointclusterid
    ///   - indexPath: indexpath
    func showDeviceTraitListVC(node: ESPNodeDetails, group: ESPNodeGroup, endpointClusterId: [String: UInt]?, indexPath: IndexPath) {
        if let nodeId = node.nodeID, let rainmakerNode = User.shared.getNode(id: nodeId) {
            if let rainmakerNodeId = rainmakerNode.node_id, let nodeId = node.nodeID, rainmakerNodeId.lowercased() == nodeId.lowercased(), let rainmakerDevices = rainmakerNode.devices, rainmakerDevices.count > 0 {
                let storyboard = UIStoryboard(name: Storyboard.deviceDetails.storyboardId, bundle: nil)
                if let deviceTraitList = storyboard.instantiateViewController(withIdentifier: Constants.deviceTraitListVCIdentifier) as? DeviceTraitListViewController {
                    deviceTraitList.group = group
                    deviceTraitList.device = rainmakerDevices[0]
                    deviceTraitList.node = node
                    if let groupId = ESPMatterFabricDetails.shared.getGroupId(nodeId: nodeId), let matterNodeId = node.matterNodeID, let deviceId = matterNodeId.hexToDecimal, let deviceName = ESPMatterFabricDetails.shared.getDeviceName(groupId: groupId, matterNodeId: matterNodeId) {
                        deviceTraitList.matterNodeId = matterNodeId
                        if let groups = ESPMatterFabricDetails.shared.getNodeGroupDetails(groupId: groupId)?.groups, groups.count > 0, let allNodes = groups[0].nodeDetails {
                            deviceTraitList.allNodes = allNodes
                        }
                        let clients = ESPMatterClusterUtil.shared.fetchBindingServers(groupId: groupId, deviceId: deviceId)
                        if ESPMatterClusterUtil.shared.isOnOffClientSupported(groupId: groupId, deviceId: deviceId), clients.count > 0 {
                            if !ESPMatterClusterUtil.shared.isOnOffServerSupported(groupId: groupId, deviceId: deviceId).0 {
                                deviceTraitList.isSwitch = true
                            }
                            deviceTraitList.endpointClusterId = endpointClusterId
                        }
                        if ESPMatterClusterUtil.shared.isOnOffClientSupported(groupId: groupId, deviceId: deviceId), clients.count > 1 {
                            deviceTraitList.deviceName = "\(deviceName).\(indexPath.item)"
                            deviceTraitList.switchIndex = indexPath.item
                        } else {
                            deviceTraitList.deviceName = deviceName
                        }
                    }
                    #if ESPRainMakerMatter
                    if #available(iOS 16.4, *) {
                        self.stopMatterDiscovery()
                    }
                    #endif
                    self.navigationController?.pushViewController(deviceTraitList, animated: true)
                }
            }
        }
    }
    
    /// Show delete device screen
    /// - Parameters:
    ///   - node: rainmaker ESPNodeDetails
    ///   - group: ESNodeGroup group
    ///   - rainmakerNode: rainmaker Node
    ///   - indexPath: indexpath
    func showDeleteDeviceVC(node: ESPNodeDetails?, group: ESPNodeGroup, rainmakerNode: Node?, indexPath: IndexPath) {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *) {
            let storyboard = UIStoryboard(name: ESPMatterConstants.matterStoryboardId, bundle: nil)
            if let deviceScreen = storyboard.instantiateViewController(withIdentifier: DeviceViewController.storyboardId) as? DeviceViewController {
                deviceScreen.group = group
                deviceScreen.node = node
                deviceScreen.isDeviceOffline = true
                deviceScreen.rainmakerNodes = User.shared.associatedNodeList
                deviceScreen.rainmakerNode = rainmakerNode
                if let groupId = group.groupID, let node = node, let matterNodeId = node.matterNodeID, let deviceId = matterNodeId.hexToDecimal {
                    let result = ESPMatterClusterUtil.shared.isOnOffClientSupported(groupId: groupId, deviceId: deviceId)
                    let clients = ESPMatterClusterUtil.shared.fetchBindingServers(groupId: groupId, deviceId: deviceId)
                    var endpointClusterId: [String: UInt]?
                    var switchIndex: Int?
                    if result, clients.count == 1 {
                        endpointClusterId = clients
                    } else if result, indexPath.item < clients.count {
                        let sortedKeys = clients.keys.sorted { $0 < $1 }
                        let key = sortedKeys[indexPath.item]
                        switchIndex = indexPath.item
                        if let value = clients[key] {
                            endpointClusterId = [key: value]
                        }
                    }
                    deviceScreen.endpointClusterId = endpointClusterId
                    deviceScreen.switchIndex = switchIndex
                    deviceScreen.matterNodeId = matterNodeId
                }
                if let groupId = group.groupID, let matterNodeId = node?.matterNodeID, let deviceId = matterNodeId.hexToDecimal, let deviceName = ESPMatterFabricDetails.shared.getDeviceName(groupId: groupId, matterNodeId: matterNodeId) {
                    deviceScreen.matterNodeId = matterNodeId
                    if let groups = ESPMatterFabricDetails.shared.getNodeGroupDetails(groupId: groupId)?.groups, groups.count > 0, let allNodes = groups[0].nodeDetails {
                        deviceScreen.allNodes = allNodes
                    }
                    let clients = ESPMatterClusterUtil.shared.fetchBindingServers(groupId: groupId, deviceId: deviceId)
                    if ESPMatterClusterUtil.shared.isOnOffClientSupported(groupId: groupId, deviceId: deviceId), clients.count > 1 {
                        deviceScreen.deviceName = "\(deviceName).\(indexPath.item)"
                    } else {
                        deviceScreen.deviceName = deviceName
                    }
                } else {
                    if let rainmakerNodes = User.shared.associatedNodeList {
                        for rainmakerNode in rainmakerNodes {
                            if let nodeId = node?.nodeID, let rainmakerNodeId = rainmakerNode.node_id, nodeId == rainmakerNodeId, let deviceName = rainmakerNode.devices?.first?.deviceName {
                                deviceScreen.deviceName = deviceName
                                break
                            }
                        }
                    }
                }
                self.stopMatterDiscovery()
                self.navigationController?.pushViewController(deviceScreen, animated: true)
            }
        }
        #endif
    }
}
