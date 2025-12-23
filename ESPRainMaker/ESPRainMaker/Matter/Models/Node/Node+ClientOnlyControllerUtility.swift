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
    
    var isMatterControllerSetupSupported: Bool {
        if let _ = self.getService(forServiceType: ClientOnlyControllerConstants.setupServiceType) {
            return true
        }
        return false
    }
    
    var isClientOnlyControllerSupported: Bool {
        if let _ = self.getService(forServiceType: MatterControllerConstants.serviceType)
            ?? self.getService(forServiceType: ClientOnlyControllerConstants.setupServiceType) {
            return true
        }
        return false
    }
    
    /// Matches Android `isCtlAvailable`: `matter-controller` service requires `esp.param.matter-node-id`.
    var isMatterControllerClientServiceAvailable: Bool {
        guard getService(forServiceType: MatterControllerConstants.serviceType) != nil else { return false }
        return getServiceParam(forServiceType: MatterControllerConstants.serviceType,
                               andParamType: MatterControllerConstants.paramMatterNodeId) != nil
    }
    
    var clientOnlyControllerRmakerGroupParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: MatterControllerConstants.serviceType, andParamType: ClientOnlyControllerConstants.paramRainmakerGroupId), let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }
    
    var clientOnlyControllerGroupParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: MatterControllerConstants.serviceType, andParamType: ClientOnlyControllerConstants.paramGroupId), let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }
    
    var clientOnlyControllerUserTokenParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: MatterControllerConstants.serviceType, andParamType: ClientOnlyControllerConstants.paramUserToken), let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }
    
    var clientOnlyControllerBaseURLParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: MatterControllerConstants.serviceType, andParamType: ClientOnlyControllerConstants.paramBaseURL), let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }
    
    var clientOnlyControllerUpdateDeviceListCommandParam: Param? {
        return self.getServiceParam(forServiceType: MatterControllerConstants.serviceType, andParamType: ClientOnlyControllerConstants.paramMatterCtlCmd)
        ?? self.getServiceParam(forServiceType: ClientOnlyControllerConstants.setupServiceType, andParamType: ClientOnlyControllerConstants.paramMatterCtlCmd)
    }
    
    var clientOnlyControllerNodeIdParam: Param? {
        return self.getServiceParam(forServiceType: MatterControllerConstants.serviceType, andParamType: ClientOnlyControllerConstants.paramMatterNodeId)
    }

    var clientOnlyControllerSetupServiceName: String? {
        return self.getServiceName(forServiceType: ClientOnlyControllerConstants.setupServiceType)
    }

    var clientOnlyControllerSetupGroupParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: ClientOnlyControllerConstants.setupServiceType, andParamType: ClientOnlyControllerConstants.paramGroupId),
           let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }

    var clientOnlyControllerSetupRmakerGroupParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: ClientOnlyControllerConstants.setupServiceType, andParamType: ClientOnlyControllerConstants.paramRainmakerGroupId),
           let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }

    var clientOnlyControllerSetupUserTokenParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: ClientOnlyControllerConstants.setupServiceType, andParamType: ClientOnlyControllerConstants.paramUserToken),
           let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }

    var clientOnlyControllerSetupBaseURLParam: Param? {
        if let dynamicAttribute = self.getServiceParam(forServiceType: ClientOnlyControllerConstants.setupServiceType, andParamType: ClientOnlyControllerConstants.paramBaseURL),
           let properties = dynamicAttribute.properties, properties.contains("write") {
            return dynamicAttribute
        }
        return nil
    }
}
