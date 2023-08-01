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
//  ESPMTRCommissioner+CommissioningComplete.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Confirm node comissioning
    /// - Parameters:
    ///   - groupId: group id
    ///   - requestId: request id
    func performPostCommissioningAction(groupId: String, requestId: String, matterNodeId: String) {
        if let deviceId = matterNodeId.hexToDecimal {
            self.fetchRainmakerNodeId(deviceId: deviceId) { rainmakerNodeId in
                if let rainmakerNodeId = rainmakerNodeId {
                    ESPMatterFabricDetails.shared.saveRainmakerType(groupId: groupId, deviceId: deviceId, val: ESPMatterConstants.trueFlag)
                    self.sendMatterNodeId(deviceId: deviceId, matterNodeId: matterNodeId) { result in
                        if result {
                            self.readAttributeChallenge(deviceId: deviceId) { challenge in
                                if let challenge = challenge {
                                    self.confirmMatterRainmakerCommissioning(requestId: requestId, groupId: groupId, rainmakerNodeId: rainmakerNodeId, challenge: challenge)
                                } else {
                                    self.hideLoaderAndShowFailure(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.challengeFailedMsg, buttonTitle: ESPMatterConstants.okTxt)
                                }
                            }
                        } else {
                            self.hideLoaderAndShowFailure(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.fetchChallengeFailedMsg, buttonTitle: ESPMatterConstants.okTxt)
                        }
                    }
                } else {
                    self.confirmMatterNodeCommissioning(requestId: requestId, groupId: groupId)
                }
            }
        }
    }
    
    /// Confirm matter only device commissioning
    /// - Parameters:
    ///   - requestId: request id
    ///   - groupId: group id
    func confirmMatterNodeCommissioning(requestId: String, groupId: String) {
        let nodeGroupURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion
        let confirmNodeCommissioningService = ESPConfirmNodeCommissioningService(presenter: self)
        confirmNodeCommissioningService.confirmNodeCommissioning(url: nodeGroupURL, groupId: groupId, requestId: requestId, status: ESPMatterConstants.success)
    }
    
    /// Confirm Matter+Rainmaker commissioning
    /// - Parameters:
    ///   - requestId: request id
    ///   - groupId: group id
    ///   - rainmakerNodeId: rainmaker node id
    ///   - challenge: challenge
    func confirmMatterRainmakerCommissioning(requestId: String, groupId: String, rainmakerNodeId: String, challenge: String) {
        let worker = ESPExtendUserSessionWorker()
        worker.checkUserSession { token, _ in
            if let token = token {
                let nodeGroupURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion
                let confirmNodeCommissioningService = ESPConfirmNodeCommissioningService(presenter: self)
                confirmNodeCommissioningService.confirmMatterRainmakerCommissioning(url: nodeGroupURL, groupId: groupId, requestId: requestId, rainmakerNodeId: rainmakerNodeId, challenge: challenge, token: token)
            } else {
                self.uidelegate?.showError(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.commissioningFailedMsg, buttonTitle: ESPMatterConstants.okTxt)
            }
        }
    }
}

/// confirm node commissioning
@available(iOS 16.4, *)
extension ESPMTRCommissioner: ESPConfirmNodeCommissioningPresentationLogic {
    
    /// Export matter node data
    /// - Parameters:
    ///   - isRainmaker: is rainmaker node
    ///   - groupId: group id
    ///   - matterNodeId: matter node id
    ///   - temporaryDeviceId: temporary device id
    func exportMatterNodeData(isRainmaker: Bool, groupId: String, matterNodeId: String, temporaryDeviceId: UInt64) {
        if let id = matterNodeId.hexToDecimal {
            ESPMatterFabricDetails.shared.exportData(groupId: groupId, temporaryDeviceId: temporaryDeviceId, matterNodeId: matterNodeId)
            let isRainmakerFlag = isRainmaker ? ESPMatterConstants.trueFlag : ESPMatterConstants.falseFlag
            ESPMatterFabricDetails.shared.saveRainmakerType(groupId: groupId, deviceId: id, val: isRainmakerFlag)
            ESPMatterFabricDetails.shared.saveDeviceName(groupId: groupId, matterNodeId: matterNodeId)
            DispatchQueue.main.async {
                self.uidelegate?.showLoaderInView(message: ESPMatterConstants.fetchingEndpointsMsg)
            }
            self.addDeviceDetailsCatId(writeCatIdOperate: true, groupId: groupId, deviceId: id) {
                DispatchQueue.main.async {
                    self.uidelegate?.hideLoaderFromView()
                    self.uidelegate?.reloadData(groupId: groupId, matterNodeId: matterNodeId)
                }
            }
        }
    }
    
    /// Matter+Rainmaker user node association confirmed
    /// - Parameter status: commissioning status
    func matterRainmakerCommissioningConfirmed(status: String?, token: String) {
        self.uidelegate?.hideLoaderFromView()
        let temporaryDeviceId = ESPMatterDeviceManager.shared.getCurrentDeviceId()
        if let _ = status {
            if let group = group, let grpId = group.groupID, let data = ESPMatterFabricDetails.shared.getAddNodeToMatterFabricDetails(groupId: grpId, deviceId: temporaryDeviceId), let certs = data.certificates, certs.count > 0, let matterNodeId = certs[0].getMatterNodeId() {
                self.exportMatterNodeData(isRainmaker: true, groupId: grpId, matterNodeId: matterNodeId, temporaryDeviceId: temporaryDeviceId)
            }
        } else {
            self.uidelegate?.showError(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.commissioningFailedMsg, buttonTitle: ESPMatterConstants.okTxt)
        }
    }
    
    /// Node commissioning confirmed callback
    /// - Parameters:
    ///   - response: response
    ///   - error: error
    func nodeCommissioningConfirmed(response: ESPConfirmNodeCommissioningResponse?, error: Error?) {
        self.uidelegate?.hideLoaderFromView()
        let temporaryDeviceId = ESPMatterDeviceManager.shared.getCurrentDeviceId()
        guard let _ = error else {
            if let response = response, let status = response.status, status.lowercased() == ESPMatterConstants.success {
                if let group = group, let grpId = group.groupID, let data = ESPMatterFabricDetails.shared.getAddNodeToMatterFabricDetails(groupId: grpId, deviceId: temporaryDeviceId), let certs = data.certificates, certs.count > 0, let matterNodeId = certs[0].matterNodeId {
                    self.exportMatterNodeData(isRainmaker: false, groupId: grpId, matterNodeId: matterNodeId, temporaryDeviceId: temporaryDeviceId)
                }
            }
            return
        }
        self.uidelegate?.showError(title: ESPMatterConstants.failureTxt, message: ESPMatterConstants.commissioningFailedMsg, buttonTitle: ESPMatterConstants.okTxt)
    }
}
#endif
