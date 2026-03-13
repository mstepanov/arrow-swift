// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import XCTest
@testable import Arrow

final class ArrayBuilderTests: XCTestCase {
    func testIsValidTypeForBuilder() throws {
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(UInt8.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Int16.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Int32.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Int64.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(UInt8.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(UInt16.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(UInt32.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(UInt64.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Float.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Double.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Date.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Bool.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Int8?.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Int16?.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Int32?.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Int64?.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(UInt8?.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(UInt16?.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(UInt32?.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(UInt64?.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Float?.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Double?.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Date?.self))
        XCTAssertTrue(ArrowArrayBuilders.isValidBuilderType(Bool?.self))

        XCTAssertFalse(ArrowArrayBuilders.isValidBuilderType(Int.self))
        XCTAssertFalse(ArrowArrayBuilders.isValidBuilderType(UInt.self))
        XCTAssertFalse(ArrowArrayBuilders.isValidBuilderType(Int?.self))
        XCTAssertFalse(ArrowArrayBuilders.isValidBuilderType(UInt?.self))
    }

    func testLoadArrayBuilders() throws {
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Int8.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Int16.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Int32.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Int64.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(UInt8.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(UInt16.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(UInt32.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(UInt64.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Float.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Double.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Date.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Bool.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Int8?.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Int16?.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Int32?.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Int64?.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(UInt8?.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(UInt16?.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(UInt32?.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(UInt64?.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Float?.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Double?.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Date?.self))
        XCTAssertNotNil(try ArrowArrayBuilders.loadBuilder(Bool?.self))

        XCTAssertThrowsError(try ArrowArrayBuilders.loadBuilder(Int.self))
        XCTAssertThrowsError(try ArrowArrayBuilders.loadBuilder(UInt.self))
        XCTAssertThrowsError(try ArrowArrayBuilders.loadBuilder(Int?.self))
        XCTAssertThrowsError(try ArrowArrayBuilders.loadBuilder(UInt?.self))
    }

    // MARK: - Buffer Boundary Tests

    /// Test that FixedBufferBuilder correctly handles arrays that exceed initial buffer capacity
    func testFixedBufferBuilderLargeArray() throws {
        let builder: NumberArrayBuilder<Int64> = try ArrowArrayBuilders.loadNumberArrayBuilder()

        // Append enough elements to trigger multiple buffer resizes
        // Initial buffer minLength is 32, so we need > 32 elements
        let count = 1000
        for i in 0..<count {
            builder.append(Int64(i))
        }

        let array = try builder.finish()
        XCTAssertEqual(Int(array.length), count)

        // Verify all values are correct
        for i in 0..<count {
            XCTAssertEqual(array[UInt(i)], Int64(i))
        }
    }

    /// Test FixedBufferBuilder with null values at boundary positions
    func testFixedBufferBuilderNullsAtBoundaries() throws {
        let builder: NumberArrayBuilder<Int32> = try ArrowArrayBuilders.loadNumberArrayBuilder()

        // Insert nulls at positions that would be at byte boundaries (8, 16, 24, etc.)
        let count = 100
        for i in 0..<count {
            if i % 8 == 0 {
                builder.append(nil)
            } else {
                builder.append(Int32(i))
            }
        }

        let array = try builder.finish()
        XCTAssertEqual(Int(array.length), count)

        for i in 0..<count {
            if i % 8 == 0 {
                XCTAssertNil(array[UInt(i)])
            } else {
                XCTAssertEqual(array[UInt(i)], Int32(i))
            }
        }
    }

    /// Test BoolBufferBuilder with large arrays (bool uses bitmap storage)
    func testBoolBufferBuilderLargeArray() throws {
        let builder = try ArrowArrayBuilders.loadBoolArrayBuilder()

        // Test with count that spans multiple bytes in bitmap
        let count = 500
        for i in 0..<count {
            builder.append(i % 2 == 0)
        }

        let array = try builder.finish()
        XCTAssertEqual(Int(array.length), count)

        for i in 0..<count {
            XCTAssertEqual(array[UInt(i)], i % 2 == 0)
        }
    }

    /// Test BoolBufferBuilder with nulls at bitmap byte boundaries
    func testBoolBufferBuilderNullsAtBoundaries() throws {
        let builder = try ArrowArrayBuilders.loadBoolArrayBuilder()

        let count = 100
        for i in 0..<count {
            if i % 8 == 7 {  // Last bit of each byte
                builder.append(nil)
            } else {
                builder.append(i % 2 == 0)
            }
        }

        let array = try builder.finish()
        XCTAssertEqual(Int(array.length), count)

        for i in 0..<count {
            if i % 8 == 7 {
                XCTAssertNil(array[UInt(i)])
            } else {
                XCTAssertEqual(array[UInt(i)], i % 2 == 0)
            }
        }
    }

    /// Test StringArrayBuilder with large arrays (variable-length data)
    func testStringBufferBuilderLargeArray() throws {
        let builder = try ArrowArrayBuilders.loadStringArrayBuilder()

        let count = 500
        for i in 0..<count {
            builder.append("String value number \(i) with some extra padding to make it longer")
        }

        let array = try builder.finish()
        XCTAssertEqual(Int(array.length), count)

        for i in 0..<count {
            XCTAssertEqual(array[UInt(i)], "String value number \(i) with some extra padding to make it longer")
        }
    }

    /// Test StringArrayBuilder with nulls interspersed
    func testStringBufferBuilderWithNulls() throws {
        let builder = try ArrowArrayBuilders.loadStringArrayBuilder()

        let count = 200
        for i in 0..<count {
            if i % 5 == 0 {
                builder.append(nil)
            } else {
                builder.append("Value \(i)")
            }
        }

        let array = try builder.finish()
        XCTAssertEqual(Int(array.length), count)

        for i in 0..<count {
            if i % 5 == 0 {
                XCTAssertNil(array[UInt(i)])
            } else {
                XCTAssertEqual(array[UInt(i)], "Value \(i)")
            }
        }
    }

    /// Test Date64BufferBuilder with large arrays
    func testDate64BufferBuilderLargeArray() throws {
        let builder = try ArrowArrayBuilders.loadDate64ArrayBuilder()

        let baseDate = Date(timeIntervalSince1970: 0)
        let count = 500
        for i in 0..<count {
            let date = Date(timeInterval: Double(i * 86400), since: baseDate)
            builder.append(date)
        }

        let array = try builder.finish()
        XCTAssertEqual(Int(array.length), count)

        for i in 0..<count {
            let expected = Date(timeInterval: Double(i * 86400), since: baseDate)
            // Date64 stores milliseconds, so we compare with some tolerance
            let actual = array[UInt(i)]!
            XCTAssertEqual(actual.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 0.001)
        }
    }

    /// Test mixed nulls and values pattern that exercises edge cases
    func testMixedNullPattern() throws {
        let builder: NumberArrayBuilder<UInt8> = try ArrowArrayBuilders.loadNumberArrayBuilder()

        // Pattern: null, 7 values, null, 7 values... (exercises byte boundaries)
        let count = 256
        for i in 0..<count {
            if i % 8 == 0 {
                builder.append(nil)
            } else {
                builder.append(UInt8(i % 256))
            }
        }

        let array = try builder.finish()
        XCTAssertEqual(Int(array.length), count)
        XCTAssertEqual(Int(array.nullCount), count / 8)
    }

    /// Test that all null array works correctly
    func testAllNullArray() throws {
        let builder: NumberArrayBuilder<Int64> = try ArrowArrayBuilders.loadNumberArrayBuilder()

        let count = 100
        for _ in 0..<count {
            builder.append(nil)
        }

        let array = try builder.finish()
        XCTAssertEqual(Int(array.length), count)
        XCTAssertEqual(Int(array.nullCount), count)

        for i in 0..<count {
            XCTAssertNil(array[UInt(i)])
        }
    }
}
