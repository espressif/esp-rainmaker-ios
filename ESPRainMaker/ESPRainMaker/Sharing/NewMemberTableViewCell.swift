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
//  NewMemberTableViewCell.swift
//  ESPRainMaker
//

import UIKit

class NewMemberTableViewCell: UITableViewCell {
    @IBOutlet var memberEmailTextField: UITextField!

    var index: Int = 0
    // Closure that contains block of code executed on the action of Cancel button
    var cancelButtonAction: () -> Void = {}
    // Closure that contains block of code executed on the action of Save button
    var saveButtonAction: () -> Void = {}

    override func awakeFromNib() {
        super.awakeFromNib()
        // UI Customisation
        memberEmailTextField.useUnderline()
        contentView.layer.borderWidth = 1
        contentView.layer.cornerRadius = 10
        contentView.layer.borderColor = UIColor.clear.cgColor
        contentView.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // Cancel sharing of node
    @IBAction func cancelButtonTapped(_: Any) {
        cancelButtonAction()
    }

    // Share node to the member
    @IBAction func saveButtonTapped(_: Any) {
        saveButtonAction()
    }
}

extension UITextField {
    func useUnderline() {
        let border = CALayer()
        let borderWidth = CGFloat(1.0)
        border.borderColor = UIColor.systemBlue.cgColor
        border.frame = CGRect(x: 0, y: frame.size.height - borderWidth, width: frame.size.width, height: frame.size.height)
        border.borderWidth = borderWidth
        layer.addSublayer(border)
        layer.masksToBounds = true
    }
}
