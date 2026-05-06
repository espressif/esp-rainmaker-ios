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
//  ParamSwitchCell+UI.swift
//  ESPRainMaker
//
//  UI Setup and Configuration

import UIKit

extension ParamSwitchCell {
    
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
        backView.addSubview(controlNameLabel)
        backView.addSubview(controlStateLabel)
        backView.addSubview(toggleSwitch)
        
        // Stored for dynamic spacing adjustments (e.g. Matter vs Rainmaker).
        backViewTopSpaceConstraint = backView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0)
        backViewBottomSpaceConstraint = backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        leadingSpaceConstraint = backView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15)
        trailingSpaceConstraint = backView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15)
        
        guard let topConstraint = backViewTopSpaceConstraint,
              let bottomConstraint = backViewBottomSpaceConstraint,
              let leadingConstraint = leadingSpaceConstraint,
              let trailingConstraint = trailingSpaceConstraint else { return }
        
        NSLayoutConstraint.activate([
            topConstraint,
            bottomConstraint,
            leadingConstraint,
            trailingConstraint,
            
            controlNameLabel.topAnchor.constraint(equalTo: backView.topAnchor, constant: 8),
            controlNameLabel.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            controlNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: toggleSwitch.leadingAnchor, constant: -16),
            
            controlStateLabel.topAnchor.constraint(equalTo: controlNameLabel.bottomAnchor, constant: 6),
            controlStateLabel.leadingAnchor.constraint(equalTo: controlNameLabel.leadingAnchor),
            controlStateLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -8),
            controlStateLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -8),
            
            toggleSwitch.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            toggleSwitch.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            toggleSwitch.leadingAnchor.constraint(greaterThanOrEqualTo: controlNameLabel.trailingAnchor, constant: 16)
        ])
        
        toggleSwitch.addTarget(self, action: #selector(switchStateChanged(_:)), for: .valueChanged)
    }
    
    // MARK: - UI Updates
    func updateUI() {
        guard let param = param else { return }
        
        // CRITICAL: Re-apply switch color every time (after reloadData() it may be reset)
        // Match XIB exactly: red="0.50980392156862742" green="0.396078431372549" blue="0.8901960784313725" = #8265E3
        toggleSwitch.onTintColor = UIColor(red: 0.50980392156862742, green: 0.396078431372549, blue: 0.8901960784313725, alpha: 1.0)
        
        controlNameLabel.text = getControlNameText(from: param)
        if attributeKey.isEmpty, let name = param.name {
            attributeKey = name
        }
        
        if let switchState = param.value as? Bool {
            toggleSwitch.setOn(switchState, animated: false)
            controlStateLabel.text = switchState ? "On" : "Off"
        }
        
        updateConnectionState()
    }
    
    // MARK: - Connection State Updates
    func updateConnectionState() {
        let isOnline = !isDeviceOffline && isDeviceOnlineForWrite()
        toggleSwitch.isEnabled = isOnline
        isUserInteractionEnabled = isOnline
        alpha = isOnline ? 1.0 : 0.5
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
    
    private func getControlNameText(from param: Param) -> String {
        guard let paramName = param.name, !paramName.isEmpty else { return "" }
        if let deviceName = device?.name {
            return paramName.deletingPrefix(deviceName)
        }
        return paramName
    }
    
    private func isDeviceOnlineForWrite() -> Bool {
        guard let properties = param?.properties, properties.contains("write"),
              let device = device, let node = device.node else { return false }
        return node.isConnected || node.localNetwork
    }
}

