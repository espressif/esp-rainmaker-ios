// Copyright 2022 Espressif Systems
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
//  UISegmentControl+SetAppearance.swift
//  ESPRainMaker
//

import Foundation
import UIKit

extension UISegmentedControl {
    func setAppearance() {
        let currentBGColor = AppConstants.shared.getBGColor()
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white as Any, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .bold)], for: .normal)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: currentBGColor as Any, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20.0, weight: .heavy)], for: .selected)
        self.backgroundColor = currentBGColor
    }
}
