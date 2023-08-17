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
//  ESPMTRCommissioner.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter
import CryptoKit

protocol ESPMTRUIDelegate: AnyObject {
    func showToastMessage(message: String)
    func hideToastMessage()
    func showLoaderInView(message: String)
    func hideLoaderFromView()
    func reloadData(groupId: String?, matterNodeId: String?)
    func showError(title: String, message: String, buttonTitle: String)
}

/// Matter controller class
@available(iOS 16.4, *)
class ESPMTRCommissioner: NSObject {
    
    var discoveryStarted: Bool = false
    let kEspressifVendorId: UInt16 = 0x131B
    var group: ESPNodeGroup?
    var fabricIndex: UInt8?
    var keys: MTRCSRKeys?
    let matterQueue = DispatchQueue(label: "com.zigbee.chip.qrcodevc.callback", qos: .userInteractive)
    public static let shared = ESPMTRCommissioner()
    public var sController: MTRDeviceController?
    var utilsDelegate: UtilsDelegate?
    var serverData: [String: [UInt]] = [String: [UInt]]()
    var clientData: [String: [UInt]] = [String: [UInt]]()
    var completion: ((MTROperationalCertificateChain?, Error?) -> Void)?
    weak var uidelegate: ESPMTRUIDelegate?
    var matterDeviceNotFoundCompletion: ((Bool) -> Void)?
    var isMaterTaskCompleted: Bool = false
    var lightQueue: DispatchQueue = DispatchQueue(label: "com.matter.light.queue")
    
    override init() {
        super.init()
    }
    
    /// Generate CSR
    /// - Returns: csr string
    func generateCSR(groupId: String, completion: @escaping (String?) -> Void) {
        let csrKeys = MTRCSRKeys(groupId: groupId)
        if let data = try? MTRCertificates.createCertificateSigningRequest(csrKeys) {
            let str = data.base64EncodedString()
            completion(str)
        } else {
            completion(nil)
        }
    }
    
    /// Start commissioning with user NOC
    /// - Parameters:
    ///   - onboardingPayload: onboarding payload
    ///   - deviceId: device id
    func startCommissioningWithUserNOC(onboardingPayload: String, deviceId: UInt64) {
        if let controller = sController, let payload = try? MTRSetupPayload(onboardingPayload: onboardingPayload) {
            do {
                try controller.setupCommissioningSession(with: payload, newNodeID: NSNumber(value: deviceId))
                if let group = self.group, let groupName = group.groupName, let deviceName = ESPMatterEcosystemInfo.shared.getDeviceName() {
                    DispatchQueue.main.async {
                        self.uidelegate?.showLoaderInView(message: "Commissioning \(deviceName) to \(groupName)")
                    }
                }
            }
            catch {
                print("ERROR pairAccessory: \(error.localizedDescription)")
            }
        }
    }
}

/// device attestation delegate
@available(iOS 16.4, *)
extension ESPMTRCommissioner: MTRDeviceAttestationDelegate {
    
    /// Device attestation completed
    /// - Parameters:
    ///   - controller: controller
    ///   - opaqueDeviceHandle: opaque device handle
    ///   - attestationDeviceInfo: attestation device info
    ///   - error: error
    func deviceAttestationCompleted(for controller: MTRDeviceController, opaqueDeviceHandle: UnsafeMutableRawPointer, attestationDeviceInfo: MTRDeviceAttestationDeviceInfo, error: Error?) {
        do {
            try controller.continueCommissioningDevice(opaqueDeviceHandle, ignoreAttestationFailure: true)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Device attestation failed
    /// - Parameters:
    ///   - controller: controller
    ///   - opaqueDeviceHandle: opaque device handle
    ///   - error: error
    func deviceAttestationFailed(for controller: MTRDeviceController, opaqueDeviceHandle: UnsafeMutableRawPointer, error: Error) {
        do {
            try controller.continueCommissioningDevice(opaqueDeviceHandle, ignoreAttestationFailure: true)
        } catch {
            print(error.localizedDescription)
        }
    }
}

/// NOC Chain issuer
@available(iOS 16.4, *)
extension ESPMTRCommissioner: MTROperationalCertificateIssuer {
    
    /// should skip attestation
    var shouldSkipAttestationCertificateValidation: Bool {
        return true
    }
    
    /// Issue operational certificate
    /// - Parameters:
    ///   - csrInfo: CSR info
    ///   - attestationInfo: attestation info
    ///   - controller: controller
    ///   - completion: completion
    func issueOperationalCertificate(forRequest csrInfo: MTROperationalCSRInfo, attestationInfo: MTRDeviceAttestationInfo, controller: MTRDeviceController, completion: @escaping (MTROperationalCertificateChain?, Error?) -> Void) {
        self.completion = completion
        let csrData = csrInfo.csr
        if let group = group, let groupId = group.groupID {
            let csrString = csrData.base64EncodedString()
            self.getDeviceMetaData { metadata in
                let nodeGroupURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion
                let service = ESPAddNodeToMatterFabricService(presenter: self)
                let finalCSR = "-----BEGIN CERTIFICATE REQUEST-----\n\(csrString)\n-----END CERTIFICATE REQUEST-----"
                print("FINAL CSR: \(finalCSR)")
                if let metadata = metadata, metadata.count > 0 {
                    service.addNodeToMatterFabric(url: nodeGroupURL, groupId: groupId, operation: "add", csr: finalCSR, metadata: metadata)
                } else {
                    service.addNodeToMatterFabric(url: nodeGroupURL, groupId: groupId, operation: "add", csr: finalCSR, metadata: nil)
                }
            }
        }
    }
}

/// add node to matter fabric response
@available(iOS 16.4, *)
extension ESPMTRCommissioner: ESPAddNodeToMatterFabricPresentationLogic {
    
    /// Node rempoved
    /// - Parameters:
    ///   - status: status
    ///   - error: error
    func nodeRemoved(status: Bool, error: Error?) {}
    
    /// Node NOC received from cloud
    /// - Parameters:
    ///   - groupId: group id
    ///   - response: response
    ///   - error: error
    func nodeNOCReceived(groupId: String, response: ESPAddNodeToFabricResponse?, error: Error?) {
        ESPMTRCommissioner.shared.matterQueue.sync {
            let deviceId = ESPMatterDeviceManager.shared.getCurrentDeviceId()
            if let completion = completion, let response = response {
                ESPMatterFabricDetails.shared.saveAddNodeToMatterFabricDetails(groupId: groupId, deviceId: deviceId, data: response)
                if let data = ESPMatterFabricDetails.shared.getAddNodeToMatterFabricDetails(groupId: groupId, deviceId: deviceId), let certs = data.certificates, certs.count > 0, let noc = certs[0].nodeNOC, let nocData = ESPDefaultData.convertPEMString(toDER: noc), let fabricData = group?.fabricDetails, let rootCACert = fabricData.rootCACertificate, let rootCertData = ESPDefaultData.convertPEMString(toDER: rootCACert) {
                    
                    if let fabData = group?.fabricDetails, let catIdAdmin = fabData.catIdAdmin, let id = "FFFFFFFD\(catIdAdmin)".hexToDecimal {
                        let params = MTROperationalCertificateChain(operationalCertificate: nocData, intermediateCertificate: nil, rootCertificate: rootCertData, adminSubject: NSNumber(value: id))
                        completion(params, nil)
                    }
                }
            }
        }
    }
}

/// matter pairing delegate
@available(iOS 16.4, *)
extension ESPMTRCommissioner: MTRDevicePairingDelegate {
    
    /// On status updated
    /// - Parameter status: pairing status
    func onStatusUpdate(_ status: MTRPairingStatus) {
        
    }
    
    /// On pairing completed
    /// - Parameter error: error
    func onPairingComplete(_ error: Error?) {
        guard let _ = error else {
            let deviceId = ESPMatterDeviceManager.shared.getCurrentDeviceId()
            let params = MTRCommissioningParameters()
            params.deviceAttestationDelegate = self
            if let controller = sController {
                do {
                    try controller.commissionNode(withID: NSNumber(value: deviceId), commissioningParams: params)
                } catch {
                    print(error.localizedDescription)
                }
            }
            return
        }
        self.hideLoaderAndShowFailure(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.mtrPairingFailedMsg, buttonTitle: ESPMatterConstants.okTxt)
    }
    
    /// On pairing deleted callback
    /// - Parameter error: error
    func onPairingDeleted(_ error: Error?) {}
    
    /// On commissioning complete
    /// - Parameter error: error
    func onCommissioningComplete(_ error: Error?) {
        let temporaryDeviceId = ESPMatterDeviceManager.shared.getCurrentDeviceId()
        guard let _ = error else {
            if let group = group, let grpId = group.groupID, let data = ESPMatterFabricDetails.shared.getAddNodeToMatterFabricDetails(groupId: grpId, deviceId: temporaryDeviceId), let certs = data.certificates, certs.count > 0, let requestId = data.requestId, let matterNodeId = certs[0].getMatterNodeId() {
                self.performPostCommissioningAction(groupId: grpId, requestId: requestId, matterNodeId: matterNodeId)
            }
            return
        }
    }
}
#endif
