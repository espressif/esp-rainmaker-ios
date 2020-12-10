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
//  ESPLocalService.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation
import UIKit

/// Enum contains error cases that can occur while communicating on local network
enum ESPLocalServiceError {
    case httpError(Error)

    case failure(Status)

    case decodingError(Error)

    case encodingError(Error)

    case zeroProperty

    var description: String {
        switch self {
        case let .httpError(error):
            return "Error while sending HTTP request: \(error.localizedDescription)"
        case let .failure(status):
            return "Recieved failure response from device with status:\(status)"
        case let .decodingError(error):
            return "Error decoding device response:\(error.localizedDescription)"
        case let .encodingError(error):
            return "Error encoding device request:\(error.localizedDescription)"
        case .zeroProperty:
            return "Found no property in device response."
        }
    }
}

/// Class that provides interface for communicating with services on local network.
class ESPLocalService: NSObject {
    var netService: NetService
    var hostname = ""

    private let control_endpoint = "esp_local_ctrl/control"
    private var paramValues: [String: Any] = [:]
    private var propertyInfo: [String: Any] = [:]

    init(service: NetService) {
        netService = service
        hostname = service.hostName ?? ""
    }

    /// Method to provide property info of a device on local netowrk.
    ///
    /// - Parameters:
    ///   - completionHandler: Callback method that is invoked in case request is succesfully processed or fails in between.
    func getPropertyInfo(completionHandler: @escaping ([String: Any]?, ESPLocalServiceError?) -> Swift.Void) {
        let data = try! createGetPropertyCountRequest()
        propertyInfo.removeAll()
        SendHTTPData(data: data!) { response, error in
            if error != nil {
                completionHandler(nil, .httpError(error!))
                return
            }

            self.processGetPropertyCount(response: response!, completionHandler: completionHandler)
        }
    }

    /// Method to set parameter of a device.
    ///
    /// - Parameters:
    ///   - json: Key-value pair of property name and value.
    ///   - completionHandler: Callback that gives information on success/failure of set method.
    func setProperty(json: [String: Any], completionHandler: @escaping (Bool, ESPLocalServiceError?) -> Swift.Void) {
        let data = try! createSetPropertyInfoRequest(json: json)
        SendHTTPData(data: data!) { response, error in
            if error != nil {
                completionHandler(false, .httpError(error!))
                return
            }
            self.processSetPropertyResponse(response: response!, completionHandler: completionHandler)
        }
    }

    private func getPropertyValues(count: UInt32, completionHandler: @escaping ([String: Any]?, ESPLocalServiceError?) -> Swift.Void) {
        var requestProcessedWithoutError = true
        if count < 1 {
            completionHandler(nil, .zeroProperty)
        } else {
            let group = DispatchGroup()
            for i in 0 ..< count {
                do {
                    let propValRequest = try createGetPropertyValueRequest(index: i)
                    group.enter()
                    SendHTTPData(data: propValRequest!) { response, error in
                        if error != nil {
                            completionHandler(nil, .httpError(error!))
                            return
                        }
                        requestProcessedWithoutError = self.processGetPropertyInfoResponse(response: response!, completionHandler: completionHandler)
                        group.leave()
                    }
                } catch {
                    completionHandler(nil, .encodingError(error))
                }
            }
            group.notify(queue: DispatchQueue.main) {
                if requestProcessedWithoutError {
                    completionHandler(self.propertyInfo, nil)
                }
            }
        }
    }

    private func createGetPropertyCountRequest() throws -> Data? {
        var request = LocalCtrlMessage()
        request.msg = LocalCtrlMsgType.typeCmdGetPropertyCount
        request.cmdGetPropCount = CmdGetPropertyCount()
        return try request.serializedData()
    }

    private func createSetPropertyInfoRequest(json: [String: Any]) throws -> Data? {
        var request = LocalCtrlMessage()
        request.msg = LocalCtrlMsgType.typeCmdSetPropertyValues
        var payload = CmdSetPropertyValues()
        var prop = PropertyValue()
        prop.index = 1
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
        prop.value = jsonData
        payload.props.append(prop)
        request.cmdSetPropVals = payload
        return try request.serializedData()
    }

    private func createGetPropertyValueRequest(index: UInt32) throws -> Data? {
        var request = LocalCtrlMessage()
        request.msg = LocalCtrlMsgType.typeCmdGetPropertyValues
        var payload = CmdGetPropertyValues()
        payload.indices.append(index)
        request.cmdGetPropVals = payload
        return try request.serializedData()
    }

    private func processGetPropertyCount(response: Data, completionHandler: @escaping ([String: Any]?, ESPLocalServiceError?) -> Swift.Void) {
        do {
            let response = try LocalCtrlMessage(serializedData: response)
            if response.respGetPropCount.status == .success {
                getPropertyValues(count: response.respGetPropCount.count, completionHandler: completionHandler)
            } else {
                completionHandler(nil, .failure(response.respGetPropCount.status))
            }
        } catch {
            completionHandler(nil, .decodingError(error))
        }
    }

    private func processSetPropertyResponse(response: Data, completionHandler: @escaping (Bool, ESPLocalServiceError?) -> Swift.Void) {
        do {
            let response = try LocalCtrlMessage(serializedData: response)
            if response.respSetPropVals.status == .success {
                completionHandler(true, nil)
            } else {
                completionHandler(false, .failure(response.respSetPropVals.status))
            }
        } catch {
            completionHandler(false, .decodingError(error))
        }
    }

    private func processGetPropertyInfoResponse(response: Data, completionHandler: @escaping ([String: Any]?, ESPLocalServiceError?) -> Swift.Void) -> Bool {
        do {
            let response = try LocalCtrlMessage(serializedData: response)
            if response.respGetPropVals.status == .success {
                let prop = response.respGetPropVals.props.first
                let json = try! JSONSerialization.jsonObject(with: prop!.value, options: .allowFragments) as! [String: Any]
                propertyInfo[prop?.name ?? ""] = json
                return true
            } else {
                completionHandler(nil, .failure(response.respGetPropVals.status))
                return false
            }
        } catch {
            completionHandler(nil, .decodingError(error))
            return false
        }
    }

    private func SendHTTPData(data: Data, completionHandler: @escaping (Data?, Error?) -> Swift.Void) {
        let url = URL(string: "http://\(hostname)/\(control_endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 2.0
        request.httpBody = data
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }

            let httpStatus = response as? HTTPURLResponse
            if httpStatus?.statusCode != 200 {
                print("statusCode should be 200, but is \(String(describing: httpStatus?.statusCode))")
            }
            completionHandler(data, nil)
        }
        task.resume()
    }
}
