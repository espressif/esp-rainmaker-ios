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
    case launchRainmakerController
    case launchController
    case updateDeviceList
    case updateThreadDataset
    case setActiveThreadDataset
    case mergeThreadDataset
    case launchKinesisVideo
}

/// This protocol defines the actions that the CustomAction cell supports
protocol CustomActionDelegate: AnyObject {
    func launchRainmakerController()
    func launchController()
    func updateDeviceList()
    func updateThreadDataset()
    func setActiveThreadDataset()
    func mergeThreadDataset()
    func launchKinesisVideo(channel: String?)
}

class CustomActionCell: UITableViewCell {
    
    static let reuseIdentifier = "CustomActionCell"
    weak var delegate: CustomActionDelegate?
    var workflow: CustomAction = .launchController
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var launchButton: PrimaryButton!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var topSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomSpaceConstraint: NSLayoutConstraint!
    
    var channel: String?
    
    override func awakeFromNib() {
        super.layoutSubviews()
        backgroundColor = UIColor.clear

        container.layer.borderWidth = 1
        container.layer.cornerRadius = 10
        container.layer.borderColor = UIColor.clear.cgColor
        container.layer.masksToBounds = true

        layer.shadowOpacity = 0.18
        layer.shadowOffset = CGSize(width: 1, height: 2)
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.black.cgColor
        layer.masksToBounds = false
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
            case .launchRainmakerController:
                self.headerLabel.text = "Controller"
                self.descriptionLabel.text = "Update Params"
            case .launchController:
                self.headerLabel.text = "Controller"
                self.descriptionLabel.text = "Update Params"
            case .updateDeviceList:
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
            case .launchKinesisVideo:
                self.headerLabel.text = "WebRTC"
                self.descriptionLabel.text = "Video Streaming"
                self.launchButton.setTitle("Start", for: .normal)
            }
        }
    }
    
    /// Perform custom launch action
    /// - Parameter sender: button
    @IBAction func performCustomAction(_ sender: Any) {
        switch workflow {
        case .launchRainmakerController:
            self.delegate?.launchRainmakerController()
        case .launchController:
            self.delegate?.launchController()
        case .updateDeviceList:
            self.delegate?.updateDeviceList()
        case .updateThreadDataset:
            self.delegate?.updateThreadDataset()
        case .setActiveThreadDataset:
            self.delegate?.setActiveThreadDataset()
        case .mergeThreadDataset:
            self.delegate?.mergeThreadDataset()
        case .launchKinesisVideo:
            self.delegate?.launchKinesisVideo(channel: channel)
        }
    }
    
    /// Set launch button connected status
    /// - Parameter isDeviceOffline: is device online or offline
    func setLaunchButtonConnectedStatus(isDeviceOffline: Bool) {
        self.launchButton.isEnabled = !isDeviceOffline
        self.launchButton.alpha = isDeviceOffline ? 0.35 : 1.0
    }
    
    func setControllerUnauthorizedStatus() {
        DispatchQueue.main.async {
            let normalText = "Controller "
            let italicText = "(Unauthorized)"
                            
            let baseFont = self.headerLabel.font!
            let italicFont = UIFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.traitItalic) ?? baseFont.fontDescriptor, size: baseFont.pointSize)
                            
            let attributedString = NSMutableAttributedString(string: normalText, attributes: [
                NSAttributedString.Key.font: baseFont
            ])
            let italicAttributedString = NSAttributedString(string: italicText, attributes: [
                NSAttributedString.Key.font: italicFont
            ])
            attributedString.append(italicAttributedString)
            self.headerLabel.attributedText = attributedString
        }
    }
}
