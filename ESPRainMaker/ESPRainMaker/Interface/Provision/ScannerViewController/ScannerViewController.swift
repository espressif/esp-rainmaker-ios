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
//  ScannerViewController.swift
//  ESPRainMaker
//
//  Created by Vikas Chandra on 26/11/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import AVFoundation
import CoreLocation
import ESPProvision
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import UIKit
import CoreBluetooth

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    let locationManager = CLLocationManager()
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet var scannerView: UIView!
    @IBOutlet var noCameraView: UIView!
    @IBOutlet var manualActionButton: UIButton!
    var onboardingPayload: String?
    var group: ESPNodeGroup?
    var groupId: String?
    let fabricDetails = ESPMatterFabricDetails.shared
    var bluetoothManager: CBCentralManager?
    var bluetoothOnStatusCompletion: ((CBManagerState) -> Void)?
    
    var threadOperationalDataset: Data!
    var espDevice: ESPDevice!
    var provisionCompletionHandler: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Check for device type to ask for location permission
        // Location permission is needed to get SSID of connected Wi-Fi network.
        
        self.setupScanningScreen()
        if self.isBluetoothRequired() {
            self.checkCBAndProceed {}
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = scannerView.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func appEnterForeground() {
        if self.isBluetoothRequired() {
            if let bleManager = self.bluetoothManager {
                let cbStatus = bleManager.state
                switch cbStatus {
                case .poweredOff, .unauthorized:
                    self.handleCBPermissionError(cbStatus: cbStatus)
                default:
                    self.setupScanningScreen()
                }
            }
        }
    }
    
    func setupScanningScreen() {
        DispatchQueue.main.async {
            self.dismissDisplayedAlert()
            switch Configuration.shared.espProvSetting.transport {
            case .both, .softAp:
                self.getLocationPermission()
            default:
                break
            }
            self.scanQrCode()
            
            Utility.setActiveSSID()
        }
    }

    func scanQrCode() {
        ESPProvisionManager.shared.scanQRCode(scanView: self.scannerView) { espDevice, scanError in
            if let device = espDevice {
                if self.isDeviceSupported(device: device) {
                    Utility.showLoader(message: "Connecting to device", view: self.view)
                    switch device.transport {
                        case .ble:
                            self.connectDevice(espDevice: device)
                        case .softap:
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.connectDevice(espDevice: device)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.retry(message: "Device type not supported. Please choose another device and try again.")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    if let error = scanError {
                        switch error {
                        case .cameraAccessDenied:
                            self.noCameraView.isHidden = false
                        case .espDeviceNotFound, .softApSearchNotSupported:
                            self.retry(message: error.description)
                        case .invalidQRCode(let code):
                            Utility.hideLoader(view: self.view)
                            if code.hasPrefix(ESPMatterConstants.matterPrefix) {
                                #if ESPRainMakerMatter
                                if #available(iOS 16.4, *) {
                                    NodeGroupManager.shared.getNodeGroups { nodeGroups, _ in
                                        if let groups = nodeGroups, groups.count > 0 {
                                            self.goToFabricSelection(onboardingPayload: code)
                                        } else {
                                            self.onboardingPayload = code
                                            self.createMatterFabric(groupName: "Home")
                                        }
                                    }
                                } else {
                                    self.alertUser(title: ESPMatterConstants.warning,
                                                   message: ESPMatterConstants.upgradeOSVersionMsg,
                                                   buttonTitle: ESPMatterConstants.okTxt,
                                                   callback: {
                                        self.navigationController?.popToRootViewController(animated: false)
                                    })
                                }
                                #else
                                self.alertUser(title: ESPMatterConstants.warning,
                                               message: ESPMatterConstants.matterNotSupportedMsg,
                                               buttonTitle: ESPMatterConstants.okTxt,
                                               callback: {
                                    self.navigationController?.popToRootViewController(animated: false)
                                })
                                #endif
                            } else {
                                self.retry(message: error.description)
                            }
                            break
                        case .videoInputError, .videoOutputError, .cameraNotAvailable, .avCaptureDeviceInputError:
                            self.showAlertWith(message: "Unable to scan QR code. Something went wrong while processing camera input.")
                        }
                    }
                }
            }
        } scanStatus: { status in
            switch status {
            case .readingCode:
                Utility.showLoader(message: "Reading QR code", view: self.view)
            case .searchingBLE(let device):
                Utility.showLoader(message: "Searching BLE device: \(device)", view: self.view)
            case .joiningSoftAP(let device):
                Utility.showLoader(message: "Joining network: \(device)", view: self.view)
            default:
                break
            }
        }
    }

    func connectDevice(espDevice: ESPDevice) {
        espDevice.connect(delegate: self) { status in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                switch status {
                case .connected:
                    self.checkForAssistedClaiming(device: espDevice)
                default:
                    self.retry(message: "Device could not be connected. Please try again")
                }
            }
        }
    }

    @IBAction func goToSettings(_: Any) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { _ in
            })
        }
    }

    func checkForAssistedClaiming(device: ESPDevice) {
        if let versionInfo = device.versionInfo, let rmaikerInfo = versionInfo[ESPScanConstants.prov] as? NSDictionary, let rainmakerCaps = rmaikerInfo[ESPScanConstants.capabilities] as? [String] {
            
            if rainmakerCaps.contains(ESPScanConstants.claim) {
                if device.transport == .ble {
                    DispatchQueue.main.async {
                        self.goToClaimVC(device: device)
                    }
                } else {
                    self.showErrorAlert(title: "", message: "Assisted Claiming not supported for SoftAP. Cannot Proceed.", buttonTitle: "OK") {}
                }
                return
            } else if rainmakerCaps.contains(ESPScanConstants.threadProv) {
                let shouldScanThreadNetworks = rainmakerCaps.contains(ESPScanConstants.threadScan)
                if #available(iOS 16.4, *) {
                    self.espDevice = device
                    self.espDevice.network = .thread
                    self.provisionDeviceWithThreadNetwork(device: self.espDevice) {
                        DispatchQueue.main.async {
                            self.showThreadNetworkSelectionVC(shouldScanThreadNetworks: shouldScanThreadNetworks, device: self.espDevice)
                        }
                    }
                }
                return
            }
        }
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            self.goToProvision(device: device)
        }
    }

    @IBAction func cancelClickecd(_: Any) {
        navigationController?.popToRootViewController(animated: false)
    }

    @IBAction func selectManualProvisioning(_: Any) {
        switch Configuration.shared.espProvSetting.transport {
        case .ble:
            goToBleProvision()
        case .softAp:
            goToSoftAPProvision()
        default:
            let actionSheet = UIAlertController(title: "", message: "Choose Provisioning Transport", preferredStyle: .actionSheet)
            let bleAction = UIAlertAction(title: "BLE", style: .default) { _ in
                self.goToBleProvision()
            }
            let softapAction = UIAlertAction(title: "SoftAP", style: .default) { _ in
                self.goToSoftAPProvision()
            }
            actionSheet.addAction(bleAction)
            actionSheet.addAction(softapAction)
            #if ESPRainMakerMatter
            let mtrCommAction = UIAlertAction(title: "Matter", style: .default) { _ in
                if #available(iOS 16.4, *) {
                    NodeGroupManager.shared.getNodeGroups { nodeGroups, _ in
                        if let groups = nodeGroups, groups.count > 0 {
                            self.goToFabricSelection(onboardingPayload: nil)
                        } else {
                            self.onboardingPayload = nil
                            self.createMatterFabric(groupName: "Home")
                        }
                    }
                } else {
                    self.alertUser(title: ESPMatterConstants.warning,
                                   message: ESPMatterConstants.upgradeOSVersionMsg,
                                   buttonTitle: ESPMatterConstants.okTxt,
                                   callback: {
                        self.navigationController?.popToRootViewController(animated: false)
                    })
                }
            }
            actionSheet.addAction(mtrCommAction)
            #endif
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            actionSheet.popoverPresentationController?.sourceView = manualActionButton
            present(actionSheet, animated: true, completion: nil)
        }
    }

    func retry(message: String) {
        Utility.hideLoader(view: view)
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
            DispatchQueue.main.async {
                self.scanQrCode()
            }
        }))
        present(alertController, animated: true, completion: nil)
    }

    func goToClaimVC(device: ESPDevice) {
        let claimVC = storyboard?.instantiateViewController(withIdentifier: Constants.claimVCIdentifier) as! ClaimViewController
        claimVC.device = device
        navigationController?.pushViewController(claimVC, animated: true)
    }

    func goToBleProvision() {
        let bleLandingVC = storyboard?.instantiateViewController(withIdentifier: "bleLandingVC") as! BLELandingViewController
        navigationController?.pushViewController(bleLandingVC, animated: true)
    }

    func goToSoftAPProvision() {
        let bleLandingVC = storyboard?.instantiateViewController(withIdentifier: "provisionLanding") as! ProvisionLandingViewController
        navigationController?.pushViewController(bleLandingVC, animated: true)
    }
    
    #if ESPRainMakerMatter
    @available(iOS 16.4, *)
    /// Check if BLE is on and authorized
    /// - Parameter onboardingPayload: onboarding payload
    func goToFabricSelection(onboardingPayload: String? =  nil) {
        self.openFabricSelectionVC(withOnboardingPayload: onboardingPayload)
    }
    
    /// Open Fabric selection screen
    /// - Parameter onboardingPayload: on boarding poayload
    @available(iOS 16.4, *)
    func openFabricSelectionVC(withOnboardingPayload onboardingPayload: String?) {
        let storyBrd = UIStoryboard(name: ESPMatterConstants.matterStoryboardId, bundle: nil)
        let fabricSelectionVC = storyBrd.instantiateViewController(withIdentifier: ESPFabricSelectionVC.storyboardId) as! ESPFabricSelectionVC
        fabricSelectionVC.onboardingPayload = onboardingPayload
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.pushViewController(fabricSelectionVC, animated: true)
    }
    #endif
    
    // Helper method to check whether app supports the scanned device.
    private func isDeviceSupported(device: ESPDevice) -> Bool {
        switch Configuration.shared.espProvSetting.transport {
        case .both:
            return true
        case .softAp:
            if device.transport == .softap {
                return true
            }
        case .ble:
            if device.transport == .ble {
                return true
            }
        }
        return false
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
    func showAlertWith(message: String = "") {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func getLocationPermission() {
        let locStatus = CLLocationManager.authorizationStatus()
        switch locStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return
        case .denied, .restricted:
            let alert = UIAlertController(title: "Location Services are disabled", message: "Please enable Location Services in your Settings", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        case .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            break
        }
    }
}

extension ScannerViewController: DeviceAssociationProtocol {
    
    @available(iOS 15.0, *)
    func provisionDeviceWithThreadNetwork(device: ESPDevice, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            Utility.showLoader(message: "Sending association data", view: self.view)
        }
        self.provisionCompletionHandler = completion
        User.shared.associateNodeWithUser(device: device, delegate: self)
    }
    
    func deviceAssociationFinishedWith(success: Bool, nodeID: String?, error: AssociationError?) {
        User.shared.currentAssociationInfo!.associationInfoDelievered = success
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            if success {
                if let deviceSecret = nodeID {
                    User.shared.currentAssociationInfo!.nodeID = deviceSecret
                }
                if let completion = self.provisionCompletionHandler {
                    completion()
                } else {
                    self.showThreadNetworkSelectionVC(device: self.espDevice)
                }
            } else {
                let alertController = UIAlertController(title: "Error", message: error?.description, preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default) { _ in
                    self.navigationController?.popToRootViewController(animated: false)
                }
                alertController.addAction(action)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}


extension ScannerViewController: ESPDeviceConnectionDelegate {
    
    func getUsername(forDevice: ESPDevice, completionHandler: @escaping (String?) -> Void) {
        if let caps = forDevice.capabilities, (caps.contains(ESPScanConstants.threadProv) || caps.contains(ESPScanConstants.threadScan)) {
            completionHandler(Configuration.shared.espProvSetting.threadSec2Username)
        } else {
            completionHandler(Configuration.shared.espProvSetting.wifiSec2Username)
        }
    }
    
    func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
        completionHandler("")
    }
}

#if ESPRainMakerMatter
@available(iOS 16.4, *)
extension ScannerViewController: ESPCreateMatterFabricPresentationLogic {
    
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
                self.getMatterFabrics()
            }
            return
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
extension ScannerViewController: ESPGetNodeGroupsPresentationLogic {
    
    /// Received node groups data
    /// - Parameters:
    ///   - data: groups data
    ///   - error: error
    func receivedNodeGroupsData(data: ESPNodeGroups?, error: Error?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
        }
        if let data = data, let groups = data.groups, groups.count > 0 {
            self.fabricDetails.saveGroupsData(groups: data)
            DispatchQueue.main.async {
                self.goToMatterCommissioning()
            }
        } else {
            self.showErrorAlert(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.scannErrorMsg, buttonTitle: ESPMatterConstants.okTxt, callback: {})
        }
    }
    
    /// Received node groups details
    /// - Parameters:
    ///   - data: node group details
    ///   - error: error
    func receivedNodeGroupDetailsData(data: ESPNodeGroupDetails?, error: Error?) {}
    
    /// Go to matter commissioning
    func goToMatterCommissioning() {
        let storyBrd = UIStoryboard(name: ESPMatterConstants.matterStoryboardId, bundle: nil)
        let matterCommissioningVC = storyBrd.instantiateViewController(withIdentifier: ESPMatterCommissioningVC.storyboardId) as! ESPMatterCommissioningVC
        matterCommissioningVC.groupId = self.groupId
        matterCommissioningVC.onboardingPayload = self.onboardingPayload
        if let data = self.fabricDetails.getGroupsData(), let groups = data.groups, groups.count > 0 {
            for grp in groups {
                if let id = grp.groupID, let groupId = self.groupId, id == groupId {
                    matterCommissioningVC.group = grp
                    navigationController?.pushViewController(matterCommissioningVC, animated: true)
                    break
                }
            }
        }
    }
}
#endif
