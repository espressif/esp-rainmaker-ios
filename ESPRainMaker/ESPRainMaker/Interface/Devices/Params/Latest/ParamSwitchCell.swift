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
//  ParamSwitchCell.swift
//  ESPRainMaker
//

import UIKit

class ParamSwitchCell: UITableViewCell {
    
    static let reuseIdentifier = "ParamSwitchCell"
    
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
    
    let controlStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18) // Matches XIB: system 18pt
        label.textColor = Constants.textColorDarkGray
        return label
    }()
    
    let toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        // Match XIB EXACTLY - all switch colors and properties
        // onTintColor: red="0.50980392156862742" green="0.396078431372549" blue="0.8901960784313725" alpha="1"
        toggle.onTintColor = UIColor(red: 0.50980392156862742, green: 0.396078431372549, blue: 0.8901960784313725, alpha: 1.0)
        // tintColor: white="0.66666666666666663" alpha="1"
        toggle.tintColor = UIColor(white: 0.66666666666666663, alpha: 1.0)
        // thumbTintColor: white="1" alpha="1"
        toggle.thumbTintColor = UIColor(white: 1.0, alpha: 1.0)
        // backgroundColor: white="0.0" alpha="0.0"
        toggle.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        // layer.borderColor: red="0.32549019610000002" green="0.18823529410000001" blue="0.72549019609999998" alpha="1"
        toggle.layer.borderColor = UIColor(red: 0.32549019610000002, green: 0.18823529410000001, blue: 0.72549019609999998, alpha: 1.0).cgColor
        return toggle
    }()
    
    // MARK: - Properties
    // CRITICAL: attributeKey is used as fallback when param.name is empty (matches old SwitchTableViewCell)
    var attributeKey: String = ""
    
    var param: Param? {
        didSet {
            updateUI()
        }
    }
    
    var device: Device?
    weak var paramDelegate: ParamUpdateProtocol?
    
    // Schedule/Scene properties (matches old SwitchTableViewCell)
    var scheduleDelegate: ScheduleActionDelegate?
    var indexPath: IndexPath!
    
    // Constraint properties (matches old SwitchTableViewCell for dynamic spacing)
    // Leading/trailing are used for schedule/scene checkbox layout; top/bottom are
    // used to control vertical insets of the visible card inside the cell so that
    // spacing between cards stays uniform across all param types.
    var backViewTopSpaceConstraint: NSLayoutConstraint?
    var backViewBottomSpaceConstraint: NSLayoutConstraint?
    var leadingSpaceConstraint: NSLayoutConstraint?
    var trailingSpaceConstraint: NSLayoutConstraint?
    
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
    // UI setup is handled in ParamSwitchCell+UI.swift
    
    // MARK: - prepareForReuse
    // CRITICAL: Properly reset all state to prevent cell reuse bugs
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset param-identifying properties
        attributeKey = ""
        param = nil
        device = nil
        
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
        controlStateLabel.text = nil
        toggleSwitch.setOn(false, animated: false)
        toggleSwitch.isEnabled = true
    }
    
    // MARK: - UI Updates
    // UI update logic is handled in ParamSwitchCell+UI.swift
    
    // MARK: - Actions
    // Switch action handling is in ParamSwitchCell+RM.swift
}

