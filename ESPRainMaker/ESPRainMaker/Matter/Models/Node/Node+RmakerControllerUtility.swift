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
        if let dynamicAttribute = self.getServiceParam(forServiceType: RainmakerControllerConstants.rmakerControllerServiceType, andParamType: RainmakerControllerConstants.paramUserToken), let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }
    
    /// Gets the base URL parameter for Rainmaker controller service
    /// - Returns: The base URL parameter if available, nil otherwise
    var rmakerControllerBaseURLParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: RainmakerControllerConstants.rmakerControllerServiceType, andParamType: RainmakerControllerConstants.paramBaseURL), let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }
    
    /// Gets the group id parameter for Rainmaker controller service
    /// - Returns: The group id parameter if available, nil otherwise
    var rmakerControllerGroupParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: RainmakerControllerConstants.rmakerControllerServiceType, andParamType: RainmakerControllerConstants.paramRainmakerGroupId), let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }
    
    /// Gets the update device list command parameter for Rainmaker controller service (if exposed)
    /// - Returns: The command parameter if available, nil otherwise
    var rmakerControllerUpdateDeviceListCommandParam: Param? {
        return self.getServiceParam(forServiceType: RainmakerControllerConstants.rmakerControllerServiceType, andParamType: ClientOnlyControllerConstants.paramMatterCtlCmd)
    }
}
