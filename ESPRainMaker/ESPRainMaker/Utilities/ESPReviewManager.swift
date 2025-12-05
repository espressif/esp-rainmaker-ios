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
//  ESPReviewManager.swift
//  ESPRainMaker
//

import Foundation
import StoreKit
import UIKit

class ESPReviewManager {
    
    static let shared = ESPReviewManager()
    
    private let userDefaults = UserDefaults.standard
    
    // Keys for tracking review triggers
    private let deviceCountKey = "ESPReviewManager_DeviceCount"
    private let scheduleCreatedKey = "ESPReviewManager_ScheduleCreated"
    private let sceneCreatedKey = "ESPReviewManager_SceneCreated"
    private let automationCreatedKey = "ESPReviewManager_AutomationCreated"
    private let reviewRequestedKey = "ESPReviewManager_ReviewRequested"
    
    private init() {}
    
    // MARK: - Review Trigger Methods
    
    /// Call this when a device is successfully provisioned
    func onDeviceProvisioned() {
        let currentCount = userDefaults.integer(forKey: deviceCountKey)
        let newCount = currentCount + 1
        userDefaults.set(newCount, forKey: deviceCountKey)
        
        // Request review on second device success
        if newCount == 2 {
            requestReviewIfAppropriate()
        }
    }
    
    /// Call this when a schedule is created
    func onScheduleCreated() {
        let hasCreatedSchedule = userDefaults.bool(forKey: scheduleCreatedKey)
        if !hasCreatedSchedule {
            userDefaults.set(true, forKey: scheduleCreatedKey)
            requestReviewIfAppropriate()
        }
    }
    
    /// Call this when a scene is created
    func onSceneCreated() {
        let hasCreatedScene = userDefaults.bool(forKey: sceneCreatedKey)
        if !hasCreatedScene {
            userDefaults.set(true, forKey: sceneCreatedKey)
            requestReviewIfAppropriate()
        }
    }
    
    /// Call this when an automation is created
    func onAutomationCreated() {
        let hasCreatedAutomation = userDefaults.bool(forKey: automationCreatedKey)
        if !hasCreatedAutomation {
            userDefaults.set(true, forKey: automationCreatedKey)
            requestReviewIfAppropriate()
        }
    }
    
    // MARK: - Private Methods
    
    private func requestReviewIfAppropriate() {
        // Check if we've already requested a review in this app session
        let hasRequestedReview = userDefaults.bool(forKey: reviewRequestedKey)
        if hasRequestedReview {
            return
        }
        
        // Check if we're running on iOS 10.3+ (required for StoreKit review)
        guard #available(iOS 10.3, *) else {
            return
        }
        
        // Request the review (prefer scene-based API on iOS 14+)
        DispatchQueue.main.async {
            if #available(iOS 14.0, *),
               let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview()
            }
            self.userDefaults.set(true, forKey: self.reviewRequestedKey)
        }
    }
    
    // MARK: - Debug/Reset Methods (for testing)
    
    /// Reset all review tracking data (useful for testing)
    func resetReviewTracking() {
        userDefaults.removeObject(forKey: deviceCountKey)
        userDefaults.removeObject(forKey: scheduleCreatedKey)
        userDefaults.removeObject(forKey: sceneCreatedKey)
        userDefaults.removeObject(forKey: automationCreatedKey)
        userDefaults.removeObject(forKey: reviewRequestedKey)
    }
    
    /// Get current review tracking status (useful for debugging)
    func getReviewStatus() -> [String: Any] {
        return [
            "deviceCount": userDefaults.integer(forKey: deviceCountKey),
            "scheduleCreated": userDefaults.bool(forKey: scheduleCreatedKey),
            "sceneCreated": userDefaults.bool(forKey: sceneCreatedKey),
            "automationCreated": userDefaults.bool(forKey: automationCreatedKey),
            "reviewRequested": userDefaults.bool(forKey: reviewRequestedKey)
        ]
    }
}

