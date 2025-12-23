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
//  ParamCentralSwitchCell+UI.swift
//  ESPRainMaker
//
//  UI Setup and Configuration

import UIKit

extension ParamCentralSwitchCell {
    
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
        backView.addSubview(powerButton)
        
        NSLayoutConstraint.activate([
            backView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            backView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            backView.widthAnchor.constraint(equalToConstant: 280),
            backView.heightAnchor.constraint(equalToConstant: 280),
            
            powerButton.centerXAnchor.constraint(equalTo: backView.centerXAnchor),
            powerButton.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            powerButton.widthAnchor.constraint(equalToConstant: 250),
            powerButton.heightAnchor.constraint(equalToConstant: 250)
        ])
        
        powerButton.addTarget(self, action: #selector(powerButtonPressed(_:)), for: .touchUpInside)
    }
    
    // MARK: - UI Updates
    func updateUI() {
        guard let param = param, let switchState = param.value as? Bool else { return }
        let imageName = switchState ? "central_switch_on" : "central_switch_off"
        powerButton.setBackgroundImage(UIImage(named: imageName), for: .normal)
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
}

