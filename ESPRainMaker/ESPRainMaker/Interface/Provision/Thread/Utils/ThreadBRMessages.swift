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
    case setPendingDatasetFailed = "Could not set homepod active dataset to the PendingDataset parameter."
    case homepodDatasetNotAvailable = "Homepod active dataset is not available. Please ensure that you have added a homehub to your Apple Id using the Home app."
    case operationNotSupported = "Operation not supported."
    case serviceNotSupported = "Service not supported."
    case espActiveDatasetAlreadyConfigured = "The ESP thread border router already has an active thread dataset."
    case espActiveDatasetNotConfigured = "The ESP thread border router does not have an active thread dataset configured."
    case addthreadCredsSuccess = "Thread credentials successfully added."
    case addthreadCredsFailure = "Thread credentials could not be added."
    case newThreadActiveDatasetCreated = "Created new thread active dataset for the border router."
}
