// Copyright 2023 Espressif Systems
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
//  Date+Seconds.swift
//  ESPRainMaker
//

import Foundation

extension Date {
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    
    /// Returns the amount of milliseconds from another date
    func milliSeconds(from date: Date) -> Int64 {
        let currentTime:Int64 = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        let elapsedTime:Int64 = currentTime - Int64((self.timeIntervalSince1970 * 1000.0).rounded())
        return elapsedTime
    }
}
