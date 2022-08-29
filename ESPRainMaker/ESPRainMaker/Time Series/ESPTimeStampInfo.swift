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
//  ESPTimeStampInfo.swift
//  ESPRainMaker
//

import Foundation

struct ESPTimeStampInfo {
    var timestamp: Double
    
    /// Formats timestamp based on aggregation and time interval.
    /// - Parameters:
    ///   - aggregate: E.g. raw, latest, etc.
    ///   - timeInterval: E.g. 1 day, 7 days, etc.
    /// - Returns: Formatted short description of timestamp.
    func timeDescription(aggregate: ESPAggregate, timeInterval: ESPTimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "dd-MMM-YY"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        let defaultInfo = dateStringFormatter.string(from: date) + " " + timeFormatter.string(from: date)
        switch aggregate {
        case .raw:
            return defaultInfo
        default:
            switch timeInterval {
            case .minute:
                return defaultInfo
            case .hour:
                return defaultInfo
            case .day:
                dateStringFormatter.dateFormat = "dd-MMM-YY"
                return dateStringFormatter.string(from: date)
            case .week:
                let endDate = Date(timeIntervalSince1970: timestamp + ESPChartsConstant.weekTimestamp)
                dateStringFormatter.dateFormat = "dd-MMM"
                return dateStringFormatter.string(from: date) + " to " + dateStringFormatter.string(from: endDate)
            case .month:
                dateStringFormatter.dateFormat = "MMM"
                return dateStringFormatter.string(from: date)
            case .year:
                return ""
            }
        }
    }
}
