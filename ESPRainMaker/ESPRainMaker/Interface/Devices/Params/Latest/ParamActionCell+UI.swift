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
//  ParamActionCell+UI.swift
//  ESPRainMaker
//
//  UI Setup and Configuration

import UIKit

extension ParamActionCell {
    
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
        backView.addSubview(controlValueLabel)
        // Button is a child of `backView`, but its constraints are relative to `contentView`.
        backView.addSubview(invokeActionButton)
        
        NSLayoutConstraint.activate([
            backView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            backView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            backView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            backView.heightAnchor.constraint(equalToConstant: 60),
            
            controlValueLabel.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            controlValueLabel.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            controlValueLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            
            invokeActionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            invokeActionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -23),
            invokeActionButton.widthAnchor.constraint(equalToConstant: 80)
        ])
        
        invokeActionButton.addTarget(self, action: #selector(invokeAction(_:)), for: .touchUpInside)
    }
    
    // MARK: - UI Updates
    func updateUI() {
        guard let param = param else { return }
        
        let labelText = param.name ?? paramName
        controlValueLabel.text = labelText.isEmpty ? "Scanner" : labelText
        
        if paramName.isEmpty, let name = param.name {
            paramName = name
            attributeKey = name
        }
        
        // Re-apply colors to override `PrimaryButton.changeTheme()` (otherwise it turns purple).
        invokeActionButton.backgroundColor = .white
        invokeActionButton.setTitleColor(UIColor(hexString: "#8265E3"), for: .normal)
        
        updateConnectionState()
    }
    
    // MARK: - Connection State Updates
    func updateConnectionState() {
        let isOnline = isDeviceOnlineForWrite()
        setInteractionEnabled(isOnline)
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
              let device = device, device.node?.isConnected == true else { return false }
        return true
    }
    
    private func setInteractionEnabled(_ enabled: Bool) {
        invokeActionButton.isEnabled = enabled
        invokeActionButton.alpha = enabled ? 1.0 : 0.5
        isUserInteractionEnabled = enabled
        alpha = enabled ? 1.0 : 0.5
    }
}

