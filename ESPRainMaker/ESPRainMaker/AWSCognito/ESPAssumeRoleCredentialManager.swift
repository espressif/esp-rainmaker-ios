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
//  ESPAssumeRoleCredentialManager.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

/// Response model for AWS credentials from assume role
struct ESPAssumeRoleCredentialsResponse: Codable {
    let accessKey: String
    let secretKey: String
    let sessionToken: String
    let expiration: String
    
    enum CodingKeys: String, CodingKey {
        case accessKey = "access_key"
        case secretKey = "secret_key"
        case sessionToken = "session_token"
        case expiration
    }
}

/// Manager class to handle AWS credentials storage and retrieval
class ESPAssumeRoleCredentialManager {
    
    static let shared = ESPAssumeRoleCredentialManager()
    private let apiManager = ESPAPIManager()
    
    private init() {}
    
    /// Get AWS credentials from UserDefaults or fetch new ones
    /// - Parameters:
    ///   - nodeId: The node ID to get credentials for
    ///   - completion: Completion handler with credentials or error
    func getAssumeRoleCredentials(nodeId: String = "7mDtoTbddw8Kgj6CXrbLHd", completion: @escaping (ESPAssumeRoleCredentialsResponse?, Error?) -> Void) {
        // Check if we have valid cached credentials
        if let cachedCredentials = getCachedCredentials() {
            completion(cachedCredentials, nil)
            return
        }
        
        // If no valid cached credentials, get new ones from API
        self.apiManager.getAssumeRoleCredentials(nodeId: nodeId) { credentials, error in
            if let error = error {
                completion(nil, error)
                return
            }
            completion(credentials, nil)
        }
    }
    
    /// Get cached credentials from UserDefaults if they exist and haven't expired
    private func getCachedCredentials() -> ESPAssumeRoleCredentialsResponse? {
        guard let credentialsDict = UserDefaults.standard.dictionary(forKey: "ESPAWSCredentials") as? [String: String],
              let accessKey = credentialsDict["access_key"],
              let secretKey = credentialsDict["secret_key"],
              let sessionToken = credentialsDict["session_token"],
              let expirationString = credentialsDict["expiration"] else {
            return nil
        }
        
        // Check if credentials have expired
        let dateFormatter = ISO8601DateFormatter()
        guard let expirationDate = dateFormatter.date(from: expirationString),
              expirationDate > Date() else {
            // Credentials have expired, remove them
            UserDefaults.standard.removeObject(forKey: "ESPAWSCredentials")
            return nil
        }
        
        return ESPAssumeRoleCredentialsResponse(accessKey: accessKey,
                                       secretKey: secretKey,
                                       sessionToken: sessionToken,
                                       expiration: expirationString)
    }
}
