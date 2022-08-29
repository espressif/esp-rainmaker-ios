// Copyright 2022 Espressif Systems
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
//  ESPSceneConstants.swift
//  ESPRainMaker
//

import Foundation

class ESPSceneConstants {
    
    //MARK: constant strings:
    static let nodeIdKey = "node_id"
    static let payloadKey = "payload"
    
    static let sceneCreationSuccessMessage: String = "Scene created successfully"
    static let sceneCreationFailureMessage: String = "Failed to create scene"
    static let sceneCreationPartialFailureMessage: String = "Failed to create scene for"
    
    static let sceneUpdationSuccessMessage: String = "Scene updated successfully"
    static let sceneUpdationFailureMessage: String = "Failed to update scene"
    static let sceneUpdationPartialFailureMessage: String = "Failed to update scene for"
    
    static let sceneActivationSuccessMessage: String = "Scene activated successfully"
    static let sceneActivationFailureMessage: String = "Failed to activate scene"
    static let sceneActivationPartialFailureMessage: String = "Failed to activate scene for"
    
    static let sceneDeletionSuccessMessage: String = "Scene removed successfully"
    static let sceneDeletionFailureMessage: String = "Failed to remove scene"
    static let sceneDeletionPartialFailureMessage: String = "Failed to remove scene for"
    
    static let addSceneNameTitle = "Add name"
    static let addSceneNameMessage = "Choose name for your scene"
    static let nameNotAddedErrorMessage = "Please enter a name for the scene to proceed."
}
