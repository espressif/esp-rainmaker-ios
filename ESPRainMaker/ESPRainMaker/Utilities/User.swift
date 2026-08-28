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
//  User.swift
//  ESPRainMaker
//

import Alamofire
import ESPProvision
import Foundation
import JWTDecode

class User {
    static let shared = User()
    var userInfo = UserInfo.getUserInfo()
    var accessToken: String?
    var associatedNodeList: [Node]?
    var username = ""
    var password = ""
    var automaticLogin = false
    var updateDeviceList = false
    var currentAssociationInfo: AssociationConfig?
    var updateUserInfo = false
    var localServices: [String: ESPLocalService] = [:]
    var discoveredNodes: [String] = []
    var discoveredNodesCompletion: (([String]) -> Void)?
    var discoveredTBRs: [String] = []
    var discoveredThreadNetworks: [String: String] = [:]
    var discoveredThreadNetworksData: [String: [String: Data]] = [:]
    var discoveredTBRsCompletion: (([String], [String: String], [String: [String: Data]]) -> Void)?
    var matterLightOnStatus: [String: Bool] = [String: Bool]()
    
    // Track when each node was last successfully discovered on local network
    // Used to handle WiFi changes: if node hasn't been discovered for >60 seconds, clear localNetwork
    private var lastLocalDiscoveryTime: [String: Date] = [:]
    private let localDiscoveryTimeout: TimeInterval = 60.0 // 60 seconds
    
    private let esp = "esp"
    private let prov = "prov"
    private let secVer = "sec_ver"

    lazy var localControl: ESPLocalControl = {
        ESPLocalControl()
    }()
    
    lazy var matterConnectionManager: ESPMatterConnectionManager = {
        ESPMatterConnectionManager()
    }()
    
    lazy var tbrConnectionManager: TBRConnectionManager = {
        TBRConnectionManager()
    }()

    private init() {
        if let value = ESPTokenWorker.shared.accessTokenString {
            accessToken = value
        }
    }
    
    var isUserSessionActive: Bool {
        if let _ = ESPTokenWorker.shared.idTokenString {
            return true
        }
        return false
    }
    
    func updateUserInfo(token: String, provider: ServiceProvider) {
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
    }


    /// Method to configure and send association related information to the connected device
    ///
    /// - Parameters:
    ///   - session: Current established session with the device for sending information.
    ///   - delegate: Object that will receive notification whether the info was delivered successfully
    func associateNodeWithUser(device: ESPDevice, delegate: DeviceAssociationProtocol) {
        currentAssociationInfo = AssociationConfig()
        currentAssociationInfo?.uuid = UUID().uuidString
        let deviceAssociation = DeviceAssociation(secretId: currentAssociationInfo!.uuid, device: device)
        deviceAssociation.associateDeviceWithUser()
        deviceAssociation.delegate = delegate
    }

    /// Update information of local network for existing nodes.
    ///
    private func updateNodeLocalNetworkInfo() {
        var notifyLocalNetworkUpdate = true
        if let nodeList = User.shared.associatedNodeList {
            let group = DispatchGroup()
            var localNodeList: [Node] = []
            
            // Only update localNetwork if we have a non-empty discovery result
            // This prevents clearing localNetwork when discovery temporarily returns empty (timeout/restart)
            let hasValidDiscoveryResult = !localServices.isEmpty
            
            for node in nodeList {
                let nodeId = node.node_id ?? "unknown"
                let previousLocalNetwork = node.localNetwork
                let isInLocalServices = localServices.keys.contains(nodeId)
                let lastDiscovery = lastLocalDiscoveryTime[nodeId]
                let timeSinceLastDiscovery = lastDiscovery.map { Date().timeIntervalSince($0) } ?? Double.infinity
                
                if isInLocalServices {
                    // Device is discovered - update timestamp and set localNetwork = true
                    lastLocalDiscoveryTime[nodeId] = Date()
                    node.localNetwork = true
                    notifyLocalNetworkUpdate = false
                    setEncryptionOnLocalControl(node: node)
                    group.enter()
                    NetworkManager.shared.getNodeInfo(nodeId: node.node_id ?? "") { node, _ in
                        if node != nil {
                            localNodeList.append(node!)
                        }
                        group.leave()
                    }
                } else {
                    node.localNetwork = false
                }
            }
            group.notify(queue: DispatchQueue.main) {
                self.processNodeInfoResponse(nodeList: localNodeList)
            }
        }
        if notifyLocalNetworkUpdate {
            NotificationCenter.default.post(Notification(name: Notification.Name(Constants.localNetworkUpdateNotification)))
        }
    }
    
    private func setEncryptionOnLocalControl(node: Node) {
        if let service = localServices[node.node_id ?? ""] {
            if node.supportsEncryption {
                var secureUserName: String!
                if let securityType = node.securityType, securityType == ESPSecurity.secure2.rawValue {
                    let nodeLevelUsername = node.localControlUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !nodeLevelUsername.isEmpty {
                        secureUserName = nodeLevelUsername
                    } else {
                        secureUserName = Configuration.shared.appConfiguration.localControlSec2Username
                    }
                    service.espLocalDevice = ESPLocalDevice(name: esp, security: .secure2, transport: .softap, proofOfPossession: node.pop, username: secureUserName, softAPPassword: nil, advertisementData: nil)
                    service.espLocalDevice.versionInfo = [prov: [secVer: securityType]]
                } else {
                    service.espLocalDevice = ESPLocalDevice(name: esp, security: .secure, transport: .softap, proofOfPossession: node.pop, username: secureUserName, softAPPassword: nil, advertisementData: nil)
                }
                service.espLocalDevice.espSoftApTransport = ESPSoftAPTransport(baseUrl: service.hostname)
            }
            service.espLocalDevice.hostname = service.hostname
        }
    }

    private func processNodeInfoResponse(nodeList: [Node]) {
        for localNode in nodeList {
            if let index = User.shared.associatedNodeList?.firstIndex(where: { node -> Bool in
                node.node_id == localNode.node_id
            }) {
                localNode.localNetwork = true
                User.shared.associatedNodeList![index] = localNode
            }
        }
        if nodeList.count > 0 {
            NotificationCenter.default.post(Notification(name: Notification.Name(Constants.localNetworkUpdateNotification)))
        }
    }

    /// Start search for services on local network.
    ///
    func startServiceDiscovery() {
        DispatchQueue.main.async {
            self.localControl.delegate = self
            self.localControl.searchForServicesOfType(type: Constants.serviceType, domain: Constants.serviceDomain)
        }
    }
    
    /// Start search for matter devices on local network
    /// - Parameter discoveredNodesCompletion: discovered nodes completion
    func startCommissionedMatterServiceDiscovery(discoveredNodesCompletion: @escaping ([String]) -> Void) {
        DispatchQueue.main.async {
            self.discoveredNodes.removeAll()
            self.discoveredNodesCompletion = discoveredNodesCompletion
            self.matterConnectionManager.delegate = self
            self.matterConnectionManager.searchForServicesOfType(type: Constants.matterCommissionedServiceType, domain: Constants.serviceDomain)
        }
    }
    
    /// Stop matter discovery
    func stopMatterDiscovery() {
        DispatchQueue.main.async {
            self.matterConnectionManager.stopService()
            self.matterConnectionManager.delegate = nil
        }
    }
    
    /// Returns node from associated node list
    /// - Parameter id: node id
    /// - Returns: node for given node id or nil if it doesn't exist
    func getNode(id: String) -> Node? {
        let predicate = NSPredicate(format: "SELF == %@", id)
        let node = associatedNodeList?.first(where: {
            predicate.evaluate(with: ($0.node_id))
        })
        return node ?? nil
    }
    
    /// Is node connected over local netowkr
    /// - Parameter matterNodeId: matter node id
    /// - Returns: is connected
    func isMatterNodeConnected(matterNodeId: String) -> Bool {
        for id in User.shared.discoveredNodes {
            if id.uppercased().contains(matterNodeId.uppercased()) {
                return true
            }
        }
        return false
    }
    
    /// Scan for TBRs broadcasting on service  "_meshcop._udp"
    /// - Parameter discoveredTBRs: TBRs discovered
    func scanThreadBorderRouters(discoveredTBRsCompletion: @escaping ([String], [String: String], [String: [String: Data]]) -> Void) {
        DispatchQueue.main.async {
            self.discoveredTBRs.removeAll()
            self.discoveredThreadNetworks.removeAll()
            self.discoveredThreadNetworksData.removeAll()
            self.discoveredTBRsCompletion = discoveredTBRsCompletion
            self.tbrConnectionManager.delegate = self
            self.tbrConnectionManager.searchForServicesOfType(type: Constants.threadBRMDNSServiceType, domain: Constants.serviceDomain)
        }
    }

    /// Stop matter discovery
    func stopThreadBRSearch() {
        DispatchQueue.main.async {
            self.tbrConnectionManager.stopService()
            self.tbrConnectionManager.delegate = nil
        }
    }
    
    /// Method to initiate mapping with challenge response
    ///
    /// - Parameters:
    ///   - completion: Callback invoked after api response is received with challenge, requestId and error
    func initiateMapping(completion: @escaping (String?, String?, Error?) -> Void) {
        let sessionWorker = ESPExtendUserSessionWorker()
        sessionWorker.checkUserSession { accessToken, error in
            if let token = accessToken {
                let headers = [Constants.contentType: Constants.applicationJSON,
                             Constants.authorization: token]
                
                NetworkManager.shared.apiManager.session.request(Constants.initiateMapping,
                                                   method: .post,
                                                   headers: HTTPHeaders(headers))
                    .responseData { response in
                        switch response.result {
                        case .success(let data):
                            let decoder = JSONDecoder()
                            if let json = try? decoder.decode([String: String].self, from: data),
                               let challenge = json[Constants.challenge],
                               let requestId = json[Constants.requestID] {
                                completion(challenge, requestId, nil)
                            } else {
                                completion(nil, nil, NSError(domain: "ESP", code: 1, userInfo: [NSLocalizedDescriptionKey: AppMessages.challengeFetchFailedMsg]))
                            }
                        case .failure(let error):
                            completion(nil, nil, error)
                        }
                    }
            } else {
                completion(nil, nil, error)
            }
        }
    }
    
    /// Method to verify user node mapping with challenge response
    ///
    /// - Parameters:
    ///   - requestId: Request ID received from initiate mapping
    ///   - nodeId: Node ID of the device
    ///   - challengeResponse: Challenge response from the device
    ///   - completion: Callback invoked after api response is received with success status and error
    func verifyUserNodeMapping(requestId: String, nodeId: String, challengeResponse: String, completion: @escaping (Bool, Error?) -> Void) {
        let sessionWorker = ESPExtendUserSessionWorker()
        sessionWorker.checkUserSession { accessToken, error in
            if let token = accessToken {
                let headers = [Constants.contentType: Constants.applicationJSON,
                             Constants.authorization: token]
                
                // Create request body
                let parameters: [String: String] = [
                    Constants.requestID: requestId,
                    Constants.nodeID: nodeId,
                    Constants.challengeResponse: challengeResponse
                ]
                
                NetworkManager.shared.apiManager.session.request(Constants.verifyMapping,
                                                   method: .post,
                                                   parameters: parameters,
                                                   encoding: JSONEncoding.default,
                                                   headers: HTTPHeaders(headers))
                    .responseData { response in
                        
                        switch response.result {
                        case .success(let data):
                            let decoder = JSONDecoder()
                            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                if let status = json[Constants.statusKey] as? String,
                                   status.lowercased() == Constants.successKey {
                                    completion(true, nil)
                                } else {
                                    var errorDescription = AppMessages.mappingVerificationFailedMsg
                                    if let description = json[Constants.descriptionKey] as? String {
                                        errorDescription = description
                                    }
                                    completion(false, NSError(domain: "ESP", code: 1, userInfo: [NSLocalizedDescriptionKey: errorDescription]))
                                }
                            }
                        case .failure(let error):
                            completion(false, error)
                        }
                    }
            } else {
                completion(false, error)
            }
        }
    }
}

extension User: ESPLocalControlDelegate {
    func updateInAvailableLocalServices(services: [ESPLocalService]) {
        localServices.removeAll()
        for service in services {
            var hostname = service.hostname
            if hostname.contains(".") {
                let endIndex = hostname.range(of: ".")!.lowerBound
                hostname = String(hostname[..<endIndex])
            }
            localServices[hostname] = service
        }
        
        updateNodeLocalNetworkInfo()
    }
}

extension User: ESPMatterNodesDiscoveredDelegate {
    func matterDevicesDiscovered(matterNodes: [String]) {
        let previousNodes = self.discoveredNodes
        self.discoveredNodes = matterNodes
        self.discoveredNodesCompletion?(matterNodes)
        
        // Post notification when Matter connection status changes
        // This allows DeviceViewController to update UI when devices connect/disconnect
        if previousNodes != matterNodes {
            DispatchQueue.main.async {
                NotificationCenter.default.post(Notification(name: Notification.Name(Constants.matterDeviceConnectivityUpdate)))
            }
        }
    }
}

extension User: TBRNodesDiscoveredDelegate {
    func threadBorderRoutersDiscovered(threadBorderRouters: [String], threadNetworks: [String: String], threadNetworksData: [String: [String: Data]]) {
        self.discoveredTBRs = threadBorderRouters
        self.discoveredThreadNetworks = threadNetworks
        self.discoveredThreadNetworksData = threadNetworksData
        self.discoveredTBRsCompletion?(threadBorderRouters, threadNetworks, threadNetworksData)
    }
}
