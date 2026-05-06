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
//  ParamCentralSwitchCell.swift
//  ESPRainMaker
//

import UIKit

class ParamCentralSwitchCell: UITableViewCell {
    
    static let reuseIdentifier = "ParamCentralSwitchCell"
    
    // MARK: - UI Elements (Programmatically Created)
    // Made internal for component extensions
    let backView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemBackground // Matches XIB: systemBackgroundColor (line 36)
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 10
        view.layer.borderColor = UIColor.clear.cgColor
        view.layer.masksToBounds = true
        return view
    }()
    
    let powerButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    // CRITICAL: Use param.name directly, NOT a stored property
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
    // UI setup is handled in ParamCentralSwitchCell+UI.swift
    
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
        powerButton.setBackgroundImage(nil, for: .normal)
    }
    
    // MARK: - UI Updates
    // UI update logic is handled in ParamCentralSwitchCell+UI.swift
    
    // MARK: - Actions
    // Action handling is in ParamCentralSwitchCell+RM.swift
}

