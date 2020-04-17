// Sources/SwiftProtobuf/SelectiveVisitor.swift - Base for custom Visitors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A base for Visitors that only expect a subset of things to called.
///
// -----------------------------------------------------------------------------

import Foundation

/// A base for Visitors that only expects a subset of things to called.
internal protocol SelectiveVisitor: Visitor {
    // Adds nothing.
}

/// Default impls for everything so things using this only have to write the
/// methods they expect.  Asserts to catch developer errors, but becomes
/// nothing in release to keep code size small.
///
/// NOTE: This is an impl for *everything*. This means the default impls
/// provided by Visitor to bridge packed->repeated, repeated->singular, etc
/// won't kick in.
extension SelectiveVisitor {
    internal mutating func visitSingularFloatField(value _: Float, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularDoubleField(value _: Double, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularInt32Field(value _: Int32, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularInt64Field(value _: Int64, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularUInt32Field(value _: UInt32, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularUInt64Field(value _: UInt64, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularSInt32Field(value _: Int32, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularSInt64Field(value _: Int64, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularFixed32Field(value _: UInt32, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularFixed64Field(value _: UInt64, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularSFixed32Field(value _: Int32, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularSFixed64Field(value _: Int64, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularBoolField(value _: Bool, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularStringField(value _: String, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularBytesField(value _: Data, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularEnumField<E: Enum>(value _: E, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularMessageField<M: Message>(value _: M, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitSingularGroupField<G: Message>(value _: G, fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedFloatField(value _: [Float], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedDoubleField(value _: [Double], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedInt32Field(value _: [Int32], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedInt64Field(value _: [Int64], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedUInt32Field(value _: [UInt32], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedUInt64Field(value _: [UInt64], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedSInt32Field(value _: [Int32], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedSInt64Field(value _: [Int64], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedFixed32Field(value _: [UInt32], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedFixed64Field(value _: [UInt64], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedSFixed32Field(value _: [Int32], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedSFixed64Field(value _: [Int64], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedBoolField(value _: [Bool], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedStringField(value _: [String], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedBytesField(value _: [Data], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedEnumField<E: Enum>(value _: [E], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedMessageField<M: Message>(value _: [M], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitRepeatedGroupField<G: Message>(value _: [G], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedFloatField(value _: [Float], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedDoubleField(value _: [Double], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedInt32Field(value _: [Int32], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedInt64Field(value _: [Int64], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedUInt32Field(value _: [UInt32], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedUInt64Field(value _: [UInt64], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedSInt32Field(value _: [Int32], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedSInt64Field(value _: [Int64], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedFixed32Field(value _: [UInt32], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedFixed64Field(value _: [UInt64], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedSFixed32Field(value _: [Int32], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedSFixed64Field(value _: [Int64], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedBoolField(value _: [Bool], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitPackedEnumField<E: Enum>(value _: [E], fieldNumber _: Int) throws {
        assert(false)
    }

    internal mutating func visitMapField<KeyType, ValueType: MapValueType>(
        fieldType _: _ProtobufMap<KeyType, ValueType>.Type,
        value _: _ProtobufMap<KeyType, ValueType>.BaseType,
        fieldNumber _: Int
    ) throws {
        assert(false)
    }

    internal mutating func visitMapField<KeyType, ValueType>(
        fieldType _: _ProtobufEnumMap<KeyType, ValueType>.Type,
        value _: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
        fieldNumber _: Int
    ) throws where ValueType.RawValue == Int {
        assert(false)
    }

    internal mutating func visitMapField<KeyType, ValueType>(
        fieldType _: _ProtobufMessageMap<KeyType, ValueType>.Type,
        value _: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
        fieldNumber _: Int
    ) throws {
        assert(false)
    }

    internal mutating func visitExtensionFields(fields _: ExtensionFieldValueSet, start _: Int, end _: Int) throws {
        assert(false)
    }

    internal mutating func visitExtensionFieldsAsMessageSet(
        fields _: ExtensionFieldValueSet,
        start _: Int,
        end _: Int
    ) throws {
        assert(false)
    }

    internal mutating func visitUnknown(bytes _: Data) throws {
        assert(false)
    }
}
