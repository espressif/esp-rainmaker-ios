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
//  ParamTriggerCell+UI.swift
//  ESPRainMaker
//
//  UI Setup and Configuration

import UIKit

extension ParamTriggerCell {
    
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
        backView.addSubview(triggerButton)
        
        NSLayoutConstraint.activate([
            backView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            backView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            backView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            backView.heightAnchor.constraint(equalToConstant: 60),
            
            controlNameLabel.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            controlNameLabel.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            controlNameLabel.trailingAnchor.constraint(equalTo: triggerButton.leadingAnchor, constant: -16),
            
            triggerButton.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            triggerButton.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            triggerButton.leadingAnchor.constraint(equalTo: controlNameLabel.trailingAnchor, constant: 16),
            triggerButton.widthAnchor.constraint(equalToConstant: 36),
            triggerButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        triggerButton.addTarget(self, action: #selector(triggerPressed(_:)), for: .touchUpInside)
    }
    
    // MARK: - UI Updates
    func updateUI() {
        guard let param = param else { return }
        controlNameLabel.text = getControlNameText(from: param)
        updateConnectionState()
    }
    
    // MARK: - Connection State Updates
    func updateConnectionState() {
        let isOnline = isDeviceOnlineForWrite()
        triggerButton.isEnabled = isOnline
        triggerButton.alpha = isOnline ? 1.0 : 0.5
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
        guard let paramName = param.name else { return "" }
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

