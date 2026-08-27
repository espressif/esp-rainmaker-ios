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
//  Node+ClientOnlyControllerUtility.swift
//  ESPRainMaker
//

extension Node {
    
    var isClientOnlyControllerSupported: Bool {
        if let _ = self.getService(forServiceType: Constants.matterControllerServiceType) {
            return true
        }
        return false
    }
    
    var clientOnlyControllerRmakerGroupParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: Constants.matterControllerServiceType, andParamType: ClientOnlyControllerConstants.paramRainmakerGroupId), let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }
    
    var clientOnlyControllerGroupParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: Constants.matterControllerServiceType, andParamType: ClientOnlyControllerConstants.paramGroupId), let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }
    
    var clientOnlyControllerUserTokenParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: Constants.matterControllerServiceType, andParamType: ClientOnlyControllerConstants.paramUserToken), let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }
    
    var clientOnlyControllerBaseURLParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: Constants.matterControllerServiceType, andParamType: ClientOnlyControllerConstants.paramBaseURL), let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }
    
    var clientOnlyControllerUpdateDeviceListCommandParam: Param? {
        return self.getServiceParam(forServiceType: Constants.matterControllerServiceType, andParamType: ClientOnlyControllerConstants.paramMatterCtlCmd)
    }
    
    var clientOnlyControllerNodeIdParam: Param? {
        return self.getServiceParam(forServiceType: Constants.matterControllerServiceType, andParamType: ClientOnlyControllerConstants.paramMatterNodeId)
    }
}
