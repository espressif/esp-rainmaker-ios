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
//  ESPAutomationPresenter.swift
//  ESPRainMaker
//

import Foundation

protocol ESPGetAutomationPresentationLogic {
    func automationListFetched(automations: ESPAutomation?, error: ESPAPIError?)
}

protocol ESPAddAutomationPresentationLogic {
    func didFinishAddingAutomationWith(automationID: String?, error: ESPAPIError?)
}

protocol ESPUpdateAutomationPresentationLogic {
    func didFinishUpdatingAutomationWith(error: ESPAPIError?)
}

protocol ESPEnableAutomationPresentationLogic {
    func didFinishEnablingAutomationWith(automationID: String, error: ESPAPIError?)
}

protocol ESPDeleteAutomationPresentationLogic {
    func didFinishDeletingAutomationWith(automationID: String, error: ESPAPIError?)
}

protocol ESPListUserDevicePresentationLogic {
    func listOfDevicesForAutomationEvent(devices: [Device])
    func listOfDevicesForAutomationAction(devices: [Device])
}
