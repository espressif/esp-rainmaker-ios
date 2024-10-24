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
//  ThreadBRUpdateService.swift
//  ESPRainMaker
//

class ThreadBRUpdateService {
    
    let threadCmdKey = "ThreadCmd"
    let activeDatasetKey = "ActiveDataset"
    let pendingDatasetKey = "PendingDataset"
    
    /// Create new thread network
    /// - Parameters:
    ///   - nodeId: node id
    ///   - serviceName: service name
    func createNewThreadNetwork(node: Node, nodeId: String, serviceName: String, completion: @escaping (Bool) -> Void) {
        var params = [serviceName: [threadCmdKey: 1]]
        if let paramName = node.getServiceParamName(forServiceType: Constants.threadBRService, andParamType: Constants.threadCommand) {
            params = [serviceName: [paramName: 1]]
        }
        DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: params, delegate: self) { status in
            if status == .success {
                completion(true)
                return
            }
            completion(false)
        }
    }
    
    /// Set active dataset
    /// - Parameters:
    ///   - nodeId: node id
    ///   - serviceName: TBR service name
    ///   - activeDataset: active dataser
    func setActiveDataset(node: Node, nodeId: String, serviceName: String, activeDataset: String, completion: @escaping (Bool) -> Void) {
        var params = [serviceName: [activeDatasetKey: activeDataset]]
        if let paramName = node.getServiceParamName(forServiceType: Constants.threadBRService, andParamType: Constants.threadActiveDataset) {
            params = [serviceName: [paramName: activeDataset]]
        }
        DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: params, delegate: self) { status in
            if status == .success {
                completion(true)
                return
            }
            completion(false)
        }
    }
    
    /// Set active dataset
    /// - Parameters:
    ///   - nodeId: node id
    ///   - serviceName: TBR service name
    ///   - activeDataset: active dataser
    func mergeThreadNetwork(node: Node, nodeId: String, serviceName: String, pendingDataset: String, completion: @escaping (Bool) -> Void) {
        var params = [serviceName: [pendingDatasetKey: pendingDataset]]
        if let paramName = node.getServiceParamName(forServiceType: Constants.threadBRService, andParamType: Constants.threadPendingDataset) {
            params = [serviceName: [paramName: pendingDataset]]
        }
        DeviceControlHelper.shared.updateParam(nodeID: nodeId, parameter: params, delegate: self) { status in
            if status == .success {
                completion(true)
                return
            }
            completion(false)
        }
    }
}

extension ThreadBRUpdateService: ParamUpdateProtocol {
    
    /// param update failed
    func failureInUpdatingParam() {}
}

