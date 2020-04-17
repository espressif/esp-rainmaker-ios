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
//  Attribute.swift
//  ESPRainMaker
//

import Foundation

class Attribute: Equatable {
    var name: String?
    var value: Any?

    static func == (lhs: Attribute, rhs: Attribute) -> Bool {
        let lhsValue = lhs.value as? String
        let rhsValue = rhs.value as? String
        return lhsValue == rhsValue && lhs.name == rhs.name
    }
}

class Param: Attribute {
    static func == (lhs: Param, rhs: Param) -> Bool {
        if lhs.name == rhs.name {
            if lhs.dataType == rhs.dataType {
                if lhs.dataType?.lowercased() == "int" {
                    let lhsValue = lhs.value as? Int
                    let rhsValue = rhs.value as? Int
                    return lhsValue == rhsValue
                } else if lhs.dataType?.lowercased() == "float" {
                    let lhsValue = lhs.value as? Float
                    let rhsValue = rhs.value as? Float
                    return lhsValue == rhsValue
                } else {
                    let lhsValue = lhs.value as? String
                    let rhsValue = rhs.value as? String
                    return lhsValue == rhsValue
                }
            }
        }
        return false
    }

    var uiType: String?
    var properties: [String]?
    var bounds: [String: Any]?
    var attributeKey: String?
    var dataType: String?
    var type: String?
}
