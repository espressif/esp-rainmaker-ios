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
//  ParamCustomActionCell+UI.swift
//  ESPRainMaker
//
//  UI Setup and Configuration

import UIKit

extension ParamCustomActionCell {
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        applyCommonCellStyling()
    }
    
    // MARK: - UI Setup
    func setupUI() {
        backgroundColor = .clear
        applyCommonCellStyling()
        
        contentView.addSubview(container)
        container.addSubview(headerLabel)
        container.addSubview(descriptionLabel)
        container.addSubview(launchButton)
        
        // Stored for dynamic spacing adjustments (e.g. Matter vs Rainmaker).
        topSpaceConstraint = container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0)
        bottomSpaceConstraint = container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        
        NSLayoutConstraint.activate([
            topSpaceConstraint,
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            bottomSpaceConstraint,
            
            headerLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            headerLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
            
            descriptionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 6),
            descriptionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            descriptionLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            
            launchButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            launchButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            launchButton.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.5)
        ])
        
        launchButton.addTarget(self, action: #selector(performCustomAction(_:)), for: .touchUpInside)
    }
    
    // MARK: - Helper Methods
    private func applyCommonCellStyling() {
        backgroundColor = .clear
        container.layer.borderWidth = 1
        container.layer.cornerRadius = 10
        container.layer.borderColor = UIColor.clear.cgColor
        container.layer.masksToBounds = true
        layer.shadowOpacity = 0.18
        layer.shadowOffset = CGSize(width: 1, height: 2)
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.black.cgColor
        layer.masksToBounds = false
    }
}

