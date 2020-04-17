//
//  CurveError.swift
//  Curve25519-iOS
//
//  Created by User on 28.01.18.
//  Copyright © 2018 User. All rights reserved.
//

import Foundation

/**
 Possible errors for Curve25519 functions.
 */
public enum CurveError: Error, CustomStringConvertible {
    /// The private/public key has less than 32 byte
    case keyLength(Int)

    /// The basepoint has less than
    case basepointLength(Int)

    /// curve function produced an error
    case curveError(Int32)

    /// Message to short
    case messageLength(Int)

    /// Random data less than 64 byte
    case randomLength(Int)

    /// Invalid signature length
    case signatureLength(Int)

    /// A textual representation of the error
    public var description: String {
        switch self {
        case let .keyLength(len): return "Key has invalid length \(len)"
        case let .basepointLength(len): return "Basepoint has invalid length \(len)"
        case let .curveError(err): return "Curve function error \(err)"
        case let .messageLength(len): return "Invalid message length \(len)"
        case let .randomLength(len): return "Too few random bytes (\(len))"
        case let .signatureLength(len): return "Invalid signature length \(len)"
        }
    }
}
