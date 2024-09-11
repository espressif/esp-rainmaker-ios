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
//  ESPControllerAPIManager.swift
//  ESPRainmaker
//

import Foundation
import Alamofire

#if ESPRainMakerMatter

@available(iOS 16.4, *)
class ESPControllerAPIManager {
    
    var session: Session!
    static let shared = ESPControllerAPIManager()
    
    private init() {
        let certificate = ESPAPIManager.certificate(filename: "amazonRootCA")
        let serverTrustEvaluators = ESPServerTrustEvaluatorsWorker.shared.getEvaluators(
            authURLDomain: Configuration.shared.awsConfiguration.baseURL.getDomain(),
            baseURLDomain: Configuration.shared.awsConfiguration.authURL.getDomain(),
            claimURLDomain: Configuration.shared.awsConfiguration.claimURL.getDomain(),
            certificates: [certificate])
        let trustManager: ServerTrustManager = ServerTrustManager(evaluators: serverTrustEvaluators)
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        self.session = Session(configuration: configuration, serverTrustManager: trustManager)
        self.session.sessionConfiguration.timeoutIntervalForRequest = 10
        self.session.sessionConfiguration.timeoutIntervalForResource = 10
    }
    
    /// Call off API
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    ///   - endpoint: endpoint
    ///   - completion: completion
    func callOffAPI(rainmakerNode: Node, controllerNodeId: String, matterNodeId: String, endpoint: String, completion: @escaping (Bool) -> Void) {
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, serverError in
            if let token = accessToken {
                let url = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/params?node_id=\(controllerNodeId)"
                let commands = [[ESPControllerAPIKeys.commandId: ESPControllerAPIKeys.offCommandId]]
                let clusters = [[ESPControllerAPIKeys.clusterId: ESPControllerAPIKeys.onOffClusterId,
                                 ESPControllerAPIKeys.commands: commands]]
                let endpoints = [[ESPControllerAPIKeys.endpointId: endpoint,
                                  ESPControllerAPIKeys.clusters: clusters]]
                let parameters = [rainmakerNode.controllerServiceName:
                                    [rainmakerNode.matterDevicesParamName:
                                        [ESPControllerAPIKeys.matterNodes:[[ESPControllerAPIKeys.matterNodeId: matterNodeId, ESPControllerAPIKeys.endpoints: endpoints]]]]]
                let headers: HTTPHeaders = [Constants.contentType: Constants.applicationJSON, Constants.authorization: token]
                self.session.request(url, method: .put, parameters: parameters, encoding: ESPCustomJsonEncoder.default, headers: headers).responseData { response in
                    switch response.result {
                    case .success(let data):
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = json[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success {
                            completion(true)
                            return
                        }
                        completion(false)
                    case .failure(_):
                        completion(false)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Call on API
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    ///   - endpoint: endpoint
    ///   - completion: completion
    func callOnAPI(rainmakerNode: Node, controllerNodeId: String, matterNodeId: String, endpoint: String, completion: @escaping (Bool) -> Void) {
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, serverError in
            if let token = accessToken {
                let url = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/params?node_id=\(controllerNodeId)"
                let commands = [[ESPControllerAPIKeys.commandId: ESPControllerAPIKeys.onCommandId]]
                let clusters = [[ESPControllerAPIKeys.clusterId: ESPControllerAPIKeys.onOffClusterId,
                                 ESPControllerAPIKeys.commands: commands]]
                let endpoints = [[ESPControllerAPIKeys.endpointId: endpoint,
                                  ESPControllerAPIKeys.clusters: clusters]]
                let parameters = [rainmakerNode.controllerServiceName:
                                    [rainmakerNode.matterDevicesParamName:
                                        [ESPControllerAPIKeys.matterNodes:[[ESPControllerAPIKeys.matterNodeId: matterNodeId, ESPControllerAPIKeys.endpoints: endpoints]]]]]
                let headers: HTTPHeaders = [Constants.contentType: Constants.applicationJSON, Constants.authorization: token]
                self.session.request(url, method: .put, parameters: parameters, encoding: ESPCustomJsonEncoder.default, headers: headers).responseData { response in
                    switch response.result {
                    case .success(let data):
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = json[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success {
                            completion(true)
                            return
                        }
                        completion(false)
                    case .failure(_):
                        completion(false)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Call toggle API
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    ///   - endpoint: endpoint
    ///   - completion: completion
    func callToggleAPI(rainmakerNode: Node, controllerNodeId: String, matterNodeId: String, endpoint: String, completion: @escaping (Bool) -> Void) {
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, serverError in
            if let token = accessToken {
                let url = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/params?node_id=\(controllerNodeId)"
                let commands = [[ESPControllerAPIKeys.commandId: ESPControllerAPIKeys.toggleCommandId]]
                let clusters = [[ESPControllerAPIKeys.clusterId: ESPControllerAPIKeys.onOffClusterId,
                                 ESPControllerAPIKeys.commands: commands]]
                let endpoints = [[ESPControllerAPIKeys.endpointId: endpoint,
                                  ESPControllerAPIKeys.clusters: clusters]]
                let parameters = [rainmakerNode.controllerServiceName:
                                    [rainmakerNode.matterDevicesParamName:
                                        [ESPControllerAPIKeys.matterNodes:[[ESPControllerAPIKeys.matterNodeId: matterNodeId, ESPControllerAPIKeys.endpoints: endpoints]]]]]
                let headers: HTTPHeaders = [Constants.contentType: Constants.applicationJSON, Constants.authorization: token]
                self.session.request(url, method: .put, parameters: parameters, encoding: ESPCustomJsonEncoder.default, headers: headers).responseData { response in
                    switch response.result {
                    case .success(let data):
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = json[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success {
                            completion(true)
                            return
                        }
                        completion(false)
                    case .failure(_):
                        completion(false)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Call brightness API
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    ///   - endpoint: endpoint
    ///   - brightnessLevel: brightness level
    ///   - completion: completion
    func callBrightnessAPI(rainmakerNode: Node, controllerNodeId: String, matterNodeId: String, endpoint: String, brightnessLevel: String, completion: @escaping (Bool) -> Void) {
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, serverError in
            if let token = accessToken {
                let url = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/params?node_id=\(controllerNodeId)"
                var finalBrighness: Int = 0
                if let val = Int(brightnessLevel) {
                    finalBrighness = val
                }
                let commands = [[ESPControllerAPIKeys.commandId: ESPControllerAPIKeys.moveToLevelWithOnOffCommandId,
                                 ESPControllerAPIKeys.data: ["0:U8": finalBrighness,
                                                             "1:U16": 0,
                                                             "2:U8": 0,
                                                             "3:U8": 0]]]
                let clusters = [[ESPControllerAPIKeys.clusterId: ESPControllerAPIKeys.levelControlClusterId,
                                 ESPControllerAPIKeys.commands: commands]]
                let endpoints = [[ESPControllerAPIKeys.endpointId: endpoint,
                                  ESPControllerAPIKeys.clusters: clusters]]
                let parameters = [rainmakerNode.controllerServiceName:
                                    [rainmakerNode.matterDevicesParamName:
                                        [ESPControllerAPIKeys.matterNodes:[[ESPControllerAPIKeys.matterNodeId: matterNodeId, ESPControllerAPIKeys.endpoints: endpoints]]]]]
                let headers: HTTPHeaders = [Constants.contentType: Constants.applicationJSON, Constants.authorization: token]
                self.session.request(url, method: .put, parameters: parameters, encoding: ESPCustomJsonEncoder.default, headers: headers).responseData { response in
                    switch response.result {
                    case .success(let data):
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = json[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success {
                            completion(true)
                            return
                        }
                        completion(false)
                    case .failure(_):
                        completion(true)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Call saturation API
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    ///   - endpoint: endpoint
    ///   - saturationLevel: saturation level
    ///   - completion: completion
    func callSaturationAPI(rainmakerNode: Node, controllerNodeId: String, matterNodeId: String, endpoint: String, saturationLevel: String, completion: @escaping (Bool) -> Void) {
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, serverError in
            if let token = accessToken {
                var finalSaturation: Int = 0
                if let val = Int(saturationLevel) {
                    finalSaturation = val
                }
                let url = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/params?node_id=\(controllerNodeId)"
                let commands = [[ESPControllerAPIKeys.commandId: ESPControllerAPIKeys.moveToSaturationCommandId,
                                 ESPControllerAPIKeys.data: ["0:U8": finalSaturation,
                                                             "1:U16": 0,
                                                             "2:U8": 0,
                                                             "3:U8": 0]]]
                let clusters = [[ESPControllerAPIKeys.clusterId: ESPControllerAPIKeys.colorControlClusterId,
                                 ESPControllerAPIKeys.commands: commands]]
                let endpoints = [[ESPControllerAPIKeys.endpointId: endpoint,
                                  ESPControllerAPIKeys.clusters: clusters]]
                let parameters = [rainmakerNode.controllerServiceName:
                                    [rainmakerNode.matterDevicesParamName:
                                        [ESPControllerAPIKeys.matterNodes:[[ESPControllerAPIKeys.matterNodeId: matterNodeId, ESPControllerAPIKeys.endpoints: endpoints]]]]]
                let headers: HTTPHeaders = [Constants.contentType: Constants.applicationJSON, Constants.authorization: token]
                self.session.request(url, method: .put, parameters: parameters, encoding: ESPCustomJsonEncoder.default, headers: headers).responseData { response in
                    switch response.result {
                    case .success(let data):
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = json[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success {
                            completion(true)
                            return
                        }
                        completion(false)
                    case .failure(_):
                        completion(true)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Call hue API
    /// - Parameters:
    ///   - controllerNodeId: controller node id
    ///   - matterNodeId: matter node id
    ///   - endpoint: endpoint
    ///   - saturationLevel: saturation level
    ///   - completion: completion
    func callHueAPI(rainmakerNode: Node, controllerNodeId: String, matterNodeId: String, endpoint: String, hue: String, completion: @escaping (Bool) -> Void) {
        ESPExtendUserSessionWorker().checkUserSession() { accessToken, serverError in
            if let token = accessToken {
                var finalHue: Int = 0
                if let val = Int(hue) {
                    finalHue = val
                }
                let url = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion + "/user/nodes/params?node_id=\(controllerNodeId)"
                let commands = [[ESPControllerAPIKeys.commandId: ESPControllerAPIKeys.moveToHueCommandId,
                                 ESPControllerAPIKeys.data: ["0:U8": finalHue,
                                                             "1:U16": 0,
                                                             "2:U16": 0,
                                                             "3:U8": 0,
                                                             "4:U8": 0]]]
                let clusters = [[ESPControllerAPIKeys.clusterId: ESPControllerAPIKeys.colorControlClusterId,
                                 ESPControllerAPIKeys.commands: commands]]
                let endpoints = [[ESPControllerAPIKeys.endpointId: endpoint,
                                  ESPControllerAPIKeys.clusters: clusters]]
                let parameters = [rainmakerNode.controllerServiceName:
                                    [rainmakerNode.matterDevicesParamName:
                                        [ESPControllerAPIKeys.matterNodes:[[ESPControllerAPIKeys.matterNodeId: matterNodeId, ESPControllerAPIKeys.endpoints: endpoints]]]]]
                let headers: HTTPHeaders = [Constants.contentType: Constants.applicationJSON, Constants.authorization: token]
                self.session.request(url, method: .put, parameters: parameters, encoding: ESPCustomJsonEncoder.default, headers: headers).responseData { response in
                    switch response.result {
                    case .success(let data):
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let status = json[ESPMatterConstants.status] as? String, status.lowercased() == ESPMatterConstants.success {
                            completion(true)
                            return
                        }
                        completion(false)
                    case .failure(_):
                        completion(true)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
}
#endif
