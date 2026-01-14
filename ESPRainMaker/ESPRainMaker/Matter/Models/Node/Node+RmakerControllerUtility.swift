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
//  Node+RmakerControllerUtility.swift
//  ESPRainMaker
//

extension Node {
    
    /// Indicates whether the node supports Rainmaker controller functionality
    /// Checks if the node has a service of type RainmakerControllerConstants.rmakerControllerServiceType
    var isRmakerControllerSupported: Bool {
        if let _ = self.getService(forServiceType: RainmakerControllerConstants.rmakerControllerServiceType) {
            return true
        }
        return false
    }
    
    /// Gets the user token parameter for Rainmaker controller service
    /// - Returns: The user token parameter if available, nil otherwise
    var rmakerControllerUserTokenParam: Param? {
        return self.getServiceParam(forServiceType: RainmakerControllerConstants.rmakerControllerServiceType, andParamType: RainmakerControllerConstants.paramUserToken)
    }
    
    /// Gets the base URL parameter for Rainmaker controller service
    /// - Returns: The base URL parameter if available, nil otherwise
    var rmakerControllerBaseURLParam: Param? {
        return self.getServiceParam(forServiceType: RainmakerControllerConstants.rmakerControllerServiceType, andParamType: RainmakerControllerConstants.paramBaseURL)
    }
    
    /// Indicates whether the node supports the complete Rainmaker controller flow
    /// Checks if the node supports Rainmaker controller AND has both base URL and user token parameters configured
    var isRmakerControllerFlowSupported: Bool {
        if self.isRmakerControllerSupported, let _ = rmakerControllerBaseURLParam, let _ = rmakerControllerUserTokenParam {
            return true
        }
        return false
    }
}
