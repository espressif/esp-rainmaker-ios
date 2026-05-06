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
//  ParamTriggerCell.swift
//  ESPRainMaker
//

import UIKit

class ParamTriggerCell: UITableViewCell {
    
    static let reuseIdentifier = "ParamTriggerCell"
    
    // MARK: - UI Elements (Programmatically Created)
    // Made internal for component extensions
    let backView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Constants.cellBackgroundLightGray
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 10
        view.layer.borderColor = UIColor.clear.cgColor
        view.layer.masksToBounds = true
        return view
    }()
    
    let controlNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15) // Matches XIB: pointSize="15" (no weight)
        label.textColor = Constants.textColorDarkGray
        return label
    }()
    
    let triggerButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        // Matches XIB: No title text (button is circular, no text)
        button.backgroundColor = Constants.triggerButtonBackground
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 3
        button.layer.borderColor = Constants.triggerButtonBorderGray.cgColor
        return button
    }()
    
    // MARK: - Properties
    // CRITICAL: Use param.name directly, NOT a stored paramName property
    var param: Param? {
        didSet {
            updateUI()
        }
    }
    
    var device: Device?
    weak var paramDelegate: ParamUpdateProtocol?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented - use programmatic initialization")
    }
    
    // MARK: - Setup
    // UI setup is handled in ParamTriggerCell+UI.swift
    
    // MARK: - prepareForReuse
    // CRITICAL: Properly reset all state to prevent cell reuse bugs
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset param-identifying properties
        param = nil
        device = nil
        
        // Reset delegates
        paramDelegate = nil
        
        // Reset UI
        controlNameLabel.text = nil
        triggerButton.isEnabled = true
        triggerButton.alpha = 1.0
    }
    
    // MARK: - UI Updates
    // UI update logic is handled in ParamTriggerCell+UI.swift
    
    // MARK: - Actions
    // Action handling is in ParamTriggerCell+RM.swift
}

