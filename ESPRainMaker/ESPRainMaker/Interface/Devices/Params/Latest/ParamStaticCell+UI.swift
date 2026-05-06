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
//  ParamStaticCell+UI.swift
//  ESPRainMaker
//
//  UI Setup and Configuration

import UIKit

extension ParamStaticCell {
    
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
        
        NSLayoutConstraint.activate([
            backView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            backView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            backView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            backView.heightAnchor.constraint(equalToConstant: 60),
            backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            controlNameLabel.topAnchor.constraint(equalTo: backView.topAnchor, constant: 8),
            controlNameLabel.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            controlNameLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            
            controlValueLabel.topAnchor.constraint(equalTo: controlNameLabel.bottomAnchor, constant: 6),
            controlValueLabel.leadingAnchor.constraint(equalTo: controlNameLabel.leadingAnchor),
            controlValueLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - UI Updates
    func updateUI() {
        guard let attribute = attribute else { return }
        controlNameLabel.text = attribute.name ?? ""
        controlValueLabel.text = attribute.value.map { "\($0)" } ?? ""
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

