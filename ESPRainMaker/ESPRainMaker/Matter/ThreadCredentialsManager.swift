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

import UIKit
import ThreadNetwork
import ESPProvision

@available(iOS 15.0, *)
class ThreadCredentialsManager: NSObject {
    
    static let shared = ThreadCredentialsManager()
    let client = THClient()
    
    /// Is thread supported
    /// - Parameter completion: status
    @available(iOS 16.4, *)
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
    
    /// Fetch thread credetials
    /// - Parameter completion: THCredentials
    func fetchThreadCredentialsWithError(_ completion: @escaping (THCredentials?, Error?) -> Void) {
        self.client.retrievePreferredCredentials { credentials, error in
            completion(credentials, error)
        }
    }
    
    /// Fetch generated thread operational dataset
    /// - Parameter completion: completion
    func fetchThreadOperationalDatasetWithError(_ completion: @escaping (Data?, Error?) -> Void) {
        self.fetchThreadCredentialsWithError { credentials, error in
            if let tod = credentials?.activeOperationalDataSet {
                completion(tod, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    /// Fetch all active thread credentials
    /// - Parameter completion: completion with (data for a single thread network, all thread networks)
    func fetchAllThreadCredentials(_ completion: @escaping (Data?, [THCredentials]?) -> Void) {
        self.client.retrieveAllCredentials { creds, error in
            if let creds = creds {
                let finalCreds = Array(creds)
                if finalCreds.count == 1 {
                    let cred = finalCreds[0]
                    if let activeOperationalDataSet = cred.activeOperationalDataSet {
                        completion(activeOperationalDataSet, nil)
                    } else {
                        completion(nil, nil)
                    }
                } else {
                    completion(nil, finalCreds)
                }
            } else {
                completion(nil, nil)
            }
        }
    }
    
    /// Fetch all active thread credentials
    /// - Parameter completion: completion with (data for a single thread network, all thread networks)
    func fetchMultipleThreadCredentials(_ completion: @escaping ([THCredentials]?) -> Void) {
        self.client.retrievePreferredCredentials { cred, _ in
            if let cred = cred {
                completion([cred])
            } else {
                completion(nil)
            }
        }
    }
    
    /// Check for saved thread credentials
    /// - Parameters:
    ///   - threadList: thread list
    ///   - completion: completion with matching thread credential
    func checkForSavedThreadCreds(threadList: [ESPThreadNetwork], _ completion: @escaping (THCredentials?) -> Void) {
        var index = 0
        self.checkThreadNetwork(index: index, threadList: threadList) { creds in
            index+=1
            guard let creds = creds else {
                if index < threadList.count {
                    self.checkThreadNetwork(index: index, threadList: threadList, completion: completion)
                } else {
                    completion(nil)
                }
                return
            }
            completion(creds)
        }
    }
    
    /// Check thread network
    /// - Parameters:
    ///   - index: the thread network at given index of thread list
    ///   - threadList: thread list
    ///   - completion: completion
    func checkThreadNetwork(index: Int = 0, threadList: [ESPThreadNetwork], completion: @escaping (THCredentials?) -> Void) {
        let extendedMacAddress = threadList[index].extAddr
        self.client.retrieveCredentials(forBorderAgent: extendedMacAddress) { creds, _ in
            if let creds = creds {
                completion(creds)
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
}
