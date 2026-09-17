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
//  ESPFederatedLoginService.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

protocol ESPFederatedLoginLogic {
    func login(provider: String, idToken: String)
}

/// Exchanges a native identity-provider ID token for RainMaker session tokens.
class ESPFederatedLoginService: ESPFederatedLoginLogic {
    
    var url: String
    var apiWorker: ESPAPIWorker
    var presenter: ESPIdProviderLoginPresenter?
    var loaderDelegate: LoaderDelegate?
    
    convenience init(presenter: ESPIdProviderLoginPresenter?) {
        self.init(url: ESPURLParams.shared.baseURL,
                  apiWorker: ESPAPIWorker(),
                  presenter: presenter)
    }
    
    private init(url: String,
                 apiWorker: ESPAPIWorker,
                 presenter: ESPIdProviderLoginPresenter?) {
        self.url = url
        self.apiWorker = apiWorker
        self.presenter = presenter
    }
    
    /// - Parameters:
    ///   - provider: Identity provider path segment expected by the backend.
    ///   - idToken: ID token issued by that provider.
    func login(provider: String, idToken: String) {
        loaderDelegate?.showLoader()
        apiWorker.callAPI(endPoint: .federatedLogin(url: url, provider: provider, idToken: idToken),
                          encoding: JSONEncoding.default) { data, error in
            self.loaderDelegate?.hideLoader()
            if error == nil, let data = data, let requestToken = RequestToken.from(data: data) {
                self.presenter?.loginSuccess(requestToken: requestToken)
                return
            }
            self.presenter?.loginFailed()
        }
    }
}
