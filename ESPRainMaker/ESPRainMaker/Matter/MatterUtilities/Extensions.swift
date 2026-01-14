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
//  Extensions.swift
//  ESPRainmaker
//

import Foundation
import UIKit
import CommonCrypto

extension String {
    
    // MARK: Event
    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    func base64Decoded() -> String? {
        var localData: Data?
        localData = Data(base64Encoded: self)
        var temp: String = self
        if localData == nil {
            temp = self + "=="
        }
        guard let data = Data(base64Encoded: temp, options: Data.Base64DecodingOptions(rawValue: 0)) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func convertToDictionaryValueAsString() throws -> [String: Any] {
        let data = Data(utf8)

        if let anyResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            return anyResult
        } else {
            return [:]
        }
    }
    
    // MARK: KVSSigner
    func sha256() -> String {
        if let stringData = self.data(using: String.Encoding.utf8) {
            return hexStringFromData(input: digest(input: stringData as NSData))
        }
        return ""
    }

    func digest(input: NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }

    func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)

        var hexString = ""
        for byte in bytes {
            hexString += String(format: "%02x", UInt8(byte))
        }

        return hexString
    }

    func hmac(keyString: String) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyString, keyString.count, self, count, &digest)
        return Data.init(bytes: digest)
    }

    func hmac(keyData: Data) -> Data {
        let keyBytes = keyData.bytes
        let data = cString(using: String.Encoding.utf8)
        let dataLen = Int(lengthOfBytes(using: String.Encoding.utf8))
        var result = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes, keyData.count, data, dataLen, &result)

        return Data.init(bytes: result)
    }

    // MARK: SignalingClient
    func convertToDictionary() throws -> [String: Any] {
        let data = Data(utf8)

        if let anyResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            return anyResult
        } else {
            return [:]
        }
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var hexadecimal: Data? {
        var data = Data(capacity: self.count / 2)
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }
        guard data.count > 0 else { return nil }
        return data
    }

    var hexToDecimal: UInt64? {
        let scanner = Scanner(string: self)
        var value: UInt64 = 0
        if scanner.scanHexInt64(&value) {
            return value
        }
        return nil
    }
}


extension Data {
    
    init?(hexStr: String) {
        // Ensure the hex string is even length
        let len = hexStr.count / 2
        guard hexStr.count % 2 == 0 else { return nil }
        
        var data = Data(capacity: len)
        var index = hexStr.startIndex
        for _ in 0..<len {
            let nextIndex = hexStr.index(index, offsetBy: 2)
            guard nextIndex <= hexStr.endIndex else { return nil }
            let byteString = hexStr[index..<nextIndex]
            guard let num = UInt8(byteString, radix: 16) else { return nil }
            data.append(num)
            index = nextIndex
        }
        self = data
    }
    
    var hexadecimalString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    var hexString: String {
        return self.base64EncodedString()
    }
    
    var bytes: [UInt8] {
        return [UInt8](self)
    }
    
    func toHexString() -> String {
        let hexString = map { String(format: "%02x", $0) }.joined()
        return hexString
    }
}

extension Array {
    public init(reserveCapacity: Int) {
        self = [Element]()
        self.reserveCapacity(reserveCapacity)
    }

    var slice: ArraySlice<Element> {
        return self[self.startIndex ..< self.endIndex]
    }
}

extension Array where Element == UInt8 {
    public init(hex: String) {
        self.init(reserveCapacity: hex.unicodeScalars.lazy.underestimatedCount)
        var buffer: UInt8?
        var skip = hex.hasPrefix("0x") ? 2 : 0
        for char in hex.unicodeScalars.lazy {
            guard skip == 0 else {
                skip -= 1
                continue
            }
            guard char.value >= 48, char.value <= 102 else {
                removeAll()
                return
            }
            let v: UInt8
            let c: UInt8 = UInt8(char.value)
            switch c {
            case let c where c <= 57:
                v = c - 48
            case let c where c >= 65 && c <= 70:
                v = c - 55
            case let c where c >= 97:
                v = c - 87
            default:
                removeAll()
                return
            }
            if let b = buffer {
                append(b << 4 | v)
                buffer = nil
            } else {
                buffer = v
            }
        }
        if let b = buffer {
            append(b)
        }
    }

    public func toHexString() -> String {
        return `lazy`.reduce("") {
            var s = String($1, radix: 16)
            if s.count == 1 {
                s = "0" + s
            }
            return $0 + s
        }
    }
}

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
