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
//  ParamGenericCell.swift
//  ESPRainMaker
//

import UIKit
#if ESPRainMakerMatter
import Matter
#endif

class ParamGenericCell: UITableViewCell {
    
    static let reuseIdentifier = "ParamGenericCell"
    
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
        label.font = UIFont.systemFont(ofSize: 14) // Matches XIB: system 14pt (no weight)
        label.textColor = Constants.textColorDarkGray
        label.alpha = 0.5 // Matches XIB alpha
        return label
    }()
    
    let controlValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17) // Matches XIB: system 17pt
        label.textColor = Constants.textColorDarkGray
        return label
    }()
    
    let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        // Match XIB EXACTLY - all button properties
        button.setTitle("Edit", for: .normal) // Matches XIB: title="Edit"
        button.setTitleColor(UIColor(hexString: Constants.customColor), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12) // Matches XIB: pointSize="12"
        button.contentHorizontalAlignment = .center // Matches XIB: contentHorizontalAlignment="center"
        button.contentVerticalAlignment = .center // Matches XIB: contentVerticalAlignment="center"
        return button
    }()
    
    let tapButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        // Match XIB EXACTLY - all button properties
        button.setImage(UIImage(named: "chart_icon"), for: .normal) // Matches XIB: image="chart_icon"
        button.contentHorizontalAlignment = .right // Matches XIB: contentHorizontalAlignment="right"
        button.contentVerticalAlignment = .center // Matches XIB: contentVerticalAlignment="center"
        // Note: tintColor not specified in XIB, will use default
        return button
    }()
    
    // MARK: - Properties
    // CRITICAL: attributeKey is used as fallback when param.name is empty (matches old GenericControlTableViewCell)
    var attributeKey: String = ""
    
    // CRITICAL: controlValue stores the string value separately from label (matches old GenericControlTableViewCell)
    var controlValue: String?
    
    var param: Param? {
        didSet {
            updateUI()
        }
    }
    
    var device: Device?
    weak var paramDelegate: ParamUpdateProtocol?
    
    var dataType: String = "String"
    var isSimpleTimeSeries: Bool?
    
    // Online/Offline state (for Matter devices)
    var isDeviceOffline: Bool = false
    var showDefaultUI: Bool = false
    
    // Matter properties
    var deviceId: UInt64?
    weak var nodeGroup: ESPNodeGroup?
    var node: ESPNodeDetails?
    var infoType: InfoType = .indoorTemperature // Matches old GenericControlTableViewCell
    
    // Schedule/Scene properties (matches old GenericControlTableViewCell)
    var scheduleDelegate: ScheduleActionDelegate?
    var indexPath: IndexPath!
    
    // Constraint properties (matches old GenericControlTableViewCell for dynamic spacing)
    var backViewTopSpaceConstraint: NSLayoutConstraint?
    var backViewBottomSpaceConstraint: NSLayoutConstraint?
    var leadingSpaceConstraint: NSLayoutConstraint?
    var trailingSpaceConstraint: NSLayoutConstraint?
    
    let boolTypeValidValues: [String: Int] = ["true": 1, "false": 0, "yes": 1, "no": 0, "0": 0, "1": 1]
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented - use programmatic initialization")
    }
    
    // MARK: - Setup
    // UI setup is handled in ParamGenericCell+UI.swift
    
    // MARK: - prepareForReuse
    // CRITICAL: Properly reset all state to prevent cell reuse bugs
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset param-identifying properties
        attributeKey = ""
        controlValue = nil
        param = nil
        device = nil
        
        // Reset configuration
        dataType = "String"
        isSimpleTimeSeries = nil
        
        // Reset Matter properties
        deviceId = nil
        nodeGroup = nil
        node = nil
        infoType = .indoorTemperature
        
        // Reset schedule/scene properties
        scheduleDelegate = nil
        indexPath = IndexPath(row: 0, section: 0) // Reset to default
        
        // Reset delegates
        paramDelegate = nil
        
        // Reset online/offline state
        isDeviceOffline = false
        showDefaultUI = false
        
        // Reset UI
        controlNameLabel.text = nil
        controlValueLabel.text = nil
        editButton.isHidden = true
        tapButton.isHidden = true
    }
    
    // MARK: - UI Updates
    // UI update logic is handled in ParamGenericCell+UI.swift
    
    // MARK: - Actions
    // Action handling is in ParamGenericCell+Actions.swift
    
    // MARK: - Parameter Update
    // Parameter update logic is in ParamGenericCell+RM.swift
}

