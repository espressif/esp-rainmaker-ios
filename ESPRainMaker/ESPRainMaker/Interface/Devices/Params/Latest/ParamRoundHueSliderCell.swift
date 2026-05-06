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
//  ParamRoundHueSliderCell.swift
//  ESPRainMaker
//

import FlexColorPicker
import UIKit

class ParamRoundHueSliderCell: UITableViewCell {
    
    static let reuseIdentifier = "ParamRoundHueSliderCell"
    
    // MARK: - UI Elements (Programmatically Created)
    // Made internal for component extensions
    let backView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // Matches XIB: systemBackgroundColor (white in light mode)
        // Note: Other cells use Constants.cellBackgroundLightGray, but XIB explicitly uses systemBackgroundColor
        view.backgroundColor = UIColor.systemBackground
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 10
        view.layer.borderColor = UIColor.clear.cgColor
        view.layer.masksToBounds = true
        return view
    }()
    
    let hueSlider: RadialHueControl = {
        let slider = RadialHueControl()
        slider.translatesAutoresizingMaskIntoConstraints = false
        // Matches XIB: selectedColor (0.0, 0.9914394021, 1, 1)
        slider.selectedColor = UIColor(red: 0.0, green: 0.9914394021, blue: 1.0, alpha: 1.0)
        return slider
    }()
    
    let selectedColor: UIView = {
        // Simple circular UIView - radius = 1/4 of outer circle (hue slider)
        // Outer circle (hueSlider) is 250x250, so inner circle diameter = 250/4 = 62.5
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white // Default background - will be updated to reflect slider thumb position
        // CRITICAL: Use clipsToBounds, NOT masksToBounds (masksToBounds is for CALayer, clipsToBounds is for UIView)
        view.clipsToBounds = true
        
        // Add minimal shadow for 3D effect
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowRadius = 2.0
        view.layer.shadowOpacity = 0.15
        view.layer.masksToBounds = false // CRITICAL: Must be false for shadow to be visible
        
        return view
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
    
    var isRainmaker: Bool = true
    
    // Hue slider state (made internal for component extensions)
    var hueInitialValue: CGFloat?
    var finalValue: CGFloat = 0.0
    var currentFinalValue: CGFloat = 0.0
    var currentTimeStamp = Date()
    
    // Continuous update support
    let group = DispatchGroup()
    
    // Track pending delayed update work item to cancel it when user releases slider
    var pendingDelayedUpdateWorkItem: DispatchWorkItem?
    
    // Flag to ignore pending group notifications after user releases slider
    var shouldIgnorePendingUpdates: Bool = false
    
    // CRITICAL: Track user interaction to prevent notification updates during/after dragging
    // Made internal for access from extensions
    var isUserDragging: Bool = false
    var dragEndTimestamp: Date?
    let notificationUpdateCooldown: TimeInterval = 3.0 // 3 seconds after drag ends
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented - use programmatic initialization")
    }
    
    // MARK: - Setup
    // UI setup is handled in ParamRoundHueSliderCell+UI.swift
    
    // MARK: - prepareForReuse
    // CRITICAL: Properly reset all state to prevent cell reuse bugs
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset param-identifying properties
        param = nil
        device = nil
        
        // Reset hue slider state
        hueInitialValue = nil
        finalValue = 0.0
        currentFinalValue = 0.0
        currentTimeStamp = Date()
        isUserDragging = false
        dragEndTimestamp = nil
        
        // Reset delegates
        paramDelegate = nil
    }
    
    // MARK: - UI Updates
    // UI update logic is handled in ParamRoundHueSliderCell+UI.swift
    
    // MARK: - Actions
    // Action handling is in ParamRoundHueSliderCell+Updates.swift
    
    // MARK: - Parameter Update
    // Parameter update logic is in ParamRoundHueSliderCell+RM.swift
}

// MARK: - RadialHueControlDelegate
// Delegate implementation is in ParamRoundHueSliderCell+Updates.swift


