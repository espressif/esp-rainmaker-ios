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
//  ThreadSuccessViewController+SendThread.swift
//  ESPRainMaker
//

import UIKit
import ESPProvision

@available(iOS 15.0, *)
extension ThreadSuccessViewController {
    
    /// Update apply configuration step
    func updateApplyConfigurationUI() {
        DispatchQueue.main.async {
            self.step1Image.isHidden = true
            self.activityIndicator1.isHidden = false
            self.activityIndicator1.startAnimating()
        }
    }
    
    /// Update UI for apply configuration success
    func updateApplyConfigurationUISuccess() {
        DispatchQueue.main.async {
            self.activityIndicator1.stopAnimating()
            self.step1Image.image = UIImage(named: "checkbox_checked")
            self.step1Image.isHidden = false
            self.step2Image.isHidden = true
            self.activityIndicator2.isHidden = false
            self.activityIndicator2.startAnimating()
        }
    }
    
    /// Update UI for apply configuration  failure
    /// - Parameter message: failure message
    func updateApplyConfigurationUIFailure(message: String) {
        DispatchQueue.main.async {
            self.activityIndicator1.stopAnimating()
            self.step1Image.image = UIImage(named: "error_icon")
            self.step1Image.isHidden = false
            self.step1Error.text = message
            self.step1Error.isHidden = false
        }
    }
    
    /// Update apply configuration applied with message
    /// - Parameter error: ESPProvision object
    func updateApplyConfigurationWithMessage(error: ESPProvisionError) {
        DispatchQueue.main.async {
            self.activityIndicator1.stopAnimating()
            self.step1Image.image = UIImage(named: "error_icon")
            self.step1Image.isHidden = false
            var errorMessage = ""
            switch error {
            case .threadStatusUnknownError, .threadStatusDettached, .threadStatusNetworkNotFound:
                errorMessage = error.description
                self.espDevice.disconnect()
                self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
            case .threadStatusError:
                errorMessage = "Unable to fetch Thread state."
                self.sendRequestToAddDeviceAndUpdateUI { requestId, errMessage in
                    guard let requestId = requestId else {
                        self.sendRequestToAddDeviceFailed(errorMessage: errMessage)
                        return
                    }
                    self.updateConfirmNodeAssociationUI(requestID: requestId)
                }
            default:
                errorMessage = "Unknown error."
                self.espDevice.disconnect()
                self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
            }
            self.step1Error.text = errorMessage
            self.step1Error.isHidden = false
        }
    }
}

