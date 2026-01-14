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
//  Event.swift
//  ESPRainMaker
//

import Foundation
import WebRTC

public class Event {
    public class func parseEvent(event: String) -> Message? {
        do {
            let payLoad = try event.convertToDictionaryValueAsString()

            if payLoad.count >= 2 {
                if let messageType: String = payLoad["messageType"] as? String, let messagePayload: String = payLoad["messagePayload"] as? String {
                    if let senderClientId = payLoad["senderClientId"] {
                        return Message(messageType, "", senderClientId as! String, messagePayload)
                    } else {
                        return Message(messageType, "", "", messagePayload)
                    }
                }
            }

        } catch {
            print("payload Error \(error)")
        }
        return nil
    }
}
