// Copyright 2024 Espressif Systems
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
//  ESPMatterCommissioningVC+TBRUtil.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import UIKit
import MatterSupport
import Matter
import Foundation

@available(iOS 16.4, *)
extension ESPMatterCommissioningVC {
    
    /// Read thread dataset from device
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endpoint: endpoint
    ///   - groupId: group id
    ///   - completion: completion
    func readThreadDataFromDevice(deviceId: UInt64, endpoint: UInt16, groupId: String, completion: @escaping (_ activeOpsDataset: Data?, _ borderAgentId: Data?) -> Void) {
        #if MTR_ENABLE_PROVISIONAL
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
        commissioner.getTBRActiveOperationalDataset(deviceId: deviceId, endpoint: endpoint) { dataset in
            commissioner.readTBRAttributeBorderAgentId(deviceId: deviceId, endpoint: endpoint) { borderAgentId in
                completion(dataset, borderAgentId)
            }
        }
        #else
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
        commissioner.readAttributeActiveOpDataset(deviceId: deviceId, endpoint: endpoint) { dataset in
            commissioner.readAttributeBorderAgentId(deviceId: deviceId, endpoint: endpoint) { bAgentId in
                completion(dataset, bAgentId)
            }
        }
        #endif
    }
    
    /// Perform TBR related actions
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    @available(iOS 18.4, *)
    func performThreadOperations(groupId: String, deviceId: UInt64) {
        let commissioner = ESPMTRCommissionerManager.shared.getCommissioner(for: groupId)
        commissioner.updateThreadDataset(groupId: groupId, deviceId: deviceId) { status, message in
            guard status else {
                if let message = message {
                    if  message == ThreadBRMessages.homepodDatasetNotAvailable.rawValue {
                        commissioner.updateThreadDataLocally(groupId: groupId, deviceId: deviceId) { _, _ in
                            DispatchQueue.main.async {
                                self.navigateToDevicesScreen()
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.alertUser(title: ThreadBRMessages.failure.rawValue,
                                           message: message,
                                           buttonTitle: "OK") {
                                self.navigateToDevicesScreen()
                            }
                        }
                    }
                }
                return
            }
            DispatchQueue.main.async {
                self.navigateToDevicesScreen()
            }
        }
    }
    
    /// Perform TBR action and navigate to devices screen
    /// - Parameters:
    ///   - groupId: group id
    ///   - deviceId: device id
    @available(iOS 18.4, *)
    func performTBRActionAndNavigate(groupId: String, deviceId: UInt64) {
        if ESPMatterClusterUtil.shared.isTBRMSupported(groupId: groupId, deviceId: deviceId).0 {
            self.performThreadOperations(groupId: groupId, deviceId: deviceId)
        } else {
            self.navigateToDevicesScreen()
        }
    }
}
#endif
