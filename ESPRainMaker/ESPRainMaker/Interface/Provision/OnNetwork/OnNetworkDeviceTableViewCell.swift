// Copyright 2026 Espressif Systems (Shanghai) PTE LTD
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
//  OnNetworkDeviceTableViewCell.swift
//  ESPRainMaker
//

import UIKit

class OnNetworkDeviceTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "OnNetworkDeviceTableViewCell"
    
    // Container view for card styling
    private let containerView: UIView
    
    // Programmatic UI elements
    private let deviceNameLabel: UILabel
    private let deviceInfoLabel: UILabel
    private let popIndicatorLabel: UILabel
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        // Initialize UI elements programmatically
        containerView = UIView()
        deviceNameLabel = UILabel()
        deviceInfoLabel = UILabel()
        popIndicatorLabel = UILabel()
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        // Initialize UI elements programmatically
        containerView = UIView()
        deviceNameLabel = UILabel()
        deviceInfoLabel = UILabel()
        popIndicatorLabel = UILabel()
        
        super.init(coder: coder)
        
        setupUI()
        setupConstraints()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func setupUI() {
        // Cell properties - match ESPFabricCell
        selectionStyle = .none
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        // Configure container view - card style matching ESPFabricCell
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 10
        containerView.layer.shadowColor = UIColor.lightGray.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        containerView.layer.shadowRadius = 1.0
        containerView.layer.shadowOpacity = 1.0
        contentView.addSubview(containerView)
        
        // Configure device name label
        deviceNameLabel.translatesAutoresizingMaskIntoConstraints = false
        deviceNameLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        deviceNameLabel.textColor = .label
        deviceNameLabel.numberOfLines = 0
        deviceNameLabel.lineBreakMode = .byWordWrapping
        containerView.addSubview(deviceNameLabel)
        
        // Configure device info label
        deviceInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        deviceInfoLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        deviceInfoLabel.textColor = .secondaryLabel
        deviceInfoLabel.numberOfLines = 0
        deviceInfoLabel.lineBreakMode = .byWordWrapping
        containerView.addSubview(deviceInfoLabel)
        
        // Configure POP indicator label
        popIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        popIndicatorLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        popIndicatorLabel.textColor = .systemOrange
        popIndicatorLabel.isHidden = true
        containerView.addSubview(popIndicatorLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view constraints - 20pt margins from contentView, 10pt top/bottom
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            // Device name label - 20pt padding from container, top aligned
            deviceNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            deviceNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            deviceNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: popIndicatorLabel.leadingAnchor, constant: -8),
            
            // Device info label - below name label, 20pt padding from container
            deviceInfoLabel.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 4),
            deviceInfoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            deviceInfoLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            deviceInfoLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            // POP indicator - top right corner
            popIndicatorLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            popIndicatorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
    }
    
    func configure(with device: ESPOnNetworkDevice) {
        deviceNameLabel.text = device.serviceName
        // Node ID with POP required indicator next to it (like Android)
        var info = device.nodeId
        if device.popRequired {
            info += " • POP Required"
        }
        deviceInfoLabel.text = info
        popIndicatorLabel.isHidden = true
    }
}
