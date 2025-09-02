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
//  KVSSigner.swift
//  ESPRainMaker
//

import CommonCrypto
import Foundation

class KVSSigner {
    
    static func iso8601() -> (fullDateTimestamp: String, shortDate: String) {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = ESPAWSConstants.utcDateFormatter
        dateFormatter.timeZone = TimeZone(abbreviation: ESPAWSConstants.utcTimezone)
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        let index = dateString.index(dateString.startIndex, offsetBy: 8)
        let shortDate = dateString.substring(to: index)
        return (fullDateTimestamp: dateString, shortDate: shortDate)
    }
    
    /*
     DateKey              = HMAC-SHA256("AWS4"+"<SecretAccessKey>", "<YYYYMMDD>")
     DateRegionKey        = HMAC-SHA256(<DateKey>, "<aws-region>")
     DateRegionServiceKey = HMAC-SHA256(<DateRegionKey>, "<aws-service>")
     SigningKey           = HMAC-SHA256(<DateRegionServiceKey>, "aws4_request")
     */
    static func signatureWith(stringToSign: String, secretAccessKey: String, shortDateString: String, awsRegion: String, serviceType: String) -> String? {

        let firstKey = "AWS4" + secretAccessKey
        let dateKey = shortDateString.hmac(keyString: firstKey)
        let dateRegionKey = awsRegion.hmac(keyData: dateKey)
        let dateRegionServiceKey = serviceType.hmac(keyData: dateRegionKey)
        let signingKey = ESPAWSConstants.awsRequestTypeKey.hmac(keyData: dateRegionServiceKey)

        let signature = stringToSign.hmac(keyData: signingKey)
        return signature.toHexString()
    }

    static func getCredentialScope(shortDate: String, region: String, serviceName: String, requestType: String) -> String {
        let credentialArray = [shortDate, region, serviceName, requestType]
        return credentialArray.joined(separator: ESPAWSConstants.slashDelimiter)
    }
    
    static func getQueryParams(accessKey: String, sessionToken: String, credentialScope: String, date:(fullDateTimestamp: String, shortDate: String)) -> (queryParamBuilder: [URLQueryItem], queryParamBuilderDict: [String: String]) {
        var queryParamsBuilderArray = [URLQueryItem]()
        queryParamsBuilderArray.append(URLQueryItem(name: ESPAWSConstants.xAmzAlgorithm, value: ESPAWSConstants.signerAlgorithm))
        queryParamsBuilderArray.append(URLQueryItem(name: ESPAWSConstants.xAmzCredential, value: (accessKey + ESPAWSConstants.slashDelimiter + credentialScope).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!))
        queryParamsBuilderArray.append(URLQueryItem(name: ESPAWSConstants.xAmzDate, value: date.fullDateTimestamp))
        queryParamsBuilderArray.append(URLQueryItem(name: ESPAWSConstants.xAmzExpiresKey, value: ESPAWSConstants.xAmzExpiresValue))
        queryParamsBuilderArray.append(URLQueryItem(name: ESPAWSConstants.xAmzSignedHeaders, value: ESPAWSConstants.hostKey))
        
        var queryParamsBuilderDictionary: [String: String] = [
            ESPAWSConstants.xAmzAlgorithm: ESPAWSConstants.signerAlgorithm,
            ESPAWSConstants.xAmzCredential: (accessKey + ESPAWSConstants.slashDelimiter + credentialScope).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!,
            ESPAWSConstants.xAmzDate: date.fullDateTimestamp,
            ESPAWSConstants.xAmzExpiresKey: ESPAWSConstants.xAmzExpiresValue,
            ESPAWSConstants.xAmzSignedHeaders: ESPAWSConstants.hostKey
        ]
        
        if !sessionToken.isEmpty {
            queryParamsBuilderArray
                .append(URLQueryItem(
                    name: ESPAWSConstants.xAmzSecurityToken,
                    value: sessionToken.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!.replacingOccurrences(of: ESPAWSConstants.plusDelimiter, with: ESPAWSConstants.plusEncoding).replacingOccurrences(of: ESPAWSConstants.equalsDelimiter, with: ESPAWSConstants.equalsEncoding)))
            queryParamsBuilderDictionary
                .updateValue(sessionToken.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!.replacingOccurrences(of: ESPAWSConstants.plusDelimiter, with: ESPAWSConstants.plusEncoding).replacingOccurrences(of: ESPAWSConstants.equalsDelimiter, with: ESPAWSConstants.equalsEncoding),
                             forKey: ESPAWSConstants.xAmzSecurityToken)
        }
        
        return (queryParamsBuilderArray, queryParamsBuilderDictionary)
    }
    
    static func getStringToSign(fullDateTimeStamp: String, credentialScope: String, canonicalRequest: String) -> String {
        return ESPAWSConstants.signerAlgorithm + ESPAWSConstants.newlineDelimiter +
        fullDateTimeStamp + ESPAWSConstants.newlineDelimiter +
        credentialScope + ESPAWSConstants.newlineDelimiter +
        canonicalRequest.sha256()
    }
    
    static func getSignedUrl(wssRequest: URL, queryParamsBuilder:[URLQueryItem], canonicalUri: String, signature: String) -> URL? {
        
        var components = URLComponents()
        components.scheme = ESPAWSConstants.wssKey
        components.host = wssRequest.host
        components.path = canonicalUri
        var queryParamsBuilderArray = queryParamsBuilder
        queryParamsBuilderArray.sort {
            $0.name < $1.name
        }
        queryParamsBuilderArray.append(URLQueryItem(name: ESPAWSConstants.xAmzSignature, value: signature))

        if #available(iOS 11.0, *) {
            components.percentEncodedQueryItems = queryParamsBuilderArray
        } else {
            
        }
        return components.url
    }
    
    static func getCanonicalHeaders(signRequest:URL) -> String? {
        guard let host = signRequest.host
            else { return .none }
        return ESPAWSConstants.hostKey + ESPAWSConstants.colonDelimiter + host + ESPAWSConstants.newlineDelimiter
    }
    
    static func getCanonicalUri (signRequest:URL) -> String? {
        if (signRequest.path.isEmpty) {
            return ESPAWSConstants.slashDelimiter
        }
        return signRequest.path
    }
    
    static func getCanonicalRequest(canonicalQuerystring: String, signRequest: URL) -> String? {
        let cleanedcanonicalQuerystring = String(canonicalQuerystring.dropLast())
        let emptyString = ""
        let payloadHash = emptyString.sha256()
        return
        ESPAWSConstants.restMethod + ESPAWSConstants.newlineDelimiter +
        getCanonicalUri(signRequest: signRequest)! + ESPAWSConstants.newlineDelimiter +
        cleanedcanonicalQuerystring + ESPAWSConstants.newlineDelimiter +
        getCanonicalHeaders(signRequest: signRequest)! + ESPAWSConstants.newlineDelimiter +
        ESPAWSConstants.hostKey + ESPAWSConstants.newlineDelimiter + payloadHash
    }
    
    static func getCanonicalQueryString(queryParamBuilderDict: [String: String]) -> String? {
        let sortedKeys = queryParamBuilderDict.keys.sorted()
        var canonicalQueryString: String = ""

        for key in sortedKeys {
            canonicalQueryString += key + ESPAWSConstants.equalsDelimiter + queryParamBuilderDict[key]! + ESPAWSConstants.ampersandDelimiter
        }
        return canonicalQueryString
    }
    
    static func sign(signRequest: URL, secretKey: String, accessKey: String, sessionToken: String, wssRequest: URL, region: String) -> URL? {
        let date = iso8601()
        return signWithDate(signRequest: signRequest, secretKey: secretKey, accessKey: accessKey, sessionToken: sessionToken, wssRequest: wssRequest, region: region, date: date)
    }
    
    static func signWithDate(signRequest: URL, secretKey: String, accessKey: String, sessionToken: String,
                             wssRequest: URL, region: String, date:(fullDateTimestamp: String, shortDate: String)) -> URL? {
        var canonicalUri = signRequest.path
        if (canonicalUri.isEmpty) {
            canonicalUri = ESPAWSConstants.slashDelimiter
        }
        let credentialScope = getCredentialScope(shortDate: date.shortDate, region: region, serviceName: ESPAWSConstants.awsKinesisVideoKey, requestType: ESPAWSConstants.awsRequestTypeKey)

        let queryParams = getQueryParams(accessKey: accessKey, sessionToken: sessionToken, credentialScope: credentialScope, date: date)
        var queryParamsBuilder :[URLQueryItem] = queryParams.queryParamBuilder
        var queryParamsBuilderDict: [String: String] = queryParams.queryParamBuilderDict

        //Adding queryParams from the signRequest's query.
        if signRequest.query != nil {
            let queryParams = signRequest.query!
            let queryParamArray = queryParams.components(separatedBy: ESPAWSConstants.ampersandDelimiter)

            for param in queryParamArray {
                if let index = param.firstIndex(of: "=") {
                    let nextIndex = param.index(after: index)
                    queryParamsBuilderDict.updateValue(String(param[nextIndex...]).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!, forKey: String(param[..<index]))
                    queryParamsBuilder.append(URLQueryItem(name: String(param[..<index].addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!), value: String(param[nextIndex...]).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!))
                }
            }
        } else {
            print("Error: Missing channel ARN.")
        }

        let canonicalQuerystring = getCanonicalQueryString(queryParamBuilderDict: queryParamsBuilderDict)
        let canonicalRequest = getCanonicalRequest(canonicalQuerystring: canonicalQuerystring!, signRequest: signRequest)
        let stringToSign = getStringToSign(fullDateTimeStamp: date.fullDateTimestamp, credentialScope: credentialScope, canonicalRequest: canonicalRequest!)
        let signature = signatureWith(stringToSign: stringToSign, secretAccessKey: secretKey, shortDateString: date.shortDate, awsRegion: region, serviceType: ESPAWSConstants.awsKinesisVideoKey)
        return getSignedUrl(wssRequest: wssRequest, queryParamsBuilder: queryParamsBuilder, canonicalUri: canonicalUri, signature: signature!)
        
    }
}
