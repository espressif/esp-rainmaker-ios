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
//  ParamSliderCell+UI.swift
//  ESPRainMaker
//
//  UI Setup and Configuration

import UIKit

extension ParamSliderCell {
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        applyCommonCellStyling()
    }
    
    // MARK: - UI Setup
    func setupUI() {
        backgroundColor = .clear
        applyCommonCellStyling()
        
        contentView.addSubview(backView)
        backView.addSubview(titleLabel)
        backView.addSubview(slider)
        backView.addSubview(minLabel)
        backView.addSubview(maxLabel)
        backView.addSubview(minImage)
        backView.addSubview(maxImage)
        
        // Stored for dynamic spacing adjustments (e.g. Matter vs Rainmaker).
        backViewTopSpaceConstraint = backView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0)
        backViewBottomSpaceConstraint = backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        leadingSpaceConstraint = backView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15)
        trailingSpaceConstraint = backView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15)
        
        guard let topConstraint = backViewTopSpaceConstraint,
              let leadingConstraint = leadingSpaceConstraint,
              let trailingConstraint = trailingSpaceConstraint,
              let bottomConstraint = backViewBottomSpaceConstraint else { return }
        
        NSLayoutConstraint.activate([
            topConstraint,
            leadingConstraint,
            trailingConstraint,
            bottomConstraint,
            
            titleLabel.topAnchor.constraint(equalTo: backView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            
            slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            slider.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            slider.heightAnchor.constraint(equalToConstant: 30),
            
            minImage.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            minImage.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 12),
            minImage.widthAnchor.constraint(equalToConstant: 20),
            minImage.heightAnchor.constraint(equalToConstant: 20),
            minImage.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -12),
            
            minLabel.leadingAnchor.constraint(equalTo: minImage.trailingAnchor, constant: 8),
            minLabel.centerYAnchor.constraint(equalTo: minImage.centerYAnchor),
            
            maxImage.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            maxImage.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 12),
            maxImage.widthAnchor.constraint(equalToConstant: 20),
            maxImage.heightAnchor.constraint(equalToConstant: 20),
            maxImage.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -12),
            
            maxLabel.trailingAnchor.constraint(equalTo: maxImage.leadingAnchor, constant: -8),
            maxLabel.centerYAnchor.constraint(equalTo: maxImage.centerYAnchor)
        ])
        
        // Performance optimizations (matching original SliderTableViewCell)
        slider.layer.shouldRasterize = true
        slider.layer.rasterizationScale = UIScreen.main.scale
        slider.layer.masksToBounds = true
        
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderValueDragged(_:)), for: [.touchDragInside, .touchDragOutside])
        // CRITICAL: Matter updates only happen on touch up (not during drag)
        slider.addTarget(self, action: #selector(sliderTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        
        // NOTE: Don't call setSliderThumbUI() here - it will be called in updateUI() after slider.value is set
        // The original awakeFromNib() calls it, but at that point XIB has already set slider.value
    }
    
    // MARK: - UI Updates
    func updateUI() {
        guard let param = param else { return }
        
        // CRITICAL: Re-apply colors every time (after reloadData() they may be reset)
        // Use #8265E3: red="0.50980392156862742" green="0.396078431372549" blue="0.8901960784313725"
        slider.minimumTrackTintColor = UIColor(red: 0.50980392156862742, green: 0.396078431372549, blue: 0.8901960784313725, alpha: 1.0)
        slider.maximumTrackTintColor = Constants.sliderTrackGrayBlue
        slider.tintColor = UIColor(red: 0.50980392156862742, green: 0.396078431372549, blue: 0.8901960784313725, alpha: 1.0)
        
        // Set title - CRITICAL: Use param.name directly, but also set paramName for fallback
        let paramNameValue = param.name ?? ""
        titleLabel.text = paramNameValue
        // Also set paramName and attributeKey for backward compatibility and fallback
        if paramName.isEmpty {
            paramName = paramNameValue
        }
        if attributeKey.isEmpty {
            attributeKey = paramNameValue
        }
        
        // Setup slider bounds from param
        if let bounds = param.bounds {
            let minValue = bounds["min"] as? Float ?? 0
            let maxValue = bounds["max"] as? Float ?? 100
            slider.minimumValue = minValue
            slider.maximumValue = maxValue
            
            // Cache dataType for performance (matching original behavior)
            dataType = param.dataType?.lowercased() ?? "float"
            minLabel.text = dataType == "int" ? "\(Int(minValue))" : "\(minValue)"
            maxLabel.text = dataType == "int" ? "\(Int(maxValue))" : "\(maxValue)"
            
            if let step = bounds["step"] as? Float {
                sliderStepValue = step
            }
        } else {
            // Set default dataType if no bounds
            dataType = param.dataType?.lowercased() ?? "float"
        }
        
        // Set initial value - Match original implementation exactly
        let value: Float?
        if dataType == "int", let intValue = param.value as? Int {
            value = Float(intValue)
        } else if let floatValue = param.value as? Float {
            value = floatValue
        } else {
            value = nil
        }
        
        if let value = value {
            let oldSliderValue = slider.value
            let willChange = abs(oldSliderValue - value) > 0.01
            let shouldIgnore = shouldIgnoreNotificationUpdates()
            
            // CRITICAL: Check if we should ignore notification updates (user is dragging or recently finished)
            if shouldIgnore {
                // Don't update slider value, but still update thumb to show current position
                setSliderThumbUI()
            } else {
                // Use setValue with animation for smooth transitions (matches original behavior)
                // Only animate if value is actually changing to avoid unnecessary animation on initial setup
                if willChange {
                    slider.setValue(value, animated: true)
                } else {
                    slider.value = value
                }
                sliderInitialValue = value
                finalValue = value
                currentFinalValue = value
                // CRITICAL: Update thumb UI immediately after setting slider.value
                // This ensures thumb is set even after reloadData() and cell reuse
                setSliderThumbUI()
            }
        } else {
            // Even if value is nil, update thumb to show current slider.value
            // This ensures thumb persists after reloadData()
            setSliderThumbUI()
        }
        
        // Set icons based on param type
        setIconsForParam(param)
        
        // Update online/offline state (for Matter devices)
        updateConnectionState()
        
        // CRITICAL: Ensure thumb is set after all UI updates
        // This is a safety net to ensure thumb persists after reloadData()
        // Call again to ensure thumb is visible even if something cleared it
        setSliderThumbUI()
    }
    
    // MARK: - Connection State Updates
    func updateConnectionState() {
        // Determine if this is a Matter device or Rainmaker device
        let isMatterDevice = (deviceId != nil) || (nodeGroup != nil)
        
        if isMatterDevice {
            // For Matter devices, check isDeviceOffline flag (no param property needed)
            slider.isEnabled = !isDeviceOffline
            slider.isUserInteractionEnabled = !isDeviceOffline
            isUserInteractionEnabled = !isDeviceOffline
            alpha = isDeviceOffline ? 0.5 : 1.0
            slider.alpha = isDeviceOffline ? 0.5 : 1.0
        } else {
            // For Rainmaker devices, check param properties and node connection
            guard let properties = param?.properties, properties.contains("write") else {
                // No write permission - disable slider
                slider.isEnabled = false
                slider.isUserInteractionEnabled = false
                isUserInteractionEnabled = false
                alpha = 0.5
                slider.alpha = 0.5
                return
            }
            
            if let device = device {
                let isConnected = device.node?.isConnected == true || device.node?.localNetwork == true
                
                slider.isEnabled = isConnected
                slider.isUserInteractionEnabled = isConnected
                isUserInteractionEnabled = isConnected
                alpha = isConnected ? 1.0 : 0.5
                slider.alpha = isConnected ? 1.0 : 0.5
            } else {
                slider.isEnabled = false
                slider.isUserInteractionEnabled = false
                isUserInteractionEnabled = false
                alpha = 0.5
                slider.alpha = 0.5
            }
        }
    }
    
    // MARK: - Helper Methods
    func applyCommonCellStyling() {
        backgroundColor = .clear
        backView.layer.borderWidth = 1
        backView.layer.cornerRadius = 10
        backView.layer.borderColor = UIColor.clear.cgColor
        backView.layer.masksToBounds = true
        layer.shadowOpacity = 0.18
        layer.shadowOffset = CGSize(width: 1, height: 2)
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.black.cgColor
        layer.masksToBounds = false
    }
    
    // MARK: - Notification Update Protection
    /// Check if notification updates should be ignored (user is dragging or recently finished)
    func shouldIgnoreNotificationUpdates() -> Bool {
        // If user is actively dragging, ignore notifications
        if isUserDragging {
            return true
        }
        
        // If user recently finished dragging (within cooldown period), ignore notifications
        if let dragEndTime = dragEndTimestamp {
            let timeSinceDragEnd = Date().timeIntervalSince(dragEndTime)
            if timeSinceDragEnd < notificationUpdateCooldown {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Icons Configuration
    func setIconsForParam(_ param: Param) {
        guard let type = param.type?.lowercased() else {
            minImage.image = nil
            maxImage.image = nil
            return
        }
        
        switch type {
        case Constants.deviceBrightnessParam:
            minImage.image = UIImage(named: "brightness_low")
            maxImage.image = UIImage(named: "brightness_high")
        case Constants.deviceSaturationParam:
            minImage.image = UIImage(named: "saturation_low")
            maxImage.image = UIImage(named: "saturation_high")
        case Constants.deviceCCTParam:
            minImage.image = UIImage(named: "cct_low")
            maxImage.image = UIImage(named: "cct_high")
        default:
            minImage.image = nil
            maxImage.image = nil
        }
    }
    
    // MARK: - Thumb UI
    func setSliderThumbUI(backgroundColor: UIColor = UIColor(red: 0.50980392156862742, green: 0.396078431372549, blue: 0.8901960784313725, alpha: 1.0)) {
        // Match original SliderTableViewCell.setSliderThumbUI EXACTLY
        slider.setThumbImage(nil, for: .normal)

        if thumbLabel == nil {
            thumbLabel = UILabel()
            thumbLabel?.font = UIFont.systemFont(ofSize: 14)
            thumbLabel?.textAlignment = .center
            thumbLabel?.textColor = .white
        }
        
        guard let thumbLabel = thumbLabel else { return }

        // CRITICAL: Set text first, then get size
        let textValue = String(format: "%.0f", slider.value)
        thumbLabel.text = textValue
        thumbLabel.isHidden = false // Ensure label is visible

        let padding: CGFloat = 16
        let textSize = thumbLabel.intrinsicContentSize
        let minWidth: CGFloat = 32
        let thumbWidth = max(textSize.width + padding, minWidth)
        
        // Ensure circular shape when at minimum width
        let thumbHeight: CGFloat
        if thumbWidth == minWidth {
            // At minimum width, make it circular
            thumbHeight = minWidth
        } else {
            // Allow rectangular shape for longer text
            thumbHeight = textSize.height + padding
        }
        
        let thumbSize = CGSize(width: thumbWidth, height: thumbHeight)
        let thumbView = UIView(frame: CGRect(origin: .zero, size: thumbSize))
        thumbView.backgroundColor = backgroundColor
        thumbView.layer.cornerRadius = thumbSize.height / 2
        thumbView.clipsToBounds = true  // Prevents UI overlap

        thumbView.subviews.forEach { $0.removeFromSuperview() }
        
        // CRITICAL: Ensure label properties are set before adding
        thumbLabel.frame = thumbView.bounds
        thumbLabel.text = textValue // Set again to ensure it's not lost
        thumbLabel.textColor = .white
        thumbLabel.isHidden = false
        thumbView.addSubview(thumbLabel)
        
        // CRITICAL: Force layout to ensure label text is rendered
        thumbView.layoutIfNeeded()
        thumbLabel.layoutIfNeeded()
        
        // CRITICAL: Ensure text is actually rendered - force display
        thumbView.setNeedsDisplay()
        thumbLabel.setNeedsDisplay()

        let thumbImage = thumbView.asImage()

        slider.setThumbImage(thumbImage, for: .normal)
        
        thumbLabel.isHidden = true
    }
}

