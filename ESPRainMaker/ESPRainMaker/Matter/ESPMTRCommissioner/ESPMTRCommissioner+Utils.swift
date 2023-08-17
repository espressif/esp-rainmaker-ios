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
//  ESPMTRCommissioner+Utils.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter
import CryptoKit

protocol UtilsDelegate {
    func showLoader()
    func hideLoader()
    func deviceAdded()
}

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Create sec key
    /// - Parameter pem: pem
    /// - Returns: desc
    func createSecKeyWithPEMSecp256r1Private(_ pem: String) throws -> SecKey? {
        if #available(iOS 14.0, *) {
            let privateKeyCK = try P256.Signing.PrivateKey(pemRepresentation: pem)
            let x963Data = privateKeyCK.x963Representation
            var errorQ: Unmanaged<CFError>? = nil
            guard let privateKeySF = SecKeyCreateWithData(x963Data as NSData, [
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            ] as NSDictionary, &errorQ) else {
                throw errorQ!.takeRetainedValue()
            }
            return privateKeySF
        } else {
            // Fallback on earlier versions
        }
        return nil
    }
    
    /// Is connected to matter
    /// - Parameter completion: completion
    func isConnectedToMatter(timeout: Double, deviceId: UInt64, _ completion: @escaping(Bool) -> Void) {
        self.isMaterTaskCompleted = false
        self.matterDeviceNotFoundCompletion = completion
        if let controller = sController {
            controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if !self.isMaterTaskCompleted {
                    self.isMaterTaskCompleted = true
                    if let _ = device {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
            Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(matterDeviceNotFound), userInfo: nil, repeats: false)
        } else {
            completion(false)
        }
    }
    
    /// Is connected to matter
    /// - Parameter completion: completion
    func isConnectedToMatterNodeId(timeout: Double, matterNodeId: String, _ completion: @escaping(String, Bool) -> Void) {
        if let deviceId = matterNodeId.hexToDecimal {
            var isMaterTaskCompleted = false
            if let controller = sController {
                controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                    if !isMaterTaskCompleted {
                        isMaterTaskCompleted = true
                        if let _ = device {
                            completion(matterNodeId, true)
                        } else {
                            completion(matterNodeId, false)
                        }
                    }
                }
                Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
                    if !isMaterTaskCompleted {
                        isMaterTaskCompleted = true
                        completion(matterNodeId, false)
                    }
                }
            } else {
                completion(matterNodeId, false)
            }
        }
    }
    
    /// Matter device not found
    @objc func matterDeviceNotFound() {
        if !self.isMaterTaskCompleted, let completion = self.matterDeviceNotFoundCompletion {
            self.isMaterTaskCompleted = true
            completion(false)
        }
    }
    
    /// Hide loader and show failure
    /// - Parameters:
    ///   - title: title
    ///   - message: message
    ///   - buttonTitle: button title
    func hideLoaderAndShowFailure(title: String, message: String, buttonTitle: String) {
        self.uidelegate?.hideLoaderFromView()
        self.uidelegate?.showError(title: title, message: message, buttonTitle: buttonTitle)
    }
    
    /// Get device metadata
    /// - Parameter completion: metadata
    func getDeviceMetaData(completion: @escaping ([String: Any]?) -> Void) {
        let deviceId = ESPMatterDeviceManager.shared.getCurrentDeviceId()
        if let group = self.group, let groupId = group.groupID {
            self.addDeviceDetails(groupId: groupId, deviceId: deviceId) {
                var metaData = [String: Any]()
                metaData[ESPMatterConstants.groupId] = groupId
                if let deviceName = ESPMatterEcosystemInfo.shared.getDeviceName() {
                    metaData[ESPMatterConstants.deviceName] = deviceName
                }
                self.readAttributeRainmakerNodeIdFromDevice(deviceId: deviceId) { rainmakerNodeId in
                    if let _ = rainmakerNodeId {
                        metaData[ESPMatterConstants.isRainmaker] = true
                    } else {
                        metaData[ESPMatterConstants.isRainmaker] = false
                    }
                    self.extractDeviceMetaData(groupId: groupId, deviceId: deviceId, metaData: &metaData)
                    completion(metaData)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    /// Get device metadata from matter device
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    ///   - metaData: meta data
    func extractDeviceMetaData(groupId: String, deviceId: UInt64, metaData: inout [String: Any]) {
        let serversData = ESPMatterFabricDetails.shared.fetchServersData(groupId: groupId, deviceId: deviceId)
        let clientsData = ESPMatterFabricDetails.shared.fetchClientsData(groupId: groupId, deviceId: deviceId)
        let endpointsData = ESPMatterFabricDetails.shared.fetchEndpointsData(groupId: groupId, deviceId: deviceId)
        if ESPMatterClusterUtil.shared.isRainmakerControllerServerSupported(groupId: groupId, deviceId: deviceId).0, let controllerNodeId = self.sController?.controllerNodeID {
            let id = controllerNodeId.uint64Value
            let str = String(id, radix: 16)
            metaData[ESPMatterConstants.controllerNodeId] = str
        }
        if serverData.count > 0 {
            metaData[ESPMatterConstants.serversData] = serversData
        }
        if clientsData.count > 0 {
            metaData[ESPMatterConstants.clientsData] = clientsData
        }
        if endpointsData.count > 0 {
            metaData[ESPMatterConstants.endpointsData] = endpointsData
        }
        if let deviceType = ESPMatterFabricDetails.shared.getDeviceType(groupId: groupId, deviceId: deviceId) {
            metaData[ESPMatterConstants.deviceType] = deviceType
        }
        if let vendorId = ESPMatterFabricDetails.shared.getVendorId(groupId: groupId, deviceId: deviceId) {
            metaData[ESPMatterConstants.vendorId] = vendorId
        }
        if let productId = ESPMatterFabricDetails.shared.getProductId(groupId: groupId, deviceId: deviceId) {
            metaData[ESPMatterConstants.productId] = productId
        }
        if let softwareVersion = ESPMatterFabricDetails.shared.getSoftwareVersion(groupId: groupId, deviceId: deviceId) {
            metaData[ESPMatterConstants.softwareVersion] = softwareVersion
        }
    }
}
#endif
