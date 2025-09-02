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
//  ESPAssumeRoleCredentialsProvider.swift
//  ESPRainMaker
//

import Foundation
import AWSCore

/// Custom AWS credentials provider that only uses cached credentials from UserDefaults.
/// If no valid cached credentials are available, it returns an error.
final class ESPAssumeRoleCredentialsProvider: NSObject, AWSCredentialsProvider {

    static let shared = ESPAssumeRoleCredentialsProvider()

    private override init() {
        super.init()
    }

    /// Return cached AWS credentials if valid, otherwise return an error
    func credentials() -> AWSTask<AWSCredentials> {
        // Check for cached credentials in UserDefaults
        guard let credentialsDict = UserDefaults.standard.dictionary(forKey: "ESPAWSCredentials") as? [String: String],
              let accessKey = credentialsDict["access_key"],
              let secretKey = credentialsDict["secret_key"],
              let sessionToken = credentialsDict["session_token"],
              let expirationString = credentialsDict["expiration"] else {
            
            return AWSTask(error: NSError(
                domain: "ESPAWSCredentialsProvider",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No cached credentials available"]
            ))
        }
        
        // Parse expiration date from string
        let dateFormatter = ISO8601DateFormatter()
        let expirationDate = dateFormatter.date(from: expirationString) ?? Date().addingTimeInterval(3600)
        
        // Create AWSCredentials object from cached data
        let awsCredentials = AWSCredentials(
            accessKey: accessKey,
            secretKey: secretKey,
            sessionKey: sessionToken,
            expiration: expirationDate
        )
        
        return AWSTask(result: awsCredentials)
    }

    /// Invalidate any cached credentials
    func invalidateCachedTemporaryCredentials() {
        UserDefaults.standard.removeObject(forKey: "ESPAWSCredentials")
    }
}
