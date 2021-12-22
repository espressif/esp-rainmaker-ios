// Copyright 2020 Espressif Systems
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
//  Configuration.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation

enum ESPDeviceType: Int {
    case both = 0
    case ble
    case softAp
}

class Configuration: ESPConfiguration {
    static let shared = Configuration()
    var awsConfiguration: AWSConfiguration!
    var appConfiguration: AppConfiguration!
    var externalLinks: ExternalLink!
    var espProvSetting: ESPProvSettings!
    var appThemeColor: String!

    private override init() {
        super.init()
        guard let configDictionary = getCustomPlist() else {
            fatalError("Configuration.plist file is not present. Please check the documents for more information.")
        }
        guard let awsConfig = configDictionary["AWS Configuration"] as? [String: Any] else {
            fatalError("AWS Configuration key is not present. Please check the documents for more information.")
        }
        awsConfiguration = AWSConfiguration(config: awsConfig)
        appConfiguration = AppConfiguration(config: configDictionary["App Configuration"] as? [String: Any])
        externalLinks = ExternalLink(config: configDictionary["External Links"] as? [String: Any])
        espProvSetting = ESPProvSettings(config: configDictionary["Provision Settings"] as? [String: Any])
        appThemeColor = configDictionary["App Theme Color"] as? String ?? "#FFFFFF"
    }
}

extension Configuration {
    
    func getAWSBaseURL() -> String {
        var url = ""
        if let str = self.awsConfiguration.baseURL {
            url = str+"/\(Constants.apiVersion)"
        }
        return url
    }
}

struct AWSConfiguration {
    var appClientId: String!
    var authURL: String!
    var baseURL: String!
    var claimURL: String!
    var redirectURL = ""

    init(config: [String: Any]) {
        guard let clientID = config["App Client ID"] as? String, !clientID.isEmpty else {
            fatalError("App Client ID is not configured. Configured it on Configuration.plist under the dictionary \"AWSConfiguration\" using \"App Client ID\" as key.")
        }
        guard let authenticationURL = config["Authentication URL"] as? String, !authenticationURL.isEmpty else {
            fatalError("Authentication URL is not configured. Configured it on Configuration.plist under the dictionary \"AWSConfiguration\" using \"Authentication URL\" as key.")
        }
        guard let endpointBaseURL = config["Base URL"] as? String, !endpointBaseURL.isEmpty else {
            fatalError("Base URL is not configured. Configured it on Configuration.plist under the dictionary \"AWSConfiguration\" using \"Base URL\" as key.")
        }
        appClientId = clientID
        authURL = authenticationURL
        baseURL = endpointBaseURL
        claimURL = config["Claim URL"] as? String ?? ""
        redirectURL = config["Redirect URL"] as? String ?? ""
    }
}

struct AppConfiguration {
    var supportSchedule = true
    var supportLocalControl = true
    var supportGrouping = true
    var supportSharing = true

    init(config: [String: Any]?) {
        if let configDict = config {
            supportSchedule = configDict["Enable Schedule"] as? Bool ?? true
            supportLocalControl = configDict["Enable Local Control"] as? Bool ?? true
            supportGrouping = configDict["Enable Grouping"] as? Bool ?? true
            supportSharing = configDict["Enable Sharing"] as? Bool ?? true
        }
    }
}

struct ExternalLink {
    var termsOfUseURL = ""
    var privacyPolicyURL = ""
    var documentationURL = ""

    init(config: [String: Any]?) {
        if let configDict = config {
            termsOfUseURL = configDict["Terms of Use"] as? String ?? ""
            privacyPolicyURL = configDict["Privacy Policy"] as? String ?? ""
            documentationURL = configDict["Documentation"] as? String ?? ""
        }
    }
}

struct ESPProvSettings {
    var securityMode: ESPSecurity = .secure
    var transport: ESPDeviceType = .both
    var allowPrefixSearch = true
    var scanEnabled = true
    var bleDevicePrefix = ""

    init(config: [String: Any]?) {
        if let configDict = config {
            scanEnabled = configDict["ESP Scan Enabled"] as? Bool ?? true
            allowPrefixSearch = configDict["Enable Schedule"] as? Bool ?? true
            if let securityModeVal = configDict["ESP Securtiy Mode"] as? String {
                securityMode = securityModeVal.lowercased() == "unsecure" ? .unsecure : .secure
            }
            if let transportVal = configDict["ESP Transport"] as? String {
                switch transportVal.lowercased() {
                case "ble":
                    transport = .ble
                case "softap":
                    transport = .softAp
                default:
                    transport = .both
                }
            }
            bleDevicePrefix = configDict["BLE Device Prefix"] as? String ?? ""
        }
    }
}
