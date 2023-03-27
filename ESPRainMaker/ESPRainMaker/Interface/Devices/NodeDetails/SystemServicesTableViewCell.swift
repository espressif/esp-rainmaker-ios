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
//  SystemServicesTableViewCell.swift
//  ESPRainMaker
//

import UIKit

protocol SystemServiceTableViewCellDelegate {
    func systemServiceOperationPerformed()
    func factoryResetPerformed()
}

class SystemServicesTableViewCell: UITableViewCell {

    static let reuseIdentifier = "SystemServicesTableViewCell"
    
    var paramName:String!
    var paramType:String!
    var node:Node!
    var delegate: SystemServiceTableViewCellDelegate?
    
    @IBOutlet var resetButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // UI Customisation
        contentView.layer.borderWidth = 0.5
        contentView.layer.cornerRadius = 10
        contentView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.layer.masksToBounds = true
    }
    
    @IBAction func buttonTapped(_: Any) {
        if let systemService = node.services?.first(where: { $0.type == Constants.systemService }), let serviceName = systemService.name, let systemServiceCase = ESPSystemService.init(rawValue: paramType) {
            let alertController = UIAlertController(title: "Warning!", message: systemServiceCase.alertDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
            alertController.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
                DeviceControlHelper.shared.updateParam(nodeID: self.node.node_id, parameter: [serviceName : [self.paramName: true]], delegate: nil)
                self.delegate?.systemServiceOperationPerformed()
                if systemServiceCase == .factoryReset {
                    self.delegate?.factoryResetPerformed()
                }
            }))
            self.parentViewController?.present(alertController, animated: true)
        }
    }

}
