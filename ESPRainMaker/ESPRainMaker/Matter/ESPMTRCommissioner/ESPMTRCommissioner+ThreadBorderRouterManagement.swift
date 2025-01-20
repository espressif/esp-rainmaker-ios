// Copyright 2025 Espressif Systems
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
//  ESPMTRCommissioner+ThreadBorderRouterManagement.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter
import ThreadNetwork

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    func getGeneralCommissioningClusterForTBRM(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (MTRBaseClusterGeneralCommissioning?) -> Void) {
        if let controller = sController {
            let device = MTRBaseDevice(nodeID: NSNumber(value: deviceId), controller: controller)
            if let generalCommsCluster = MTRBaseClusterGeneralCommissioning(device: device, endpointID: NSNumber(value: endpoint), queue: self.matterQueue) {
                completion(generalCommsCluster)
                return
            }
        }
        completion(nil)
    }
    
    /// Arm fail safe timer before we attempt to set the thread border router active operational dataset
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoint: endpoint
    ///   - completion: completion
    func armFailSafeTimerForTBRM(deviceId: UInt64, endpoint: UInt16, completion: @escaping (Bool) -> Void) {
        self.getGeneralCommissioningClusterForTBRM(deviceId: deviceId, endpoint: endpoint) { generalCommsCluster in
            guard let generalCommsCluster = generalCommsCluster else {
                completion(false)
                return
            }
            let armFailSafeParams = MTRGeneralCommissioningClusterArmFailSafeParams()
            armFailSafeParams.expiryLengthSeconds = NSNumber(value: 300)
            armFailSafeParams.breadcrumb = NSNumber(value: 1)
            generalCommsCluster.armFailSafe(with: armFailSafeParams) { armFailSafeResponseParams, armFailSafeError in
                guard let armFailSafeError = armFailSafeError else {
                    if armFailSafeResponseParams?.errorCode.intValue == 0 {
                        completion(true)
                    } else {
                        completion(false)
                    }
                    return
                }
                completion(false)
            }
        }
    }
    
    /// Send  commissioning complete command to device
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoint: endpoint
    ///   - completion: completion
    func sendCommissioningCompleteCommand(deviceId: UInt64, endpoint: UInt16, completion: @escaping (Bool) -> Void) {
        self.getGeneralCommissioningClusterForTBRM(deviceId: deviceId, endpoint: endpoint) { generalCommsCluster in
            guard let generalCommsCluster = generalCommsCluster else {
                completion(false)
                return
            }
            generalCommsCluster.commissioningComplete { params, error in
                guard let _ = error else {
                    if let params = params {
                        let code = params.errorCode.intValue
                        completion(code == 0)
                        return
                    }
                    completion(false)
                    return
                }
                completion(false)
            }
        }
    }
    
    // MARK: MTRBaseClusterThreadBorderRouterManagement
    
    /// Get TBR Manqgement cluster
    /// - Parameters:
    ///   - deviceId: matter device id
    ///   - endpoint: TBR Management cluster endpoint
    ///   - completion: completion handler with cluster instance if available
    func getTBRThreadBRManagementCluster(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (MTRBaseClusterThreadBorderRouterManagement?) -> Void) {
        if let controller = sController {
            let device = MTRBaseDevice(nodeID: NSNumber(value: deviceId), controller: controller)
            if let tbrManagementCluster = MTRBaseClusterThreadBorderRouterManagement(device: device, endpointID: NSNumber(value: endpoint), queue: self.matterQueue) {
                completion(tbrManagementCluster)
                return
            }
        }
        completion(nil)
    }
    
    /// Get active operational dataset from the matter TBR
    /// - Parameters:
    ///   - deviceId: matter device id
    ///   - endpoint: cluster endpoint
    ///   - completion: completion handler
    func getTBRActiveOperationalDataset(deviceId: UInt64, endpoint: UInt16, completion: @escaping (Data?) -> Void) {
        getTBRThreadBRManagementCluster(deviceId: deviceId, endpoint: endpoint) { tbrManagementCluster in
            guard let tbrManagementCluster = tbrManagementCluster else {
                completion(nil)
                return
            }
            
            tbrManagementCluster.getActiveDatasetRequest() { activeDatasetResponseParams, error in
                if let activeDatasetResponseParams = activeDatasetResponseParams {
                    completion(activeDatasetResponseParams.dataset)
                    return
                }
                completion(nil)
            }
        }
    }
    
    /// Set active operational dataset
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoint: cluster endpoint
    ///   - activeDataset: active operational dataset
    ///   - completion: completion handler
    func setTBRActiveOperationalDataset(deviceId: UInt64, endpoint: UInt16, activeDataset: Data, _ completion: @escaping (Bool) -> Void) {
        getTBRThreadBRManagementCluster(deviceId: deviceId, endpoint: endpoint) { tbrManagementCluster in
            guard let tbrManagementCluster = tbrManagementCluster else {
                completion(false)
                return
            }
            let request = MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams()
            request.activeDataset = activeDataset
            request.breadcrumb = NSNumber(value: 1)
            request.timedInvokeTimeoutMs = NSNumber(value: 5000)
            tbrManagementCluster.setActiveDatasetRequestWith(request) { error in
                completion(error == nil)
            }
        }
    }
    
    /// Read attribute border agent id
    /// - Parameters:
    ///   - deviceId: matter device id
    ///   - endpoint: cluster endpoint id
    ///   - completion: completion handelr with border agent id
    func readTBRAttributeBorderAgentId(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (Data?) -> Void) {
        getTBRThreadBRManagementCluster(deviceId: deviceId, endpoint: endpoint) { tbrManagementCluster in
            guard let tbrManagementCluster = tbrManagementCluster else {
                completion(nil)
                return
            }
            tbrManagementCluster.readAttributeBorderAgentID { borderAgentId, _ in
                completion(borderAgentId)
            }
        }
    }
    
    /// Get pending operational dataset from the matter TBR
    /// - Parameters:
    ///   - deviceId: matter device id
    ///   - endpoint: cluster endpoint
    ///   - completion: completion handler with dataset if available
    func getTBRPendingOperationalDataset(deviceId: UInt64, endpoint: UInt16, completion: @escaping (Data?) -> Void) {
        getTBRThreadBRManagementCluster(deviceId: deviceId, endpoint: endpoint) { tbrManagementCluster in
            guard let tbrManagementCluster = tbrManagementCluster else {
                completion(nil)
                return
            }
            tbrManagementCluster.getPendingDatasetRequest { pendingDatasetResponseParams, error in
                if let pendingDatasetResponseParams = pendingDatasetResponseParams {
                    completion(pendingDatasetResponseParams.dataset)
                    return
                }
                completion(nil)
            }
        }
    }
    
    /// Set pending operational dataset
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoint: cluster endpoint
    ///   - pendingDataset: pending operational dataset
    ///   - completion: completion handler with success status
    func setTBRPendingOperationalDataset(deviceId: UInt64, endpoint: UInt16, pendingDataset: Data, _ completion: @escaping (Bool) -> Void) {
        getTBRThreadBRManagementCluster(deviceId: deviceId, endpoint: endpoint) { tbrManagementCluster in
            guard let tbrManagementCluster = tbrManagementCluster else {
                completion(false)
                return
            }
            let request = MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams()
            request.pendingDataset = pendingDataset
            tbrManagementCluster.setPendingDatasetRequestWith(request) { error in
                completion(error == nil)
            }
        }
    }
    
    /// Read border router name attribute
    /// - Parameters:
    ///   - deviceId: matter device id
    ///   - endpoint: cluster endpoint
    ///   - completion: completion handler with router name if available
    func readTBRBorderRouterName(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (String?) -> Void) {
        getTBRThreadBRManagementCluster(deviceId: deviceId, endpoint: endpoint) { tbrManagementCluster in
            guard let tbrManagementCluster = tbrManagementCluster else {
                completion(nil)
                return
            }
            tbrManagementCluster.readAttributeBorderRouterName { value, _ in
                completion(value)
            }
        }
    }
    
    /// Read Thread version attribute
    /// - Parameters:
    ///   - deviceId: matter device id
    ///   - endpoint: cluster endpoint
    ///   - completion: completion handler with version if available
    func readTBRThreadVersion(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (NSNumber?) -> Void) {
        getTBRThreadBRManagementCluster(deviceId: deviceId, endpoint: endpoint) { tbrManagementCluster in
            guard let tbrManagementCluster = tbrManagementCluster else {
                completion(nil)
                return
            }
            tbrManagementCluster.readAttributeThreadVersion { value, _ in
                completion(value)
            }
        }
    }
    
    /// Read interface enabled status
    /// - Parameters:
    ///   - deviceId: matter device id
    ///   - endpoint: cluster endpoint
    ///   - completion: completion handler with enabled status if available
    func readTBRInterfaceEnabled(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (NSNumber?) -> Void) {
        getTBRThreadBRManagementCluster(deviceId: deviceId, endpoint: endpoint) { tbrManagementCluster in
            guard let tbrManagementCluster = tbrManagementCluster else {
                completion(nil)
                return
            }
            tbrManagementCluster.readAttributeInterfaceEnabled { value, _ in
                completion(value)
            }
        }
    }
    
    /// Read active dataset timestamp
    /// - Parameters:
    ///   - deviceId: matter device id
    ///   - endpoint: cluster endpoint
    ///   - completion: completion handler with timestamp if available
    func readTBRActiveDatasetTimestamp(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (NSNumber?) -> Void) {
        getTBRThreadBRManagementCluster(deviceId: deviceId, endpoint: endpoint) { tbrManagementCluster in
            guard let tbrManagementCluster = tbrManagementCluster else {
                completion(nil)
                return
            }
            tbrManagementCluster.readAttributeActiveDatasetTimestamp { value, _ in
                completion(value)
            }
        }
    }
    
    func readFeatureMap(deviceId: UInt64, endpoint: UInt16, _ completion: @escaping (NSNumber?) -> Void) {
        getTBRThreadBRManagementCluster(deviceId: deviceId, endpoint: endpoint) { tbrManagementCluster in
            guard let tbrManagementCluster = tbrManagementCluster else {
                completion(nil)
                return
            }
            tbrManagementCluster.readAttributeFeatureMap { featureMap, _ in
                completion(featureMap)
            }
        }
    }
    
    /// Update thread dataset on the device
    /// - Parameters:
    ///   - groupId: group identifier
    ///   - deviceId: matter device id
    ///   - completion: completion handler with success status
    func updateThreadDataset(groupId: String, deviceId: UInt64, completion: @escaping (Bool, String?) -> Void) {
        
        // Get endpoint for TBRM cluster
        let clusterInfo = ESPMatterClusterUtil.shared.isTBRMSupported(groupId: groupId, deviceId: deviceId)
        guard let key = clusterInfo.1, let endpoint = UInt16(key) else {
            completion(false, ThreadBRMessages.tbrmClusterNotSupported.rawValue)
            return
        }
        
        // Fetch active thread creds dataset from the TBR
        self.getTBRActiveOperationalDataset(deviceId: deviceId, endpoint: endpoint) { tbrActiveOpsDataset in
            
            // Dataset not configured on TBR - fetch active operational dataset from iOS device
            ThreadCredentialsManager.shared.fetchThreadCredentials { credentials, userAllowed in
                if !userAllowed {
                    completion(false, "")
                    return
                }
                // First we check if there is an active dataset on the TBR
                guard let tbrActiveOpsDataset = tbrActiveOpsDataset else {
                    
                    //If dataset is not configured on TBR we check if dataset is locally available on iOS
                    guard let credentials = credentials, let dataset = credentials.activeOperationalDataSet else {
                        
                        // No thread dataset is locally configured on iOS + no active dataset is
                        // present on the TBR as well. So we need to create a dataset locally
                        self.generateTBRDataLocallyAndSet(groupId: groupId, deviceId: deviceId, endpoint: endpoint, completion: completion)
                        return
                    }
                    
                    // There is a thread dataset locally configured on iOS
                    // which can be set to the TBR
                    self.setLocaliOSDatasetToTBRActive(credentials: credentials, dataset: dataset, groupId: groupId, deviceId: deviceId, endpoint: endpoint, completion: completion)
                    return
                }
                
                // If dataset is configured on TBR we set local iOS data to
                // pending dataset
                guard let credentials = credentials, let iOSDataset = credentials.activeOperationalDataSet else {
                    
                    // Here the active operational dataset is present on the TBR,
                    // but there is no dataset configured on iOS
                    // So we set the TBR data locally on iOS
                    self.updateThreadDataLocally(tbrActiveDataset: tbrActiveOpsDataset, groupId: groupId, deviceId: deviceId, completion: completion)
                    return
                }
                
                print("TBR Active Dataset: \(tbrActiveOpsDataset.hexadecimalString)")
                print("iOS Active Dataset: \(iOSDataset.hexadecimalString)")
                
                // There is a thread dataset locally configured on iOS
                // which can be set to the TBR
                self.setLocaliOSDatasetToTBRPending(credentials: credentials, tbrActiveDataset: tbrActiveOpsDataset, iOSDataset: iOSDataset, groupId: groupId, deviceId: deviceId, endpoint: endpoint, completion: completion)
            }
        }
    }
    
    /// Set local iOS data to TBR active dataset
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func setLocaliOSDatasetToTBRActive(credentials: THCredentials?, dataset: Data, groupId: String, deviceId: UInt64, endpoint: UInt16, completion: @escaping (Bool, String?) -> Void) {
        // Check if general commissioning cluster is supported
        let result = ESPMatterClusterUtil.shared.isGeneralCommissioningSupported(groupId: groupId, deviceId: deviceId)
        guard result.0, let key = result.1, let generalCommsEndpoint = UInt16(key) else {
            completion(false, ThreadBRMessages.failSafeTimerNotSupported.rawValue)
            return
        }
        
        // Arm failsafe timer
        self.armFailSafeTimerForTBRM(deviceId: deviceId, endpoint: generalCommsEndpoint) { armed in
            guard armed else {
                completion(false, ThreadBRMessages.armingFailSafeTimerFailed.rawValue)
                return
            }
            
            // Set active operational dataset
            self.setTBRActiveOperationalDataset(deviceId: deviceId, endpoint: endpoint, activeDataset: dataset) { tbrSet in
                guard tbrSet else {
                    self.sendCommissioningCompleteCommand(deviceId: deviceId, endpoint: generalCommsEndpoint) { _ in
                        completion(false, ThreadBRMessages.setActiveOpsDatasetFailed.rawValue)
                    }
                    return
                }
                if let borderAgentId = credentials?.borderAgentID {
                    ESPMatterEcosystemInfo.shared.saveBorderAgentIdKey(borderAgentId: borderAgentId)
                }
                // Send commissioning complete command
                self.sendCommissioningCompleteCommand(deviceId: deviceId, endpoint: generalCommsEndpoint) { _ in
                    completion(true, nil)
                }
            }
        }
    }
    
    /// Set local iOS data to TBR pending dataset
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion
    func setLocaliOSDatasetToTBRPending(credentials: THCredentials, tbrActiveDataset: Data, iOSDataset: Data, groupId: String, deviceId: UInt64, endpoint: UInt16, completion: @escaping (Bool, String?) -> Void) {
        
        self.readFeatureMap(deviceId: deviceId, endpoint: endpoint) { featureMap in
            if let featureMap = featureMap, featureMap.intValue == 1 {
                var espActiveDataset = tbrActiveDataset
                
                var homepodActiveDataset = iOSDataset
                let updateHomepodParams = ThreadBRDatasetWorker.shared.shouldUpdateHomepodDataset(homepodDataset: homepodActiveDataset, espDataset: espActiveDataset)
                if updateHomepodParams.shouldUpdate {
                    let delayTimer: UInt32 = 60000
                    ThreadBRDatasetWorker.shared.addDelayTimer(to: &homepodActiveDataset, delay: delayTimer)
                } else {
                    /// Should increase homepod dataset
                    if updateHomepodParams.timestampDifference > 0 {
                        ThreadBRDatasetWorker.shared.increaseHomepodActiveTimestamp(in: &homepodActiveDataset, byValue: updateHomepodParams.timestampDifference)
                    }
                    /// If homepod active timestamp is lower than esp active timestamp
                    /// increase the homepod active dataset
                    /// write the homepod data to esp thread dataset
                    let delayTimer: UInt32 = 60000
                    ThreadBRDatasetWorker.shared.addDelayTimer(to: &homepodActiveDataset, delay: delayTimer)
                }
                
                // Check if general commissioning cluster is supported
                let result = ESPMatterClusterUtil.shared.isGeneralCommissioningSupported(groupId: groupId, deviceId: deviceId)
                guard result.0, let key = result.1, let generalCommsEndpoint = UInt16(key) else {
                    completion(false, ThreadBRMessages.failSafeTimerNotSupported.rawValue)
                    return
                }
                
                // Arm failsafe timer
                self.armFailSafeTimerForTBRM(deviceId: deviceId, endpoint: generalCommsEndpoint) { armed in
                    guard armed else {
                        completion(false, ThreadBRMessages.armingFailSafeTimerFailed.rawValue)
                        return
                    }
                    
                    print("Updated iOS Active Dataset: \(homepodActiveDataset.hexadecimalString)")
                    // Set active operational dataset
                    self.setTBRPendingOperationalDataset(deviceId: deviceId, endpoint: endpoint, pendingDataset: homepodActiveDataset) { tbrSet in
                        guard tbrSet else {
                            completion(false, ThreadBRMessages.setPendingDatasetFailed.rawValue)
                            self.sendCommissioningCompleteCommand(deviceId: deviceId, endpoint: generalCommsEndpoint) { _ in
                            }
                            return
                        }
                        if let borderAgentId = credentials.borderAgentID {
                            ESPMatterEcosystemInfo.shared.saveBorderAgentIdKey(borderAgentId: borderAgentId)
                        }
                        // Send commissioning complete command
                        self.sendCommissioningCompleteCommand(deviceId: deviceId, endpoint: generalCommsEndpoint) { _ in
                            completion(true, ThreadBRMessages.addPendingThreadCredsSuccess.rawValue)
                        }
                    }
                }
            } else {
                completion(false, "Setting pending dataset is not supported on the device.")
            }
        }
    }
    
    /// This is called when there is:
    /// - no active dataset is configured on the TBR
    /// - no dataset is saved locally on the iOS device
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - endpoint: endpoint
    ///   - completion: completion
    func generateTBRDataLocallyAndSet(groupId: String, deviceId: UInt64, endpoint: UInt16, completion: @escaping (Bool, String?) -> Void) {
        
        // Try to generate thread dataset locally on iOS
        guard let activeDataset = self.generateTBRActiveDataset() else {
            
            // Unable to generate thread dataset
            completion(false, ThreadBRMessages.homepodDatasetNotAvailable.rawValue)
            return
        }
        
        print("Active dataset: \(activeDataset.hexadecimalString)")
        
        //Was able to generate thread dataset locally
        self.setLocaliOSDatasetToTBRActive(credentials: nil, dataset: activeDataset, groupId: groupId, deviceId: deviceId, endpoint: endpoint) { result, _ in
            
            guard result else {
                
                // Was unable to set the thread active dataset to the TBR
                completion(false, ThreadBRMessages.homepodDatasetNotAvailable.rawValue)
                return
            }
            
            // Start MDNS search to verify if the TBR network is visible
            User.shared.scanThreadBorderRouters { tBRs, scannedNetworks, scannedNetworksData in
                User.shared.stopThreadBRSearch()
                
                // Get network name from dataset for verification
                guard let networkName = ThreadCredentialsManager.shared.getNetworkName(from: activeDataset) else {
                    completion(false, ThreadBRMessages.failedToExtractNetworkName.rawValue)
                    return
                }
                
                // Check if our network is visible in the scanned networks
                var networkFound = false
                for (_, scannedNetwork) in scannedNetworks {
                    if scannedNetwork == networkName {
                        networkFound = true
                        break
                    }
                }
                
                if networkFound {
                    // Network is visible, proceed with updating local data
                    self.updateThreadDataLocally(groupId: groupId, deviceId: deviceId) { set, message in
                        guard set else {
                            completion(false, ThreadBRMessages.failedToSetThreadCredsLocally.rawValue)
                            return
                        }
                        completion(true, nil)
                    }
                } else {
                    // Network not visible after setting
                    completion(false, ThreadBRMessages.networkNotVisibleAfterSetting.rawValue)
                }
            }
        }
    }
    
    /// Update thread data locally
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - completion: completion handler
    func updateThreadDataLocally(tbrActiveDataset: Data? = nil, groupId: String, deviceId: UInt64, completion: @escaping (Bool, String) -> Void) {
        let clusterInfo = ESPMatterClusterUtil.shared.isTBRMSupported(groupId: groupId, deviceId: deviceId)
        guard let key = clusterInfo.1, let endpoint = UInt16(key) else {
            completion(false, ThreadBRMessages.serviceNotSupported.rawValue)
            return
        }
        ESPMTRCommissioner.shared.readTBRAttributeBorderAgentId(deviceId: deviceId, endpoint: endpoint) { borderAgentId in
            guard let borderAgentId = borderAgentId else {
                completion(false, ThreadBRMessages.failedToReadBorderAgentId.rawValue)
                return
            }
            ESPMatterEcosystemInfo.shared.saveBorderAgentIdKey(borderAgentId: borderAgentId)
            if let tbrActiveDataset = tbrActiveDataset {
                ESPMatterEcosystemInfo.shared.saveBorderAgentIdKey(borderAgentId: borderAgentId)
                ThreadCredentialsManager.shared.saveThreadOperationalCredentials(activeOpsDataset: tbrActiveDataset, borderAgentId: borderAgentId) { result in
                    completion(result, result ? ThreadBRMessages.setThreadCredsLocally.rawValue : ThreadBRMessages.failedToSetThreadCredsLocally.rawValue)
                }
            } else {
                ESPMTRCommissioner.shared.getTBRActiveOperationalDataset(deviceId: deviceId, endpoint: endpoint) { dataset in
                    guard let dataset = dataset else {
                        completion(false, ThreadBRMessages.failedToReadActiveDataset.rawValue)
                        return
                    }
                    ESPMatterEcosystemInfo.shared.saveBorderAgentIdKey(borderAgentId: borderAgentId)
                    ThreadCredentialsManager.shared.saveThreadOperationalCredentials(activeOpsDataset: dataset, borderAgentId: borderAgentId) { result in
                        completion(result, result ? ThreadBRMessages.setThreadCredsLocally.rawValue : ThreadBRMessages.failedToSetThreadCredsLocally.rawValue)
                    }
                }
            }
        }
    }
    
    /// Create a sample thread active dataset locally on iOS (network name: Espressif-BR)
    /// - Returns: thread active dataswet
    func generateTBRActiveDataset() -> Data? {
        guard let networkName = "Espressif-TBR".data(using: .utf8) else {
            return nil
        }

        var tlvData = Data()

        // Active Timestamp (0x0E) - Nonzero and monotonic
        let activeTimestamp: UInt64 = UInt64(Date().timeIntervalSince1970 * 1000)
        var activeTimestampData = Data()
        withUnsafeBytes(of: activeTimestamp.bigEndian) { activeTimestampData.append(contentsOf: $0) }
        tlvData.append(contentsOf: [0x0E, 0x08])
        tlvData.append(activeTimestampData)

        // Channel (0x00) - Set to 17 (0x11)
        tlvData.append(contentsOf: [0x00, 0x03, 0x00, 0x00, 0x11]) // Channel 17 (0x0011)

        // Custom Field (0x35) - Matches provided dataset
        tlvData.append(contentsOf: [0x35, 0x06, 0x00, 0x04, 0x00, 0x1F, 0xFF, 0xE0])

        // Extended PAN ID (0x02) - Randomized 8-byte
        var extendedPanId = Data(count: 8)
        _ = extendedPanId.withUnsafeMutableBytes { ptr in
            SecRandomCopyBytes(kSecRandomDefault, 8, ptr.baseAddress!)
        }
        tlvData.append(contentsOf: [0x02, 0x08])
        tlvData.append(extendedPanId)

        // Mesh Local Prefix (0x07) - Randomized 8-byte
        let meshLocalPrefix = Data((0..<8).map { _ in UInt8.random(in: 0...255) })
        tlvData.append(contentsOf: [0x07, 0x08])
        tlvData.append(meshLocalPrefix)

        // Network Key (0x05) - Randomized 16-byte
        var networkKey = Data(count: 16)
        _ = networkKey.withUnsafeMutableBytes { ptr in
            SecRandomCopyBytes(kSecRandomDefault, 16, ptr.baseAddress!)
        }
        tlvData.append(contentsOf: [0x05, 0x10])
        tlvData.append(networkKey)

        // Network Name (0x03) - "Espressif-TBR"
        tlvData.append(contentsOf: [0x03, UInt8(networkName.count)])
        tlvData.append(networkName)

        // PAN ID (0x01) - Random 2-byte
        var panId = Data(count: 2)
        _ = panId.withUnsafeMutableBytes { ptr in
            SecRandomCopyBytes(kSecRandomDefault, 2, ptr.baseAddress!)
        }
        tlvData.append(contentsOf: [0x01, 0x02])
        tlvData.append(panId)

        // PSKc (0x04) - Randomized 16-byte
        var pskc = Data(count: 16)
        _ = pskc.withUnsafeMutableBytes { ptr in
            SecRandomCopyBytes(kSecRandomDefault, 16, ptr.baseAddress!)
        }
        tlvData.append(contentsOf: [0x04, 0x10])
        tlvData.append(pskc)

        // Security Policy (0x0C) - Matches provided dataset (0x02A0F778)
        tlvData.append(contentsOf: [0x0C, 0x04, 0x02, 0xA0, 0xF7, 0x78])

        print(tlvData.hexadecimalString)
        return tlvData
    }
}
#endif
