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
//  DeviceViewController+OnOffDelegate.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation

@available(iOS 16.4, *)
extension DeviceViewController: OnOffDelegate {
    
    /// On/off action taken
    /// - Parameters:
    ///   - dId: device id
    ///   - endpointId: endpoint id
    ///   - state: state
    func actionTaken(dId: UInt64?, endpointId: UInt16?, state: OnOffState) {
        var endPoint = self.endPoint
        if let endpointId = endpointId {
            endPoint = endpointId
        }
        if let dId = dId, let controller = ESPMTRCommissioner.shared.sController {
            controller.getBaseDevice(dId, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let onOffCluster = MTRBaseClusterOnOff(device: device, endpointID: NSNumber(value: endPoint), queue: ESPMTRCommissioner.shared.matterQueue) {
                    switch state {
                    case .off:
                        onOffCluster.off { _ in}
                    case .on:
                        onOffCluster.on { _ in}
                    case .toggle:
                        onOffCluster.toggle { _ in}
                    }
                }
            }
        }
    }
}
#endif
