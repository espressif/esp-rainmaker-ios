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
//  ESPAWSConstants.swift
//  ESPRainMaker
//

struct ESPAWSConstants {
    
    static let awsCognitoUserPoolsSignInProviderKey = "UserPool"
    
    // Existing constants
    static let awsKinesisVideoKey = "kinesisvideo"
    
    // Video protocols
    static let videoProtocols = ["WSS", "HTTPS"]
    
    // Connection constants
    static let connectAsMasterKey = "connect-as-master"
    static let connectAsViewerKey = "connect-as-viewer"
    static let masterRole = "MASTER"
    static let viewerRole = "VIEWER"
    static let connectAsViewClientId = "ConsumerViewer"
    
    // Headers
    static let userAgentHeader = "User-Agent"
    
    // AWS Signer Constants
    static let signerAlgorithm = "AWS4-HMAC-SHA256"
    static let awsRequestTypeKey = "aws4_request"
    
    // X-Amz Headers
    static let xAmzAlgorithm = "X-Amz-Algorithm"
    static let xAmzCredential = "X-Amz-Credential"
    static let xAmzDate = "X-Amz-Date"
    static let xAmzExpiresKey = "X-Amz-Expires"
    static let xAmzExpiresValue = "299"
    static let xAmzSecurityToken = "X-Amz-Security-Token"
    static let xAmzSignature = "X-Amz-Signature"
    static let xAmzSignedHeaders = "X-Amz-SignedHeaders"
    
    // Delimiters
    static let newlineDelimiter = "\n"
    static let slashDelimiter = "/"
    static let colonDelimiter = ":"
    static let plusDelimiter = "+"
    static let equalsDelimiter = "="
    static let ampersandDelimiter = "&"
    
    // HTTP Methods
    static let restMethod = "GET"
    
    // Date Formatting
    static let utcDateFormatter = "yyyyMMdd'T'HHmmss'Z'"
    static let utcTimezone = "UTC"
    
    // Keys
    static let hostKey = "host"
    static let wssKey = "wss"
    
    // URL Encodings
    static let plusEncoding = "%2B"
    static let equalsEncoding = "%3D"
    
    static let localSenderId = "ConsumerViewer"
}
