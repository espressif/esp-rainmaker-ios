// Copyright 2026 Espressif Systems
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
//  ESPGoogleSignInService.swift
//  ESPRainMaker
//

import Foundation
import GoogleSignIn
import UIKit

enum ESPGoogleSignInResult {
    case success(idToken: String)
    case cancelled
    /// Native Google Sign-In is not configured or cannot run; caller should use Hosted UI.
    case unavailable
    case failure
}

/// Presents Google's in-app account picker and returns the Google ID token.
class ESPGoogleSignInService {
    
    static let shared = ESPGoogleSignInService()
    
    /// Native Sign-In needs the iOS client ID (GID client / URL scheme) and the web client ID
    /// (token audience for federated login).
    static var isConfigured: Bool {
        if let config = Configuration.shared.awsConfiguration {
            return !config.googleWebClientId.isEmpty && !config.googleIOSClientId.isEmpty
        }
        return false
    }
    
    /// Clears Google Sign-In state so the next login shows the account picker again.
    static func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
    
    func signIn(presenting viewController: UIViewController,
                completion: @escaping (ESPGoogleSignInResult) -> Void) {
        guard ESPGoogleSignInService.isConfigured else {
            completion(.unavailable)
            return
        }
        
        let webClientId = Configuration.shared.awsConfiguration.googleWebClientId
        let iosClientId = Configuration.shared.awsConfiguration.googleIOSClientId
        let clientId = iosClientId.isEmpty ? webClientId : iosClientId
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId,
                                                                  serverClientID: webClientId)
        
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
            if let error = error as NSError? {
                switch error.code {
                case -5: // kGIDSignInErrorCodeCanceled
                    completion(.cancelled)
                case -1, -2: // kGIDSignInErrorCodeUnknown, kGIDSignInErrorCodeKeychain
                    // Native picker cannot run; fall back to Hosted UI like Android.
                    completion(.unavailable)
                default:
                    completion(.failure)
                }
                return
            }
            guard let idToken = result?.user.idToken?.tokenString, !idToken.isEmpty else {
                completion(.failure)
                return
            }
            completion(.success(idToken: idToken))
        }
    }
}
