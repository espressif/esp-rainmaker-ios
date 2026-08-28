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
//  TimeZoneTableViewCell.swift
//  ESPRainMaker
//

import DropDown
import UIKit

class TimeZoneTableViewCell: DropDownTableViewCell {
    private var hasConfiguredAppearance = false
    private static let dropDownCellNibName = "DropDownCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        // Customise dropdown element for param screen
        // Hide row selection button
        checkButton.isHidden = true
        leadingSpaceConstraint.constant = 0
        trailingSpaceConstraint.constant = 0
        contentView.layer.borderWidth = 0.5
        contentView.layer.cornerRadius = 10
        contentView.layer.borderColor = UIColor.lightGray.cgColor
        backView.backgroundColor = UIColor.white
        if !hasConfiguredAppearance {
            backView.heightAnchor.constraint(equalToConstant: 55.0).isActive = true
            hasConfiguredAppearance = true
        }
        contentView.layer.masksToBounds = true
    }

    override func dropDownButtonTapped(_: Any) {
        let dropDownBundle = Bundle(for: DropDown.self)
        guard dropDownBundle.path(forResource: Self.dropDownCellNibName, ofType: "nib") != nil else {
            if let view = resolveHostViewForToast() {
                Utility.showToastMessage(view: view, message: "Timezone options are unavailable right now.")
            }
            return
        }

        DropDown.appearance().backgroundColor = UIColor.white
        DropDown.appearance().selectionBackgroundColor = #colorLiteral(red: 0.04705882353, green: 0.4392156863, blue: 0.9098039216, alpha: 1)
        let dropDown = DropDown()

        // Selecting param value in dropdown list
        if let index = datasource.firstIndex(where: { $0 == currentValue }) {
            let value = datasource.remove(at: index)
            datasource.insert(value, at: 0)
        }

        dropDown.dataSource = datasource
        dropDown.width = UIScreen.main.bounds.size.width - 100
        dropDown.anchorView = self
        dropDown.selectRow(at: 0)
        dropDown.show()

        // Assigning action for dropdown item selection
        dropDown.selectionAction = { [unowned self] (_: Int, item: String) in
            guard let paramName = self.param?.name, let serviceName = self.service?.name else { return }
            DeviceControlHelper.shared.updateParam(nodeID: self.node?.node_id, parameter: [serviceName: [paramName: item]], delegate: paramDelegate)
            param.value = item
            currentValue = item
            DispatchQueue.main.async {
                controlValueLabel.text = item
            }
        }
    }

    private func resolveHostViewForToast() -> UIView? {
        var responder: UIResponder? = self
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController.view
            }
            responder = current.next
        }
        return self.window
    }
}
