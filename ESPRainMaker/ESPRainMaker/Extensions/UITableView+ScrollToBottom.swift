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
//  UITableView+ScrollToBottom.swift
//  ESPRainMaker
//

import UIKit

extension UITableView {
    
    /// Method to scroll tableView to the bottom automatically.
    /// - Parameter isAnimated: Tells whether scrolling is animated. Default value is `true`.
    func scrollToBottom(isAnimated:Bool = true){
        DispatchQueue.main.async {
            let indexPath = IndexPath(
                row: self.numberOfRows(inSection:  self.numberOfSections-1) - 1,
                section: self.numberOfSections - 1)
            if self.hasRowAtIndexPath(indexPath: indexPath) {
                self.scrollToRow(at: indexPath, at: .bottom, animated: isAnimated)
            }
        }
    }
    
    /// Check if there is a row at the indexPath provided
    /// - Parameter indexPath: indexPath of the tableView
    /// - Returns: `True` if row is present. `False` otherwise
    func hasRowAtIndexPath(indexPath: IndexPath) -> Bool {
            return indexPath.section < self.numberOfSections && indexPath.row < self.numberOfRows(inSection: indexPath.section)
    }
}
