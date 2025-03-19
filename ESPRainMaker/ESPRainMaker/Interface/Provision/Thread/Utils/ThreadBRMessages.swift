// Copyright 2024 Espressif Systems
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
//  ThreadBRMessages.swift
//  ESPRainMaker
//

enum ThreadBRMessages: String {
    
    case success = "Success"
    case failure = "Failure"
    case ok = "OK"
    case activeDatasetCreationFailed = "Unable to create active thread dataset for the ActiveDataset parameter for the thread border router."
    
    case homepodDatasetNotAvailable = "Homepod active dataset is not available. Please ensure that you have added a homehub to your Apple Id using the Home app."
    case operationNotSupported = "Operation not supported."
    case serviceNotSupported = "Service not supported."
    case espActiveDatasetAlreadyConfigured = "The ESP thread border router already has an active thread dataset."
    case espActiveDatasetNotConfigured = "The ESP thread border router does not have an active thread dataset configured."
    case addthreadCredsSuccess = "Active thread credentials successfully added."
    case addthreadCredsFailure = "Thread credentials could not be added."
    case newThreadActiveDatasetCreated = "Created new thread active dataset for the border router."
    
    //Thread border router management messages:
    case tbrmClusterNotSupported = "The Thread Border Router Management cluster is not supported."
    case failSafeTimerNotSupported = "Setting fail safe timer is not supported on this device."
    case armingFailSafeTimerFailed = "Failed to arm Fail Safe timer."
    case setActiveOpsDatasetFailed = "Failed to set active operational dataset on the device."
    case setPendingDatasetFailed = "Could not set homepod active dataset to the PendingDataset parameter."
    case addPendingThreadCredsSuccess = "Pending thread credentials successfully added."
    
    case failedToReadActiveDataset = "Failed to read thread active dataset from the matter device."
    case failedToReadBorderAgentId = "Failed to read thread border agent id from the matter device."
    case failedToSetThreadCredsLocally = "Failed to set thread dataset locally."
    case setThreadCredsLocally = "Successfully set thread dataset locally."
    
    case failedToExtractNetworkName = "Failed to extract thread network name from the matter device."
    case networkNotVisibleAfterSetting = "Thread network is not visible after setting thread credentials locally."
}
