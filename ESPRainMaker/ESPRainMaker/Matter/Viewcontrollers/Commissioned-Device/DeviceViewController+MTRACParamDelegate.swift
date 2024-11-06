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
        if let node = self.node, let matterNodeId = node.matterNodeID, let deviceId = matterNodeId.hexToDecimal, let item = node.getMatterSystemMode(deviceId: deviceId) {
            switch item {
            case ESPMatterConstants.heat, ESPMatterConstants.cool:
                let isHeatMode = (item == ESPMatterConstants.heat)
                
                for (index, val) in self.cellInfo.enumerated() {
                    DispatchQueue.main.async {
                        switch val {
                        case ESPMatterConstants.occupiedCoolingSetpoint:
                            self.hideOCS = !isHeatMode
                        case ESPMatterConstants.occupiedHeatingSetpoint:
                            self.hideOHS = isHeatMode
                        default:
                            return
                        }
                        self.deviceTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    }
                }
            default:
                for (index, val) in self.cellInfo.enumerated() {
                    if val == ESPMatterConstants.occupiedCoolingSetpoint || val == ESPMatterConstants.occupiedHeatingSetpoint {
                        DispatchQueue.main.async {
                            if val == ESPMatterConstants.occupiedCoolingSetpoint {
                                self.hideOCS = true
                            } else {
                                self.hideOHS = true
                            }
                            self.deviceTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        }
                    }
                }
            }
        }
    }
}
#endif
