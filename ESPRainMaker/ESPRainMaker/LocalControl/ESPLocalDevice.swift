// Copyright 2021 Espressif Systems
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
//  ESPLocalDevice.swift
//  ESPRainMaker
//

import Foundation
import ESPProvision

// Subclass of ESPDevice to manage device communication
class ESPLocalDevice : ESPDevice {
    
    // Session path for local control
    private let sessionPath = "esp_local_ctrl/session"
    var hostname = ""
    
    /// Method to send data to device available on WLAN.
    ///
    /// - Parameters:
    ///   - path: Endpoint of device.
    ///   - data: Data to be sent to device.
    ///   - completionHandler: The completion handler that is called when data transmission is successful.
    ///                          Parameter of block include response received from the HTTP request or error if any.
    override func sendData(path: String, data: Data, completionHandler: @escaping (Data?, ESPSessionError?) -> Void) {
        if self.security == .unsecure {
            self.sendUnsecureData(path: path, data: data, completionHandler: completionHandler)
            return
        }
        // Match Android EspLocalDevice: establish session first, then send (two-step).
        // Android uses cookies so the second request (ch_resp) carries the session; we do the same.
        if !self.isSessionEstablished() {
            self.initialiseSession(sessionPath: sessionPath) { status in
                switch status {
                case .connected:
                    self.sendDataPrivate(path: path, data: data, retryOnce: true, completionHandler: completionHandler)
                default:
                    completionHandler(nil, .sessionNotEstablished)
                }
            }
            return
        }
        // Session is already established, sending data.
        sendDataPrivate(path: path, data: data, retryOnce: true, completionHandler: completionHandler)
    }
    
    
    func sendDataPrivate(path: String, data: Data, retryOnce: Bool, completionHandler: @escaping (Data?, ESPSessionError?) -> Void) {
        guard self.isSessionEstablished() else {
            // Re-establish session and retry
            if retryOnce {
                DispatchQueue.main.async {
                    self.initialiseSession(sessionPath: self.sessionPath) { status in
                        switch status {
                        case .connected:
                            self.sendDataPrivate(path: path, data: data, retryOnce: false, completionHandler: completionHandler)
                        default:
                            completionHandler(nil, .sessionNotEstablished)
                        }
                    }
                }
                return
            } else {
                completionHandler(nil, .sessionNotEstablished)
                return
            }
        }

        guard let encryptedData = securityLayer.encrypt(data: data) else {
            completionHandler(nil, .securityMismatch)
            return
        }

        espSoftApTransport.SendConfigData(path: path, data: encryptedData) { response, error in
            if error != nil, response == nil {
                if retryOnce {
                    DispatchQueue.main.async {
                        self.initialiseSession(sessionPath: self.sessionPath) { status in
                            switch status {
                            case .connected:
                                self.sendDataPrivate(path: path, data: data, retryOnce: false, completionHandler: completionHandler)
                            default:
                                completionHandler(nil, .sendDataError(error!))
                            }
                        }
                    }
                } else {
                    completionHandler(nil, .sendDataError(error!))
                }
            } else {
                if let responseData = self.securityLayer.decrypt(data: response!) {
                    completionHandler(responseData, nil)
                } else {
                    completionHandler(nil, .encryptionError)
                }
            }
        }
    }
    
    // Method to send unencrypted data to devices over WLAN.
    private func sendUnsecureData(path: String, data: Data, completionHandler: @escaping (Data?, ESPSessionError?) -> Swift.Void) {
        let url = URL(string: "http://\(hostname)/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 2.0
        request.httpBody = data
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completionHandler(nil, .sendDataError(error!))
                return
            }

            completionHandler(data, nil)
        }
        task.resume()
    }
}
