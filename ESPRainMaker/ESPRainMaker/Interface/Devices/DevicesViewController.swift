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
import AWSAuthCore
import AWSCognitoIdentityProvider
import Foundation
import JWTDecode
import MBProgressHUD
import UIKit

class DevicesViewController: UIViewController {
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var addButton: UIButton!
    @IBOutlet var initialView: UIView!
    @IBOutlet var emptyListIcon: UIImageView!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var networkIndicator: UIView!
    @IBOutlet var loadingIndicator: SpinnerView!

    let controlStoryBoard = UIStoryboard(name: "DeviceDetail", bundle: nil)
    private let refreshControl = UIRefreshControl()

    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    var checkDeviceAssociation = false
    var deviceID: String?
    var requestID: String?
    var singleDeviceNodeCount = 0
    var flag = false

    override func viewDidLoad() {
        super.viewDidLoad()

        _ = User.shared.currentUser()
        pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        if user == nil {
            user = pool?.currentUser()
        }

        if (UserDefaults.standard.value(forKey: Constants.userInfoKey) as? [String: Any]) != nil {
            collectionView.isUserInteractionEnabled = false
            collectionView.isHidden = false
            User.shared.associatedNodeList = ESPLocalStorage.shared.fetchNodeDetails()
            refreshDeviceList()
        } else {
            refresh()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(updateUIView), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)

        refreshControl.addTarget(self, action: #selector(refreshDeviceList), for: .valueChanged)
        refreshControl.tintColor = .clear
        collectionView.refreshControl = refreshControl
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        checkNetworkUpdate()
        getSingleDeviceNodeCount()
        collectionView.reloadData()

        if User.shared.updateUserInfo {
            User.shared.updateUserInfo = false
            updateUserInfo()
        }

        if (UserDefaults.standard.value(forKey: Constants.userInfoKey) as? [String: Any]) != nil {
            if User.shared.updateDeviceList {
                refreshDeviceList()
            }
        }

        setViewForNoNodes()
        flag = false
    }

    func getUserInfo(token: String, provider: ServiceProvider) {
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
        refreshDeviceList()
    }

    func setViewForNoNodes() {
        if User.shared.associatedNodeList?.count == 0 || User.shared.associatedNodeList == nil {
            infoLabel.text = "No Device Added"
            emptyListIcon.image = UIImage(named: "no_device_icon")
            infoLabel.textColor = .black
            initialView.isHidden = false
            collectionView.isHidden = true
            addButton.isHidden = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addButton.setImage(UIImage(named: "add_icon"), for: .normal)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(Constants.networkUpdateNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(Constants.localNetworkUpdateNotification), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        if Configuration.shared.appConfiguration.supportSchedule {
            tabBarController?.tabBar.isHidden = false
        }

        NotificationCenter.default.addObserver(self, selector: #selector(checkNetworkUpdate), name: Notification.Name(Constants.networkUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(localNetworkUpdate), name: Notification.Name(Constants.localNetworkUpdateNotification), object: nil)
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
        getSingleDeviceNodeCount()
        collectionView.reloadData()
    }

    func refresh() {
        user?.getDetails().continueOnSuccessWith { (_) -> AnyObject? in
            DispatchQueue.main.async {
                self.updateUserInfo()
            }
            return nil
        }
    }

    func updateUserInfo() {
        User.shared.getcognitoIdToken { idToken in
            if idToken != nil {
                self.getUserInfo(token: idToken!, provider: .cognito)
            } else {
                Utility.hideLoader(view: self.view)
                self.refreshDeviceList()
            }
        }
    }

    @IBAction func refreshClicked(_: Any) {
        refreshDeviceList()
    }

    func showLoader() {
        loadingIndicator.isHidden = false
        loadingIndicator.animate()
    }

    @objc func updateUIView() {
        for subview in view.subviews {
            subview.setNeedsDisplay()
        }
    }

    @objc func refreshDeviceList() {
        showLoader()
        refreshControl.endRefreshing()
        collectionView.isUserInteractionEnabled = false
        User.shared.updateDeviceList = false

        NetworkManager.shared.getNodes { nodes, error in
            DispatchQueue.main.async {
                self.loadingIndicator.isHidden = true
                User.shared.associatedNodeList = nil
                if error != nil {
                    self.unhideInitialView(error: error)
                    if Configuration.shared.appConfiguration.supportLocalControl {
                        User.shared.startServiceDiscovery()
                    }
                    self.collectionView.isUserInteractionEnabled = true
                    return
                }
                User.shared.associatedNodeList = nodes

                // Start local discovery if its enabled
                if Configuration.shared.appConfiguration.supportLocalControl {
                    User.shared.startServiceDiscovery()
                }

                if nodes == nil || nodes?.count == 0 {
                    self.setViewForNoNodes()
                } else {
                    self.initialView.isHidden = true
                    self.collectionView.isHidden = false
                    self.addButton.isHidden = false
                    self.getSingleDeviceNodeCount()
                    self.collectionView.reloadData()
                }
                self.collectionView.isUserInteractionEnabled = true
            }
        }
    }

    private func getSingleDeviceNodeCount() {
        singleDeviceNodeCount = 0
        if let nodeList = User.shared.associatedNodeList {
            for item in nodeList {
                if item.devices?.count == 1 {
                    singleDeviceNodeCount += 1
                }
            }
        }
    }

    func unhideInitialView(error: ESPNetworkError?) {
        User.shared.associatedNodeList = ESPLocalStorage.shared.fetchNodeDetails()
        if User.shared.associatedNodeList?.count == 0 || User.shared.associatedNodeList == nil {
            infoLabel.text = "No devices to show\n" + (error?.description ?? "Something went wrong!!")
            emptyListIcon.image = UIImage(named: "api_error_icon")
            infoLabel.textColor = .red
            initialView.isHidden = false
            collectionView.isHidden = true
            addButton.isHidden = true
        } else {
            getSingleDeviceNodeCount()
            collectionView.reloadData()
            initialView.isHidden = true
            collectionView.isHidden = false
            addButton.isHidden = false
            Utility.showToastMessage(view: view, message: "Network error: \(error?.description ?? "Something went wrong!!")")
        }
    }

    func preparePopover(contentController: UIViewController,
                        sender: UIView,
                        delegate: UIPopoverPresentationControllerDelegate?) {
        contentController.modalPresentationStyle = .popover
        contentController.popoverPresentationController!.sourceView = sender
        contentController.popoverPresentationController!.sourceRect = sender.bounds
        contentController.preferredContentSize = CGSize(width: 182.0, height: 112.0)
        contentController.popoverPresentationController!.delegate = delegate
    }

    func getDeviceAt(indexPath: IndexPath) -> Device {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return User.shared.associatedNodeList![indexPath.row].devices![0]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return User.shared.associatedNodeList![index].devices![indexPath.row]
    }

    func getNodeAt(indexPath: IndexPath) -> Node {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return User.shared.associatedNodeList![indexPath.section]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return User.shared.associatedNodeList![index]
    }

    override func prepare(for _: UIStoryboardSegue, sender _: Any?) {
        tabBarController?.tabBar.isHidden = true
    }
}

extension DevicesViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if flag {
            return
        }
        flag = true
        Utility.showLoader(message: "", view: view)
        let currentDevice = getDeviceAt(indexPath: indexPath)
        let deviceTraitsVC = controlStoryBoard.instantiateViewController(withIdentifier: Constants.deviceTraitListVCIdentifier) as! DeviceTraitListViewController
        deviceTraitsVC.device = currentDevice

        Utility.hideLoader(view: view)
        navigationController?.pushViewController(deviceTraitsVC, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0, singleDeviceNodeCount > 0 {
            return CGSize(width: 0, height: 68.0)
        }
        return CGSize(width: collectionView.bounds.width, height: 68.0)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForFooterInSection _: Int) -> CGSize {
        return CGSize(width: 0, height: 0)
    }
}

extension DevicesViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var index = section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return singleDeviceNodeCount
            }
            index = index + singleDeviceNodeCount - 1
        }
        return User.shared.associatedNodeList![index].devices?.count ?? 0
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        let count = User.shared.associatedNodeList?.count ?? 0
        if count == 0 {
            return count
        }
        if singleDeviceNodeCount > 0 {
            return count - singleDeviceNodeCount + 1
        }
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "deviceCollectionViewCell", for: indexPath) as! DevicesCollectionViewCell
        cell.refresh()
        let device = getDeviceAt(indexPath: indexPath)
        cell.deviceName.text = device.getDeviceName()
        cell.device = device
        cell.switchButton.isHidden = true
        cell.primaryValue.isHidden = true

        cell.layer.backgroundColor = UIColor.white.cgColor
        cell.layer.shadowColor = UIColor.lightGray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        cell.layer.shadowRadius = 0.5
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false

        if device.node?.localNetwork ?? false {
            cell.statusView.isHidden = false
        } else if device.node?.isConnected ?? false {
            cell.statusView.isHidden = true
        } else {
            cell.statusView.isHidden = false
        }

        cell.offlineLabel.text = device.node?.getNodeStatus() ?? ""

        var primaryKeyFound = false

        if let primary = device.primary {
            if let primaryParam = device.params?.first(where: { param -> Bool in
                param.name == primary
            }) {
                primaryKeyFound = true
                if primaryParam.dataType?.lowercased() == "bool" {
                    if device.isReachable(), primaryParam.properties?.contains("write") ?? false {
                        cell.switchButton.alpha = 1.0
                        cell.switchButton.backgroundColor = UIColor.white
                        cell.switchButton.isEnabled = true
                        cell.switchButton.isHidden = false
                        cell.switchButton.setImage(UIImage(named: "switch_icon_enabled_off"), for: .normal)
                        if let value = primaryParam.value as? Bool {
                            if value {
                                cell.switchButton.setImage(UIImage(named: "switch_icon_enabled_on"), for: .normal)
                                cell.switchValue = true
                            }
                        }
                    } else {
                        cell.switchButton.isHidden = false
                        cell.switchButton.isEnabled = false
                        cell.switchButton.backgroundColor = UIColor(hexString: "#E5E5E5")
                        cell.switchButton.alpha = 0.4
                        cell.switchButton.setImage(UIImage(named: "switch_icon_disabled"), for: .normal)
                    }
                } else if primaryParam.dataType?.lowercased() == "string" {
                    cell.switchButton.isHidden = true
                    cell.primaryValue.text = primaryParam.value as? String ?? ""
                    cell.primaryValue.isHidden = false
                } else {
                    cell.switchButton.isHidden = true
                    if let value = primaryParam.value {
                        cell.primaryValue.text = "\(value)"
                        cell.primaryValue.isHidden = false
                    }
                }
            }
            if !primaryKeyFound {
                if let staticParams = device.attributes {
                    for item in staticParams {
                        if item.name == primary {
                            if let value = item.value as? String {
                                primaryKeyFound = true
                                cell.primaryValue.text = value
                                cell.primaryValue.isHidden = false
                            }
                        }
                    }
                }
            }
        }

        if let deviceType = device.type {
            var deviceImage: UIImage!
            switch deviceType {
            case "esp.device.switch":
                deviceImage = UIImage(named: "switch_device_icon")
            case "esp.device.lightbulb":
                deviceImage = UIImage(named: "light_bulb_icon")
            case "esp.device.fan":
                deviceImage = UIImage(named: "fan_icon")
            case "esp.device.thermostat":
                deviceImage = UIImage(named: "thermostat_icon")
            case "esp.device.temperature-sensor":
                deviceImage = UIImage(named: "temperature_sensor_icon")
            case "esp.device.lock":
                deviceImage = UIImage(named: "lock_icon")
            case "esp.device.sensor":
                deviceImage = UIImage(named: "sensor_icon")
            default:
                deviceImage = UIImage(named: "dummy_device_icon")
            }
            cell.deviceImageView.image = deviceImage
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "deviceListCollectionReusableView", for: indexPath) as! DeviceListCollectionReusableView
        let node = getNodeAt(indexPath: indexPath)
        if singleDeviceNodeCount > 0 {
            if indexPath.section == 0 {
                headerView.headerLabel.isHidden = true
                headerView.infoButton.isHidden = true
                headerView.statusIndicator.isHidden = true
                return headerView
            }
        }
        headerView.headerLabel.isHidden = false
        headerView.infoButton.isHidden = false
        headerView.statusIndicator.isHidden = false
        headerView.headerLabel.text = node.info?.name ?? "Node"
        headerView.delegate = self
        headerView.nodeID = node.node_id ?? ""
        if node.isConnected {
            headerView.statusIndicator.backgroundColor = UIColor.green
        } else {
            headerView.statusIndicator.backgroundColor = UIColor.lightGray
        }
        return headerView
    }
}

extension DevicesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width
        var cellWidth: CGFloat = 0
        if width > 450 {
            cellWidth = (width - 60) / 3.0
        } else {
            cellWidth = (width - 30) / 2.0
        }
        return CGSize(width: cellWidth, height: 110.0)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        if UIScreen.main.bounds.width > 450 {
            return 15.0
        }
        return 10.0
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

extension DevicesViewController: DeviceListHeaderProtocol {
    func deviceInfoClicked(nodeID: String) {
        if let node = User.shared.associatedNodeList?.first(where: { item -> Bool in
            item.node_id == nodeID
        }) {
            let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
            let destination = deviceStoryboard.instantiateViewController(withIdentifier: "nodeDetailsVC") as! NodeDetailsViewController
            destination.currentNode = node
            navigationController?.pushViewController(destination, animated: true)
        }
    }
}
