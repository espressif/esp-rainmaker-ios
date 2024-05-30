// Copyright 2023 Espressif Systems
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
//  DeviceViewController+BadgeCellDelegate.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import UIKit

@available(iOS 16.4, *)
extension DeviceViewController: BadgeCellDelegate {
    
    
    /// Get saved badge data
    /// - Returns: badge data
    func getData() -> ESPParticipantData? {
        if let groupId = self.group?.groupID, let matterNodeId = self.rainmakerNode?.matter_node_id, let deviceId = matterNodeId.hexToDecimal, let data = self.fabricDetails.fetchParticipantData(groupId: groupId, deviceId: deviceId) as? ESPParticipantData {
            return data
        }
        return nil
    }
    
    /// Get name
    /// - Returns: name
    func getName() -> String? {
        if let data = self.getData() {
            return data.name
        }
        return nil
    }
    
    /// Get company name
    /// - Returns: company  name
    func getCompanyName() -> String? {
        if let data = self.getData() {
            return data.companyName
        }
        return nil
    }
    
    /// Get email
    /// - Returns: email
    func getEmail() -> String? {
        if let data = self.getData() {
            return data.email
        }
        return nil
    }
    
    /// Get contact
    /// - Returns: contact
    func getContact() -> String? {
        if let data = self.getData() {
            return data.contact
        }
        return nil
    }
    
    /// Get event name
    /// - Returns: event name
    func getEventName() -> String? {
        if let data = self.getData() {
            return data.eventName
        }
        return "CSA MM Nov '23"
    }
    
    func updateBadgeData() {
        DispatchQueue.main.async {
            let input = UIAlertController(title: "", message: ESPMatterConstants.enterBadgeDetails, preferredStyle: .alert)
            input.addTextField { textField in
                self.nameField = textField
                textField.placeholder = "Name"
                if let name = self.getName() {
                    textField.text = name.replacingOccurrences(of: "\0", with: "")
                }
                self.addHeightConstraint(textField: textField)
                textField.isUserInteractionEnabled = true
            }
            input.addTextField { textField in
                self.companyNameField = textField
                textField.placeholder = "Company name"
                if let companyName = self.getCompanyName() {
                    textField.text = companyName.replacingOccurrences(of: "\0", with: "")
                }
                self.addHeightConstraint(textField: textField)
                textField.isUserInteractionEnabled = true
            }
            input.addTextField { textField in
                self.emailField = textField
                textField.placeholder = "Email"
                textField.keyboardType = .emailAddress
                if let email = self.getEmail() {
                    textField.text = email.replacingOccurrences(of: "\0", with: "")
                }
                self.addHeightConstraint(textField: textField)
                textField.isUserInteractionEnabled = true
            }
            input.addTextField { textField in
                self.contactField = textField
                textField.placeholder = "Phone number"
                textField.keyboardType = .phonePad
                if let contact = self.getContact() {
                    textField.text = contact.replacingOccurrences(of: "\0", with: "")
                }
                self.addHeightConstraint(textField: textField)
                textField.isUserInteractionEnabled = true
            }
            input.addTextField { textField in
                self.eventNameField = textField
                textField.placeholder = "Event name"
                if let eventName = self.getEventName() {
                    textField.text = eventName.replacingOccurrences(of: "\0", with: "")
                }
                self.addHeightConstraint(textField: textField)
                textField.isUserInteractionEnabled = true
            }
            input.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak input] _ in
                self.validateAndUpdateBadgeInfo()
            }))
            input.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(input, animated: true, completion: nil)
        }
    }
    
    /// Validate and update badge info
    func validateAndUpdateBadgeInfo() {
        let result = self.validateBadgeInfo()
        if result.0 {
            if let groupId = self.group?.groupID, let matterNodeId = self.rainmakerNode?.matter_node_id, let deviceId = matterNodeId.hexToDecimal, let data = result.1 {
                let value = ESPMatterClusterUtil.shared.isParticipantDataSupported(groupId: groupId, deviceId: deviceId)
                if let key = value.1, let endpoint = UInt16(key) {
                    DispatchQueue.main.async {
                        Utility.showLoader(message: "Updating badge details", view: self.view)
                    }
                    ESPMTRCommissioner.shared.sendParticipantData(deviceId: deviceId, endpoint: endpoint, data: data) { apiResult in
                        DispatchQueue.main.async {
                            Utility.hideLoader(view: self.view)
                        }
                        if apiResult {
                            self.fabricDetails.saveParticipantData(groupId: groupId, deviceId: deviceId, participantData: data)
                            DispatchQueue.main.async {
                                self.deviceTableView.reloadData()
                            }
                        } else {
                            //Badge update failed
                        }
                    }
                } else {
                    //endpoint is not available
                }
            }
        }
    }
    
    /// Validate badge info
    /// - Returns: (result, badge data)
    func validateBadgeInfo() -> (Bool, ESPParticipantData?) {
        var data = ESPParticipantData()
        if let field = self.nameField, let text = field.text {
            if text.replacingOccurrences(of: " ", with: "").count == 0 { //failure
                self.showErrorAlert(title: "Invalid", message: ESPMatterConstants.enterBadgeUserNameMsg, buttonTitle: "OK", callback: {})
                return (false, nil)
            } else { //success
                data.name = text
            }
        }
        
        if let field = self.companyNameField, let text = field.text {
            if text.replacingOccurrences(of: " ", with: "").count == 0 { //failure
                self.showErrorAlert(title: "Invalid", message: ESPMatterConstants.enterBadgeCompanyNameMsg, buttonTitle: "OK", callback: {})
                return (false, nil)
            } else { //success
                data.companyName = text
            }
        }
        
        if let field = self.emailField, let text = field.text {
            if !(text.replacingOccurrences(of: " ", with: "").count == 0) { //success
                data.email = text
            } else {
                data.email = ""
            }
        }
        
        if let field = self.contactField, let text = field.text {
            if !(text.replacingOccurrences(of: " ", with: "").count == 0) { //success
                data.contact = text
            } else {
                data.contact = ""
            }
        }
        
        if let field = self.eventNameField, let text = field.text {
            if text.replacingOccurrences(of: " ", with: "").count == 0 { //failure
                self.showErrorAlert(title: "Invalid", message: ESPMatterConstants.enterBadgeEventNameMsg, buttonTitle: "OK", callback: {})
                return (false, nil)
            } else { //success
                data.eventName = text
            }
        }
        return (true, data)
    }
}
#endif
