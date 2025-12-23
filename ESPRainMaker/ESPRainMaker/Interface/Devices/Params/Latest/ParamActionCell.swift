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
//  ParamActionCell.swift
//  ESPRainMaker
//

import UIKit

protocol ParamActionCellDelegate: AnyObject {
    func actionInvoked(device: Device?, param: Param?, paramName: String)
}

class ParamActionCell: UITableViewCell {
    
    static let reuseIdentifier = "ParamActionCell"
    
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
    
    let controlValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17) // Matches XIB: font 17 (not 16)
        label.textColor = Constants.textColorDarkGray
        // XIB doesn't specify textAlignment, defaults to .natural (left-aligned for LTR languages)
        // Frame shows x=16 which confirms left-alignment
        label.textAlignment = .natural
        return label
    }()
    
    let invokeActionButton: PrimaryButton = {
        // CRITICAL: XIB uses customClass="PrimaryButton", not UIButton
        // PrimaryButton's changeTheme() is NOT producing white background - must override explicitly
        // Original shows: white background with purple text
        let button = PrimaryButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Scan QR", for: .normal) // Matches XIB default title
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15) // Matches XIB: pointSize="15"
        // XIB: cornerRadius="5" (PrimaryButton defaults to 10, but XIB overrides to 5)
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        // XIB: imageEdgeInsets minX="0.0" minY="0.0" maxX="2.2250738585072014e-308" maxY="0.0" (essentially 0)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        // CRITICAL: Force white background and purple text to match original
        // Original screenshot shows white background with purple text, NOT purple background
        button.backgroundColor = .white
        button.setTitleColor(UIColor(hexString: "#8265E3"), for: .normal) // Purple text
        return button
    }()
    
    // MARK: - Properties
    var param: Param? {
        didSet {
            updateUI()
        }
    }
    
    var device: Device?
    weak var delegate: ParamActionCellDelegate?
    
    // CRITICAL: These properties match the old ActionTableViewCell implementation
    // Used for backward compatibility and cell reuse protection
    var attributeKey: String = ""
    var paramName: String = ""
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented - use programmatic initialization")
    }
    
    // MARK: - Setup
    // UI setup is handled in ParamActionCell+UI.swift
    
    // MARK: - prepareForReuse
    // CRITICAL: Properly reset all state to prevent cell reuse bugs
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset param-identifying properties
        param = nil
        device = nil
        attributeKey = ""
        paramName = ""
        
        // Reset delegates
        delegate = nil
        
        // Reset UI
        controlValueLabel.text = nil
        invokeActionButton.isEnabled = true
        invokeActionButton.alpha = 1.0
        isUserInteractionEnabled = true
        alpha = 1.0
    }
    
    // MARK: - UI Updates
    // UI update logic is handled in ParamActionCell+UI.swift
    
    // MARK: - Actions
    // Action handling is in ParamActionCell+Actions.swift
}

