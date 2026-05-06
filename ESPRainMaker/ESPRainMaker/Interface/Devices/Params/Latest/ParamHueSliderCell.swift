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
//  ParamHueSliderCell.swift
//  ESPRainMaker
//

import UIKit
#if ESPRainMakerMatter
import Matter
#endif

class ParamHueSliderCell: UITableViewCell {
    
    static let reuseIdentifier = "ParamHueSliderCell"
    
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
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14) // Matches XIB: pointSize="14" (no weight)
        label.textColor = Constants.textColorDarkGray
        label.alpha = 0.5 // Matches XIB: alpha="0.5"
        return label
    }()
    
    let hueSlider: GradientSlider = {
        let slider = GradientSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.thickness = 5 // Matches XIB: thickness="5"
        return slider
    }()
    
    let minLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14) // Matches XIB: pointSize="14" (not 12)
        label.textColor = Constants.textColorGrayBlue
        label.textAlignment = .left
        return label
    }()
    
    let maxLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14) // Matches XIB: pointSize="14" (not 12)
        label.textColor = Constants.textColorGrayBlue
        label.textAlignment = .right
        return label
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
    
    // Matter properties (for future Matter support)
    var deviceId: UInt64?
    weak var nodeGroup: ESPNodeGroup?
    var node: ESPNodeDetails?
    var nodeConnectionStatus: NodeConnectionStatus = .local
    weak var paramChipDelegate: ParamCHIPDelegate?
    
    // Online/Offline state (for Matter devices)
    var isDeviceOffline: Bool = false
    var showDefaultUI: Bool = false
    
    // Hue slider state (made internal for component extensions)
    var sliderInitialValue: Float?
    var sliderStepValue: Float?
    var hueFinalValue: CGFloat = 0.0
    var hueCurrentFinalValue: CGFloat = 0.0
    var currentHueValue: CGFloat = 0.0
    var currentTimeStamp = Date()
    
    // Continuous update support
    let group = DispatchGroup()
    
    // Track pending delayed update work item to cancel it when user releases slider
    var pendingDelayedUpdateWorkItem: DispatchWorkItem?
    
    // Flag to ignore pending group notifications after user releases slider
    var shouldIgnorePendingUpdates: Bool = false
    
    // Constraint references for dynamic modification (Rainmaker vs Matter spacing)
    var backViewTopSpaceConstraint: NSLayoutConstraint?
    var backViewBottomSpaceConstraint: NSLayoutConstraint?
    
    // CRITICAL: Track user interaction to prevent notification updates during/after dragging
    // Made internal for access from extensions
    var isUserDragging: Bool = false
    var dragEndTimestamp: Date?
    let notificationUpdateCooldown: TimeInterval = 3.0 // 3 seconds after drag ends
    
    // CRITICAL: Track update results for partial success handling
    var continuousUpdateResults: [(value: Int, success: Bool)] = []
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented - use programmatic initialization")
    }
    
    // MARK: - Setup
    // UI setup is handled in ParamHueSliderCell+UI.swift
    
    // MARK: - prepareForReuse
    // CRITICAL: Properly reset all state to prevent cell reuse bugs
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset param-identifying properties
        param = nil
        device = nil
        
        // Reset configuration
        isRainmaker = true
        
        // Reset hue slider state
        sliderInitialValue = nil
        sliderStepValue = nil
        hueFinalValue = 0.0
        hueCurrentFinalValue = 0.0
        currentTimeStamp = Date()
        isUserDragging = false
        dragEndTimestamp = nil
        continuousUpdateResults.removeAll()
        
        // Reset Matter properties
        deviceId = nil
        nodeGroup = nil
        node = nil
        nodeConnectionStatus = .local
        paramChipDelegate = nil
        isDeviceOffline = false
        showDefaultUI = false
        
        // Reset delegates
        paramDelegate = nil
        
        // Reset UI
        titleLabel.text = nil
        minLabel.text = nil
        maxLabel.text = nil
        hueSlider.value = 0
        hueSlider.hasRainbow = false
    }
    
    // MARK: - UI Updates
    // UI update logic is handled in ParamHueSliderCell+UI.swift
    
    // MARK: - Hue Slider Actions
    // Slider action handlers are in ParamHueSliderCell+Updates.swift
    
    // MARK: - Helper Methods
    // Helper methods are in ParamHueSliderCell+Updates.swift
}


