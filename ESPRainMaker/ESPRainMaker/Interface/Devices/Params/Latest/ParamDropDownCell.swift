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
//  ParamDropDownCell.swift
//  ESPRainMaker
//

import DropDown
import UIKit
#if ESPRainMakerMatter
import Matter
#endif

// DropDownType and MTRACParamDelegate are defined in ParamDropDownTableViewCell.swift
// Using the existing definitions to avoid duplication

class ParamDropDownCell: UITableViewCell {
    
    static let reuseIdentifier = "ParamDropDownCell"
    
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
        label.font = UIFont.systemFont(ofSize: 14) // Matches XIB: pointSize="14"
        label.textColor = Constants.textColorDarkGray
        label.alpha = 0.5 // Matches XIB: alpha="0.5"
        return label
    }()
    
    let controlValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17) // Matches XIB: pointSize="17"
        label.textColor = Constants.textColorDarkGray
        return label
    }()
    
    let dropDownButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        // Match XIB EXACTLY - all button properties
        button.setImage(UIImage(named: "down_arrow"), for: .normal) // Matches XIB: image="down_arrow"
        button.contentHorizontalAlignment = .trailing // Matches XIB: contentHorizontalAlignment="trailing"
        button.contentVerticalAlignment = .center // Matches XIB: contentVerticalAlignment="center"
        // CRITICAL: XIB shows imageEdgeInsets maxX="16" which means 16pt inset from right edge
        // This places the arrow 16pt from the right edge of the button
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16) // Matches XIB: maxX="16"
        // CRITICAL: Button is a full overlay, so arrow will be 16pt from right edge of backView
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
    
    var datasource: [String] = []
    var currentValue: String = ""
    
    var isRainmaker: Bool = true
    var type: DropDownType = .rainmaker
    
    // Matter properties
    var deviceId: UInt64?
    weak var nodeGroup: ESPNodeGroup?
    var matterNode: ESPNodeDetails?
    weak var paramChipDelegate: ParamCHIPDelegate?
    weak var acParamDelegate: MTRACParamDelegate?
    
    // Online/Offline state (for Matter devices)
    var isDeviceOffline: Bool = false
    var showDefaultUI: Bool = false
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented - use programmatic initialization")
    }
    
    // MARK: - Setup
    // UI setup is handled in ParamDropDownCell+UI.swift
    
    // MARK: - prepareForReuse
    // CRITICAL: Properly reset all state to prevent cell reuse bugs
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset param-identifying properties
        param = nil
        device = nil
        
        // Reset configuration
        datasource = []
        currentValue = ""
        isRainmaker = true
        type = .rainmaker
        
        // Reset Matter properties
        deviceId = nil
        nodeGroup = nil
        matterNode = nil
        paramChipDelegate = nil
        acParamDelegate = nil
        isDeviceOffline = false
        showDefaultUI = false
        
        // Reset delegates
        paramDelegate = nil
        
        // Reset UI
        controlNameLabel.text = nil
        controlValueLabel.text = nil
        dropDownButton.isHidden = false
    }
    
    // MARK: - UI Updates
    // UI update logic is handled in ParamDropDownCell+UI.swift
    
    // MARK: - Actions
    // Dropdown action handling is in ParamDropDownCell+Actions.swift
}


