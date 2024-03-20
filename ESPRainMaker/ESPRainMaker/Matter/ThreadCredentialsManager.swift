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
//  ThreadCredentialsManager.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import UIKit
import ThreadNetwork

@available(iOS 16.4, *)
class ThreadCredentialsManager: NSObject {

    static let shared = ThreadCredentialsManager()
    let client = THClient()
    
    /// Is thread supported
    /// - Parameter completion: status
    func isThreadSupported(_ completion: @escaping (Bool) -> Void) {
        self.client.isPreferredNetworkAvailable { result in
            completion(result)
        }
    }
    
    /// Fetch thread credetials
    /// - Parameter completion: THCredentials
    func fetchThreadCredentials(_ completion: @escaping (THCredentials?) -> Void) {
        self.client.retrievePreferredCredentials { credentials, _ in
            completion(credentials)
        }
    }
    
    /// Fetch generated thread operational dataset
    /// - Parameter completion: completion
    func fetchThreadOperationalDataset(_ completion: @escaping (Data?) -> Void) {
        self.fetchThreadCredentials { credentials in
            if let tod = credentials?.activeOperationalDataSet {
                completion(tod)
            } else {
                completion(nil)
            }
        }
    }
    
    /// Save thread operational credentials
    /// - Parameter completion: thread completion
    func saveThreadOperationalCredentials(activeOpsDataset: Data, borderAgentId: Data, completion: @escaping(Bool) -> Void) {
        self.client.storeCredentials(forBorderAgent: borderAgentId, activeOperationalDataSet: activeOpsDataset) { error in
            guard let _ = error else {
                completion(true)
                return
            }
            completion(false)
        }
    }
    
    /// Get generated thread operational dataset
    /// - Parameter completion: completion with thread operational dataset
    func getGeneratedTOD(_ completion: @escaping (Data?) -> Void)  {
        /*var zero = 0x00
         var NUM_CHANNEL_BYTES = 3
         var NUM_PANID_BYTES = 2
         var NUM_XPANID_BYTES = 8
         var NUM_MASTER_KEY_BYTES = 16
         var TYPE_CHANNEL = 0 // Type of Thread Channel TLV.
         var TYPE_PANID = 1 // Type of Thread PAN ID TLV.
         var TYPE_XPANID = 2 // Type of Thread Extended PAN ID TLV.
         var TYPE_MASTER_KEY = 5 // Type of Thread Network Master Key TLV.
              
         self.fetchThreadCredentials { credentials in
            if let credentials = credentials {
                var dataset: [UInt8] = [UInt8]()
                //Channel data
                if let data = Data(bytes: &TYPE_CHANNEL, count: MemoryLayout.size(ofValue: TYPE_CHANNEL)) {
                    dataset += data
                }
                if let data = Data(bytes: &NUM_CHANNEL_BYTES, count: MemoryLayout.size(ofValue: NUM_CHANNEL_BYTES)) {
                    dataset += data
                }
                if let data = Data(bytes: &zero, count: MemoryLayout.size(ofValue: zero)) {
                    dataset += data
                }
                if let channel = credentials.channel {
                    var channelRSInput = ((channel >> 8) & 0xFF)
                    if let channelRSInputData = Data(bytes: &channelRSInput, count: MemoryLayout.size(ofValue: channelRSInput)) {
                        dataset += channelRSInputData
                    }
                    var channelInput = (channel & 0xFF)
                    if let channelInputData = Data(bytes: &channelInput, count: MemoryLayout.size(ofValue: channelInput)) {
                        dataset += channelInputData
                    }
                }
                //Pan ID
                if let data = Data(bytes: &TYPE_PANID, count: MemoryLayout.size(ofValue: TYPE_PANID)) {
                    dataset += data
                }
                if let data = Data(bytes: &NUM_PANID_BYTES, count: MemoryLayout.size(ofValue: NUM_PANID_BYTES)) {
                    dataset += data
                }
                if let panIDData = credentials.panID, let panId = panIDData.withUnsafeBytes { $0.pointee } as? Int {
                    let panIdRSInput = ((panId >> 8) & 0xFF)
                    if var panIdRSData = Data(bytes: &panIdRSInput, count: MemoryLayout.size(ofValue: panIdRSInput)) {
                        dataset += panIdRSData
                    }
                    let panIdInput = (panId & 0xFF)
                    let panIdData = Data(bytes: &panIdInput, count: MemoryLayout.size(ofValue: panIdInput)) {
                        dataset += panIdData
                    }
                }
                //Extended Pan ID
                if let data = Data(bytes: &TYPE_XPANID, count: MemoryLayout.size(ofValue: TYPE_XPANID)) {
                    dataset += data
                }
                if let data = Data(bytes: &NUM_XPANID_BYTES, count: MemoryLayout.size(ofValue: NUM_XPANID_BYTES)) {
                    dataset += data
                }
                if let extendedPanIDData = credentials.extendedPANID, let extendedPanId = extendedPanIDData.withUnsafeBytes { $0.pointee } as? Int {
                    let extendedPanIdRSInput = ((extendedPanId >> 8) & 0xFF)
                    if var extendedPanIdRSData = Data(bytes: &extendedPanIdRSInput, count: MemoryLayout.size(ofValue: extendedPanIdRSInput)) {
                        dataset += extendedPanIdRSData
                    }
                    let extendedPanIdInput = (extendedPanId & 0xFF)
                    let extendedPanIdData = Data(bytes: &extendedPanIdInput, count: MemoryLayout.size(ofValue: extendedPanIdInput)) {
                        dataset += extendedPanIdData
                        }
                    }
                    //Network Master Key
                    if let data = Data(bytes: &TYPE_MASTER_KEY, count: MemoryLayout.size(ofValue: TYPE_MASTER_KEY)) {
                        dataset += data
                    }
                    if let data = Data(bytes: &NUM_MASTER_KEY_BYTES, count: MemoryLayout.size(ofValue: NUM_MASTER_KEY_BYTES)) {
                        dataset += data
                    }
                    if let networkKeyData = credentials.networkKey {
                        dataset += networkKeyData
                    }
                    completion(dataset)
                } else {
                    completion(nil)
                }
            }*/
    }
}
#endif
