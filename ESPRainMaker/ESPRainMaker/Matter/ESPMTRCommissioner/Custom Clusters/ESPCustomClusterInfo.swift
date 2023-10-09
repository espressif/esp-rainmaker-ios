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
//  ESPCustomClusterInfo.swift
//  ESPRainmaker
//

import Foundation

/*
 // MARK: Custom Rainmaker Cluster Info
 */
enum rainmaker {
    
    enum attributes {
        case rainmakerNodeId
        case challenge
        
        var attributeId: NSNumber {
            switch self {
            case .rainmakerNodeId:
                return NSNumber(value: 1)
            case .challenge:
                return NSNumber(value: 2)
            }
        }
    }
    
    enum commands {
        case sendNodeId
        
        var commandId: NSNumber {
            switch self {
            case .sendNodeId:
                return NSNumber(value: 1)
            }
        }
    }
    
    static let clusterId: NSNumber = NSNumber(value: 320601088)
}

/*
 // MARK: Custom Rainmaker Controller Cluster Info
 */
enum rainmakerController {
    
    enum attributes {
        case refreshToken
        case accessToken
        case authorized
        case userNOCInstalled
        case endpointURL
        
        var attributeId: NSNumber {
            switch self {
            case .refreshToken:
                return NSNumber(value: 0)
            case .accessToken:
                return NSNumber(value: 1)
            case .authorized:
                return NSNumber(value: 2)
            case .userNOCInstalled:
                return NSNumber(value: 3)
            case .endpointURL:
                return NSNumber(value: 4)
            }
        }
    }
    
    enum commands {
        case appendRefreshToken
        case resetRefreshToken
        case authorize
        case updateUserNOC
        case updateDeviceList
        
        var commandId: NSNumber {
            switch self {
            case .appendRefreshToken:
                return NSNumber(value: 0)
            case .resetRefreshToken:
                return NSNumber(value: 1)
            case .authorize:
                return NSNumber(value: 2)
            case .updateUserNOC:
                return NSNumber(value: 3)
            case .updateDeviceList:
                return NSNumber(value: 4)
            }
        }
    }
    
    static let clusterId: NSNumber = NSNumber(value: 320601089)
}

/*
 // MARK: Custom Cluster to enter participant data
 */
enum participantData {
    
    enum attributes {
        case name
        case companyName
        case email
        case contact
        case eventName
        
        var attributeId: NSNumber {
            switch self {
            case .name:
                return NSNumber(value: 0)
            case .companyName:
                return NSNumber(value: 1)
            case .email:
                return NSNumber(value: 2)
            case .contact:
                return NSNumber(value: 3)
            case .eventName:
                return NSNumber(value: 4)
            }
        }
    }
    
    enum commands {
        case sendData
        
        var commandId: NSNumber {
            switch self {
            case .sendData:
                return NSNumber(value: 0)
            }
        }
    }
    
    static let clusterId: NSNumber = NSNumber(value: 320601091)
}

/*
 // MARK: Custom Cluster to for air conditioner
 */
enum airConditioner {
    
    enum attributes {
        case localtemperature
        case occupiedCoolingSetpoint
        case controlSequenceOfOperation
        case systemMode
        
        var attributeId: NSNumber {
            switch self {
            case .localtemperature:
                return NSNumber(value: 0)
            case .occupiedCoolingSetpoint:
                return NSNumber(value: 17)
            case .controlSequenceOfOperation:
                return NSNumber(value: 27)
            case .systemMode:
                return NSNumber(value: 28)
            }
        }
    }
    
    static let clusterId: NSNumber = NSNumber(value: 513)
}



/*
 // MARK: Custom Rainmaker Cluster Info
 */
enum borderRouter {
    
    enum attributes {
        case activeOperationalDataset
        case borderAgentId
        
        var attributeId: NSNumber {
            switch self {
            case .activeOperationalDataset:
                return NSNumber(value: 0)
            case .borderAgentId:
                return NSNumber(value: 2)
            }
        }
    }
    
    enum commands {
        case configureThreadDataset
        case startThreadNetwork
        case stopThreadNetwork
        
        var commandId: NSNumber {
            switch self {
            case .configureThreadDataset:
                return NSNumber(value: 0)
            case .startThreadNetwork:
                return NSNumber(value: 1)
            case .stopThreadNetwork:
                return NSNumber(value: 2)
            }
        }
    }
    
    static let clusterId: NSNumber = NSNumber(value: 320601090)
}
