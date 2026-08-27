// Copyright 2025 Espressif Systems
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
//  ParamCustomActionCell+Actions.swift
//  ESPRainMaker
//
//  Component: Custom Action Handling
//  Handles: Custom action execution, delegate communication

import UIKit

extension ParamCustomActionCell {
    
    // MARK: - Custom Action Execution
    @objc func performCustomAction(_ sender: Any) {
        switch workflow {
        case .launchRainmakerController:
            delegate?.launchRainmakerController()
        case .launchController:
            delegate?.launchController()
        case .updateDeviceList:
            delegate?.updateDeviceList()
        case .updateThreadDataset:
            delegate?.updateThreadDataset()
        case .setActiveThreadDataset:
            delegate?.setActiveThreadDataset()
        case .mergeThreadDataset:
            delegate?.mergeThreadDataset()
        case .launchKinesisVideo:
            delegate?.launchKinesisVideo(channel: channel)
        }
    }
}

