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
//  ESPAutomationConstants.swift
//  ESPRainMaker
//

import Foundation

class ESPAutomationConstants {
    
    // Automation URLS
    static let automationsURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/node_automation"
    static let storyboardName = "DeviceAutomation"
    
    // Parsing keys
    static let automationTriggerActions = "automation_trigger_actions"
    static let name = "name"
    static let automationID = "automation_id"
    static let enabled = "enabled"
    static let nodeID = "node_id"
    static let eventType = "event_type"
    static let metadata = "metadata"
    static let events = "events"
    static let params = "params"
    static let check = "check"
    static let eventOperator = "event_operator"
    static let actions = "actions"
    static let total = "total"
    static let nextID = "next_id"
    
}
