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
//  Node+ServiceParamUtilityProtocol.swift
//  ESPRainMaker
//

import Foundation

protocol ServiceParamUtilityProtocol {
 
    func getService(forServiceType sType: String) -> Service?
    func getServiceName(forServiceType sType: String) -> String?
    func getServiceParams(forServiceType sType: String) -> [Param]?
    func getServiceParam(forServiceType sType: String, andParamType pType: String) -> Param?
    func getServiceParamName(forServiceType sType: String, andParamType pType: String) -> String?
}

extension Node: ServiceParamUtilityProtocol {
    
    /// Get service for service type
    /// - Parameter sType: service type
    /// - Returns: service
    func getService(forServiceType sType: String) -> Service? {
        return services?.first { $0.type == sType }
    }
    
    /// Get service name for service type
    /// - Parameter sType: service type
    /// - Returns: service name
    func getServiceName(forServiceType sType: String) -> String? {
        return getService(forServiceType: sType)?.name
    }
    
    /// Get params for a service type
    /// - Parameter serviceType: service type
    /// - Returns: params
    func getServiceParams(forServiceType sType: String) -> [Param]? {
        return getService(forServiceType: sType)?.params
    }
    
    /// Get param for service and param type
    /// - Parameters:
    ///   - serviceType: service type
    ///   - paramType: param type
    /// - Returns: param
    func getServiceParam(forServiceType sType: String, andParamType pType: String) -> Param? {
        return getServiceParams(forServiceType: sType)?.first { $0.type == pType }
    }
    
    /// Get param name for service type and param type
    /// - Parameters:
    ///   - sType: service type
    ///   - pType: param type
    /// - Returns: param name
    func getServiceParamName(forServiceType sType: String, andParamType pType: String) -> String? {
        return getServiceParam(forServiceType: sType, andParamType: pType)?.name
    }
    
    /// Is the node a thread border router
    var isThreadBorderRouter: Bool {
        return getService(forServiceType: "esp.service.thread-br") != nil
    }
}
