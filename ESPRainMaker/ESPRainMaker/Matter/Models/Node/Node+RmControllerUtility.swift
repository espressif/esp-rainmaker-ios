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
//  Node+RmControllerUtility.swift
//  ESPRainMaker
//

extension Node {
    
    var isRmControllerSupported: Bool {
        return getService(forServiceType: RainmakerControllerConstants.rmControllerServiceType) != nil
    }
    
    var rmControllerUserTokenParam: Param? {
        if let param = getServiceParam(forServiceType: RainmakerControllerConstants.rmControllerServiceType,
                                       andParamType: RainmakerControllerConstants.paramUserToken),
           let properties = param.properties, properties.contains("write") {
            return param
        }
        return nil
    }
    
    var rmControllerBaseURLParam: Param? {
        if let param = getServiceParam(forServiceType: RainmakerControllerConstants.rmControllerServiceType,
                                       andParamType: RainmakerControllerConstants.paramBaseURL),
           let properties = param.properties, properties.contains("write") {
            return param
        }
        return nil
    }
    
    var rmControllerRmakerGroupParam: Param? {
        if let param = getServiceParam(forServiceType: RainmakerControllerConstants.rmControllerServiceType,
                                       andParamType: RainmakerControllerConstants.paramRainmakerGroupId),
           let properties = param.properties, properties.contains("write") {
            return param
        }
        return nil
    }
    
    var rmControllerGroupParam: Param? {
        if let param = getServiceParam(forServiceType: RainmakerControllerConstants.rmControllerServiceType,
                                       andParamType: RainmakerControllerConstants.paramGroupId),
           let properties = param.properties, properties.contains("write") {
            return param
        }
        return nil
    }
}
