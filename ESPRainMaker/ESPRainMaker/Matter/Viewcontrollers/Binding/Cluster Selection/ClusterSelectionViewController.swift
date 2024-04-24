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
//  ClusterSelectionViewController.swift
//  ESPRainmaker
//

import UIKit

class ClusterSelectionViewController: UIViewController {
    
    static let storyboardId = "ClusterSelectionViewController"
    
    @IBOutlet weak var clusterSelectionTableView: UITableView!
    var clusters: [String] = [String]()
    var switchIndex: Int?
    let fabricDetails = ESPMatterFabricDetails.shared
    var bindingEndpointClusterId: [String: UInt]?
    var group: ESPNodeGroup?
    var allNodes: [ESPNodeDetails]?
    var sourceNode: ESPNodeDetails?
    var isUserActionAllowed: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.generateCells()
        self.clusterSelectionTableView.reloadData()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
        
    func generateCells() {
        if let groupID = self.group?.groupID, let node = sourceNode, let matterNodeId = node.matterNodeID, let deviceId = matterNodeId.hexToDecimal {
            if ESPMatterClusterUtil.shared.isOnOffClientSupported(groupId: groupID, deviceId: deviceId).0 {
                clusters.append(ESPMatterConstants.onOffCluster)
            }
            if ESPMatterClusterUtil.shared.isClientClusterSupported(groupId: groupID, deviceId: deviceId, clusterId: temperatureMeasurement.clusterId.uintValue).0 {
                clusters.append(ESPMatterConstants.tempMeasurementCluster)
            }
        }
    }
    
    #if ESPRainMakerMatter
    /// Open Binding Window
    @available(iOS 16.4, *)
    func openBindingWindow(cluster: String) {
        if let _ = self.sourceNode {
            let storyboard = UIStoryboard(name: ESPMatterConstants.matterStoryboardId, bundle: nil)
            let devicesBindingVC = storyboard.instantiateViewController(withIdentifier: DevicesBindingViewController.storyboardId) as! DevicesBindingViewController
            devicesBindingVC.group = self.group
            devicesBindingVC.nodes = self.allNodes
            devicesBindingVC.sourceNode = self.sourceNode
            devicesBindingVC.bindingEndpointClusterId = self.bindingEndpointClusterId
            devicesBindingVC.switchIndex = self.switchIndex
            devicesBindingVC.cluster = cluster
            self.navigationController?.pushViewController(devicesBindingVC, animated: true)
        }
    }
    #endif
}

extension ClusterSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clusters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: ClusterSelectionCell.reuseIdentifier, for: indexPath) as? ClusterSelectionCell {
            if self.clusters.count > indexPath.row {
                let cluster = self.clusters[indexPath.row]
                cell.cluster.text = cluster
                cell.clusterString = cluster
                cell.clusterSelectedDelegate = self
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
}


extension ClusterSelectionViewController: ClusterSelectedDelegate {
    
    func clusterSelected(cluster: String) {
        #if ESPRainMakerMatter
        if #available(iOS 16.4, *) {
            self.openBindingWindow(cluster: cluster)
        }
        #endif
    }
}
