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
//  KVSSignerConstants.swift
//  ESPRainMaker
//

struct KVSSignerConstants {
    // Date formatters
    static let utcDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    static let utcTimezone = TimeZone(identifier: "UTC")!
    
    // AWS Constants
    static let awsKinesisVideoKey = "kinesisvideo"
    static let awsRequestTypeKey = "aws4_request"
    static let wssKey = "wss"
    
    // Headers
    static let xAmzAlgorithm = "X-Amz-Algorithm"
    static let xAmzCredential = "X-Amz-Credential"
    static let xAmzDate = "X-Amz-Date"
    static let xAmzExpiresKey = "X-Amz-Expires"
    static let xAmzSignedHeaders = "X-Amz-SignedHeaders"
    static let xAmzSignature = "X-Amz-Signature"
    static let xAmzSecurityToken = "X-Amz-Security-Token"
    
    // Values
    static let signerAlgorithm = "AWS4-HMAC-SHA256"
    static let xAmzExpiresValue = "299"
    static let hostKey = "host"
    static let restMethod = "GET"
    
    // Delimiters
    static let slashDelimiter = "/"
    static let newlineDelimiter = "\n"
    static let colonDelimiter = ":"
    static let plusDelimiter = "+"
    static let equalsDelimiter = "="
    static let ampersandDelimiter = "&"
    
    // Encodings
    static let plusEncoding = "%2B"
    static let equalsEncoding = "%3D"
} 
