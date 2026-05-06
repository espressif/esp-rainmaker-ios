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
//  ParamRoundHueSliderCell+UI.swift
//  ESPRainMaker
//
//  UI Setup and Configuration

import FlexColorPicker
import UIKit

extension ParamRoundHueSliderCell {
    
    // MARK: - Helper Methods
    private func updateSelectedColorCornerRadius() {
        // CRITICAL: Ensure selectedColor is laid out before setting corner radius
        selectedColor.setNeedsLayout()
        selectedColor.layoutIfNeeded()
        
        // CRITICAL: Make selectedColor perfectly circular
        // cornerRadius must be exactly half the width (or height, they should be equal)
        let width = selectedColor.bounds.width
        let height = selectedColor.bounds.height
        
        if width > 0 {
            // Set cornerRadius to exactly half the width to make it perfectly circular
            selectedColor.layer.cornerRadius = width / 2.0
        } else if height > 0 {
            // Fallback to height if width is 0
            selectedColor.layer.cornerRadius = height / 2.0
        }
        
        // CRITICAL: For shadow to work, we need:
        // 1. clipsToBounds = true on the view itself (for circular shape)
        // 2. layer.masksToBounds = false (for shadow to be visible outside bounds)
        selectedColor.clipsToBounds = true
        selectedColor.layer.masksToBounds = false // Shadow must be outside bounds
        
        // Ensure shadow is applied (re-apply shadow properties)
        selectedColor.layer.shadowColor = UIColor.black.cgColor
        selectedColor.layer.shadowOffset = CGSize(width: 0, height: 1)
        selectedColor.layer.shadowRadius = 2.0
        selectedColor.layer.shadowOpacity = 0.15
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        applyCommonCellStyling()
        
        // CRITICAL: Make selectedColor perfectly circular after layout
        updateSelectedColorCornerRadius()
        
        // CRITICAL: Re-apply connection state after layout to ensure alpha persists
        updateConnectionState()
    }
    
    // MARK: - UI Setup
    func setupUI() {
        backgroundColor = .clear
        applyCommonCellStyling()
        
        contentView.addSubview(backView)
        backView.addSubview(hueSlider)
        backView.addSubview(selectedColor)
        
        NSLayoutConstraint.activate([
            backView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            backView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            backView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            hueSlider.centerXAnchor.constraint(equalTo: backView.centerXAnchor),
            hueSlider.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            hueSlider.widthAnchor.constraint(equalToConstant: 250),
            hueSlider.heightAnchor.constraint(equalToConstant: 250),
            
            selectedColor.centerXAnchor.constraint(equalTo: backView.centerXAnchor),
            selectedColor.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            selectedColor.widthAnchor.constraint(equalTo: hueSlider.widthAnchor, multiplier: 1.0/4.0),
            selectedColor.heightAnchor.constraint(equalTo: hueSlider.heightAnchor, multiplier: 1.0/4.0)
        ])
        
        hueSlider.delegate = self
        
        hueSlider.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
    }
    
    // MARK: - UI Updates
    func updateUI() {
        guard let param = param else { return }
        
        // CRITICAL: Ensure selectedColor is circular - set corner radius here too
        // This ensures it's set on initial render, not just in layoutSubviews
        updateSelectedColorCornerRadius()
        
        // Set initial hue value from param - CRITICAL: Only update if user is NOT dragging
        // This prevents notification updates from interfering with user interaction
        if let value = param.value as? Int {
            let hueValue = CGFloat(value) / 360.0
            let currentColor = HSBColor(hue: hueValue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            let oldHueValue = hueSlider.selectedHSBColor.hue * 360.0
            let willChange = abs(oldHueValue - CGFloat(value)) > 0.01
            let shouldIgnore = shouldIgnoreNotificationUpdates()
            
            if shouldIgnore {
                // User is dragging or recently finished - don't update slider from param.value
                // Just keep current state
            } else {
                // User is not interacting - safe to update slider from param.value
                hueSlider.setInitialHSBColor(currentColor, isInteractive: true)
                // Update simple UIView background color to reflect slider thumb position
                selectedColor.backgroundColor = UIColor(hue: currentColor.hue, saturation: currentColor.saturation, brightness: currentColor.brightness, alpha: 1.0)
                hueInitialValue = CGFloat(value)
                finalValue = CGFloat(value)
                currentFinalValue = CGFloat(value)
            }
        }
        
        // Update online/offline state
        updateConnectionState()
    }
    
    // MARK: - Notification Update Handling
    internal func shouldIgnoreNotificationUpdates() -> Bool {
        // If user is actively dragging, ignore notifications
        if isUserDragging {
            return true
        }
        
        // CRITICAL: For Rainmaker devices with continuous updates enabled, we need cooldown
        // For Matter devices or when continuous updates are disabled, no cooldown needed
        // User only sets value once on touch up, so notifications should have the new value
        if isRainmaker && Configuration.shared.appConfiguration.supportContinuousUpdate {
            // If user recently finished dragging (within cooldown period), ignore notifications
            if let dragEndTime = dragEndTimestamp {
                let timeSinceDragEnd = Date().timeIntervalSince(dragEndTime)
                if timeSinceDragEnd < notificationUpdateCooldown {
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Connection State Updates
    func updateConnectionState() {
        guard let properties = param?.properties, properties.contains("write"),
              let device = device, let node = device.node else {
            // No write permission or no device/node - disable slider
            hueSlider.isEnabled = false
            hueSlider.isUserInteractionEnabled = false
            isUserInteractionEnabled = false
            alpha = 0.5
            hueSlider.alpha = 0.5
            return
        }
        
        // Check if device is actually online (connected OR on local network)
        let isConnected = node.isConnected == true
        let isLocalNetwork = node.localNetwork == true
        let isOnline = isConnected || isLocalNetwork
        
        hueSlider.isEnabled = isOnline
        hueSlider.isUserInteractionEnabled = isOnline
        isUserInteractionEnabled = isOnline
        // CRITICAL: Set alpha to 0.5 when offline to match other cells
        alpha = isOnline ? 1.0 : 0.5
        hueSlider.alpha = isOnline ? 1.0 : 0.5
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
    
    private func isDeviceOnlineForWrite() -> Bool {
        guard let properties = param?.properties, properties.contains("write"),
              let device = device, let node = device.node else { return false }
        return node.isConnected == true || node.localNetwork == true
    }
}

