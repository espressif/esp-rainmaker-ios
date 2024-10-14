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
//  TBRConnectionManager.swift
//  ESPRainMaker
//

import UIKit

protocol TBRNodesDiscoveredDelegate {
    func threadBorderRoutersDiscovered(threadBorderRouters: [String], threadNetworks: [String: String])
}

class TBRConnectionManager: NSObject {
    
    static let shared = TBRConnectionManager()
    private var serviceBrowser = NetServiceBrowser()
    private var servicesBeingResolved: [NetService] = []
    private var serviceTimeout = Timer()
    var hosts: [String] = []
    var threadNetworks: [String: String] = [:]
    let timeout: TimeInterval = 10.0
    let threadBorderRouterDiscoveryTimeout: TimeInterval = 10.0
    var delegate: TBRNodesDiscoveredDelegate?
    let networkNameRecordKey = "nn"

    override init() {
        super.init()
        serviceBrowser.delegate = self
    }

    /// Search for service of a particular type in a given domain.
    ///
    /// - Parameters:
    ///   - type: Service type.
    ///   - domain: Domain type.
    func searchForServicesOfType(type: String, domain: String) {
        serviceTimeout = Timer.scheduledTimer(
            timeInterval: threadBorderRouterDiscoveryTimeout,
            target: self,
            selector: #selector(noServicesFound),
            userInfo: nil,
            repeats: false
        )
        hosts.removeAll()
        threadNetworks.removeAll()
        servicesBeingResolved.removeAll()
        serviceBrowser.stop()
        serviceBrowser.searchForServices(ofType: type, inDomain: domain)
    }
    
    /// Method invoked if search is taking longer than expected.
    ///
    @objc private func noServicesFound() {
        serviceBrowser.stop()
        hosts.removeAll()
        updateServiceList()
    }
    
    
    /// Stop scanning matter devices
    ///
    func stopService() {
        serviceBrowser.stop()
    }
    
    /// Tell delegate there is change in available services.
    ///
    private func updateServiceList() {
        self.delegate?.threadBorderRoutersDiscovered(threadBorderRouters: hosts, threadNetworks: threadNetworks)
    }
    
    /// Remove resolved service from queue of found services.
    ///
    /// - Parameters:
    ///   - service: Service that needs to be removed from the resolved queue.
    /// Remove resolved service from queue of found services.
    ///
    /// - Parameters:
    ///   - service: Service that needs to be removed from the resolved queue.
    private func removeServiceFromResolveQueue(service: NetService) {
        if let serviceIndex = servicesBeingResolved.firstIndex(of: service) {
            servicesBeingResolved.remove(at: serviceIndex)
        }

        if servicesBeingResolved.count == 0 {
            updateServiceList()
        }
    }
}

extension TBRConnectionManager: NetServiceBrowserDelegate {
    
    func netServiceBrowser(_: NetServiceBrowser, didFind service: NetService, moreComing _: Bool) {
        service.delegate = self
        serviceTimeout.invalidate()
        servicesBeingResolved.append(service)
        service.resolve(withTimeout: 5.0)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        self.servicesBeingResolved.append(service)
        if self.hosts.count > 0 {
            let name = service.name
            var index = 0
            for host in self.hosts {
                if host == name {
                    break
                }
                index+=1
            }
            if index < self.hosts.count {
                self.hosts.remove(at: index)
            }
        }
        self.removeServiceFromResolveQueue(service: service)
    }
}

extension TBRConnectionManager: NetServiceDelegate {
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        let name = sender.name
        if !hosts.contains(name) {
            hosts.append(name)
            if let data = sender.txtRecordData() {
                let dict = NetService.dictionary(fromTXTRecord: data)
                if let networkNameData = dict[networkNameRecordKey], let networkName = String(data: networkNameData, encoding: .utf8) {
                    threadNetworks[name] = networkName
                }
            }
        }
        self.removeServiceFromResolveQueue(service: sender)
    }

    func netService(_ sender: NetService, didNotResolve address: [String: NSNumber]) {
        removeServiceFromResolveQueue(service: sender)
    }
}
