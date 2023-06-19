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
//  ESPMTRCommissioner+Setup.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Shut down matter controller
    func shutDownController() {
        self.group = nil
        if let _ = sController {
            sController?.shutdown()
            sController = nil
        }
    }
    
    /// Init matter controller with user noc
    /// - Parameters:
    ///   - matterFabricData: matter fabric data
    ///   - userNOCData: user NOC data
    func initializeMTRControllerWithUserNOC(matterFabricData: ESPNodeGroup, userNOCData: ESPIssueUserNOCResponse) {
        let storage = ESPMatterStorage.shared
        let factory = MTRDeviceControllerFactory.sharedInstance()
        let factoryParams = MTRDeviceControllerFactoryParams(storage: storage)
        if let _ = matterFabricData.fabricID?.hexToDecimal {
            do {
                try factory.start(factoryParams)
            } catch {
                return
            }
            if let grpId = group?.groupID {
                let keys = MTRCSRKeys(groupId: grpId)
                if let details = matterFabricData.fabricDetails, let rootCA = details.rootCACertificate, let rootCADerBytes = MTRCertificates.convertPEMString(toDER: rootCA), let certs = userNOCData.certificates, certs.count > 0, let noc = certs[0].userNOC, let nocDerBytes = MTRCertificates.convertPEMString(toDER: noc) {
                    var finalIPK = keys.ipk
                    if let ipkString = ESPMatterFabricDetails.shared.getIPK(groupId: grpId), ipkString.replacingOccurrences(of: " ", with: "").lowercased() != "", let savedIpk = ipkString.hexadecimal {
                        finalIPK = savedIpk
                    }
                    let params = MTRDeviceControllerStartupParams(ipk: finalIPK,
                                                                  operationalKeypair: keys,
                                                                  operationalCertificate: nocDerBytes,
                                                                  intermediateCertificate: nil,
                                                                  rootCertificate: rootCADerBytes)
                    if let attestationCertificate = ESPMatterEcosystemInfo.shared.getAttestationInfo() {
                        let vendorId = MTRCertificates.getVendorId(fromCert: attestationCertificate)
                        ESPDefaultData.shared.saveVendorId(groupId: grpId, vendorId: vendorId)
                        params.vendorID = NSNumber(value: vendorId)
                        ESPMatterEcosystemInfo.shared.removeAttestationInfo()
                        ESPMatterEcosystemInfo.shared.removeCertDeclaration()
                    } else if let vendorId = ESPDefaultData.shared.getVendorId(groupId: grpId) {
                        params.vendorID = NSNumber(value: vendorId)
                    } else {
                        params.vendorID = NSNumber(value: kTestVendorId)
                    }
                    params.operationalCertificateIssuer = self
                    params.operationalCertificateIssuerQueue = self.matterQueue
                    if let controller = try? factory.createController(onNewFabric: params) {
                        sController = controller
                        sController?.setDeviceControllerDelegate(self, queue: self.matterQueue)
                    } else if let controller = try? factory.createController(onExistingFabric: params) {
                        sController = controller
                        sController?.setDeviceControllerDelegate(self, queue: self.matterQueue)
                    }
                    return
                }
            }
        }
    }
}

@available(iOS 16.4, *)
extension ESPMTRCommissioner: MTRDeviceControllerDelegate {
    func controller(_ controller: MTRDeviceController, statusUpdate status: MTRCommissioningStatus) {
        
    }
    
    func controller(_ controller: MTRDeviceController, commissioningComplete error: Error?) {
        let temporaryDeviceId = ESPMatterDeviceManager.shared.getCurrentDeviceId()
        guard let _ = error else {
            if let group = group, let grpId = group.groupID, let data = ESPMatterFabricDetails.shared.getAddNodeToMatterFabricDetails(groupId: grpId, deviceId: temporaryDeviceId), let certs = data.certificates, certs.count > 0, let requestId = data.requestId, let matterNodeId = certs[0].matterNodeId {
                self.performPostCommissioningAction(groupId: grpId, requestId: requestId, matterNodeId: matterNodeId)
            }
            return
        }
    }
    
    func controller(_ : MTRDeviceController, commissioningSessionEstablishmentDone error: Error?) {
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
}
#endif
