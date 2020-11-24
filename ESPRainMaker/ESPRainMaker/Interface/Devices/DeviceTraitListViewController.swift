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
import MBProgressHUD
import UIKit

class DeviceTraitListViewController: UIViewController {
    var device: Device?
    var pollingTimer: Timer!
    var skipNextAttributeUpdate = false

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var offlineLabel: UILabel!
    @IBOutlet var networkIndicator: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
        tableView.register(UINib(nibName: "GenericSliderTableViewCell", bundle: nil), forCellReuseIdentifier: "GenericSliderTableViewCell")
        tableView.register(UINib(nibName: "StaticControlTableViewCell", bundle: nil), forCellReuseIdentifier: "staticControlTableViewCell")
        tableView.register(UINib(nibName: "GenericControlTableViewCell", bundle: nil), forCellReuseIdentifier: "genericControlCell")
        titleLabel.text = device?.getDeviceName() ?? "Details"
        tableView.estimatedRowHeight = 70.0
        tableView.rowHeight = UITableView.automaticDimension
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        tableView.contentInset = insets

        if device?.isReachable() ?? false {
            if ESPNetworkMonitor.shared.isConnectedToWifi || ESPNetworkMonitor.shared.isConnectedToNetwork {
                showLoader(message: "Getting info")
                updateDeviceAttributes()
            }
        }

        checkOfflineStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkNetworkUpdate()
        tabBarController?.tabBar.isHidden = true
        pollingTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(fetchNodeInfo), userInfo: nil, repeats: true)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paramUpdated), name: Notification.Name(Constants.paramUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkNetworkUpdate), name: Notification.Name(Constants.networkUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkOfflineStatus), name: Notification.Name(Constants.localNetworkUpdateNotification), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pollingTimer.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    @objc func appEnterForeground() {
        pollingTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(fetchNodeInfo), userInfo: nil, repeats: true)
    }

    @objc func appEnterBackground() {
        pollingTimer.invalidate()
    }

    @objc func fetchNodeInfo() {
        if skipNextAttributeUpdate {
            skipNextAttributeUpdate = false
        } else {
            refreshDeviceAttributes()
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
        }
    }

    func refreshDeviceAttributes() {
        if device?.isReachable() ?? false {
            tableView.alpha = 1.0
            tableView.isUserInteractionEnabled = true
            if device?.node?.node_id == nil {
                print("nil")
            }
            NetworkManager.shared.getNodeInfo(nodeId: (device?.node?.node_id)!) { node, error in
                if error != nil {
                    return
                }
                if let index = User.shared.associatedNodeList?.firstIndex(where: { node -> Bool in
                    node.node_id == (self.device?.node?.node_id)!
                }) {
                    let oldNode = User.shared.associatedNodeList![index]
                    node?.localNetwork = oldNode.localNetwork
                    User.shared.associatedNodeList![index] = node!
                    if let currentDevice = node!.devices?.first(where: { nodeDevice -> Bool in
                        nodeDevice.name == self.device?.name
                    }) {
                        self.device = currentDevice
                    } else {
                        print("Device with no node.")
                    }
                }
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                    self.tableView.reloadData()
                }
            }
        } else {
            tableView.alpha = 0.5
            tableView.isUserInteractionEnabled = false
        }
    }

    func updateDeviceAttributes() {
        NetworkManager.shared.getNodeInfo(nodeId: (device?.node?.node_id)!) { node, error in
            if error != nil {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error!!",
                                                            message: error?.description,
                                                            preferredStyle: .alert)
                    let retryAction = UIAlertAction(title: "Ok", style: .default) { _ in
                        Utility.hideLoader(view: self.view)
                    }
                    alertController.addAction(retryAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                if let index = User.shared.associatedNodeList?.firstIndex(where: { node -> Bool in
                    node.node_id == (self.device?.node?.node_id)!
                }) {
                    let oldNode = User.shared.associatedNodeList![index]
                    node?.localNetwork = oldNode.localNetwork
                    User.shared.associatedNodeList![index] = node!
                    if let currentDevice = node!.devices?.first(where: { nodeDevice -> Bool in
                        nodeDevice.name == self.device?.name
                    }) {
                        self.device = currentDevice
                    }
                }
            }
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.tableView.reloadData()
            }
        }
    }

    @objc func checkOfflineStatus() {
        if device?.node?.localNetwork ?? false {
            offlineLabel.text = "Reachable on WLAN"
            offlineLabel.isHidden = false
        } else if device?.node?.isConnected ?? true {
            offlineLabel.isHidden = true
        } else {
            offlineLabel.text = device?.node?.getNodeStatus() ?? ""
            offlineLabel.isHidden = false
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

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    @objc func setBrightness(_: UISlider) {}

    func getTableViewGenericCell(attribute: Param, indexPath: IndexPath) -> GenericControlTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "genericControlCell", for: indexPath) as! GenericControlTableViewCell
        cell.controlName.text = attribute.name
        cell.delegate = self
        if let value = attribute.value {
            cell.controlValue = "\(value)"
        }
        cell.controlValueLabel.text = cell.controlValue
        if attribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false {
            cell.editButton.isHidden = false
        } else {
            cell.editButton.isHidden = true
        }
        if let data_type = attribute.dataType {
            cell.dataType = data_type
        }
        cell.device = device
        cell.attribute = attribute
        if let attributeName = attribute.name {
            cell.attributeKey = attributeName
        }
        cell.attribute = attribute
        return cell
    }

    func getTableViewCellBasedOn(dynamicAttribute: Param, indexPath: IndexPath) -> UITableViewCell {
        if dynamicAttribute.uiType == "esp.ui.slider" {
            if let dataType = dynamicAttribute.dataType?.lowercased(), dataType == "int" || dataType == "float" {
                if let bounds = dynamicAttribute.bounds {
                    let maxValue = bounds["max"] as? Float ?? 100
                    let minValue = bounds["min"] as? Float ?? 0
                    if minValue < maxValue {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "GenericSliderTableViewCell", for: indexPath) as! GenericSliderTableViewCell
                        cell.delegate = self
                        if let bounds = dynamicAttribute.bounds {
                            cell.slider.minimumValue = bounds["min"] as? Float ?? 0
                            cell.slider.maximumValue = bounds["max"] as? Float ?? 100
                        }
                        if dynamicAttribute.dataType!.lowercased() == "int" {
                            let value = Int(dynamicAttribute.value as? Float ?? 100)
                            cell.minLabel.text = "\(Int(cell.slider.minimumValue))"
                            cell.maxLabel.text = "\(Int(cell.slider.maximumValue))"
                            cell.slider.value = Float(value)
                        } else {
                            cell.minLabel.text = "\(cell.slider.minimumValue)"
                            cell.maxLabel.text = "\(cell.slider.maximumValue)"
                            cell.slider.value = dynamicAttribute.value as? Float ?? 100
                        }
                        cell.device = device
                        cell.dataType = dynamicAttribute.dataType
                        if let attributeName = dynamicAttribute.name {
                            cell.paramName = attributeName
                        }
                        if dynamicAttribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false || device!.node?.localNetwork ?? false {
                            cell.slider.isEnabled = true
                        } else {
                            cell.slider.isEnabled = false
                        }
                        cell.title.text = dynamicAttribute.name ?? ""
                        return cell
                    }
                }
            }
        } else if dynamicAttribute.uiType == "esp.ui.toggle", dynamicAttribute.dataType?.lowercased() == "bool" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell", for: indexPath) as! SwitchTableViewCell
            cell.delegate = self
            cell.controlName.text = dynamicAttribute.name?.deletingPrefix(device!.name!)
            cell.device = device
            cell.param = dynamicAttribute
            if let attributeName = dynamicAttribute.name {
                cell.attributeKey = attributeName
            }
            if let switchState = dynamicAttribute.value as? Bool {
                if switchState {
                    cell.controlStateLabel.text = "On"
                } else {
                    cell.controlStateLabel.text = "Off"
                }
                cell.toggleSwitch.setOn(switchState, animated: true)
            }
            if dynamicAttribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false || device!.node?.localNetwork ?? false {
                cell.toggleSwitch.isEnabled = true
            } else {
                cell.toggleSwitch.isEnabled = false
            }

            return cell
        }

        return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == Constants.nodeDetailSegue {
            let destination = segue.destination as! NodeDetailsViewController
            if let i = User.shared.associatedNodeList!.firstIndex(where: { $0.node_id == self.device?.node?.node_id }) {
                destination.currentNode = User.shared.associatedNodeList![i]
            }
        }
    }
}

extension DeviceTraitListViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 40.0
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeaderView = SectionHeaderView.instanceFromNib()
        if section >= device?.params?.count ?? 0 {
            let staticControl = device?.attributes![section - (device?.params?.count ?? 0)]
            sectionHeaderView.sectionTitle.text = staticControl?.name!.deletingPrefix(device!.name!)
        } else {
            let control = device?.params![section]
            sectionHeaderView.sectionTitle.text = control?.name!.deletingPrefix(device!.name!)
        }
        return sectionHeaderView
    }
}

extension DeviceTraitListViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func numberOfSections(in _: UITableView) -> Int {
        return (device?.params?.count ?? 0) + (device?.attributes?.count ?? 0)
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var paramCell: UITableViewCell!
        if indexPath.section >= device?.params?.count ?? 0 {
            let staticControl = device?.attributes![indexPath.section - (device?.params?.count ?? 0)]
            let cell = tableView.dequeueReusableCell(withIdentifier: "staticControlTableViewCell", for: indexPath) as! StaticControlTableViewCell
            cell.controlNameLabel.text = staticControl?.name ?? ""
            cell.controlValueLabel.text = staticControl?.value as? String ?? ""
            paramCell = cell as UITableViewCell
        } else {
            let control = device?.params![indexPath.section]
            paramCell = getTableViewCellBasedOn(dynamicAttribute: control!, indexPath: indexPath)
        }

        if device?.isReachable() ?? false {
            paramCell.isUserInteractionEnabled = true
        } else {
            paramCell.isUserInteractionEnabled = false
        }
        return paramCell
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
        return UINib(nibName: "ControlSectionHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! SectionHeaderView
    }
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count + 1))
    }
}
