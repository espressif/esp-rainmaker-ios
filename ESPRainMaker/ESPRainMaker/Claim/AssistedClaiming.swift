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
//  AssistedClaiming.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation

enum ClaimError: String {
    case startClaimFailed = "Claim start failed"
    case initClaimFailed = "Claim init failed"
    case verifyClaimFailed = "Claim verify failed"
}

class AssistedClaiming {
    var device: ESPDevice!
    var csrData: Data!
    var certificateData: Data!
    var datacount = 1

    init(espDevice: ESPDevice) {
        device = espDevice
        csrData = nil
        certificateData = nil
    }

    /// Start the process of assisted claiming from iOS
    ///
    /// - Parameters:
    ///   - completionHandler: block invoked will contain the result of claiming process and error if claim process fails.
    func initiateAssistedClaiming(completionHandler: @escaping (Bool, String?) -> Void) {
        do {
            let payloadData = try createClaimStartRequest()
            if let data = payloadData {
                device.sendData(path: Constants.claimPath, data: data) { response, error in
                    guard error == nil, response != nil else {
                        completionHandler(false, ClaimError.startClaimFailed.rawValue)
                        return
                    }
                    self.readDeviceInfo(responseData: response!, completionHandler: completionHandler)
                }
            } else {
                completionHandler(false, ClaimError.startClaimFailed.rawValue)
            }
        } catch {
            completionHandler(false, ClaimError.startClaimFailed.rawValue)
        }
    }

    private func getCSRFromDevice(response: Data?, completionHandler: @escaping (Bool, String?) -> Void) {
        do {
            var payloadData: Data!
            if csrData == nil {
                payloadData = try createClaimInitRequest(response: response!)
            } else {
                payloadData = try createSubsequentRequest()
            }
            if let data = payloadData {
                device.sendData(path: Constants.claimPath, data: data) { response, error in
                    guard error == nil, response != nil else {
                        completionHandler(false, ClaimError.initClaimFailed.rawValue)
                        return
                    }
                    self.processCSRResponse(response: response!, completionHandler: completionHandler)
                }
            } else {
                completionHandler(false, ClaimError.initClaimFailed.rawValue)
            }
        } catch {
            completionHandler(false, ClaimError.initClaimFailed.rawValue)
        }
    }

    private func sendCertificateToDevice(completionHandler: @escaping (Bool, String?) -> Void, offset: Int = 0) {
        do {
            var payload: Data!
            if offset + datacount > certificateData.count {
                payload = certificateData.subdata(in: Range(offset ... certificateData.count - 1))
            } else {
                payload = certificateData.subdata(in: Range(offset ... offset + datacount - 1))
            }
            let payloadData = try createClaimVerifyRequest(data: payload, offset: offset)
            if let data = payloadData {
                device.sendData(path: Constants.claimPath, data: data) { response, error in
                    guard error == nil, response != nil else {
                        return
                    }
                    if offset + self.datacount >= self.certificateData.count {
                        completionHandler(true, nil)
                    } else {
                        self.sendCertificateToDevice(completionHandler: completionHandler, offset: offset + self.datacount)
                    }
                }
            } else {
                completionHandler(false, ClaimError.verifyClaimFailed.rawValue)
            }
        } catch {
            completionHandler(false, ClaimError.verifyClaimFailed.rawValue)
        }
    }

    private func abortDevice(message: String, completionHandler: @escaping (Bool, String?) -> Void) {
        do {
            let payloadData = try createClaimAbortRequest()
            if let data = payloadData {
                device.sendData(path: Constants.claimPath, data: data) { _, _ in
                    completionHandler(false, message)
                }
            } else {
                completionHandler(false, message)
            }
        } catch {
            completionHandler(false, message)
        }
    }

    // MARK: - Claim API Calls

    private func sendDeviceInfoToCloud(response: [String: Any], completionHandler: @escaping (Bool, String?) -> Void) {
        NetworkManager.shared.genericAuthorizedDataRequest(url: Constants.claimInitPath, parameter: response) { data in
            if data == nil {
                completionHandler(false, ClaimError.initClaimFailed.rawValue)
                return
            }
            do {
                if let responseJSON = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: String] {
                    if let status = responseJSON["status"] {
                        if status.lowercased() == "failure" {
                            var failDescription = ClaimError.initClaimFailed.rawValue
                            if let description = responseJSON["description"] {
                                failDescription = description
                            }
                            self.abortDevice(message: failDescription, completionHandler: completionHandler)
                            return
                        }
                    }
                }
                self.getCSRFromDevice(response: data!, completionHandler: completionHandler)
            } catch {
                completionHandler(false, ClaimError.initClaimFailed.rawValue)
            }
        }
    }

    private func sendCSRToAPI(completionHandler: @escaping (Bool, String?) -> Void) {
        do {
            let response = try JSONSerialization.jsonObject(with: csrData, options: .allowFragments) as? [String: String] ?? [:]
            NetworkManager.shared.genericAuthorizedDataRequest(url: Constants.claimVerifyPath, parameter: response) { data in
                if data == nil {
                    completionHandler(false, ClaimError.initClaimFailed.rawValue)
                    return
                }
                do {
                    if let responseJSON = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: String] {
                        if let status = responseJSON["status"] {
                            if status.lowercased() == "failure" {
                                var failDescription = ClaimError.verifyClaimFailed.rawValue
                                if let description = responseJSON["description"] {
                                    failDescription = description
                                }
                                self.abortDevice(message: failDescription, completionHandler: completionHandler)
                                return
                            }
                        }
                    }
                    self.certificateData = data!
                    self.sendCertificateToDevice(completionHandler: completionHandler, offset: 0)
                } catch {
                    completionHandler(false, ClaimError.verifyClaimFailed.rawValue)
                }
            }
        } catch {
            completionHandler(false, ClaimError.verifyClaimFailed.rawValue)
        }
    }

    // MARK: - Process Response

    private func readDeviceInfo(responseData: Data, completionHandler: @escaping (Bool, String?) -> Void) {
        do {
            let response = try RmakerClaim_RMakerClaimPayload(serializedData: responseData)
            if response.respPayload.status == .success {
                sendDeviceInfoToCloud(response: try (JSONSerialization.jsonObject(with: response.respPayload.buf.payload, options: .allowFragments) as? [String: Any] ?? [:]), completionHandler: completionHandler)
            } else {
                completionHandler(false, ClaimError.startClaimFailed.rawValue)
            }
        } catch {
            completionHandler(false, ClaimError.startClaimFailed.rawValue)
        }
    }

    private func processCSRResponse(response: Data, completionHandler: @escaping (Bool, String?) -> Void) {
        do {
            let response = try RmakerClaim_RMakerClaimPayload(serializedData: response)
            if response.respPayload.status == .success {
                let payload = response.respPayload.buf
                if payload.offset == 0 {
                    datacount = payload.payload.count
                    csrData = payload.payload
                } else {
                    csrData.append(payload.payload)
                }
                if csrData.count >= payload.totalLen {
                    sendCSRToAPI(completionHandler: completionHandler)
                } else {
                    getCSRFromDevice(response: nil, completionHandler: completionHandler)
                }
            } else {
                completionHandler(false, ClaimError.initClaimFailed.rawValue)
            }
        } catch {
            completionHandler(false, ClaimError.initClaimFailed.rawValue)
        }
    }

    // MARK: - Create request payload

    private func createClaimStartRequest() throws -> Data? {
        var payload = RmakerClaim_RMakerClaimPayload()
        payload.msg = RmakerClaim_RMakerClaimMsgType.typeCmdClaimStart
        payload.cmdPayload = RmakerClaim_PayloadBuf()
        return try payload.serializedData()
    }

    private func createClaimInitRequest(response: Data) throws -> Data? {
        var payloadBuf = RmakerClaim_PayloadBuf()
        payloadBuf.offset = 0
        payloadBuf.totalLen = UInt32(response.count)
        payloadBuf.payload = response
        var payload = RmakerClaim_RMakerClaimPayload()
        payload.msg = RmakerClaim_RMakerClaimMsgType.typeCmdClaimInit
        payload.cmdPayload = payloadBuf
        return try payload.serializedData()
    }

    private func createSubsequentRequest() throws -> Data? {
        var payload = RmakerClaim_RMakerClaimPayload()
        payload.msg = RmakerClaim_RMakerClaimMsgType.typeCmdClaimInit
        payload.cmdPayload = RmakerClaim_PayloadBuf()
        return try payload.serializedData()
    }

    private func createClaimVerifyRequest(data: Data, offset: Int) throws -> Data? {
        var payloadBuf = RmakerClaim_PayloadBuf()
        payloadBuf.offset = UInt32(offset)
        payloadBuf.totalLen = UInt32(certificateData.count)
        payloadBuf.payload = data
        var payload = RmakerClaim_RMakerClaimPayload()
        payload.msg = RmakerClaim_RMakerClaimMsgType.typeCmdClaimVerify
        payload.cmdPayload = payloadBuf
        return try payload.serializedData()
    }

    private func createClaimAbortRequest() throws -> Data? {
        var payload = RmakerClaim_RMakerClaimPayload()
        payload.msg = RmakerClaim_RMakerClaimMsgType.typeCmdClaimAbort
        return try payload.serializedData()
    }
}
