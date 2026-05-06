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
//  ParamGenericCell+UI.swift
//  ESPRainMaker
//
//  UI Setup and Configuration

import UIKit

extension ParamGenericCell {
    
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
        backView.addSubview(editButton)
        backView.addSubview(tapButton)
        
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
            backView.heightAnchor.constraint(equalToConstant: 60),
            
            controlNameLabel.topAnchor.constraint(equalTo: backView.topAnchor, constant: 8),
            controlNameLabel.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            
            controlValueLabel.topAnchor.constraint(equalTo: controlNameLabel.bottomAnchor, constant: 6),
            controlValueLabel.leadingAnchor.constraint(equalTo: controlNameLabel.leadingAnchor),
            
            editButton.widthAnchor.constraint(equalToConstant: 22),
            editButton.topAnchor.constraint(equalTo: backView.topAnchor, constant: 16),
            editButton.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            editButton.leadingAnchor.constraint(greaterThanOrEqualTo: controlValueLabel.trailingAnchor, constant: 10),
            editButton.leadingAnchor.constraint(greaterThanOrEqualTo: controlNameLabel.trailingAnchor, constant: 10),
            
            tapButton.topAnchor.constraint(equalTo: backView.topAnchor),
            tapButton.leadingAnchor.constraint(equalTo: backView.leadingAnchor),
            tapButton.trailingAnchor.constraint(equalTo: backView.trailingAnchor),
            tapButton.bottomAnchor.constraint(equalTo: backView.bottomAnchor),
            bottomConstraint
        ])
        
        tapButton.isHidden = true
        tapButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
        
        editButton.addTarget(self, action: #selector(editButtonTapped(_:)), for: .touchUpInside)
        tapButton.addTarget(self, action: #selector(paramTapped(_:)), for: .touchUpInside)
        
        editButton.isHidden = false
        editButton.isEnabled = true
    }
    
    // MARK: - UI Updates
    func updateUI() {
        guard let param = param else { return }
        
        let paramName = param.name ?? ""
        controlNameLabel.text = paramName
        if attributeKey.isEmpty {
            attributeKey = paramName
        }
        
        if let value = param.value {
            let valueString = "\(value)"
            controlValue = valueString
            controlValueLabel.text = valueString
        } else {
            controlValue = nil
            controlValueLabel.text = nil
        }
        
        if let paramDataType = param.dataType {
            dataType = paramDataType
        }
        
        updateTimeSeriesButton(for: param)
        updateConnectionState()
    }
    
    // MARK: - Connection State Updates
    func updateConnectionState() {
        let isOnline = isDeviceOnlineForEdit()
        editButton.isHidden = !isOnline
        editButton.isEnabled = isOnline
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
    
    private func updateTimeSeriesButton(for param: Param) {
        let timeSeriesProperty = "time_series"
        let simpleTimeSeriesProperty = "simple_ts"
        guard let properties = param.properties else {
            tapButton.isHidden = true
            return
        }
        
        let hasTimeSeries = properties.contains(timeSeriesProperty)
        let hasSimpleTimeSeries = properties.contains(simpleTimeSeriesProperty)
        
        if hasTimeSeries || hasSimpleTimeSeries {
            tapButton.isHidden = false
            isSimpleTimeSeries = hasSimpleTimeSeries && !hasTimeSeries
        } else {
            tapButton.isHidden = true
        }
    }
    
    private func isDeviceOnlineForEdit() -> Bool {
        let isMatterDevice = (deviceId != nil) || (nodeGroup != nil)
        
        if isMatterDevice {
            return !isDeviceOffline
        }
        
        guard let device = device, let node = device.node else {
            return true // Default to showing button if device/node info not available
        }
        
        return node.isConnected || node.localNetwork
    }
}

