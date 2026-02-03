// Copyright 2026 Espressif Systems (Shanghai) PTE LTD
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
//  ESPOnNetworkDevice.swift
//  ESPRainMaker
//

import Foundation

/// Model representing a device discovered on the local network via mDNS/Bonjour
struct ESPOnNetworkDevice: Codable {
    /// Node identifier of the device
    var nodeId: String
    
    /// Service name from mDNS discovery
    var serviceName: String
    
    /// IP address of the device
    var ipAddress: String
    
    /// Port number for communication
    var port: Int
    
    /// Security version (0 = no security, 1 = secure)
    var secVersion: Int
    
    /// Whether Proof of Possession (POP) is required
    var popRequired: Bool
    
    /// Challenge-response endpoint path
    var chRespEndpoint: String
    
    init(nodeId: String, serviceName: String, ipAddress: String, port: Int, secVersion: Int, popRequired: Bool, chRespEndpoint: String) {
        self.nodeId = nodeId
        self.serviceName = serviceName
        self.ipAddress = ipAddress
        self.port = port
        self.secVersion = secVersion
        self.popRequired = popRequired
        self.chRespEndpoint = chRespEndpoint
    }
}
