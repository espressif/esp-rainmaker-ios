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
//  ESPAppleSignInService.swift
//  ESPRainMaker
//

import AuthenticationServices
import Foundation
import UIKit

enum ESPAppleSignInResult {
    case success(idToken: String)
    case cancelled
    /// Native Sign in with Apple cannot be presented; caller should use Hosted UI.
    case unavailable
    case failure
}

/// Presents the system Sign in with Apple sheet and returns Apple's identity token (JWT).
class ESPAppleSignInService: NSObject {
    
    static let shared = ESPAppleSignInService()
    
    private var pendingRequest: AppleAuthorizationRequest?
    
    /// Native Sign in with Apple needs backend federated support and the App ID capability; otherwise use Hosted UI.
    static var isConfigured: Bool {
        Configuration.shared.appConfiguration.enableNativeAppleSignIn
    }
    
    func signIn(presenting viewController: UIViewController,
                completion: @escaping (ESPAppleSignInResult) -> Void) {
        guard ESPAppleSignInService.isConfigured else {
            completion(.unavailable)
            return
        }
        
        DispatchQueue.main.async {
            guard let anchor = viewController.view.window ?? ESPAppleSignInService.keyWindow() else {
                completion(.unavailable)
                return
            }
            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.email]
            
            let handler = AppleAuthorizationRequest(anchor: anchor) { [weak self] result in
                self?.pendingRequest = nil
                completion(result)
            }
            self.pendingRequest = handler
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = handler
            controller.presentationContextProvider = handler
            controller.performRequests()
        }
    }
    
    private static func keyWindow() -> UIWindow? {
        let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        return scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first
    }
}

/// Retains ASAuthorizationController's weak delegate for one request.
private final class AppleAuthorizationRequest: NSObject,
                                               ASAuthorizationControllerDelegate,
                                               ASAuthorizationControllerPresentationContextProviding {
    
    private let anchor: UIWindow
    private var completion: ((ESPAppleSignInResult) -> Void)?
    
    init(anchor: UIWindow, completion: @escaping (ESPAppleSignInResult) -> Void) {
        self.anchor = anchor
        self.completion = completion
        super.init()
    }
    
    private func finish(_ result: ESPAppleSignInResult) {
        completion?(result)
        completion = nil
    }
    
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8),
              !identityToken.isEmpty else {
            finish(.failure)
            return
        }
        finish(.success(idToken: identityToken))
    }
    
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain,
           nsError.code == ASAuthorizationError.canceled.rawValue {
            finish(.cancelled)
            return
        }
        finish(.failure)
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return anchor
    }
}
