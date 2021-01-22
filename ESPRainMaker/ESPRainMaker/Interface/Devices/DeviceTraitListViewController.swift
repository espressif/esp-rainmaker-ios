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
        tableView.register(UINib(nibName: "SliderTableViewCell", bundle: nil), forCellReuseIdentifier: "SliderTableViewCell")
        tableView.register(UINib(nibName: "StaticControlTableViewCell", bundle: nil), forCellReuseIdentifier: "staticControlTableViewCell")
        tableView.register(UINib(nibName: "GenericControlTableViewCell", bundle: nil), forCellReuseIdentifier: "genericControlCell")
        tableView.register(UINib(nibName: "DropDownTableViewCell", bundle: nil), forCellReuseIdentifier: "dropDownTableViewCell")
        tableView.register(ParamSwitchTableViewCell.self, forCellReuseIdentifier: "switchParamTableViewCell")

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
        let genericCell = tableView.dequeueReusableCell(withIdentifier: "genericControlCell", for: indexPath) as! GenericControlTableViewCell
        object_setClass(genericCell, GenericParamTableViewCell.self)
        let cell = genericCell as! GenericParamTableViewCell
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
        cell.param = attribute
        if let attributeName = attribute.name {
            cell.attributeKey = attributeName
        }
        return cell
    }

    func getTableViewCellBasedOn(dynamicAttribute: Param, indexPath: IndexPath) -> UITableViewCell {
        if dynamicAttribute.uiType == "esp.ui.slider" {
            if let dataType = dynamicAttribute.dataType?.lowercased(), dataType == "int" || dataType == "float" {
                if let bounds = dynamicAttribute.bounds {
                    let maxValue = bounds["max"] as? Float ?? 100
                    let minValue = bounds["min"] as? Float ?? 0
                    if minValue < maxValue {
                        let sliderCell = tableView.dequeueReusableCell(withIdentifier: "SliderTableViewCell", for: indexPath) as! SliderTableViewCell
                        object_setClass(sliderCell, ParamSliderTableViewCell.self)
                        let cell = sliderCell as! ParamSliderTableViewCell

                        cell.delegate = self
                        cell.hueSlider.isHidden = true
                        cell.slider.isHidden = false
                        cell.param = dynamicAttribute
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
            let switchCell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell", for: indexPath) as! SwitchTableViewCell
            object_setClass(switchCell, ParamSwitchTableViewCell.self)
            let cell = switchCell as! ParamSwitchTableViewCell
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
        } else if dynamicAttribute.uiType == "esp.ui.hue-slider" {
            var minValue = 0
            var maxValue = 360
            if let bounds = dynamicAttribute.bounds {
                minValue = bounds["min"] as? Int ?? 0
                maxValue = bounds["max"] as? Int ?? 360
            }

            let sliderCell = tableView.dequeueReusableCell(withIdentifier: "SliderTableViewCell", for: indexPath) as! SliderTableViewCell
            object_setClass(sliderCell, ParamSliderTableViewCell.self)
            let cell = sliderCell as! ParamSliderTableViewCell
            cell.delegate = self
            cell.param = dynamicAttribute
            cell.slider.isHidden = true
            cell.hueSlider.isHidden = false

            cell.hueSlider.minimumValue = CGFloat(minValue)
            cell.hueSlider.maximumValue = CGFloat(maxValue)

            if minValue == 0 && maxValue == 360 {
                cell.hueSlider.hasRainbow = true
                cell.hueSlider.setGradientVaryingHue(saturation: 1.0, brightness: 1.0)
            } else {
                cell.hueSlider.hasRainbow = false
                cell.hueSlider.minColor = UIColor(hue: CGFloat(minValue / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
                cell.hueSlider.maxColor = UIColor(hue: CGFloat(maxValue / 360), saturation: 1.0, brightness: 1.0, alpha: 1.0)
            }

            let value = CGFloat(dynamicAttribute.value as? Int ?? 0)
            cell.hueSlider.value = CGFloat(value)
            cell.minLabel.text = "\(minValue)"
            cell.maxLabel.text = "\(maxValue)"
            cell.hueSlider.thumbColor = UIColor(hue: value / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            cell.device = device
            cell.dataType = dynamicAttribute.dataType
            if let attributeName = dynamicAttribute.name {
                cell.paramName = attributeName
            }
            if dynamicAttribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false || device!.node?.localNetwork ?? false {
                cell.hueSlider.isEnabled = true
            } else {
                cell.hueSlider.isEnabled = false
            }
            cell.title.text = dynamicAttribute.name ?? ""

            return cell
        } else if dynamicAttribute.uiType == "esp.ui.dropdown" {
            if let dataType = dynamicAttribute.dataType?.lowercased(), dataType == "int" || dataType == "string" {
                let dropDownCell = tableView.dequeueReusableCell(withIdentifier: "dropDownTableViewCell", for: indexPath) as! DropDownTableViewCell
                object_setClass(dropDownCell, ParamDropDownTableViewCell.self)
                let cell = dropDownCell as! ParamDropDownTableViewCell
                cell.controlName.text = dynamicAttribute.name?.deletingPrefix(device!.name!)
                cell.device = device
                cell.param = dynamicAttribute
                cell.delegate = self

                var currentValue = ""
                if dataType == "string" {
                    currentValue = dynamicAttribute.value as! String
                } else {
                    currentValue = String(dynamicAttribute.value as! Int)
                }
                cell.controlValueLabel.text = currentValue
                cell.currentValue = currentValue

                if dynamicAttribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false {
                    cell.dropDownButton.isHidden = false
                    var datasource: [String] = []
                    if dataType == "int" {
                        guard let bounds = dynamicAttribute.bounds, let max = bounds["max"] as? Int, let min = bounds["min"] as? Int, let step = bounds["step"] as? Int, max > min else {
                            return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
                        }
                        for item in stride(from: min, to: max + 1, by: step) {
                            datasource.append(String(item))
                        }
                    } else if dynamicAttribute.dataType?.lowercased() == "string" {
                        datasource.append(contentsOf: dynamicAttribute.valid_strs ?? [])
                    }
                    cell.datasource = datasource
                } else {
                    cell.dropDownButton.isHidden = true
                }

                if !cell.datasource.contains(currentValue) {
                    cell.controlValueLabel.text = currentValue + " (Invalid)"
                }
                return cell
            }
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
