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
//  ParamHueSliderCell+UI.swift
//  ESPRainMaker
//
//  UI Setup and Configuration

import UIKit

extension ParamHueSliderCell {
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        applyCommonCellStyling()
        
        // CRITICAL: Re-apply connection state after layout to ensure alpha persists
        // GradientSlider's layoutSubviews might be called after ours, so we need to set alpha again
        updateConnectionState()
    }
    
    // MARK: - UI Setup
    func setupUI() {
        backgroundColor = .clear
        applyCommonCellStyling()
        
        contentView.addSubview(backView)
        backView.addSubview(titleLabel)
        backView.addSubview(hueSlider)
        backView.addSubview(minLabel)
        backView.addSubview(maxLabel)
        
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = Constants.textColorDarkGray
        titleLabel.alpha = 0.5
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        
        minLabel.font = UIFont.systemFont(ofSize: 14)
        minLabel.textColor = Constants.textColorGrayBlue
        minLabel.textAlignment = .left
        minLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        minLabel.setContentHuggingPriority(.required, for: .vertical)
        maxLabel.font = UIFont.systemFont(ofSize: 14)
        maxLabel.textColor = Constants.textColorGrayBlue
        maxLabel.textAlignment = .right
        maxLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        maxLabel.setContentHuggingPriority(.required, for: .vertical)
        
        // Stored for dynamic spacing adjustments (e.g. Matter vs Rainmaker).
        backViewTopSpaceConstraint = backView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0)
        backViewBottomSpaceConstraint = backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        
        guard let topConstraint = backViewTopSpaceConstraint,
              let bottomConstraint = backViewBottomSpaceConstraint else { return }
        
        NSLayoutConstraint.activate([
            topConstraint,
            backView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            backView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            bottomConstraint,
            
            titleLabel.topAnchor.constraint(equalTo: backView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            
            hueSlider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            hueSlider.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            hueSlider.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            hueSlider.heightAnchor.constraint(equalToConstant: 30),
            
            minLabel.topAnchor.constraint(equalTo: hueSlider.bottomAnchor, constant: 12),
            minLabel.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            minLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -12),
            
            maxLabel.centerYAnchor.constraint(equalTo: minLabel.centerYAnchor),
            maxLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16)
        ])
        
        hueSlider.addTarget(self, action: #selector(hueSliderValueChanged(_:)), for: .valueChanged)
        hueSlider.addTarget(self, action: #selector(hueSliderValueDragged(_:)), for: [.touchDragInside, .touchDragOutside])
        // CRITICAL: Matter updates only happen on touch up (not during drag)
        hueSlider.addTarget(self, action: #selector(hueSliderTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
    }
    
    // MARK: - UI Updates
    func updateUI() {
        guard let param = param else { return }
        
        let paramName = param.name ?? ""
        titleLabel.text = paramName.isEmpty ? "Hue" : paramName
        titleLabel.isHidden = false
        titleLabel.alpha = 1.0
        
        // Setup hue slider bounds from param
        var minValue = 0
        var maxValue = 360
        
        if let bounds = param.bounds {
            minValue = bounds["min"] as? Int ?? 0
            maxValue = bounds["max"] as? Int ?? 360
            
            if let step = bounds["step"] as? Float {
                sliderStepValue = step
            }
        }
        
        hueSlider.minimumValue = CGFloat(minValue)
        hueSlider.maximumValue = CGFloat(maxValue)
        
        let resolvedMin = "\(minValue)"
        let resolvedMax = "\(maxValue)"
        minLabel.text = resolvedMin.isEmpty ? "0" : resolvedMin
        maxLabel.text = resolvedMax.isEmpty ? "360" : resolvedMax
        minLabel.isHidden = false
        maxLabel.isHidden = false
        minLabel.alpha = 1.0
        maxLabel.alpha = 1.0
        // Ensure labels stay visible even if reused
        minLabel.textColor = UIColor(hexString: "#AFAFB4")
        maxLabel.textColor = UIColor(hexString: "#AFAFB4")
        
        // Bring header/labels to front to avoid overlap
        backView.bringSubviewToFront(titleLabel)
        backView.bringSubviewToFront(minLabel)
        backView.bringSubviewToFront(maxLabel)
        
        // Setup gradient colors
        if minValue == 0 && maxValue == 360 {
            hueSlider.hasRainbow = true
            hueSlider.setGradientVaryingHue(saturation: 1.0, brightness: 1.0)
        } else {
            hueSlider.hasRainbow = false
            hueSlider.minColor = UIColor(hue: CGFloat(minValue) / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            hueSlider.maxColor = UIColor(hue: CGFloat(maxValue) / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        }
        
        // Set initial value - CRITICAL: Only update slider from param.value if user is NOT dragging
        // This prevents notification updates from interfering with user interaction
        if let value = param.value as? Int {
            let hueValue = CGFloat(value)
            let oldSliderValue = hueSlider.value
            let willChange = abs(oldSliderValue - hueValue) > 0.01
            let shouldIgnore = shouldIgnoreNotificationUpdates()
            
            if shouldIgnore {
                // User is dragging or recently finished - don't update slider from param.value
                // Just update thumb to show current slider position
                let currentHue = hueSlider.value
                hueSlider.thumbColor = UIColor(hue: currentHue / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            } else {
                // User is not interacting - safe to update slider from param.value
                hueSlider.value = hueValue
                sliderInitialValue = Float(value)
                hueFinalValue = hueValue
                hueCurrentFinalValue = hueValue
                hueSlider.thumbColor = UIColor(hue: hueValue / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            }
        } else {
            // No value yet - just update thumb with current slider position
            let currentHue = hueSlider.value
            hueSlider.thumbColor = UIColor(hue: currentHue / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        }
        
        // CRITICAL: Update online/offline state AFTER all UI updates
        // This ensures alpha is set correctly and persists
        updateConnectionState()
        
        // CRITICAL: Update online/offline state AFTER all UI updates
        updateConnectionState()
    }
    
    // MARK: - Connection State Updates
    func updateConnectionState() {
        // Determine if this is a Matter device or Rainmaker device
        let isMatterDevice = (deviceId != nil) || (nodeGroup != nil)
        
        if isMatterDevice {
            // For Matter devices, check isDeviceOffline flag (no param property needed)
            hueSlider.isEnabled = !isDeviceOffline
            hueSlider.isUserInteractionEnabled = !isDeviceOffline
            isUserInteractionEnabled = !isDeviceOffline
            alpha = isDeviceOffline ? 0.5 : 1.0
            hueSlider.alpha = isDeviceOffline ? 0.5 : 1.0
            // Force update to ensure alpha is applied
            hueSlider.setNeedsLayout()
            hueSlider.layoutIfNeeded()
        } else {
            // For Rainmaker devices, check param properties and node connection
            guard let properties = param?.properties, properties.contains("write") else {
                // No write permission - disable slider
                hueSlider.isEnabled = false
                hueSlider.isUserInteractionEnabled = false
                isUserInteractionEnabled = false
                alpha = 0.5
                hueSlider.alpha = 0.5
                return
            }
            
            if let device = device, let node = device.node {
                let isConnected = node.isConnected == true
                let isLocalNetwork = node.localNetwork == true
                let isOnline = isConnected || isLocalNetwork
                let hasWritePermission = properties.contains("write")
                
                hueSlider.isEnabled = isOnline && hasWritePermission
                hueSlider.isUserInteractionEnabled = isOnline && hasWritePermission
                isUserInteractionEnabled = isOnline && hasWritePermission
                // CRITICAL: Set alpha to 0.5 when offline to match other cells
                // GradientSlider uses CALayers, so we need to set both view alpha and ensure it persists
                let targetAlpha: CGFloat = (isOnline && hasWritePermission) ? 1.0 : 0.5
                alpha = targetAlpha
                hueSlider.alpha = targetAlpha
                // Force update to ensure alpha is applied
                hueSlider.setNeedsLayout()
                hueSlider.layoutIfNeeded()
            } else {
                hueSlider.isEnabled = false
                hueSlider.isUserInteractionEnabled = false
                isUserInteractionEnabled = false
                alpha = 0.5
                hueSlider.alpha = 0.5
            }
        }
    }
    
    // MARK: - Helper Methods
    private func applyCommonCellStyling() {
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
    internal func shouldIgnoreNotificationUpdates() -> Bool {
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
}

