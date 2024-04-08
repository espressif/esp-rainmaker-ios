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
//  DeviceViewController+MTRACParamDelegate.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import UIKit

@available(iOS 16.4, *)
extension DeviceViewController: MTRACParamDelegate {
    
    func acSystemModeSet() {
        for index in 0..<self.cellInfo.count {
            let val = self.cellInfo[index]
            if val == ESPMatterConstants.occupiedCoolingSetpoint {
                if let node = self.node, let matterNodeId = node.matterNodeID, let deviceId = matterNodeId.hexToDecimal, let item = node.getMatterSystemMode(deviceId: deviceId), [ESPMatterConstants.heat, ESPMatterConstants.cool].contains(item) {
                    DispatchQueue.main.async {
                        self.deviceTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    }
                    break
                }
            }
        }
    }
}
#endif
