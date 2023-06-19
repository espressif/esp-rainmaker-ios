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
//  ESPMTRCommissioner+GetServerDetails.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Get all servers
    /// - Parameters:
    ///   - deviceId: device id
    ///   - index: index
    ///   - endpoints: endpoints
    ///   - completionHandler: completionHandler with all servers
    func getAllServers(deviceId: UInt64, index: Int, endpoints: [UInt], completionHandler: @escaping
([String: [UInt]]) -> Void) {
        self.getServer(forIndex: index, endpoints: endpoints, deviceId: deviceId) { val, ind in
            if let val = val, val.count > 0 {
                let endpoint = endpoints[ind]
                self.serverData["\(endpoint)"] = val
            }
            if ind+1 < endpoints.count {
                self.getAllServers(deviceId: deviceId, index: ind+1, endpoints: endpoints, completionHandler: completionHandler)
            } else {
                completionHandler(self.serverData)
            }
        }
    }
    
    /// Get server
    /// - Parameters:
    ///   - index: index
    ///   - endpoints: endPoints
    ///   - deviceId: device id
    ///   - completionHandler: completionHandler [endpoint: [servers]]
    func getServer(forIndex index: Int, endpoints: [UInt], deviceId: UInt64, completionHandler: @escaping ([UInt]?, Int) -> Void) {
        if index < endpoints.count {
            let endpoint = endpoints[index]
            self.getDescriptor(deviceId: deviceId, endPoint: UInt16(endpoint)) { desc in
                if let desc = desc {
                    desc.readAttributeServerList() { values, error in
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
