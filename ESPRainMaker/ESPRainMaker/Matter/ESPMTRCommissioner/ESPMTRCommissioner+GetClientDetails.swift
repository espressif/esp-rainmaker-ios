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
//  ESPMTRCommissioner+GetClientDetails.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Get all clients
    /// - Parameters:
    ///   - deviceId: device id
    ///   - index: index
    ///   - endpoints: endpoints
    ///   - completionHadnler: completionHandler
    func getAllClients(deviceId: UInt64, index: Int, endpoints: [UInt], completionHadnler: @escaping ([String: [UInt]]) -> Void) {
        self.getClient(forIndex: index, endpoints: endpoints, deviceId: deviceId) { val, ind in
            if let val = val, val.count > 0 {
                let endpoint = endpoints[ind]
                self.clientData["\(endpoint)"] = val
            }
            if ind+1 < endpoints.count {
                self.getAllClients(deviceId: deviceId, index: ind+1, endpoints: endpoints, completionHadnler: completionHadnler)
            } else {
                completionHadnler(self.clientData)
            }
        }
    }
    
    /// Get client
    /// - Parameters:
    ///   - index: index
    ///   - endpoints: endpoints
    ///   - deviceId: device id
    ///   - completionHandler: completionHandler
    func getClient(forIndex index: Int, endpoints: [UInt], deviceId: UInt64, completionHandler: @escaping ([UInt]?, Int) -> Void) {
        if index < endpoints.count {
            let endpoint = endpoints[index]
            self.getDescriptor(deviceId: deviceId, endPoint: UInt16(endpoint)) { desc in
                if let desc = desc {
                    desc.readAttributeClientList() { values, error in
                        guard let _ = error else {
                            if let values = values as? [UInt] {
                                completionHandler(values, index)
                            }
                            return
                        }
                        completionHandler(nil, index)
                    }
                } else {
                    completionHandler(nil, index)
                }
            }
        } else {
            completionHandler(nil, index)
        }
    }
}
#endif
