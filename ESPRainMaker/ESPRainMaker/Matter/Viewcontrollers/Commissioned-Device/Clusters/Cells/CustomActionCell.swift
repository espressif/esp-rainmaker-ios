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
//  CustomActionCell.swift
//  ESPRainmaker
//

import UIKit

/// Actions supported by the custom action cell
enum CustomAction {
    case launchController
    case updateThreadDataset
    case setActiveThreadDataset
    case mergeThreadDataset
}

/// This protocol defines the actions that the CustomAction cell supports
protocol CustomActionDelegate: AnyObject {
    
    func launchController()
    func updateThreadDataset()
    func setActiveThreadDataset()
    func mergeThreadDataset()
}

class CustomActionCell: UITableViewCell {
    
    static let reuseIdentifier = "CustomActionCell"
    weak var delegate: CustomActionDelegate?
    var workflow: CustomAction = .launchController
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var launchButton: PrimaryButton!
    @IBOutlet weak var container: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        container.layer.shadowOpacity = 0.18
        container.layer.shadowOffset = CGSize(width: 1, height: 2)
        container.layer.shadowRadius = 2
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.masksToBounds = false
        launchButton.backgroundColor = UIColor(hexString: ESPMatterConstants.customBackgroundColor)
        launchButton.tintColor = UIColor(hexString: ESPMatterConstants.customBackgroundColor)
        launchButton.setTitleColor(UIColor.white, for: .normal)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupWorkflow(workflow: CustomAction) {
        DispatchQueue.main.async {
            self.workflow = workflow
            switch workflow {
            case .launchController:
                self.headerLabel.text = "Controller"
                self.descriptionLabel.text = "Update Device List"
            case .updateThreadDataset:
                self.headerLabel.text = "Border Router"
                self.descriptionLabel.text = "Update Thread Dataset"
            case .setActiveThreadDataset:
                self.headerLabel.text = "Border Router"
                self.descriptionLabel.text = "Update Thread Dataset"
            case .mergeThreadDataset:
                self.headerLabel.text = "Border Router"
                self.descriptionLabel.text = "Merge With Homepod"
                self.launchButton.setTitle("Merge", for: .normal)
            }
        }
    }
    
    /// Perform custom launch action
    /// - Parameter sender: button
    @IBAction func performCustomAction(_ sender: Any) {
        switch workflow {
        case .launchController:
            self.delegate?.launchController()
        case .updateThreadDataset:
            self.delegate?.updateThreadDataset()
        case .setActiveThreadDataset:
            self.delegate?.setActiveThreadDataset()
        case .mergeThreadDataset:
            self.delegate?.mergeThreadDataset()
        }
    }
}
