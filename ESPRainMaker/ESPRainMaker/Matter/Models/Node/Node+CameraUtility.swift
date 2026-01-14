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
//  Node+CameraUtility.swift
//  ESPRainMaker
//

import Foundation

extension Node {
    
    /// Get camera device
    /// - Returns: Camera device pbject
    /// Get camera device
    /// - Returns: Camera device object
    func getCameraDevice() -> Device? {
        return devices?.first { $0.type == Constants.cameraDeviceType }
    }
    
    /// Channel param value
    /// Channel param value
    var channelParamValue: String? {
        return getCameraDevice()?.params?
            .first { $0.type == Constants.channelParamType }?
            .value as? String
    }
}
