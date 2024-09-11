// Copyright 2023 Espressif Systems
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
//  ESPOTAAPIWorker.swift
//  ESPRainMaker
//

import Foundation
import Alamofire

class ESPOTAAPIWorker {
    
    var session: Session!
    
    init() {
        if let fileName = ESPServerTrustParams.shared.fileName {
            let certificate = ESPOTAAPIWorker.certificate(filename: fileName)
            let serverTrustEvaluators = ESPServerTrustEvaluatorsWorker.shared.getEvaluators(
                authURLDomain: ESPServerTrustParams.shared.authURLDomain,
                baseURLDomain: ESPServerTrustParams.shared.baseURLDomain,
                claimURLDomain: ESPServerTrustParams.shared.claimURLDomain,
                certificates: [certificate])
            let trustManager: ServerTrustManager = ServerTrustManager(evaluators: serverTrustEvaluators)
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 10
            session = Session(configuration: configuration, serverTrustManager: trustManager)
            session.sessionConfiguration.timeoutIntervalForRequest = 10
            session.sessionConfiguration.timeoutIntervalForResource = 10
        }
    }
    
    public func callAPI(endPoint: ESPOTAAPIEndpoint,
                 encoding: ParameterEncoding = URLEncoding.default,
                 completionHandler: @escaping (Data?, Error?) -> Void) {
        
        #if DEBUG
        debugLog(endPoint: endPoint)
        #endif
        
        callAPI(url: endPoint.url,
                method: endPoint.method,
                parameters: endPoint.parameters,
                encoding: encoding,
                headers: endPoint.headers,
                completionHandler: completionHandler)
    }
    
    /// Method to get security certificate from bundle resource
    /// - Parameters:
    ///   - filename: name of the certificate file
    private static func certificate(filename: String) -> SecCertificate {
        let filePath = Bundle.main.path(forResource: filename, ofType: "der")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        let certificate = SecCertificateCreateWithData(nil, data as CFData)!

        return certificate
    }
    
    /// Method to make API call
    /// - Parameters:
    ///   - url: url endpoint
    ///   - method: HTTP method
    ///   - parameters: request body
    ///   - encoding: data encoding
    ///   - headers: HTTP headers
    ///   - completionHandler: callback on getting response
    private func callAPI(url: URLConvertible,
                 method: HTTPMethod,
                 parameters: Parameters? = nil,
                 encoding: ParameterEncoding = URLEncoding.default,
                 headers: HTTPHeaders? = nil,
                 completionHandler: @escaping (Data?, Error?) -> Void) {
        
        session.request(url,
                        method: method,
                        parameters: parameters,
                        encoding: encoding,
                        headers: headers)
            .response { response in
                switch response.result {
                case .success(let data):
                    completionHandler(data, nil)
                case .failure(let error):
                    completionHandler(nil, error)
                }
            }
    }
    
    /// Method is to print data in string format
    /// - Parameters:
    ///   - api: api name
    ///   - data: response data for API
    func logData(api: String, data: Data?) {
        if let data = data {
            print("API: \(api)\nParsed Data: \(String(data: data, encoding: .utf8 )!)")
        }
    }
    
    /// Log API details
    /// - Parameter endPoint: endpoint to be logged
    private func debugLog(endPoint: ESPAPIEndPoint) {
        print("\n************************||************************")
        print("ENDPOINT: \(endPoint.description)")
        print("URL: \(endPoint.url)")
        print("METHOD: \(endPoint.method)")
        if let params = endPoint.parameters {
            print("PARAMS: \(params.description)")
        }
        print("HEADERS: \(endPoint.headers.description)")
        print("************************||************************\n")
    }
}
