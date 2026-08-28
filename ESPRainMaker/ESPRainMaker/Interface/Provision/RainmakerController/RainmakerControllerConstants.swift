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
//  RainmakerControllerConstants.swift
//  ESPRainMaker
//

struct RainmakerControllerConstants {
    
    static let defaultType = "rmaker-user-auth"
    static let groupsServiceDefaultType = "groups-service"
    
    /// Service type identifier for Rainmaker controller functionality
    /// Used to identify nodes that support Rainmaker controller services
    static let rmakerControllerServiceType = "esp.service.rmaker-user-auth"

    /// Matches Android `AppConstants.SERVICE_TYPE_RM_CONTROLLER` — group id params may live on this service.
    static let rmControllerServiceType = "esp.service.rmaker-controller"

    /// Matches Android `AppConstants.SERVICE_TYPE_GROUPS`.
    static let groupsServiceType = "esp.service.groups"
    
    /// Parameter name for base URL configuration in Rainmaker controller service
    /// Used to store the base URL endpoint for the Rainmaker controller
    static let paramBaseURL = MatterControllerConstants.paramBaseURL
    
    /// Parameter name for user authentication token in Rainmaker controller service
    /// Used to store the user's authentication token for accessing Rainmaker controller features
    static let paramUserToken = MatterControllerConstants.paramUserToken
    
    static let paramRainmakerGroupId = MatterControllerConstants.paramRainmakerGroupId
    static let paramGroupId = MatterControllerConstants.paramGroupId
}

enum ControllerGroupSelectionPurpose {
    case clientOnlyController
    case groupsServiceOnly
}
