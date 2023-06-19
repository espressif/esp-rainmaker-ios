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
//  DeviceViewController+ParamCHIPDelegate.swift
//  ESPRainmaker
//

#if ESPRainMakerMatter
import Foundation
import UIKit

@available(iOS 16.4, *)
extension DeviceViewController: ParamCHIPDelegate {
    
    func levelInitialValuesSet() {
        if cellInfo.contains(ESPMatterConstants.colorControl) {
            if let row = cellInfo.firstIndex(of: ESPMatterConstants.colorControl) {
                if let cell = self.deviceTableView.cellForRow(at: IndexPath(row: row, section: 0)) as? ParamSliderTableViewCell {
                    Utility.showLoader(message: "", view: self.view)
                    cell.setCurrentHueValue()
                }
            }
        }
    }
    
    func matterAPIRequestSent() {
        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
    }
    
    func matterAPIResponseReceived() {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
        }
    }
    
    func alertUserError(message: String) {
        DispatchQueue.main.async {
            Utility.showToastMessage(view: self.view, message: message, duration: 2.0)
        }
    }
}
#endif
