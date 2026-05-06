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
//  ParamCustomActionCell+Configuration.swift
//  ESPRainMaker
//
//  Component: Workflow Configuration
//  Handles: Workflow setup, button state management, status display

import UIKit

extension ParamCustomActionCell {
    
    // MARK: - Workflow Configuration
    func setupWorkflow(workflow: CustomAction) {
        // CRITICAL: Must be synchronous, not async!
        // If async, prepareForReuse() can clear labels before this executes
        self.workflow = workflow
        switch workflow {
        case .launchRainmakerController:
            self.headerLabel.text = "Controller"
            self.descriptionLabel.text = "Update Params"
            self.launchButton.setTitle("Update", for: .normal)
        case .launchController:
            self.headerLabel.text = "Controller"
            self.descriptionLabel.text = "Update Device List"
            self.launchButton.setTitle("Update", for: .normal)
        case .updateThreadDataset:
            self.headerLabel.text = "Border Router"
            self.descriptionLabel.text = "Update Thread Dataset"
            self.launchButton.setTitle("Update", for: .normal)
        case .setActiveThreadDataset:
            self.headerLabel.text = "Border Router"
            self.descriptionLabel.text = "Update Thread Dataset"
            self.launchButton.setTitle("Update", for: .normal)
        case .mergeThreadDataset:
            self.headerLabel.text = "Border Router"
            self.descriptionLabel.text = "Merge With Homepod"
            self.launchButton.setTitle("Merge", for: .normal)
        case .launchKinesisVideo:
            self.headerLabel.text = "WebRTC"
            self.descriptionLabel.text = "Video Streaming"
            self.launchButton.setTitle("Start", for: .normal)
        }
        
        // CRITICAL: Re-apply colors to override PrimaryButton.changeTheme() which is setting purple background
        // Match ParamActionCell: white background with purple text
        launchButton.backgroundColor = .white
        launchButton.setTitleColor(UIColor(hexString: "#8265E3"), for: .normal)
    }
    
    // MARK: - Button State Management
    /// Set launch button connected status
    /// - Parameter isDeviceOffline: is device online or offline
    func setLaunchButtonConnectedStatus(isDeviceOffline: Bool) {
        launchButton.isEnabled = !isDeviceOffline
        // CRITICAL: Match ParamActionCell behavior - set alpha for offline state
        // Also re-apply colors to ensure they persist (white background, purple text)
        launchButton.backgroundColor = .white
        launchButton.setTitleColor(UIColor(hexString: "#8265E3"), for: .normal)
        launchButton.alpha = isDeviceOffline ? 0.5 : 1.0 // Match ParamActionCell: 0.5 alpha when offline
    }
    
    func setControllerUnauthorizedStatus() {
        // CRITICAL: Must be synchronous, not async!
        let normalText = "Controller "
        let italicText = "(Unauthorized)"
                        
        let baseFont = self.headerLabel.font!
        let italicFont = UIFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.traitItalic) ?? baseFont.fontDescriptor, size: baseFont.pointSize)
                        
        let attributedString = NSMutableAttributedString(string: normalText, attributes: [
            NSAttributedString.Key.font: baseFont
        ])
        let italicAttributedString = NSAttributedString(string: italicText, attributes: [
            NSAttributedString.Key.font: italicFont
        ])
        attributedString.append(italicAttributedString)
        self.headerLabel.attributedText = attributedString
    }
}

