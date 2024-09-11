// Copyright 2024 Espressif Systems
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
//  ESPServerTrustEvaluatorsWorker.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

class ESPServerTrustEvaluatorsWorker {
    
    static let shared = ESPServerTrustEvaluatorsWorker()
    
    /// Get evaluators for AWS certificate pinning
    ///  
    /// - Parameters:
    ///   - authURLDomain: auth URL domaon
    ///   - baseURLDomain: base URL domain
    ///   - claimURLDomain: claim URL domain
    ///   - certificates: List of certificates used for pinning
    /// - Returns: get server trust evaluators dictionary
    func getEvaluators(authURLDomain: String, 
                       baseURLDomain: String,
                       claimURLDomain: String,
                       certificates: [SecCertificate]) -> [String: PinnedCertificatesTrustEvaluator] {
        
        let pinnedCertificate = PinnedCertificatesTrustEvaluator(certificates: certificates)
        var evaluators: [String: PinnedCertificatesTrustEvaluator] = [String: PinnedCertificatesTrustEvaluator]()
        evaluators[authURLDomain] = pinnedCertificate
        var keys = evaluators.keys
        if !keys.contains(baseURLDomain) {
            evaluators[baseURLDomain] = pinnedCertificate
        }
        keys = evaluators.keys
        if !keys.contains(claimURLDomain) {
            evaluators[claimURLDomain] = pinnedCertificate
        }
        return evaluators
    }
}
