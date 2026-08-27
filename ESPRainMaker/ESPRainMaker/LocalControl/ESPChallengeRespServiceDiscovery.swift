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
//  ESPChallengeRespServiceDiscovery.swift
//  ESPRainMaker
//

import Foundation

/// Protocol to notify when a challenge-response device is discovered
protocol ESPChallengeRespDiscoveryDelegate: AnyObject {
    func deviceFound(_ device: ESPOnNetworkDevice)
}

/// Class to manage discovery of challenge-response services on the local network using Bonjour.
class ESPChallengeRespServiceDiscovery: NSObject {
    
    weak var delegate: ESPChallengeRespDiscoveryDelegate?
    
    private var serviceBrowser = NetServiceBrowser()
    private var servicesBeingResolved: [NetService] = []
    private var serviceTimeout: Timer?
    private let serviceType: String
    private let domain: String
    private let timeout: TimeInterval = 10.0
    
    init(serviceType: String, domain: String = "local", delegate: ESPChallengeRespDiscoveryDelegate?) {
        self.serviceType = serviceType
        self.domain = domain
        self.delegate = delegate
        super.init()
        serviceBrowser.delegate = self
    }
    
    /// Start discovering challenge-response services
    func startDiscovery() {
        stopDiscovery()
        serviceTimeout?.invalidate()
        servicesBeingResolved.removeAll()
        
        // Set timeout for discovery
        serviceTimeout = Timer.scheduledTimer(
            timeInterval: timeout,
            target: self,
            selector: #selector(discoveryTimeout),
            userInfo: nil,
            repeats: false
        )
        
        serviceBrowser.searchForServices(ofType: serviceType, inDomain: domain)
    }
    
    /// Stop service discovery
    func stopDiscovery() {
        serviceTimeout?.invalidate()
        serviceTimeout = nil
        serviceBrowser.stop()
        servicesBeingResolved.removeAll()
    }
    
    @objc private func discoveryTimeout() {
        stopDiscovery()
    }
    
    /// Remove resolved service from queue
    private func removeServiceFromResolveQueue(_ service: NetService) {
        if let index = servicesBeingResolved.firstIndex(of: service) {
            servicesBeingResolved.remove(at: index)
        }
    }
    
    /// Parse TXT record data to extract device information
    private func parseTXTRecord(_ txtRecord: [String: Data]) -> (nodeId: String?, secVersion: Int, popRequired: Bool, chRespEndpoint: String) {
        var nodeId: String?
        var secVersion = 0
        var popRequired = false
        var chRespEndpoint = "ch_resp"
        
        for (key, value) in txtRecord {
            guard let stringValue = String(data: value, encoding: .utf8) else { continue }
            
            switch key {
            case "node_id":
                nodeId = stringValue
            case "sec_version":
                secVersion = Int(stringValue) ?? 0
            case "pop_required":
                let lowercased = stringValue.lowercased()
                popRequired = lowercased == "true" || lowercased == "1" || lowercased == "yes"
            case "ch_resp":
                chRespEndpoint = stringValue
            default:
                break
            }
        }
        
        return (nodeId, secVersion, popRequired, chRespEndpoint)
    }
}

// MARK: - NetServiceBrowserDelegate
extension ESPChallengeRespServiceDiscovery: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        guard service.type == serviceType else { return }
        
        service.delegate = self
        servicesBeingResolved.append(service)
        service.resolve(withTimeout: 5.0)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        removeServiceFromResolveQueue(service)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        stopDiscovery()
    }
}

// MARK: - NetServiceDelegate
extension ESPChallengeRespServiceDiscovery: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let hostName = sender.hostName else {
            removeServiceFromResolveQueue(sender)
            return
        }
        
        // Get TXT record data
        guard let txtRecordData = sender.txtRecordData() else {
            removeServiceFromResolveQueue(sender)
            return
        }
        
        // Parse TXT record
        let txtRecord = NetService.dictionary(fromTXTRecord: txtRecordData)
        let parsed = parseTXTRecord(txtRecord)
        
        guard let nodeId = parsed.nodeId, !nodeId.isEmpty else {
            removeServiceFromResolveQueue(sender)
            return
        }
        
        // Extract actual IP address from NetService addresses
        // iOS may not resolve .local hostnames for HTTP, so we need the actual IP
        var ipAddress = hostName

        if let addresses = sender.addresses, !addresses.isEmpty {
            var foundIPv4 = false
            var foundIPv6 = false

            for (_, addressData) in addresses.enumerated() {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = addressData.withUnsafeBytes { bytes in
                    let sockaddr = bytes.bindMemory(to: sockaddr.self).baseAddress!
                    return getnameinfo(
                        sockaddr,
                        socklen_t(addressData.count),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        0,
                        NI_NUMERICHOST
                    )
                }

                if result == 0 {
                    let addressString = String(cString: hostname)
                    if !addressString.contains(":") {
                        ipAddress = addressString
                        foundIPv4 = true
                        break
                    } else if !foundIPv6 {
                        ipAddress = addressString
                        foundIPv6 = true
                    }
                }
            }

            if !foundIPv4 && !foundIPv6 {
                if ipAddress.hasSuffix(".") {
                    ipAddress = String(ipAddress.dropLast())
                }
            }
        } else {
            if ipAddress.hasSuffix(".") {
                ipAddress = String(ipAddress.dropLast())
            }
        }

        // Create device model
        let device = ESPOnNetworkDevice(
            nodeId: nodeId,
            serviceName: sender.name,
            ipAddress: ipAddress,
            port: Int(sender.port),
            secVersion: parsed.secVersion,
            popRequired: parsed.popRequired,
            chRespEndpoint: parsed.chRespEndpoint
        )
        
        // Notify delegate
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.deviceFound(device)
        }
        
        removeServiceFromResolveQueue(sender)
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        removeServiceFromResolveQueue(sender)
    }
}
