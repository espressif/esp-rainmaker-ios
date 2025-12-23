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
//  ESPMatterCommissioningVC.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import UIKit
import MatterSupport
import Matter
import Foundation

@available(iOS 16.4, *)
class ESPMatterCommissioningVC: UIViewController {

    static let storyboardId = "ESPMatterCommissioningVC"
    let csrQueue = DispatchQueue(label: "com.matterqueue.generate.csr")
    var groupId: String?
    var group: ESPNodeGroup?
    var matterNodeId: String?
    var nodes: [ESPNodeDetails]?
    var onboardingPayload: String?
    let fabricDetails = ESPMatterFabricDetails.shared
    private let commissionedNodeSyncService = ESPCommissionedNodeSyncService()
    let paramTypes = [Constants.scanQRCode,
                 Constants.slider,
                 Constants.hue,
                 Constants.toggle,
                 Constants.hueCircle,
                 Constants.bigSwitch,
                 Constants.dropdown,
                 Constants.trigger,
                 Constants.hidden]
    
    @IBOutlet weak var topBarTitle: BarTitle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.topBarTitle.text = ESPMatterConstants.commissioning
        self.issueUserNOC()
    }
    
    /// Back pressed by user
    /// - Parameter sender: button
    @IBAction func backButtonPressed(_ sender: Any) {
        DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    /// Issue user NOC
    func issueUserNOC() {
        if let group = group, let groupId = group.groupID {
            guard let _ = self.fabricDetails.getUserNOCDetails(groupId: groupId) else {
                Utility.showLoader(message: "Issuing user NOC...", view: self.view)
                var finalCSRString = ""
                self.csrQueue.async {
                    let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
                    commissioner.generateCSR(groupId: groupId) { csr in
                        if let csr = csr {
                            finalCSRString = csr.replacingOccurrences(of: "\n", with: "")
                            finalCSRString = "\(ESPMatterConstants.csrHeader)\n" + finalCSRString + "\n\(ESPMatterConstants.csrFooter)"
                        }
                        let nodeGroupURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion
                        let service = ESPIssueUserNOCService(presenter: self)
                        service.issueUserNOC(url: nodeGroupURL, groupId: groupId, operation: ESPMatterConstants.add, csr: finalCSRString)
                    }
                }
                return
            }
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
            commissioner.shutDownController()
            Task {
                await self.setup()
            }
        }
    }
    
    /// Initialize matter controller
    func initializeMatterController() {
        if let group = group, let grpId = group.groupID, let userNOCData = self.fabricDetails.getUserNOCDetails(groupId: grpId) {
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: grpId)
            commissioner.shutDownController()
            commissioner.group = group
            commissioner.initializeMTRControllerWithUserNOC(matterFabricData: group, userNOCData: userNOCData)
        }
    }
    
    /// Start commissioning process with MatterSupport
    func startCommissioningProcess() {
        Task {
            await self.setup()
        }
    }
    
    /// Setup commissioning session
    func setup() async {
        ESPMatterEcosystemInfo.shared.removeOnboardingPayload()
        ESPMatterEcosystemInfo.shared.removeDeviceName()
        ESPMatterEcosystemInfo.shared.removeCertDeclaration()
        ESPMatterEcosystemInfo.shared.removeAttestationInfo()
        if let group = self.group, let groupName = group.groupName, let groupId = group.groupID {
            if let onboardingPayload = self.onboardingPayload {
                if let setupPayload = try? MTRSetupPayload(onboardingPayload: onboardingPayload) {
                    self.startEcosystemCommissioning(matterEcosystemName: Configuration.shared.appConfiguration.matterEcosystemName,
                                                     groupName: groupName,
                                                     groupId: groupId,
                                                     showDeviceCriteria: true,
                                                     setupPayload: setupPayload)
                } else if #available(iOS 17.6, *), let setupPayload = try? MTRSetupPayload(payload: onboardingPayload) {
                    self.startEcosystemCommissioning(matterEcosystemName: Configuration.shared.appConfiguration.matterEcosystemName,
                                                     groupName: groupName,
                                                     groupId: groupId,
                                                     showDeviceCriteria: true,
                                                     setupPayload: setupPayload)
                } else {
                    self.startEcosystemCommissioning(matterEcosystemName: Configuration.shared.appConfiguration.matterEcosystemName,
                                                     groupName: groupName,
                                                     groupId: groupId,
                                                     showDeviceCriteria: true,
                                                     setupPayload: nil)
                }
            } else {
                self.startEcosystemCommissioning(matterEcosystemName: Configuration.shared.appConfiguration.matterEcosystemName,
                                                 groupName: groupName,
                                                 groupId: groupId,
                                                 showDeviceCriteria: true,
                                                 setupPayload: nil)
            }
        }
    }
    
    /// Start commissioning to Apple's ecosystem
    /// - Parameters:
    ///   - matterEcosystemName: matter ecosystem name
    ///   - groupName: group name
    ///   - showDeviceCriteria: show device criteria
    ///   - setupPayload: setup payload
    func startEcosystemCommissioning(matterEcosystemName: String, groupName: String, groupId: String? = nil, showDeviceCriteria: Bool = false, setupPayload: MTRSetupPayload?) {
        Task {
            let topology = MatterAddDeviceRequest.Topology(ecosystemName: matterEcosystemName, homes: [MatterAddDeviceRequest.Home(displayName: groupName)])
            var setupRequest = MatterAddDeviceRequest(topology: topology, setupPayload: setupPayload)
            if showDeviceCriteria {
                setupRequest.showDeviceCriteria = .allDevices
            }
            do {
                try await setupRequest.perform()
                self.validatePayloadAndStartCommissioning(groupName: groupName)
            } catch {
                self.showErrorAlert(title: ESPMatterConstants.failureTxt,
                                    message: ESPMatterConstants.commissioningFailureMsg,
                                    buttonTitle: ESPMatterConstants.okTxt,
                                    callback: {
                    DispatchQueue.main.async {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                })
            }
        }
    }
    
    /// Hide loader and alert user
    func hideLoaderAndAlertUser() {
        Utility.hideLoader(view: self.view)
        self.alertUser(title: ESPMatterConstants.emptyString,
                       message: ESPMatterConstants.operationFailedMsg,
                       buttonTitle: ESPMatterConstants.okTxt,
                       callback: {
            self.goToHomeScreen(isRainmaker: false)
        })
    }
    
    
    
    /// Navigate to devices screen
    func navigateToDevicesScreen() {
        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
        self.commissionedNodeSyncService.syncCommissionedNode(groupId: self.groupId,
                                                              matterNodeId: self.matterNodeId,
                                                              retries: 8,
                                                              retryDelay: 1.25) { node in
            DispatchQueue.main.async {
                if let node = node {
                    self.upsertAssociatedNodeList(with: node)
                }
                Utility.hideLoader(view: self.view)
                self.markDeviceListNeedsRefresh()
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    /// Go to Home screen
    func goToHomeScreen(isRainmaker: Bool) {
        if let groupId = self.groupId, let matterNodeId = self.matterNodeId, let deviceId = matterNodeId.hexToDecimal {
            if ESPMatterClusterUtil.shared.isRainmakerServerSupported(groupId: groupId, deviceId: deviceId).0, isRainmaker {
                DispatchQueue.main.async {
                    Utility.showLoader(message: "", view: self.view)
                }
                let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
                if let nodeID = commissioner.rainmakerNodeId {
                    // First update device timezone
                    self.updateTimezone(nodeID: nodeID) { _ in
                        // Update device name
                        self.updateDeviceName(nodeId: nodeID) {
                            // Finally perform TBR action and navigate
                            if #available(iOS 18.4, *) {
                                self.performTBRActionAndNavigate(groupId: groupId, deviceId: deviceId)
                            } else {
                                self.navigateToDevicesScreen()
                            }
                        }
                    }
                } else {
                    if #available(iOS 18.4, *) {
                        self.performTBRActionAndNavigate(groupId: groupId, deviceId: deviceId)
                    } else {
                        self.navigateToDevicesScreen()
                    }
                }
            } else {
                if #available(iOS 18.4, *) {
                    self.performTBRActionAndNavigate(groupId: groupId, deviceId: deviceId)
                } else {
                    self.navigateToDevicesScreen()
                }
            }
        } else {
            self.navigateToDevicesScreen()
        }
    }

    /// Update timezone for Rainmaker node
    /// - Parameters:
    ///   - nodeID: rainmaker node ID
    ///   - completion: completion handler with rainmaker nodeId
    private func updateTimezone(nodeID: String, completion: @escaping (String?) -> Void) {
        // Fetch latest nodes
        NetworkManager.shared.getNodeInfo(nodeId: nodeID) { node, _ in
            if let node = node {
                for service in node.services ?? [] {
                    if service.type?.lowercased() == Constants.timezoneServiceName {
                        if let param = service.params?.first(where: { $0.type?.lowercased() == Constants.timezoneServiceParam }) {
                            let timezone = param.value as? String
                            if timezone == nil || timezone!.isEmpty {
                                DeviceControlHelper.shared.updateParam(nodeID: nodeID, parameter: [service.name ?? "Time": [param.name ?? "": TimeZone.current.identifier]], delegate: nil)
                            }
                        }
                    }
                }
                completion(nodeID)
            } else {
                completion(nil)
            }
        }
    }

    /// Update device name
    /// - Parameters:
    ///   - nodeId: rainmaker node ID
    ///   - completion: completion handler
    private func updateDeviceName(nodeId: String, completion: @escaping () -> Void) {
        NetworkManager.shared.getNodeInfo(nodeId: nodeId) { node, _ in
            if let node = node, let devices = node.devices, devices.count > 0 {
                for device in devices {
                    if let params = device.params {
                        for param in params {
                            if let type = param.type, type == Constants.deviceNameParam, let paramName = param.name, let deviceName = ESPMatterEcosystemInfo.shared.getDeviceName() {
                                DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: [device.name ?? "" : [paramName: deviceName]], delegate: nil)
                            }
                        }
                    }
                }
                completion()
            } else {
                completion()
            }
        }
    }
}

//MARK: commissioning methods
@available(iOS 16.4, *)
extension ESPMatterCommissioningVC {
    
    /// Validate onboarding payload and start commissioning
    /// - Parameter groupName: group name
    func validatePayloadAndStartCommissioning(groupName: String) {
        if let _ = ESPMatterEcosystemInfo.shared.getOnboardingPayload() {
            self.startCommissioning()
        } else if let _ = self.onboardingPayload {
            self.startCommissioning()
        } else {
            DispatchQueue.main.async {
                self.hideLoaderAndAlertUser()
            }
        }
    }
    
    /// Launch commissioning dialog
    /// - Parameter groupName: group name
    func launchCommissioningDialog(groupName: String) {
        self.alertUser(title: ESPMatterConstants.info,
                       message: ESPMatterConstants.scanQRCodeMsg,
                       buttonTitle: ESPMatterConstants.okTxt,
                       callback: {
            Task {
                let topology = MatterAddDeviceRequest.Topology(ecosystemName: Configuration.shared.appConfiguration.matterEcosystemName, homes: [MatterAddDeviceRequest.Home(displayName: groupName)])
                let setupRequest = MatterAddDeviceRequest(topology: topology)
                do {
                    try await setupRequest.perform()
                    self.matterSupportFlowCompleted()
                } catch {
                    self.matterSupportFlowCompleted()
                }
            }
        })
    }
    
    /// Matter support flow completed
    func matterSupportFlowCompleted() {
        if let _ = ESPMatterEcosystemInfo.shared.getOnboardingPayload() {
            self.startCommissioning()
        } else {
            self.showErrorAlert(title: ESPMatterConstants.failureTxt,
                                message: ESPMatterConstants.commissioningFailureMsg,
                                buttonTitle: ESPMatterConstants.okTxt,
                                callback: {})
        }
    }
    
    /// start custom fabric commissioning flow
    func startCommissioning() {
        if let payload = ESPMatterEcosystemInfo.shared.getOnboardingPayload(), let groupId = self.groupId {
            self.initializeMatterController()
            let deviceId = ESPMatterDeviceManager.shared.getNextAvailableDeviceID()
            ESPMatterDeviceManager.shared.setNextAvailableDeviceID(deviceId+1)
            let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
            commissioner.uidelegate = self
            commissioner.startCommissioningWithUserNOC(onboardingPayload: payload, deviceId: deviceId)
        }
    }
}

//MARK: issue user noc
@available(iOS 16.4, *)
extension ESPMatterCommissioningVC: ESPIssueUserNOCPresentationLogic {
    
    func userNOCReceived(groupId: String,
                         response: ESPIssueUserNOCResponse?,
                         error: Error?) {
        Utility.hideLoader(view: self.view)
        guard let _ = error else {
            if let response = response {
                self.fabricDetails.saveUserNOCDetails(groupId: groupId, data: response)
                let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
                commissioner.shutDownController()
                Task {
                    await self.setup()
                }
            }
            return
        }
    }
}

/// UI delegate
@available(iOS 16.4, *)
extension ESPMatterCommissioningVC: ESPMTRUIDelegate {
    
    func showToastMessage(message: String) {
        //show toast message
    }
    
    func hideToastMessage() {
        //hide toast message
    }
    
    func showLoaderInView(message: String) {
        DispatchQueue.main.async {
            Utility.showLoader(message: message, view: self.view)
        }
    }
    
    func hideLoaderFromView() {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
        }
    }
    
    func reloadData(groupId: String? = nil, matterNodeId: String? = nil, isRainmaker: Bool) {
        self.matterNodeId = matterNodeId
        guard let groupId = groupId,
              let matterNodeId = matterNodeId,
              let deviceId = matterNodeId.hexToDecimal else { return }
        
        self.handlePostCommissioningSetupControllerFlowIfNeeded(groupId: groupId, isRainmaker: isRainmaker) { _ in
            // Go to home screen.
            if let nodes = User.shared.associatedNodeList, nodes.count > 0 {
                DispatchQueue.main.async {
                    Utility.showLoader(message: "", view: self.view)
                }
                self.sendUpdateDeviceListToControllersInGroup(groupId: groupId) {
                    DispatchQueue.main.async {
                        Utility.hideLoader(view: self.view)
                        self.goToHomeScreen(isRainmaker: isRainmaker)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.goToHomeScreen(isRainmaker: isRainmaker)
                }
            }
        }
    }

    
    func showError(title: String, message: String, buttonTitle: String) {
        DispatchQueue.main.async {
            self.showErrorAlert(title: title,
                                message: message,
                                buttonTitle: buttonTitle,
                                callback: {
                DispatchQueue.main.async {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            })
        }
    }
    
    //TODO: update_device_cat_ids: Write to ACL
    func updateDeviceCATIds(completion: @escaping () -> Void) {
        var index = 0
        if let group = self.group, group.shouldUpdate, let fabricDetails = group.fabricDetails, let catIdAdmin = fabricDetails.catIdAdminDecimal, let catIdOperate = fabricDetails.catIdOperateDecimal, let nodes = self.nodes, nodes.count > 0 {
            for node in nodes {
                if let matterNodeId = node.matterNodeID, let deviceId = matterNodeId.hexToDecimal, let groupId = group.groupID {
                    let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
                    commissioner.readAllACLAttributes(deviceId: deviceId) { accessControlEntries in
                        if var accessControlEntries = accessControlEntries, accessControlEntries.count > 0 {
                            var entries = [MTRAccessControlClusterAccessControlEntryStruct]()
                            for index in 0..<accessControlEntries.count {
                                var entry = accessControlEntries[index]
                                if entry.privilege.intValue == 5 {
                                    entry.subjects = [NSNumber(value: catIdAdmin)]
                                } else if entry.privilege.intValue == 3 {
                                    entry.subjects = [NSNumber(value: catIdOperate)]
                                }
                                entries.append(entry)
                            }
                            commissioner.writeAllACLAttributes(deviceId: deviceId, accessControlEntry: entries) { result in
                                index+=1
                                if index >= nodes.count {
                                    completion()
                                }
                            }
                        } else {
                            index+=1
                            if index >= nodes.count {
                                completion()
                            }
                        }
                    }
                } else {
                    index+=1
                    if index >= nodes.count {
                        completion()
                    }
                }
            }
        } else {
            completion()
        }
    }

    private func sendUpdateDeviceListToControllersInGroup(groupId: String, completion: @escaping () -> Void) {
        guard let allNodes = User.shared.associatedNodeList else {
            completion()
            return
        }

        var updatePayloads: [(String, [String: Any])] = []
        for node in allNodes where self.isNodeInTargetGroup(node: node, groupId: groupId) {
            guard let nodeId = node.node_id else { continue }
            var body: [String: Any] = [:]

            if let serviceName = node.getServiceName(forServiceType: MatterControllerConstants.serviceType),
               let commandName = node.clientOnlyControllerUpdateDeviceListCommandParam?.name {
                body[serviceName] = [commandName: 2]
            }

            if let serviceName = node.getServiceName(forServiceType: RainmakerControllerConstants.rmakerControllerServiceType),
               let commandName = node.rmakerControllerUpdateDeviceListCommandParam?.name {
                body[serviceName] = [commandName: 2]
            }

            if let serviceName = node.getServiceName(forServiceType: ClientOnlyControllerConstants.setupServiceType),
               let commandName = node.clientOnlyControllerUpdateDeviceListCommandParam?.name {
                body[serviceName] = [commandName: 2]
            }

            if !body.isEmpty {
                updatePayloads.append((nodeId, body))
            }
        }

        if updatePayloads.isEmpty {
            completion()
            return
        }

        print("Update payloads: \(updatePayloads.description)")
        var pending = updatePayloads.count
        for payload in updatePayloads {
            print("Node addition command to be sent for nodeid: \(payload.0) with params: \(payload.1)")
            DeviceControlHelper.shared.updateParam(nodeID: payload.0, parameter: payload.1, delegate: nil) { _ in
                pending -= 1
                if pending == 0 {
                    completion()
                }
            }
        }
    }

    private func isNodeInTargetGroup(node: Node, groupId: String) -> Bool {
        if node.groupId == groupId {
            return true
        }
        let candidateGroupIds: [String?] = [
            node.clientOnlyControllerRmakerGroupParam?.value as? String,
            node.clientOnlyControllerGroupParam?.value as? String,
            node.clientOnlyControllerSetupRmakerGroupParam?.value as? String,
            node.clientOnlyControllerSetupGroupParam?.value as? String,
            node.rmakerControllerGroupParam?.value as? String
        ]
        for candidate in candidateGroupIds {
            if let id = candidate?.trimmingCharacters(in: .whitespacesAndNewlines),
               !id.isEmpty,
               id == groupId {
                return true
            }
        }
        return false
    }

    private func markDeviceListNeedsRefresh() {
        User.shared.updateDeviceList = true
    }

    private func upsertAssociatedNodeList(with updatedNode: Node) {
        guard let nodeId = updatedNode.node_id?.trimmingCharacters(in: .whitespacesAndNewlines), !nodeId.isEmpty else {
            return
        }
        var nodes = User.shared.associatedNodeList ?? []
        if let index = nodes.firstIndex(where: { $0.node_id == nodeId }) {
            nodes[index] = updatedNode
        } else if let matterNodeId = updatedNode.matter_node_id,
                  let index = nodes.firstIndex(where: { $0.matter_node_id == matterNodeId }) {
            nodes[index] = updatedNode
        } else {
            nodes.append(updatedNode)
        }
        User.shared.associatedNodeList = nodes
    }
}

@available(iOS 16.4, *)
private final class ESPCommissionedNodeSyncService: NSObject {

    private let apiManager = ESPAPIManager()
    private let getNodeGroupsService: ESPGetNodeGroupsService
    private var nodeGroupDetailsCompletion: ((ESPNodeGroupDetails?) -> Void)?

    override init() {
        self.getNodeGroupsService = ESPGetNodeGroupsService()
        super.init()
        self.getNodeGroupsService.presenter = self
    }

    func syncCommissionedNode(groupId: String?,
                              matterNodeId: String?,
                              retries: Int,
                              retryDelay: TimeInterval,
                              completion: @escaping (Node?) -> Void) {
        guard let groupId = groupId, !groupId.isEmpty else {
            completion(nil)
            return
        }
        resolveRainmakerNodeId(groupId: groupId,
                               matterNodeId: matterNodeId,
                               retriesLeft: retries,
                               retryDelay: retryDelay) { nodeId in
            guard let nodeId = nodeId, !nodeId.isEmpty else {
                completion(nil)
                return
            }
            self.fetchNodeDetails(nodeId: nodeId,
                                  retriesLeft: retries,
                                  retryDelay: retryDelay,
                                  completion: completion)
        }
    }

    private func resolveRainmakerNodeId(groupId: String,
                                        matterNodeId: String?,
                                        retriesLeft: Int,
                                        retryDelay: TimeInterval,
                                        completion: @escaping (String?) -> Void) {
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
        if let nodeId = commissioner.rainmakerNodeId?.trimmingCharacters(in: .whitespacesAndNewlines), !nodeId.isEmpty {
            completion(nodeId)
            return
        }
        guard let matterNodeId = matterNodeId?.trimmingCharacters(in: .whitespacesAndNewlines), !matterNodeId.isEmpty else {
            completion(nil)
            return
        }
        fetchNodeGroupDetails(groupId: groupId) { details in
            let nodeId = self.findRainmakerNodeId(matterNodeId: matterNodeId, details: details)
            if let nodeId = nodeId, !nodeId.isEmpty {
                completion(nodeId)
                return
            }
            guard retriesLeft > 1 else {
                completion(nil)
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                self.resolveRainmakerNodeId(groupId: groupId,
                                            matterNodeId: matterNodeId,
                                            retriesLeft: retriesLeft - 1,
                                            retryDelay: retryDelay,
                                            completion: completion)
            }
        }
    }

    private func findRainmakerNodeId(matterNodeId: String, details: ESPNodeGroupDetails?) -> String? {
        guard let groups = details?.groups else {
            return nil
        }
        for group in groups {
            for node in group.nodeDetails ?? [] {
                let candidateMatterNodeId = node.matterNodeID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if candidateMatterNodeId.caseInsensitiveCompare(matterNodeId) == .orderedSame {
                    let nodeId = node.nodeID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !nodeId.isEmpty {
                        return nodeId
                    }
                }
            }
        }
        return nil
    }

    private func fetchNodeGroupDetails(groupId: String, completion: @escaping (ESPNodeGroupDetails?) -> Void) {
        let worker = ESPExtendUserSessionWorker()
        worker.checkUserSession { token, _ in
            guard let token = token else {
                completion(nil)
                return
            }
            let nodeGroupURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion
            self.nodeGroupDetailsCompletion = completion
            self.getNodeGroupsService.getNodeDetails(url: nodeGroupURL, token: token, groupId: groupId)
        }
    }

    private func fetchNodeDetails(nodeId: String,
                                  retriesLeft: Int,
                                  retryDelay: TimeInterval,
                                  completion: @escaping (Node?) -> Void) {
        self.apiManager.getNodeInfo(nodeId: nodeId) { node, _ in
            let fetchedNodeId = node?.node_id?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let fetchedNodeId = fetchedNodeId, !fetchedNodeId.isEmpty {
                completion(node)
                return
            }
            guard retriesLeft > 1 else {
                completion(nil)
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                self.fetchNodeDetails(nodeId: nodeId,
                                      retriesLeft: retriesLeft - 1,
                                      retryDelay: retryDelay,
                                      completion: completion)
            }
        }
    }
}

@available(iOS 16.4, *)
extension ESPCommissionedNodeSyncService: ESPGetNodeGroupsPresentationLogic {
    func receivedNodeGroupsData(data: ESPNodeGroups?, error: Error?) {}

    func receivedNodeGroupDetailsData(data: ESPNodeGroupDetails?, error: Error?) {
        let completion = self.nodeGroupDetailsCompletion
        self.nodeGroupDetailsCompletion = nil
        completion?(data)
    }
}

@available(iOS 16.4, *)
extension ESPMatterCommissioningVC: ParamUpdateProtocol {
    
    func failureInUpdatingParam() {
        
    }
}
#endif
