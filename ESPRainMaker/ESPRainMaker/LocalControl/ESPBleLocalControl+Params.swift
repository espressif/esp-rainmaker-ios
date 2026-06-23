// Copyright 2026 Espressif Systems
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
//  ESPBleLocalControl+Params.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation
import SwiftProtobuf

extension ESPBleLocalControl {

    func connectAndSetParams(nodeId: String, parameter: [String: Any], completion: @escaping (ESPCloudResponseStatus) -> Void) {
        let needsBleConnect = isDiscovered(nodeId: nodeId) && !isConnected(nodeId: nodeId)
        if needsBleConnect {
            paramUpdateNodeIds.insert(nodeId)
            notifyUpdate()
        }
        let finish: (ESPCloudResponseStatus) -> Void = { [weak self] status in
            if needsBleConnect {
                self?.paramUpdateNodeIds.remove(nodeId)
                self?.notifyUpdate()
            }
            completion(status)
        }
        if isConnected(nodeId: nodeId) {
            setParams(nodeId: nodeId, parameter: parameter, completion: finish)
            return
        }
        if isDiscovered(nodeId: nodeId) {
            connectDevice(nodeId: nodeId) { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.setParams(nodeId: nodeId, parameter: parameter, completion: finish)
                } else {
                    finish(.failure)
                }
            }
            return
        }
        finish(.failure)
    }

    private func setParams(nodeId: String, parameter: [String: Any], completion: @escaping (ESPCloudResponseStatus) -> Void) {
        enqueueBleOp(nodeId: nodeId, op: .setParams(parameter: parameter, completion: completion))
    }

    func queryParams(nodeId: String, completion: @escaping ([String: Any]?) -> Void) {
        enqueueBleOp(nodeId: nodeId, op: .queryParams(completion: completion))
    }

    func getParamsWithTimestamp(nodeId: String, completion: @escaping (_ parsed: [String: Any]?, _ rawJSON: String?) -> Void) {
        enqueueBleOp(nodeId: nodeId, op: .getParamsWithTimestamp(completion: completion))
    }

    /// Chunked read used during BLE-only provisioning (`get_config` / `get_params`).
    func fetchRawData(
        device: ESPDevice,
        dataType: RmakerProvLocalCtrl_RMakerLocalCtrlDataType,
        timestamp: Int64?,
        completion: @escaping (_ parsed: [String: Any]?, _ rawJSON: String?) -> Void
    ) {
        fetchParamsChunkOnDevice(device: device, dataType: dataType, offset: 0, timestamp: timestamp, buffer: Data()) { parsed, rawJSON in
            completion(parsed, rawJSON)
        }
    }

    private func sendData(device: ESPDevice, path: String, data: Data, completion: @escaping (Data?, Error?) -> Void) {
        if device.isSessionEstablished() {
            device.sendData(path: path, data: data) { response, error in
                if let error = error {
                    completion(nil, error)
                } else {
                    completion(response, nil)
                }
            }
        } else {
            device.initialiseSession(sessionPath: nil) { [weak self] status in
                switch status {
                case .connected:
                    self?.sendData(device: device, path: path, data: data, completion: completion)
                default:
                    completion(nil, NSError(domain: "ESPBleLocalControl", code: 1, userInfo: nil))
                }
            }
        }
    }

    private func fetchParamsChunk(
        nodeId: String,
        dataType: RmakerProvLocalCtrl_RMakerLocalCtrlDataType,
        offset: Int,
        timestamp: Int64?,
        buffer: Data,
        completion: @escaping (_ parsed: [String: Any]?, _ rawJSON: String?) -> Void
    ) {
        guard let device = activeDevice(nodeId: nodeId) else {
            completion(nil, nil)
            return
        }
        fetchParamsChunkOnDevice(device: device, dataType: dataType, offset: offset, timestamp: timestamp, buffer: buffer, completion: completion)
    }

    private func fetchParamsChunkOnDevice(
        device: ESPDevice,
        dataType: RmakerProvLocalCtrl_RMakerLocalCtrlDataType,
        offset: Int,
        timestamp: Int64?,
        buffer: Data,
        completion: @escaping (_ parsed: [String: Any]?, _ rawJSON: String?) -> Void
    ) {
        var cmd = RmakerProvLocalCtrl_CmdGetData()
        cmd.dataType = dataType
        cmd.offset = UInt32(offset)
        if let timestamp = timestamp {
            cmd.timestamp = timestamp
            cmd.hasTimestamp_p = true
        } else {
            cmd.hasTimestamp_p = false
        }

        var payload = RmakerProvLocalCtrl_RMakerLocalCtrlPayload()
        payload.msg = .typeCmdGetData
        payload.cmdGetData = cmd

        guard let requestData = try? payload.serializedData() else {
            completion(nil, nil)
            return
        }

        let endpointPath = dataType == .typeConfig ? Constants.handlerGetConfig : Constants.handlerGetParams
        sendData(device: device, path: endpointPath, data: requestData) { [weak self] responseData, error in
            guard let self = self, error == nil, let responseData = responseData else {
                completion(nil, nil)
                return
            }
            do {
                let response = try RmakerProvLocalCtrl_RMakerLocalCtrlPayload(serializedData: responseData)
                guard response.msg == .typeRespGetData,
                      response.respGetData.status == .success else {
                    completion(nil, nil)
                    return
                }
                let buf = response.respGetData.buf
                guard buf.offset == UInt32(offset) else {
                    completion(nil, nil)
                    return
                }
                var accumulated = buffer
                accumulated.append(buf.payload)
                let totalLen = Int(buf.totalLen)
                let newOffset = offset + buf.payload.count
                if newOffset >= totalLen {
                    guard let rawJSON = String(data: accumulated, encoding: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: accumulated) as? [String: Any] else {
                        completion(nil, nil)
                        return
                    }
                    completion(json, rawJSON)
                } else {
                    self.fetchParamsChunkOnDevice(
                        device: device,
                        dataType: dataType,
                        offset: newOffset,
                        timestamp: nil,
                        buffer: accumulated,
                        completion: completion
                    )
                }
            } catch {
                completion(nil, nil)
            }
        }
    }

    private func enqueueBleOp(nodeId: String, op: BleLocalCtrlOp) {
        let apply = { [weak self] in
            guard let self = self else { return }
            var queue = self.bleOpQueue[nodeId] ?? []
            if case .setParams(let newParameter, let newCompletion) = op,
               case .setParams(_, let oldCompletion) = queue.last {
                queue.removeLast()
                queue.append(.setParams(parameter: newParameter, completion: { status in
                    oldCompletion(status)
                    newCompletion(status)
                }))
            } else {
                queue.append(op)
            }
            self.bleOpQueue[nodeId] = queue
            self.pumpBleOps(nodeId: nodeId)
        }
        if Thread.isMainThread {
            apply()
        } else {
            DispatchQueue.main.async(execute: apply)
        }
    }

    private func pumpBleOps(nodeId: String) {
        guard !bleOpRunning.contains(nodeId) else { return }
        guard var queue = bleOpQueue[nodeId], !queue.isEmpty else {
            bleOpQueue[nodeId] = nil
            return
        }
        let op = queue.removeFirst()
        bleOpQueue[nodeId] = queue.isEmpty ? nil : queue
        bleOpRunning.insert(nodeId)
        executeBleOp(nodeId: nodeId, op: op)
    }

    private func finishBleOp(nodeId: String) {
        let finish = { [weak self] in
            guard let self = self else { return }
            self.bleOpRunning.remove(nodeId)
            self.pumpBleOps(nodeId: nodeId)
        }
        if Thread.isMainThread {
            finish()
        } else {
            DispatchQueue.main.async(execute: finish)
        }
    }

    func failQueuedBleOps(nodeId: String) {
        let ops = bleOpQueue.removeValue(forKey: nodeId) ?? []
        guard !ops.isEmpty else { return }
        for op in ops {
            switch op {
            case .setParams(_, let completion):
                completion(.failure)
            case .queryParams(let completion):
                completion(nil)
            case .getParamsWithTimestamp(let completion):
                completion(nil, nil)
            }
        }
    }

    private func executeBleOp(nodeId: String, op: BleLocalCtrlOp) {
        switch op {
        case .setParams(let parameter, let completion):
            performSetParams(nodeId: nodeId, parameter: parameter) { [weak self] status in
                completion(status)
                self?.finishBleOp(nodeId: nodeId)
            }
        case .queryParams(let completion):
            performQueryParams(nodeId: nodeId) { [weak self] parsed in
                completion(parsed)
                self?.finishBleOp(nodeId: nodeId)
            }
        case .getParamsWithTimestamp(let completion):
            performGetParamsWithTimestamp(nodeId: nodeId) { [weak self] parsed, rawJSON in
                completion(parsed, rawJSON)
                self?.finishBleOp(nodeId: nodeId)
            }
        }
    }

    private func performSetParams(nodeId: String, parameter: [String: Any], completion: @escaping (ESPCloudResponseStatus) -> Void) {
        // `.withoutEscapingSlashes` avoids "Asia/Kolkata" -> "Asia\/Kolkata"; the local-ctrl
        // firmware handler doesn't unescape JSON, so an escaped slash breaks TZ-string lookups.
        guard let device = activeDevice(nodeId: nodeId),
              let jsonData = try? JSONSerialization.data(withJSONObject: parameter, options: .withoutEscapingSlashes) else {
            completion(.failure)
            return
        }

        var didComplete = false
        let finishOnce: (ESPCloudResponseStatus) -> Void = { status in
            guard !didComplete else { return }
            didComplete = true
            completion(status)
        }

        let timer = startOperationTimer(nodeId: nodeId) { [weak self] in
            self?.handleOperationTimeout(nodeId: nodeId)
            finishOnce(.failure)
        }

        sendData(device: device, path: Constants.handlerSetParams, data: jsonData) { [weak self] _, error in
            self?.cancelOperationTimer(nodeId: nodeId, timer: timer)
            if error != nil {
                self?.handleOperationTimeout(nodeId: nodeId)
                finishOnce(.failure)
            } else {
                finishOnce(.success)
            }
        }
    }

    private func performQueryParams(nodeId: String, completion: @escaping ([String: Any]?) -> Void) {
        guard activeDevice(nodeId: nodeId) != nil else {
            completion(nil)
            return
        }
        fetchParamsChunk(nodeId: nodeId, dataType: .typeParams, offset: 0, timestamp: nil, buffer: Data()) { parsed, _ in
            completion(parsed)
        }
    }

    private func performGetParamsWithTimestamp(nodeId: String, completion: @escaping (_ parsed: [String: Any]?, _ rawJSON: String?) -> Void) {
        guard activeDevice(nodeId: nodeId) != nil else {
            completion(nil, nil)
            return
        }
        guard !proxyReadInProgress.contains(nodeId) else {
            completion(nil, nil)
            return
        }
        proxyReadInProgress.insert(nodeId)
        let timestamp = Int64(Date().timeIntervalSince1970)
        fetchParamsChunk(nodeId: nodeId, dataType: .typeParams, offset: 0, timestamp: timestamp, buffer: Data()) { parsed, rawJSON in
            self.proxyReadInProgress.remove(nodeId)
            completion(parsed, rawJSON)
        }
    }

    private func handleOperationTimeout(nodeId: String) {
        failQueuedBleOps(nodeId: nodeId)
        connectionMap[nodeId]?.activeDevice?.disconnect()
        if var conn = connectionMap[nodeId] {
            conn.activeDevice = nil
            if conn.scannedDevice != nil {
                conn.state = .discovered
                setBleDiscoveredOnNode(nodeId: nodeId)
            } else {
                conn.state = .disconnected
                clearBleStatusOnNode(nodeId: nodeId)
            }
            connectionMap[nodeId] = conn
        }
        notifyUpdate()
    }

    private func startOperationTimer(nodeId: String, handler: @escaping () -> Void) -> Timer {
        let timer = Timer.scheduledTimer(withTimeInterval: operationTimeout, repeats: false) { _ in
            handler()
        }
        operationTimers[nodeId] = timer
        return timer
    }

    private func cancelOperationTimer(nodeId: String, timer: Timer) {
        timer.invalidate()
        operationTimers.removeValue(forKey: nodeId)
    }
}
