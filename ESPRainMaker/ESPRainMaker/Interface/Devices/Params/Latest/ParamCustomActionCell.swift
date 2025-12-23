// Copyright 2025 Espressif Systems
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
//  ParamCustomActionCell.swift
//  ESPRainMaker
//

import UIKit

// CustomAction enum is defined in CustomActionCell.swift
// Using the existing definition to avoid duplication

/// This protocol defines the actions that the CustomAction cell supports
protocol ParamCustomActionDelegate: AnyObject {
    func launchRainmakerController()
    func launchController()
    func updateThreadDataset()
    func setActiveThreadDataset()
    func mergeThreadDataset()
    func launchKinesisVideo(channel: String?)
}

class ParamCustomActionCell: UITableViewCell {
    
    static let reuseIdentifier = "ParamCustomActionCell"
    
    // MARK: - UI Elements (Programmatically Created)
    // Made internal for component extensions
    let container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Constants.cellBackgroundLightGray
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 10
        view.layer.borderColor = UIColor.clear.cgColor
        view.layer.masksToBounds = true
        return view
    }()
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = Constants.textColorDarkGray
        label.alpha = 0.5 // Matches XIB: alpha="0.5" on label
        label.lineBreakMode = .byTruncatingTail // Matches XIB: lineBreakMode="tailTruncation"
        label.adjustsFontSizeToFitWidth = false // Matches XIB: adjustsFontSizeToFit="NO"
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = Constants.textColorDarkGray
        label.lineBreakMode = .byTruncatingTail // Matches XIB: lineBreakMode="tailTruncation"
        label.adjustsFontSizeToFitWidth = false // Matches XIB: adjustsFontSizeToFit="NO"
        label.numberOfLines = 0 // Allow multiple lines if needed (XIB doesn't set this, but allows wrapping)
        return label
    }()
    
    let launchButton: PrimaryButton = {
        // CRITICAL: XIB uses customClass="PrimaryButton", not UIButton
        // PrimaryButton's changeTheme() is NOT producing white background - must override explicitly
        // Original shows: white background with purple text (matches ParamActionCell)
        let button = PrimaryButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Update", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15) // Matches XIB: pointSize="15"
        // XIB: cornerRadius="5" (PrimaryButton defaults to 10, but XIB overrides to 5)
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        // XIB: contentEdgeInsets minX="10" minY="0.0" maxX="10" maxY="0.0"
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        // XIB: imageEdgeInsets minX="0.0" minY="0.0" maxX="2.2250738585072014e-308" maxY="0.0" (essentially 0)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        // CRITICAL: Force white background and purple text to match ParamActionCell
        // Original screenshot shows white background with purple text, NOT purple background
        button.backgroundColor = .white
        button.setTitleColor(UIColor(hexString: "#8265E3"), for: .normal) // Purple text
        return button
    }()
    
    // MARK: - Properties
    var param: Param? {
        didSet {
            // Update UI if param changes (for notification updates)
            // Note: setupWorkflow is called during cell configuration, not here
            // This property is mainly for tracking which param this cell represents
        }
    }
    var device: Device?
    weak var delegate: ParamCustomActionDelegate?
    var workflow: CustomAction = .launchController
    var channel: String?
    
    // Constraints for spacing (public for external access)
    var topSpaceConstraint: NSLayoutConstraint!
    var bottomSpaceConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented - use programmatic initialization")
    }
    
    // MARK: - Setup
    // UI setup is handled in ParamCustomActionCell+UI.swift
    
    // MARK: - prepareForReuse
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset properties
        param = nil
        device = nil
        delegate = nil
        workflow = .launchController
        channel = nil
        
        // Reset UI
        headerLabel.text = nil
        descriptionLabel.attributedText = nil // Reset attributed text as well
        descriptionLabel.text = nil
        launchButton.setTitle("Update", for: .normal) // Matches XIB default title
        launchButton.isEnabled = true
        launchButton.alpha = 1.0
        
        // Reset spacing to XIB defaults (10, not 0)
        topSpaceConstraint.constant = 10
        bottomSpaceConstraint.constant = -10
    }
    
    // MARK: - Public Methods
    // Workflow configuration is in ParamCustomActionCell+Configuration.swift
    
    // MARK: - Actions
    // Action handling is in ParamCustomActionCell+Actions.swift
}

