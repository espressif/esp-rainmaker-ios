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
//  ESPMTRCommissioner+GetDescriptor.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import Matter

@available(iOS 16.4, *)
extension ESPMTRCommissioner {
    
    /// Get matter descriptor
    /// - Parameters:
    ///   - deviceId: device id
    ///   - endPoint: endpoint id
    ///   - completion: completion handler
    func getDescriptor(deviceId: UInt64, endPoint: UInt16, completion: @escaping (MTRBaseClusterDescriptor?) -> Void) {
        if let controller = sController {
            if let device = try? controller.getDeviceBeingCommissioned(deviceId) {
                if let descriptor = MTRBaseClusterDescriptor(device: device, endpointID: NSNumber(value: endPoint), queue: ESPMTRCommissioner.shared.matterQueue) {
                    completion(descriptor)
                } else {
                    completion(nil)
                }
            } else {
                controller.getBaseDevice(deviceId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                    if let device = device, let descriptor = MTRBaseClusterDescriptor(device: device, endpointID: NSNumber(value: endPoint), queue: ESPMTRCommissioner.shared.matterQueue) {
                        completion(descriptor)
                    } else {
                        completion(nil)
                    }
                }
            }
        } else {
            completion(nil)
        }
    }
}
#endif
