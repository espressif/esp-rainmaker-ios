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
//  ESPAutomationParser.swift
//  ESPRainMaker
//

import Foundation
import ESPProvision

protocol ESPAutomationParsable {
    func parseAutomationList(_ data: Data) -> (automations: ESPAutomation?, error: Error?)
}

struct ESPAutomationParser: ESPAutomationParsable {
    /// Method to parse API response to automation trigger list.
    ///
    /// - Parameters:
    ///   - data: Response data for get automation API..
    func parseAutomationList(_ data: Data) -> (automations: ESPAutomation?, error: Error?) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let automationTriggerActionsJSON = json[ESPAutomationConstants.automationTriggerActions] as? [[String: Any]] {
                var espAutomation = ESPAutomation(automationTriggerActions: [], total: json[ESPAutomationConstants.total] as? Int, nextID: json[ESPAutomationConstants.nextID] as? String)
                var automationTriggerActions: [ESPAutomationTriggerAction] = []
                for triggerActionsJSON in automationTriggerActionsJSON {
                    var triggerAction = ESPAutomationTriggerAction()
                    triggerAction.name = triggerActionsJSON[ESPAutomationConstants.name] as? String
                    triggerAction.automationID = triggerActionsJSON[ESPAutomationConstants.automationID] as? String
                    triggerAction.enabled = triggerActionsJSON[ESPAutomationConstants.enabled] as? Bool ?? false
                    triggerAction.nodeID = triggerActionsJSON[ESPAutomationConstants.nodeID] as? String
                    triggerAction.eventType = triggerActionsJSON[ESPAutomationConstants.eventType] as? String
                    triggerAction.metadata = triggerActionsJSON[ESPAutomationConstants.metadata] as? String
                    triggerAction.events = triggerActionsJSON[ESPAutomationConstants.events] as? [[String:Any]]
                    triggerAction.eventOperator = triggerActionsJSON[ESPAutomationConstants.eventOperator] as? String
                    
                    if let automationActionsJSON = triggerActionsJSON[ESPAutomationConstants.actions] as? [[String: Any]] {
                        var automationActions: [ESPAutomationAction] = []
                        for actionsJSON in automationActionsJSON {
                            var action = ESPAutomationAction()
                            action.nodeID = actionsJSON[ESPAutomationConstants.nodeID] as? String
                            action.params = actionsJSON[ESPAutomationConstants.params] as? [String:[String:Any]]
                            automationActions.append(action)
                        }
                        triggerAction.actions = automationActions
                    }
                    automationTriggerActions.append(triggerAction)
                }
                espAutomation.automationTriggerActions  = automationTriggerActions
                return (espAutomation, nil)
            }
            return (nil, nil)
        } catch {
            return (nil, error)
        }
    }
}

