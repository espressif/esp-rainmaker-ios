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
//  DeviceViewController+TableView.swift
//  ESPRainmaker
//

import Foundation
import UIKit

#if ESPRainMakerMatter
@available(iOS 16.4, *)
extension DeviceViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < cellInfo.count {
            let value = cellInfo[indexPath.row]
            if value == ESPMatterConstants.onOff {
                return 100.0
            } else if value == ESPMatterConstants.openCW {
                return 100.0
            } else if value == ESPMatterConstants.delete {
                return 75.0
            } else if value == ESPMatterConstants.levelControl || value == ESPMatterConstants.colorControl {
                return 126.0
            } else if value == ESPMatterConstants.rainmakerController {
                return 100.0
            }
        }
        return 0.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellInfo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if cellInfo.count == 1, indexPath.row < cellInfo.count {
            let value = cellInfo[indexPath.row]
            if value == ESPMatterConstants.delete, let cell = tableView.dequeueReusableCell(withIdentifier: RemoveDeviceCell.reuseIdentifier, for: indexPath) as? RemoveDeviceCell {
                cell.delegate = self
                self.setAutoresizingMask(cell)
                return cell
            }
        }
        if let group = group, let groupId = group.groupID, let matterNodeId = matterNodeId, let _ = matterNodeId.hexToDecimal, let deviceId = matterNodeId.hexToDecimal, indexPath.row < cellInfo.count {
            let value = cellInfo[indexPath.row]
            if value == ESPMatterConstants.onOff {
                
                if let cell = tableView.dequeueReusableCell(withIdentifier: DeviceOnOffCell.reuseIdentifier, for: indexPath) as? DeviceOnOffCell {
                    cell.node = self.node
                    cell.deviceId = deviceId
                    cell.delegate = self
                    cell.group = self.group
                    self.setAutoresizingMask(cell)
                    if self.isDelete {
                        cell.setupOfflineUI(deviceId: deviceId)
                    } else {
                        cell.setupInitialUI()
                    }
                    return cell
                }
            } else if value == ESPMatterConstants.levelControl {
                
                let sliderCell = tableView.dequeueReusableCell(withIdentifier: SliderTableViewCell.reuseIdentifier, for: indexPath) as! SliderTableViewCell
                object_setClass(sliderCell, ParamSliderTableViewCell.self)
                let cell = sliderCell as! ParamSliderTableViewCell
                cell.isRainmaker = false
                cell.nodeGroup = self.group
                cell.deviceId = deviceId
                cell.hueSlider.isHidden = true
                cell.slider.isHidden = false
                cell.paramChipDelegate = self
                self.setAutoresizingMask(cell)
                if self.isDelete {
                    cell.setupOfflineUI()
                } else {
                    cell.getCurrentLevelValues(groupId: groupId, deviceId: deviceId)
                }
                return cell
            } else if value == ESPMatterConstants.colorControl {
                
                let sliderCell = tableView.dequeueReusableCell(withIdentifier: SliderTableViewCell.reuseIdentifier, for: indexPath) as! SliderTableViewCell
                object_setClass(sliderCell, ParamSliderTableViewCell.self)
                let cell = sliderCell as! ParamSliderTableViewCell
                cell.isRainmaker = false
                cell.nodeGroup = self.group
                cell.deviceId = deviceId
                cell.slider.isHidden = true
                cell.hueSlider.isHidden = false
                cell.hueSlider.thumbColor = UIColor(hue: 0.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                cell.paramChipDelegate = self
                self.setAutoresizingMask(cell)
                cell.setupInitialHueValues()
                return cell
            } else if value == ESPMatterConstants.delete {
                
                if let cell = tableView.dequeueReusableCell(withIdentifier: RemoveDeviceCell.reuseIdentifier, for: indexPath) as? RemoveDeviceCell {
                    cell.delegate = self
                    self.setAutoresizingMask(cell)
                    return cell
                }
            } else if value == ESPMatterConstants.openCW {
                
                if let cell = tableView.dequeueReusableCell(withIdentifier: OpenCommissioningWindowCell.reuseIdentifier, for: indexPath) as? OpenCommissioningWindowCell {
                    cell.delegate = self
                    self.setAutoresizingMask(cell)
                    return cell
                }
            } else if value == ESPMatterConstants.rainmakerController {
                if let cell = tableView.dequeueReusableCell(withIdentifier: LaunchControllerCell.reuseIdentifier, for: indexPath) as? LaunchControllerCell {
                    cell.delegate = self
                    self.setAutoresizingMask(cell)
                    return cell
                }
            }
        }
        return UITableViewCell()
    }
}
#endif
