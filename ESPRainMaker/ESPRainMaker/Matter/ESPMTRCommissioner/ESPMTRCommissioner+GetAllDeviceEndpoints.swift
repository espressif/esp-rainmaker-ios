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
//  ESPMTRCommissioner+GetAllDeviceEndpoints.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Get all device endpoints
    /// - Parameters:
    ///   - deviceId: device id
    ///   - completionHandler: all device endpoints
    func getAllDeviceEndpoints(deviceId: UInt64, completionHandler: @escaping ([UInt])->Void) {
        var data: [UInt] = [0]
        self.getDescriptor(deviceId: deviceId, endPoint: 0) { desc in
            if let desc = desc {
                desc.readAttributePartsList() { values, error in
                    guard let _ = error else {
                        if let values = values as? [UInt], values.count > 0 {
                            data.append(contentsOf: values)
                            completionHandler(data)
                        }
                        return
                    }
                    completionHandler(data)
                }
            } else {
                completionHandler(data)
            }
        }
    }
}
#endif
