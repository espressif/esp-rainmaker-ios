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
//  ParamDropDownCell+UI.swift
//  ESPRainMaker
//
//  UI Setup and Configuration

import UIKit
import DropDown

extension ParamDropDownCell {
    
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
        backView.addSubview(controlValueLabel)
        backView.addSubview(dropDownButton)
        
        NSLayoutConstraint.activate([
            backView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            backView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            backView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            backView.heightAnchor.constraint(equalToConstant: 60),
            backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            
            controlNameLabel.topAnchor.constraint(equalTo: backView.topAnchor, constant: 8),
            controlNameLabel.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            controlNameLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -40),
            
            controlValueLabel.topAnchor.constraint(equalTo: controlNameLabel.bottomAnchor, constant: 6),
            controlValueLabel.leadingAnchor.constraint(equalTo: controlNameLabel.leadingAnchor),
            controlValueLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -40),
            
            dropDownButton.topAnchor.constraint(equalTo: backView.topAnchor),
            dropDownButton.leadingAnchor.constraint(equalTo: backView.leadingAnchor),
            dropDownButton.trailingAnchor.constraint(equalTo: backView.trailingAnchor),
            dropDownButton.bottomAnchor.constraint(equalTo: backView.bottomAnchor)
        ])
        
        dropDownButton.addTarget(self, action: #selector(dropDownButtonPressed(_:)), for: .touchUpInside)
    }
    
    // MARK: - UI Updates
    func updateUI() {
        guard let param = param else { return }
        
        controlNameLabel.text = getControlNameText(from: param)
        
        if let value = param.value {
            if let stringValue = value as? String {
                currentValue = stringValue
                controlValueLabel.text = stringValue
            } else if let intValue = value as? Int {
                currentValue = "\(intValue)"
                controlValueLabel.text = "\(intValue)"
            }
        }
        
        updateConnectionState()
    }
    
    // MARK: - Connection State Updates
    func updateConnectionState() {
        let isOnline = isDeviceOnlineForWrite()
        dropDownButton.isEnabled = isOnline
        dropDownButton.alpha = isOnline ? 1.0 : 0.5
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
        if isRainmaker {
            guard let properties = param?.properties, properties.contains("write"),
                  let device = device, let node = device.node else { return false }
            return node.isConnected || node.localNetwork
        } else {
            return !isDeviceOffline
        }
    }
}

