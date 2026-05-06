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
//  ParamSliderCell.swift
//  ESPRainMaker
//

import UIKit
#if ESPRainMakerMatter
import Matter
#endif

/// Configuration enum for different slider types
enum SliderConfiguration: Equatable {
    case standard(min: Float, max: Float, step: Float?)
    case matterLevel
    case matterSaturation
    case matterCCT
    case matterCoolingSetpoint
    case matterHeatingSetpoint
}

class ParamSliderCell: UITableViewCell {
    
    static let reuseIdentifier = "ParamSliderCell"
    
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
        label.font = UIFont.systemFont(ofSize: 14) // Matches XIB: system 14pt (no weight)
        label.textColor = Constants.textColorDarkGray
        label.alpha = 0.5 // Matches XIB alpha
        return label
    }()
    
    let slider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        // Matches XIB colors
        // Use #8265E3: red="0.50980392156862742" green="0.396078431372549" blue="0.8901960784313725"
        slider.minimumTrackTintColor = UIColor(red: 0.50980392156862742, green: 0.396078431372549, blue: 0.8901960784313725, alpha: 1.0)
        slider.maximumTrackTintColor = Constants.sliderTrackGrayBlue
        slider.tintColor = UIColor(red: 0.50980392156862742, green: 0.396078431372549, blue: 0.8901960784313725, alpha: 1.0) // For thumb (custom thumb image is used)
        return slider
    }()
    
    let minLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14) // Matches XIB: system 14pt
        label.textColor = Constants.textColorGrayBlue
        label.textAlignment = .left
        return label
    }()
    
    let maxLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14) // Matches XIB: system 14pt
        label.textColor = Constants.textColorGrayBlue
        label.textAlignment = .right
        return label
    }()
    
    let minImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let maxImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    var thumbLabel: UILabel?
    
    // MARK: - Properties
    // CRITICAL: paramName is used as fallback when param.name is empty (matches old SliderTableViewCell)
    var paramName: String = ""
    
    // CRITICAL: attributeKey for consistency with other cells (matches old pattern)
    var attributeKey: String = ""
    
    // CRITICAL: sliderValue stores formatted string value (matches old SliderTableViewCell)
    var sliderValue: String = ""
    
    var param: Param? {
        didSet {
            // CRITICAL: Matter devices (isRainmaker = false) NEVER use generic Param logic
            // They ONLY use stored values from node.getMatterLevelValue() etc.
            // Do NOT call updateUI() for Matter - it will overwrite stored values
            if isRainmaker {
                updateUI()
            }
        }
    }
    
    var device: Device?
    weak var paramDelegate: ParamUpdateProtocol?
    
    // Schedule/Scene properties (matches old SliderTableViewCell)
    var scheduleDelegate: ScheduleActionDelegate?
    var indexPath: IndexPath!
    
    // Constraint properties (matches old SliderTableViewCell for dynamic spacing)
    var backViewTopSpaceConstraint: NSLayoutConstraint?
    var backViewBottomSpaceConstraint: NSLayoutConstraint?
    var leadingSpaceConstraint: NSLayoutConstraint?
    var trailingSpaceConstraint: NSLayoutConstraint?
    
    // Timer property (matches old SliderTableViewCell)
    var timer = Timer()
    
    // Configuration
    var configuration: SliderConfiguration = .standard(min: 0, max: 100, step: nil)
    var isRainmaker: Bool = true
    
    // Window covering property (matches old SliderTableViewCell)
    var isWindowCovering: Bool = false
    
    // Matter properties
    var deviceId: UInt64?
    weak var nodeGroup: ESPNodeGroup?
    var node: ESPNodeDetails?
    var nodeConnectionStatus: NodeConnectionStatus = .local
    weak var paramChipDelegate: ParamCHIPDelegate?
    var sliderParamType: SliderParamType = .brightness
    
    // Online/Offline state (for Matter devices)
    var isDeviceOffline: Bool = false
    var showDefaultUI: Bool = false
    
    // Matter state (for different slider types)
    var currentLevel: Int = 0
    var minLevel: Int = 0
    var maxLevel: Int = 100
    
    // Slider state (made internal for component extensions)
    var sliderInitialValue: Float?
    var sliderStepValue: Float?
    var finalValue: Float = 0.0
    var currentFinalValue: Float = 0.0
    var currentTimeStamp = Date()
    
    // Data type (cached for performance, derived from param.dataType)
    var dataType: String = "float"
    
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
    
    // CRITICAL: Track slider value when user interaction began (for step calculation direction)
    // This is the reference point for determining if user is moving up or down
    var dragStartValue: Float?
    
    // CRITICAL: Track update results for partial success handling
    var continuousUpdateResults: [(value: Float, success: Bool)] = []
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented - use programmatic initialization")
    }
    
    // MARK: - Setup
    // UI setup is handled in ParamSliderCell+UI.swift
    
    // MARK: - prepareForReuse
    // CRITICAL: Properly reset all state to prevent cell reuse bugs
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset param-identifying properties
        paramName = ""
        attributeKey = ""
        sliderValue = ""
        param = nil
        device = nil
        
        // Reset schedule/scene properties
        scheduleDelegate = nil
        indexPath = IndexPath(row: 0, section: 0) // Reset to default
        
        // Reset configuration
        configuration = .standard(min: 0, max: 100, step: nil)
        sliderParamType = .brightness // CRITICAL: Reset param type to prevent cross-contamination
        isRainmaker = true
        isWindowCovering = false
        
        // Reset slider state
        sliderInitialValue = nil
        sliderStepValue = nil
        finalValue = 0.0
        currentFinalValue = 0.0
        currentTimeStamp = Date()
        dataType = "float"
        isUserDragging = false
        // CRITICAL: Always reset dragEndTimestamp in prepareForReuse
        // It will be set again in sliderValueChanged if the user is dragging
        // Preserving it across reuse causes cross-param interference (one param's cooldown affecting another)
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
        minImage.image = nil
        maxImage.image = nil
        slider.value = 0
    }
    
    // MARK: - UI Updates
    // UI update logic is handled in ParamSliderCell+UI.swift
    
    // MARK: - Slider Actions
    // Slider action handlers are in ParamSliderCell+Updates.swift
    
    // MARK: - Helper Methods
    // Helper methods are in ParamSliderCell+Updates.swift and ParamSliderCell+UI.swift
}

