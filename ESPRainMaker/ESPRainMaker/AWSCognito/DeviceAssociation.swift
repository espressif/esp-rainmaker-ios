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
//  DeviceAssociation.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation
import SwiftProtobuf

protocol DeviceAssociationProtocol {
    func deviceAssociationFinishedWith(success: Bool, nodeID: String?)
}

class DeviceAssociation {
    let secretKey: String

    var delegate: DeviceAssociationProtocol?
    var device: ESPDevice

    /// Create DeviceAssociation object that sends configuration data
    /// Required for sending data related to assoicating device with app user
    ///
    /// - Parameters:
    ///   - session: Initialised session object
    ///   - secretId: a unique key to authenticate user-device mapping
    init(secretId: String, device: ESPDevice) {
        secretKey = secretId
        self.device = device
    }

    /// Method to start user device mapping
    /// Info like userID and secretKey are sent from user to device
    ///
    func associateDeviceWithUser() {
        do {
            let payloadData = try createAssociationConfigRequest()

            if let data = payloadData {
                device.sendData(path: Constants.associationPath, data: data) { response, error in
                    guard error == nil, response != nil else {
                        self.delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil)
                        return
                    }
                    self.processResponse(responseData: response!)
                }
            } else {
                delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil)
            }
        } catch {
            delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil)
        }
    }

    /// Prcocess response to check status of mapping
    /// Info like userID and secretKey are sent from user to device
    ///
    /// - Parameters:
    ///   - responseData: Response recieved from device after sending mapping payload
    func processResponse(responseData: Data) {
        let decryptedResponse = (device.securityLayer.decrypt(data: responseData))!
        do {
            let response = try Rainmaker_RMakerConfigPayload(serializedData: decryptedResponse)
            if response.respSetUserMapping.status == .success {
                delegate?.deviceAssociationFinishedWith(success: true, nodeID: response.respSetUserMapping.nodeID)
            } else {
                delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil)
            }
        } catch {
            delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil)
        }
    }

    /// Method to convert device association payload into encrypted data
    /// This info is sent to device
    ///
    private func createAssociationConfigRequest() throws -> Data? {
        var configRequest = Rainmaker_CmdSetUserMapping()
        configRequest.secretKey = secretKey
        configRequest.userID = User.shared.userInfo.userID
        var payload = Rainmaker_RMakerConfigPayload()
        payload.msg = Rainmaker_RMakerConfigMsgType.typeCmdSetUserMapping
        payload.cmdSetUserMapping = configRequest
        return try device.securityLayer.encrypt(data: payload.serializedData())
    }
}
