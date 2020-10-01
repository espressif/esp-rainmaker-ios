// Copyright 2020 Espressif Systems
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
//  ESPSchedule.swift
//  ESPRainMaker
//
#if SCHEDULE
    import Foundation

    /// Enum with available operation that can be performed in a Schedule.
    enum ESPOperation: String {
        case add
        case edit
    }

    /// Instance of this class contain a single Schedule.
    class ESPSchedule {
        var id: String!
        var name: String?
        var actions: [String: [Device]] = [:]
        var trigger = ESPTrigger()
        var operation: ESPOperation?
        var week = ESPWeek(number: 0)
        var enabled = true
        var scheduleJSON: [String: Any] = [:]
    }

    /// Contain information about the time of Schedule.
    class ESPTrigger {
        var days: Int?
        var minutes: Int?

        init() {
            days = 0
            minutes = 0
        }

        /// Get short description of the time in "hh:mm AM" format.
        ///
        /// - Returns: Decimal conversion of the selected days.
        func getTimeDetails() -> String {
            let hours: Int = (minutes ?? 0) / 60
            let min: Int = (minutes ?? 0) % 60
            var minuteString = "\(min)"
            if min < 10 {
                minuteString = "0\(min)"
            }
            var hourString = "\(hours % 12)"
            if hourString.count == 1 {
                hourString = "0\(hourString)"
            }
            var dateString = "\(hourString):\(minuteString) AM"
            if hours == 12 {
                dateString = "\(hours):\(minuteString) PM"
            } else if hours == 24 {
                dateString = "\(12):\(minuteString) AM"
            } else if hours > 12 {
                var hourString = "\(hours % 12)"
                if hourString.count == 1 {
                    hourString = "0\(hourString)"
                }
                dateString = "\(hourString):\(minuteString) PM"
            }
            return dateString
        }
    }
#endif
