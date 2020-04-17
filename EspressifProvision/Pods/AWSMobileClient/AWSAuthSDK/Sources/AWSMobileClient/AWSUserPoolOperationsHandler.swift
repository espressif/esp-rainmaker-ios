//
// Copyright 2017-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//
//  AWSUserPoolOperationsHandler.swift
//  AWSMobileClient
//

import AWSCognitoIdentityProvider
import Foundation

protocol UserPoolAuthHelperlCallbacks {
    func getPasswordDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>)

    func didCompletePasswordStepWithError(_ error: Error?)

    func getNewPasswordDetails(_ newPasswordRequiredInput: AWSCognitoIdentityNewPasswordRequiredInput, newPasswordRequiredCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityNewPasswordRequiredDetails>)

    func didCompleteNewPasswordStepWithError(_ error: Error?)

    func getCustomAuthenticationDetails(_ customAuthentiationInput: AWSCognitoIdentityCustomAuthenticationInput, customAuthCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityCustomChallengeDetails>)

    func didCompleteCustomAuthenticationStepWithError(_ error: Error?)

    func getCode(_ authenticationInput: AWSCognitoIdentityMultifactorAuthenticationInput, mfaCodeCompletionSource: AWSTaskCompletionSource<NSString>)

    func didCompleteMultifactorAuthenticationStepWithError(_ error: Error?)
}

internal class UserPoolOperationsHandler: NSObject,
    AWSCognitoIdentityInteractiveAuthenticationDelegate,
    AWSCognitoUserPoolInternalDelegate {
    internal var userpoolClient: AWSCognitoIdentityUserPool?
    internal var signUpUser: AWSCognitoIdentityUser?

    internal var currentActiveUser: AWSCognitoIdentityUser? {
        return userpoolClient?.currentUser()
    }

    internal var passwordAuthTaskCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>?
    internal var newPasswordRequiredTaskCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityNewPasswordRequiredDetails>?
    internal var customAuthChallengeTaskCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityCustomChallengeDetails>?

    internal var mfaAuthenticationInput: AWSCognitoIdentityMultifactorAuthenticationInput?
    internal var mfaCodeCompletionSource: AWSTaskCompletionSource<NSString>?

    internal var currentSignInHandlerCallback: ((SignInResult?, Error?) -> Void)?
    internal var currentConfirmSignInHandlerCallback: ((SignInResult?, Error?) -> Void)?

    var authHelperDelegate: UserPoolAuthHelperlCallbacks?
    var customAuthHandler: AWSUserPoolCustomAuthHandler?
    internal static let sharedInstance: UserPoolOperationsHandler = UserPoolOperationsHandler()

    public override init() {
        super.init()
        if AWSInfo.default().defaultServiceInfo("CognitoUserPool") != nil {
            userpoolClient = AWSCognitoIdentityUserPool.default()
            userpoolClient?.delegate = self
        }
    }

    internal func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        return self
    }

    internal func startNewPasswordRequired() -> AWSCognitoIdentityNewPasswordRequired {
        return self
    }

    internal func startMultiFactorAuthentication() -> AWSCognitoIdentityMultiFactorAuthentication {
        return self
    }

    internal func setAuthHelperDelegate(authHelperDelegate: UserPoolAuthHelperlCallbacks) {
        self.authHelperDelegate = authHelperDelegate
    }

    internal func startCustomAuthentication_v2() -> AWSCognitoIdentityCustomAuthentication {
        if customAuthHandler == nil {
            customAuthHandler = AWSUserPoolCustomAuthHandler()
            customAuthHandler?.authHelperDelegate = authHelperDelegate
        }
        return customAuthHandler!
    }
}

extension UserPoolOperationsHandler: AWSCognitoIdentityPasswordAuthentication {
    public func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        authHelperDelegate?.getPasswordDetails(authenticationInput, passwordAuthenticationCompletionSource: passwordAuthenticationCompletionSource)
    }

    public func didCompleteStepWithError(_ error: Error?) {
        authHelperDelegate?.didCompletePasswordStepWithError(error)
    }
}

extension UserPoolOperationsHandler: AWSCognitoIdentityNewPasswordRequired {
    public func getNewPasswordDetails(_ newPasswordRequiredInput: AWSCognitoIdentityNewPasswordRequiredInput, newPasswordRequiredCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityNewPasswordRequiredDetails>) {
        newPasswordRequiredTaskCompletionSource = newPasswordRequiredCompletionSource
        authHelperDelegate?.getNewPasswordDetails(newPasswordRequiredInput, newPasswordRequiredCompletionSource: newPasswordRequiredCompletionSource)
    }

    public func didCompleteNewPasswordStepWithError(_ error: Error?) {
        authHelperDelegate?.didCompleteNewPasswordStepWithError(error)
    }
}

extension UserPoolOperationsHandler: AWSCognitoIdentityMultiFactorAuthentication {
    public func getCode(_ authenticationInput: AWSCognitoIdentityMultifactorAuthenticationInput, mfaCodeCompletionSource: AWSTaskCompletionSource<NSString>) {
        mfaAuthenticationInput = authenticationInput
        authHelperDelegate?.getCode(authenticationInput, mfaCodeCompletionSource: mfaCodeCompletionSource)
    }

    public func didCompleteMultifactorAuthenticationStepWithError(_ error: Error?) {
        authHelperDelegate?.didCompleteMultifactorAuthenticationStepWithError(error)
    }
}
