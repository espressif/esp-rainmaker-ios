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
//  Node+GroupsServiceUtility.swift
//  ESPRainMaker
//

extension Node {
    
    var isGroupsServiceSupported: Bool {
        return getService(forServiceType: RainmakerControllerConstants.groupsServiceType) != nil
    }
    
    var groupsServiceRmakerGroupParam: Param? {
        return getServiceParam(forServiceType: RainmakerControllerConstants.groupsServiceType,
                               andParamType: RainmakerControllerConstants.paramRainmakerGroupId)
    }
    
    var groupsServiceGroupParam: Param? {
        return getServiceParam(forServiceType: RainmakerControllerConstants.groupsServiceType,
                               andParamType: RainmakerControllerConstants.paramGroupId)
    }
    
    var isGroupsGroupIdEmpty: Bool {
        guard isGroupsServiceSupported else { return false }
        if let param = groupsServiceRmakerGroupParam ?? groupsServiceGroupParam {
            let value = (param.value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return value.isEmpty
        }
        return false
    }
}
