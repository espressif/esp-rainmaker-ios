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

enum ESPSecurity2Type: String {
    case wifiprov = "wifiprov"
    case threadprov = "threadprov"
}

class Configuration: ESPConfiguration {
    static let shared = Configuration()
    var cnConfiguration: CNConfiguration!
    var awsConfiguration: AWSConfiguration!
    var jPushServiceConfiguration: JPushServiceConfiguration!
    var weChatServiceConfiguration: WeChatServiceConfiguration!
    var appConfiguration: AppConfiguration!
    var espAlexaConfiguration: ESPAlexaConfiguration!
    var externalLinks: ExternalLink!
    var espProvSetting: ESPProvSettings!
    var appThemeColor: String!

    private override init() {
        super.init()
        guard let configDictionary = getCustomPlist() else {
            fatalError("Configuration.plist file is not present. Please check the documents for more information.")
        }
        guard let cnConfig = configDictionary["CN Configuration"] as? [String: Any] else {
            fatalError("CN Configuration key is not present. Please check the documents for more information.")
        }
        guard let awsConfig = configDictionary["AWS Configuration"] as? [String: Any] else {
            fatalError("AWS Configuration key is not present. Please check the documents for more information.")
        }
        guard let jPushConfig = configDictionary["JPushService Configuration"] as? [String: Any] else {
            fatalError("JPushService Configuration key is not present. Please check the documents for more information.")
        }
        guard let weChatConfig = configDictionary["WeChat Configuration"] as? [String: Any] else {
            fatalError("WeChat Configuration key is not present. Please check the documents for more information.")
        }
        jPushServiceConfiguration = JPushServiceConfiguration(config: jPushConfig)
        weChatServiceConfiguration = WeChatServiceConfiguration(config: weChatConfig)
        cnConfiguration = CNConfiguration(config: cnConfig)
        awsConfiguration = AWSConfiguration(config: awsConfig, cnConfiguration: ESPLocaleManager.shared.isLocaleChina ? cnConfiguration : nil)
        appConfiguration = AppConfiguration(config: configDictionary["App Configuration"] as? [String: Any])
        espAlexaConfiguration = ESPAlexaConfiguration(configPlist: configDictionary["ESP Alexa Configuration"] as? [String: Any])
        externalLinks = ExternalLink(config: configDictionary["External Links"] as? [String: Any], isRegionChina: ESPLocaleManager.shared.isLocaleChina)
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

struct CNConfiguration {
    var appClientId: String!
    var authURL: String!
    var baseURL: String!
    var claimURL: String!

    init(config: [String: Any]) {
        if ESPLocaleManager.shared.isLocaleChina {
            guard let clientID = config["App Client ID"] as? String, !clientID.isEmpty else {
                fatalError("App Client ID is not configured. Configured it on Configuration.plist under the dictionary \"CNConfiguration\" using \"App Client ID\" as key.")
            }
            guard let authenticationURL = config["Authentication URL"] as? String, !authenticationURL.isEmpty else {
                fatalError("Authentication URL is not configured. Configured it on Configuration.plist under the dictionary \"CNConfiguration\" using \"Authentication URL\" as key.")
            }
            guard let endpointBaseURL = config["Base URL"] as? String, !endpointBaseURL.isEmpty else {
                fatalError("Base URL is not configured. Configured it on Configuration.plist under the dictionary \"CNConfiguration\" using \"Base URL\" as key.")
            }
            guard let claimBaseURL = config["Claim URL"] as? String, !endpointBaseURL.isEmpty else {
                fatalError("Base URL is not configured. Configured it on Configuration.plist under the dictionary \"CNConfiguration\" using \"Base URL\" as key.")
            }
            appClientId = clientID
            authURL = authenticationURL
            baseURL = endpointBaseURL
            claimURL = claimBaseURL
        } else {
            appClientId = config["App Client ID"] as? String ?? ""
            authURL = config["Authentication URL"] as? String ?? ""
            baseURL = config["Base URL"] as? String ?? ""
            claimURL = config["Claim URL"] as? String ?? ""
        }
    }
}

struct AWSConfiguration {
    var appClientId: String!
    var authURL: String!
    var baseURL: String!
    var claimURL: String!
    var redirectURL = ""

    init(config: [String: Any], cnConfiguration: CNConfiguration?) {
        guard let clientID = config["App Client ID"] as? String, !clientID.isEmpty else {
            fatalError("App Client ID is not configured. Configured it on Configuration.plist under the dictionary \"AWSConfiguration\" using \"App Client ID\" as key.")
        }
        guard let authenticationURL = config["Authentication URL"] as? String, !authenticationURL.isEmpty else {
            fatalError("Authentication URL is not configured. Configured it on Configuration.plist under the dictionary \"AWSConfiguration\" using \"Authentication URL\" as key.")
        }
        guard let endpointBaseURL = config["Base URL"] as? String, !endpointBaseURL.isEmpty else {
            fatalError("Base URL is not configured. Configured it on Configuration.plist under the dictionary \"AWSConfiguration\" using \"Base URL\" as key.")
        }
        if let cnConfig = cnConfiguration {
            appClientId = cnConfig.appClientId
            authURL = cnConfig.authURL
            baseURL = UserDefaults.standard.value(forKey: Constants.overriddenBaseURLKey) as? String ?? cnConfig.baseURL
            claimURL = cnConfig.claimURL
        } else {
            appClientId = clientID
            authURL = authenticationURL
            baseURL = UserDefaults.standard.value(forKey: Constants.overriddenBaseURLKey) as? String ?? endpointBaseURL
            claimURL = config["Claim URL"] as? String ?? ""
        }
        redirectURL = config["Redirect URL"] as? String ?? ""
    }
    
    mutating func resetBaseURLFromConfig() {
        guard let configDictionary = Configuration.shared.getCustomPlist() else {
            fatalError("Configuration.plist file is not present. Please check the documents for more information.")
        }
        guard let awsConfig = configDictionary["AWS Configuration"] as? [String: Any] else {
            fatalError("AWS Configuration key is not present. Please check the documents for more information.")
        }
        guard let endpointBaseURL = awsConfig["Base URL"] as? String, !endpointBaseURL.isEmpty else {
            fatalError("Base URL is not configured. Configured it on Configuration.plist under the dictionary \"AWSConfiguration\" using \"Base URL\" as key.")
        }
        self.baseURL = endpointBaseURL
    }
}

struct JPushServiceConfiguration {
    var appKey: String!
    var apsForProduction: Bool = true
    
    init(config: [String: Any]) {
        appKey = config["App Key"] as? String ?? ""
        apsForProduction = config["APS For Production"] as? Bool ?? false
    }
}

struct WeChatServiceConfiguration {
    var appId: String!
    var universalLink: String!
    var scope: String!
    static let state = "esp_rainmaker_we_chat_prod_state"
    
    init(config: [String: Any]) {
        appId = config["App Id"] as? String ?? ""
        universalLink = config["Universal Link"] as? String ?? ""
        scope = config["Scope"] as? String ?? ""
    }
}

struct AppConfiguration {
    var supportSchedule = true
    var supportLocalControl = true
    var localControlSec2Username = ESPSecurity2Type.wifiprov.rawValue
    var supportGrouping = true
    var supportSharing = true
    var supportScene = true
    var supportDeviceAutomation = true
    var supportOTAUpdate = false
    var supportConfigOverride = false
    var userPool: Int = 2
    var supportContinuousUpdate = true
    // In milliseconds
    var continuousUpdateInterval:Int64 = 400
    
    #if ESPRainMakerMatter
    var matterEcosystemName: String = ESPMatterConstants.espressif
    var matterVendorId: UInt16 = ESPMatterConstants.matterVendorId
    #endif
    
    init(config: [String: Any]?) {
        if let configDict = config {
            supportSchedule = configDict["Enable Schedule"] as? Bool ?? true
            supportScene = configDict["Enable Scene"] as? Bool ?? true
            supportLocalControl = configDict["Enable Local Control"] as? Bool ?? true
            localControlSec2Username = configDict["Local Control Security 2 Username"] as? String ?? ESPSecurity2Type.wifiprov.rawValue
            supportGrouping = configDict["Enable Grouping"] as? Bool ?? true
            supportSharing = configDict["Enable Sharing"] as? Bool ?? true
            supportDeviceAutomation = configDict["Enable Device Automation"] as? Bool ?? true
            supportOTAUpdate = configDict["Enable OTA Update"] as? Bool ?? false
            supportConfigOverride = configDict["Enable Config Override"] as? Bool ?? false
            if let pool = configDict["User Pool"] as? Int {
                userPool = pool
            }
            supportContinuousUpdate = configDict["Enable Continuous Updates"] as? Bool ?? true
            let interval = configDict["Continuous Update Interval"] as? Int64 ?? 400
            switch interval {
            case 0..<400:
                continuousUpdateInterval = 400
            case 400...1000:
                continuousUpdateInterval = interval
            default:
                continuousUpdateInterval = 1000
            }
            #if ESPRainMakerMatter
            matterEcosystemName = configDict["Matter Ecosystem"] as? String ?? ESPMatterConstants.espressif
            matterVendorId = configDict["Matter Vendor Id"] as? UInt16 ?? ESPMatterConstants.matterVendorId
            #endif
        }
    }
}

struct ExternalLink {
    var termsOfUseURL = ""
    var privacyPolicyURL = ""
    var documentationURL = ""

    init(config: [String: Any]?, isRegionChina: Bool) {
        if let configDict = config {
            if isRegionChina {
                termsOfUseURL = configDict["CN Terms of Use"] as? String ?? ""
            } else {
                termsOfUseURL = configDict["Terms of Use"] as? String ?? ""
            }
            if isRegionChina {
                privacyPolicyURL = configDict["CN Privacy Policy"] as? String ?? ""
            } else {
                privacyPolicyURL = configDict["Privacy Policy"] as? String ?? ""
            }
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
    var wifiSec2Username = ""
    var threadSec2Username = ""

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
            wifiSec2Username = configDict["Security 2 Username"] as? String ?? ESPSecurity2Type.wifiprov.rawValue
            threadSec2Username = configDict["Security 2 Username Thread"] as? String ?? ESPSecurity2Type.threadprov.rawValue
        }
    }
}

/// Struct that reads data from "ESPAlexaConfiguration.plist" and allows user to access that data via this class
struct ESPAlexaConfiguration {
    
    // MARK: - Config keys
    private let appClientIdKey = "Alexa Client Id"
    private let clientSecretKey = "Alexa Client Secret"
    private let skillStageKey = "Skill Stage"
    private let redirectURIKey = "Redirect URL"
    private let skillIDKey = "Skill Id"
    private let clientIDKey = "Alexa RM Client Id"
    private let fetchAccessTokenURLKey = "Alexa Access Token URL"
    
    // MARK: - Config values
    var appClientId: String = ""
    var appClientSecret: String = ""
    var skillStage: String = ""
    var redirectURI: String = ""
    var skillId: String = ""
    var clientId: String = ""
    var fetchAccessTokenURL: String = ""
    
    //Placeholder value used in alexa app URL, LWA URL
    let state: String = "temp"
    
    //Alexa specific configs:
    let useRefreshTokenURL: String = "https://api.amazon.com/auth/o2/token"
    let getAPIEndpointURL: String = "https://api.amazonalexa.com/v1/alexaApiEndpoint"
    let alexaAppURL: String = "https://alexa.amazon.com/spa/skill-account-linking-consent?fragment=skill-account-linking-consent"
    let loginWithAmazonURL: String = "https://www.amazon.com/ap/oa"
    let loginWithAmazonScope: String = "alexa::skills:account_linking"
    let alexaActions: [String] = ["Alexa, turn on the boiler switch",
                                  "Alexa, turn on the kitchen light",
                                  "Alexa, set kitchen light to red"]
    
    // MARK: - Config computed values
    
    /// Universal link to open alexa from rainmaker
    var alexaURL: String {
        return "\(alexaAppURL)&client_id=\(appClientId)&scope=\(loginWithAmazonScope)&skill_stage=\(skillStage)&response_type=code&redirect_uri=\(redirectURI)&state=\(state)"
    }
    
    /// URL to open alexa login page in WKWebview
    var lwaURL: String {
        return "\(loginWithAmazonURL)?client_id=\(appClientId)&scope=\(loginWithAmazonScope)&response_type=code&redirect_uri=\(redirectURI)&state=\(state)"
    }
    
    /// URL to open rainmaker login page in WKWebview
    var rainmakerURL: String {
        return "\(Configuration.shared.awsConfiguration.authURL!)/authorize?response_type=code&client_id=\(clientId)&redirect_uri=\(redirectURI)&state=\(state)&scope=aws.cognito.signin.user.admin"
    }
    
    /// String compiled of the alexa actions specified in AlexaConfiguration.plist
    var alexaActionsString: String {
        var result = ""
        for i in 0..<alexaActions.count {
            if i == alexaActions.count-1 {
                result+="\(alexaActions[i])"
            } else {
                result+="\(alexaActions[i])\n\n"
            }
        }
        return result
    }
    
    /// This variable returns a randomly generated string to be sent in the alexa url endpoints in order to validate if callbacks from URLs are from correct source
    var urlState: String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let length = 20
        let len = UInt32(letters.length)
        var randomString = ""
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
    
    init(configPlist: [String: Any]?) {
        if let configPlist = configPlist {
            if let val = configPlist[appClientIdKey] as? String {
                appClientId = val
            }
            if let val = configPlist[skillStageKey] as? String {
                skillStage = val
            }
            if let val = configPlist[redirectURIKey] as? String {
                redirectURI = val
            }
            if let val = configPlist[clientSecretKey] as? String {
                appClientSecret = val
            }
            if let val = configPlist[skillIDKey] as? String {
                skillId = val
            }
            if let val = configPlist[clientIDKey] as? String {
                clientId = val
            }
            if let val = configPlist[fetchAccessTokenURLKey] as? String {
                fetchAccessTokenURL = val
            }
        }
    }
}

