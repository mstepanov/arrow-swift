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

final class CodableTests: XCTestCase { // swiftlint:disable:this type_body_length
    public class TestClass: Codable {
        public var propBool: Bool
        public var propInt8: Int8
        public var propInt16: Int16
        public var propInt32: Int32
        public var propInt64: Int64
        public var propUInt8: UInt8
        public var propUInt16: UInt16
        public var propUInt32: UInt32
        public var propUInt64: UInt64
        public var propFloat: Float
        public var propDouble: Double?
        public var propString: String
        public var propDate: Date

        public required init() {
            self.propBool = false
            self.propInt8 = 1
            self.propInt16 = 2
            self.propInt32 = 3
            self.propInt64 = 4
            self.propUInt8 = 5
            self.propUInt16 = 6
            self.propUInt32 = 7
            self.propUInt64 = 8
            self.propFloat = 9
            self.propDouble = 10
            self.propString = "11"
            self.propDate = Date.now
        }
    }

    func testArrowKeyedDecoder() throws { // swiftlint:disable:this function_body_length
        let date1 = Date(timeIntervalSinceReferenceDate: 86400 * 5000 + 352)
        let boolBuilder = try ArrowArrayBuilders.loadBoolArrayBuilder()
        let int8Builder: NumberArrayBuilder<Int8> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        let int16Builder: NumberArrayBuilder<Int16> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        let int32Builder: NumberArrayBuilder<Int32> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        let int64Builder: NumberArrayBuilder<Int64> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        let uint8Builder: NumberArrayBuilder<UInt8> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        let uint16Builder: NumberArrayBuilder<UInt16> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        let uint32Builder: NumberArrayBuilder<UInt32> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        let uint64Builder: NumberArrayBuilder<UInt64> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        let floatBuilder: NumberArrayBuilder<Float> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        let doubleBuilder: NumberArrayBuilder<Double> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        let stringBuilder = try ArrowArrayBuilders.loadStringArrayBuilder()
        let dateBuilder = try ArrowArrayBuilders.loadDate64ArrayBuilder()

        boolBuilder.append(false, true, false)
        int8Builder.append(10, 11, 12)
        int16Builder.append(20, 21, 22)
        int32Builder.append(30, 31, 32)
        int64Builder.append(40, 41, 42)
        uint8Builder.append(50, 51, 52)
        uint16Builder.append(60, 61, 62)
        uint32Builder.append(70, 71, 72)
        uint64Builder.append(80, 81, 82)
        floatBuilder.append(90.1, 91.1, 92.1)
        doubleBuilder.append(101.1, nil, nil)
        stringBuilder.append("test0", "test1", "test2")
        dateBuilder.append(date1, date1, date1)
        let result = RecordBatch.Builder()
            .addColumn("propBool", arrowArray: try boolBuilder.toHolder())
            .addColumn("propInt8", arrowArray: try int8Builder.toHolder())
            .addColumn("propInt16", arrowArray: try int16Builder.toHolder())
            .addColumn("propInt32", arrowArray: try int32Builder.toHolder())
            .addColumn("propInt64", arrowArray: try int64Builder.toHolder())
            .addColumn("propUInt8", arrowArray: try uint8Builder.toHolder())
            .addColumn("propUInt16", arrowArray: try uint16Builder.toHolder())
            .addColumn("propUInt32", arrowArray: try uint32Builder.toHolder())
            .addColumn("propUInt64", arrowArray: try uint64Builder.toHolder())
            .addColumn("propFloat", arrowArray: try floatBuilder.toHolder())
            .addColumn("propDouble", arrowArray: try doubleBuilder.toHolder())
            .addColumn("propString", arrowArray: try stringBuilder.toHolder())
            .addColumn("propDate", arrowArray: try dateBuilder.toHolder())
            .finish()
        switch result {
        case .success(let rb):
            let decoder = ArrowDecoder(rb)
            let testClasses = try decoder.decode(TestClass.self)
            for index in 0..<testClasses.count {
                let testClass = testClasses[index]
                XCTAssertEqual(testClass.propBool, index % 2 == 0 ? false : true)
                XCTAssertEqual(testClass.propInt8, Int8(index + 10))
                XCTAssertEqual(testClass.propInt16, Int16(index + 20))
                XCTAssertEqual(testClass.propInt32, Int32(index + 30))
                XCTAssertEqual(testClass.propInt64, Int64(index + 40))
                XCTAssertEqual(testClass.propUInt8, UInt8(index + 50))
                XCTAssertEqual(testClass.propUInt16, UInt16(index + 60))
                XCTAssertEqual(testClass.propUInt32, UInt32(index + 70))
                XCTAssertEqual(testClass.propUInt64, UInt64(index + 80))
                XCTAssertEqual(testClass.propFloat, Float(index) + 90.1)
                if index == 0 {
                    XCTAssertEqual(testClass.propDouble, 101.1)
                } else {
                    XCTAssertEqual(testClass.propDouble, nil)
                }
                XCTAssertEqual(testClass.propString, "test\(index)")
                XCTAssertEqual(testClass.propDate, date1)
            }
        case .failure(let err):
            throw err
        }
    }

    func testArrowSingleDecoderWithoutNull() throws {
        let int8Builder: NumberArrayBuilder<Int8> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        int8Builder.append(10, 11, 12)
        let result = RecordBatch.Builder()
            .addColumn("propInt8", arrowArray: try int8Builder.toHolder())
            .finish()
        switch result {
        case .success(let rb):
            let decoder = ArrowDecoder(rb)
            let testData = try decoder.decode(Int8?.self)
            for index in 0..<testData.count {
                let val: Int8? = testData[index]
                XCTAssertEqual(val!, Int8(index + 10))
            }
        case .failure(let err):
            throw err
        }
    }

    func testArrowSingleDecoderWithNull() throws {
        let int8WNilBuilder: NumberArrayBuilder<Int8> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        int8WNilBuilder.append(10, nil, 12, nil)
        let resultWNil = RecordBatch.Builder()
            .addColumn("propInt8", arrowArray: try int8WNilBuilder.toHolder())
            .finish()
        switch resultWNil {
        case .success(let rb):
            let decoder = ArrowDecoder(rb)
            let testData = try decoder.decode(Int8?.self)
            for index in 0..<testData.count {
                let val: Int8? = testData[index]
                if index % 2 == 1 {
                    XCTAssertNil(val)
                } else {
                    XCTAssertEqual(val!, Int8(index + 10))
                }
            }
        case .failure(let err):
            throw err
        }
    }

    func testArrowMapDecoderWithoutNull() throws {
        let int8Builder: NumberArrayBuilder<Int8> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        let stringBuilder = try ArrowArrayBuilders.loadStringArrayBuilder()
        int8Builder.append(10, 11, 12, 13)
        stringBuilder.append("test10", "test11", "test12", "test13")
        switch RecordBatch.Builder()
            .addColumn("propInt8", arrowArray: try int8Builder.toHolder())
            .addColumn("propString", arrowArray: try stringBuilder.toHolder())
            .finish() {
        case .success(let rb):
            let decoder = ArrowDecoder(rb)
            let testData = try decoder.decode([Int8: String].self)
            for data in testData {
                XCTAssertEqual("test\(data.key)", data.value)
            }
        case .failure(let err):
            throw err
        }

        switch RecordBatch.Builder()
            .addColumn("propString", arrowArray: try stringBuilder.toHolder())
            .addColumn("propInt8", arrowArray: try int8Builder.toHolder())
            .finish() {
        case .success(let rb):
            let decoder = ArrowDecoder(rb)
            let testData = try decoder.decode([String: Int8].self)
            for data in testData {
                XCTAssertEqual("test\(data.value)", data.key)
            }
        case .failure(let err):
            throw err
        }
    }

    func testArrowMapDecoderWithNull() throws {
        let int8Builder: NumberArrayBuilder<Int8> = try ArrowArrayBuilders.loadNumberArrayBuilder()
        let stringWNilBuilder = try ArrowArrayBuilders.loadStringArrayBuilder()
        int8Builder.append(10, 11, 12, 13)
        stringWNilBuilder.append(nil, "test11", nil, "test13")
        let resultWNil = RecordBatch.Builder()
            .addColumn("propInt8", arrowArray: try int8Builder.toHolder())
            .addColumn("propString", arrowArray: try stringWNilBuilder.toHolder())
            .finish()
        switch resultWNil {
        case .success(let rb):
            let decoder = ArrowDecoder(rb)
            let testData = try decoder.decode([Int8: String?].self)
            for data in testData {
                let str = data.value
                if data.key % 2 == 0 {
                    XCTAssertNil(str)
                } else {
                    XCTAssertEqual(str, "test\(data.key)")
                }
            }
        case .failure(let err):
            throw err
        }
    }

    func getArrayValue<T>(_ rb: RecordBatch, colIndex: Int, rowIndex: UInt) -> T? {
        let anyArray = rb.columns[colIndex].array
        return anyArray.asAny(UInt(rowIndex)) as? T
    }

    func testArrowKeyedEncoder() throws { // swiftlint:disable:this function_body_length
        var infos = [TestClass]()
        for index in 0..<10 {
            let tClass = TestClass()
            let offset = index * 12
            tClass.propBool = index % 2 == 0
            tClass.propInt8 = Int8(offset + 1)
            tClass.propInt16 = Int16(offset + 2)
            tClass.propInt32 = Int32(offset + 3)
            tClass.propInt64 = Int64(offset + 4)
            tClass.propUInt8 = UInt8(offset + 5)
            tClass.propUInt16 = UInt16(offset + 6)
            tClass.propUInt32 = UInt32(offset + 7)
            tClass.propUInt64 = UInt64(offset + 8)
            tClass.propFloat = Float(offset + 9)
            tClass.propDouble = index % 2 == 0 ? Double(offset + 10) : nil
            tClass.propString = "\(offset + 11)"
            tClass.propDate = Date.now
            infos.append(tClass)
        }

        let rb = try ArrowEncoder.encode(infos)!
        XCTAssertEqual(Int(rb.length), infos.count)
        XCTAssertEqual(rb.columns.count, 13)
        XCTAssertEqual(rb.columns[0].type.id, ArrowTypeId.boolean)
        XCTAssertEqual(rb.columns[1].type.id, ArrowTypeId.int8)
        XCTAssertEqual(rb.columns[2].type.id, ArrowTypeId.int16)
        XCTAssertEqual(rb.columns[3].type.id, ArrowTypeId.int32)
        XCTAssertEqual(rb.columns[4].type.id, ArrowTypeId.int64)
        XCTAssertEqual(rb.columns[5].type.id, ArrowTypeId.uint8)
        XCTAssertEqual(rb.columns[6].type.id, ArrowTypeId.uint16)
        XCTAssertEqual(rb.columns[7].type.id, ArrowTypeId.uint32)
        XCTAssertEqual(rb.columns[8].type.id, ArrowTypeId.uint64)
        XCTAssertEqual(rb.columns[9].type.id, ArrowTypeId.float)
        XCTAssertEqual(rb.columns[10].type.id, ArrowTypeId.double)
        XCTAssertEqual(rb.columns[11].type.id, ArrowTypeId.string)
        XCTAssertEqual(rb.columns[12].type.id, ArrowTypeId.date64)
        for index in 0..<10 {
            let offset = index * 12
            XCTAssertEqual(getArrayValue(rb, colIndex: 0, rowIndex: UInt(index)), index % 2 == 0)
            XCTAssertEqual(getArrayValue(rb, colIndex: 1, rowIndex: UInt(index)), Int8(offset + 1))
            XCTAssertEqual(getArrayValue(rb, colIndex: 2, rowIndex: UInt(index)), Int16(offset + 2))
            XCTAssertEqual(getArrayValue(rb, colIndex: 3, rowIndex: UInt(index)), Int32(offset + 3))
            XCTAssertEqual(getArrayValue(rb, colIndex: 4, rowIndex: UInt(index)), Int64(offset + 4))
            XCTAssertEqual(getArrayValue(rb, colIndex: 5, rowIndex: UInt(index)), UInt8(offset + 5))
            XCTAssertEqual(getArrayValue(rb, colIndex: 6, rowIndex: UInt(index)), UInt16(offset + 6))
            XCTAssertEqual(getArrayValue(rb, colIndex: 7, rowIndex: UInt(index)), UInt32(offset + 7))
            XCTAssertEqual(getArrayValue(rb, colIndex: 8, rowIndex: UInt(index)), UInt64(offset + 8))
            XCTAssertEqual(getArrayValue(rb, colIndex: 9, rowIndex: UInt(index)), Float(offset + 9))
            if index % 2 == 0 {
                XCTAssertEqual(getArrayValue(rb, colIndex: 10, rowIndex: UInt(index)), Double(offset + 10))
            } else {
                XCTAssertEqual(getArrayValue(rb, colIndex: 10, rowIndex: UInt(index)), Double?(nil))
            }

            XCTAssertEqual(getArrayValue(rb, colIndex: 11, rowIndex: UInt(index)), String(offset + 11))
        }
    }

    func testArrowUnkeyedEncoder() throws {
        var testMap = [Int8: String?]()
        for index in 0..<10 {
            testMap[Int8(index)] = "test\(index)"
        }

        let rb = try ArrowEncoder.encode(testMap)
        XCTAssertEqual(Int(rb.length), testMap.count)
        XCTAssertEqual(rb.columns.count, 2)
        XCTAssertEqual(rb.columns[0].type.id, ArrowTypeId.int8)
        XCTAssertEqual(rb.columns[1].type.id, ArrowTypeId.string)
        for index in 0..<10 {
            let key: Int8 = getArrayValue(rb, colIndex: 0, rowIndex: UInt(index))!
            let value: String = getArrayValue(rb, colIndex: 1, rowIndex: UInt(index))!
            XCTAssertEqual("test\(key)", value)
        }
    }

    func testArrowSingleEncoder() throws {
        var intArray = [Int32?]()
        for index in 0..<100 {
            if index == 10 {
                intArray.append(nil)
            } else {
                intArray.append(Int32(index))
            }
        }

        let rb = try ArrowEncoder.encode(intArray)!
        XCTAssertEqual(Int(rb.length), intArray.count)
        XCTAssertEqual(rb.columns.count, 1)
        XCTAssertEqual(rb.columns[0].type.id, ArrowTypeId.int32)
        for index in 0..<100 {
            if index == 10 {
                let anyArray = rb.columns[0].array
                XCTAssertNil(anyArray.asAny(UInt(index)))
            } else {
                XCTAssertEqual(getArrayValue(rb, colIndex: 0, rowIndex: UInt(index)), Int32(index))
            }
        }
    }

    // MARK: - Large Array Encoding Tests (Buffer Boundary Coverage)

    /// Test encoding a large array that triggers multiple buffer resizes
    func testArrowEncoderLargeInt64Array() throws {
        var largeArray = [Int64?]()
        let count = 1000

        for index in 0..<count {
            if index % 100 == 0 {
                largeArray.append(nil)  // Add nulls at regular intervals
            } else {
                largeArray.append(Int64(index))
            }
        }

        let rb = try ArrowEncoder.encode(largeArray)!
        XCTAssertEqual(Int(rb.length), count)
        XCTAssertEqual(rb.columns.count, 1)
        XCTAssertEqual(rb.columns[0].type.id, ArrowTypeId.int64)

        for index in 0..<count {
            if index % 100 == 0 {
                let anyArray = rb.columns[0].array
                XCTAssertNil(anyArray.asAny(UInt(index)))
            } else {
                XCTAssertEqual(getArrayValue(rb, colIndex: 0, rowIndex: UInt(index)), Int64(index))
            }
        }
    }

    /// Test encoding a large string array that exercises variable-length buffer resizing
    func testArrowEncoderLargeStringArray() throws {
        var stringArray = [String?]()
        let count = 500

        for index in 0..<count {
            if index % 50 == 0 {
                stringArray.append(nil)
            } else {
                // Use varying string lengths to stress the variable buffer
                stringArray.append("String value #\(index) with some additional content to vary length: \(String(repeating: "x", count: index % 20))")
            }
        }

        let rb = try ArrowEncoder.encode(stringArray)!
        XCTAssertEqual(Int(rb.length), count)
        XCTAssertEqual(rb.columns.count, 1)
        XCTAssertEqual(rb.columns[0].type.id, ArrowTypeId.string)

        for index in 0..<count {
            if index % 50 == 0 {
                let anyArray = rb.columns[0].array
                XCTAssertNil(anyArray.asAny(UInt(index)))
            } else {
                let expected = "String value #\(index) with some additional content to vary length: \(String(repeating: "x", count: index % 20))"
                XCTAssertEqual(getArrayValue(rb, colIndex: 0, rowIndex: UInt(index)), expected)
            }
        }
    }

    /// Test encoding a large boolean array (bitmap storage boundary test)
    func testArrowEncoderLargeBoolArray() throws {
        var boolArray = [Bool?]()
        let count = 1000

        for index in 0..<count {
            if index % 8 == 7 {  // Null at last bit of each byte
                boolArray.append(nil)
            } else {
                boolArray.append(index % 2 == 0)
            }
        }

        let rb = try ArrowEncoder.encode(boolArray)!
        XCTAssertEqual(Int(rb.length), count)
        XCTAssertEqual(rb.columns.count, 1)
        XCTAssertEqual(rb.columns[0].type.id, ArrowTypeId.boolean)

        let anyArray = rb.columns[0].array
        for index in 0..<count {
            if index % 8 == 7 {
                XCTAssertNil(anyArray.asAny(UInt(index)))
            } else {
                let actual = anyArray.asAny(UInt(index)) as? Bool
                XCTAssertNotNil(actual, "Expected non-nil Bool at index \(index)")
                XCTAssertEqual(actual, index % 2 == 0, "Mismatch at index \(index)")
            }
        }
    }

    /// Test encoding a large keyed struct array that exercises multiple column types
    func testArrowEncoderLargeKeyedArray() throws {
        var infos = [TestClass]()
        let count = 500

        for index in 0..<count {
            let tClass = TestClass()
            tClass.propBool = index % 2 == 0
            tClass.propInt8 = Int8(truncatingIfNeeded: index)
            tClass.propInt16 = Int16(truncatingIfNeeded: index)
            tClass.propInt32 = Int32(index)
            tClass.propInt64 = Int64(index)
            tClass.propUInt8 = UInt8(truncatingIfNeeded: index)
            tClass.propUInt16 = UInt16(truncatingIfNeeded: index)
            tClass.propUInt32 = UInt32(index)
            tClass.propUInt64 = UInt64(index)
            tClass.propFloat = Float(index)
            tClass.propDouble = index % 10 == 0 ? nil : Double(index)
            tClass.propString = "Row \(index)"
            tClass.propDate = Date(timeIntervalSince1970: Double(index * 86400))
            infos.append(tClass)
        }

        let rb = try ArrowEncoder.encode(infos)!
        XCTAssertEqual(Int(rb.length), count)
        XCTAssertEqual(rb.columns.count, 13)

        // Verify a few values to ensure encoding was correct
        for index in stride(from: 0, to: count, by: 50) {
            XCTAssertEqual(getArrayValue(rb, colIndex: 3, rowIndex: UInt(index)), Int32(index))
            XCTAssertEqual(getArrayValue(rb, colIndex: 11, rowIndex: UInt(index)), "Row \(index)")
        }
    }

    /// Test encoding with all nulls to exercise null bitmap edge cases
    func testArrowEncoderAllNullsArray() throws {
        var nullArray = [Int64?]()
        let count = 256  // Multiple of 8 to test byte boundaries

        for _ in 0..<count {
            nullArray.append(nil)
        }

        let rb = try ArrowEncoder.encode(nullArray)!
        XCTAssertEqual(Int(rb.length), count)
        XCTAssertEqual(rb.columns[0].nullCount, UInt(count))

        for index in 0..<count {
            let anyArray = rb.columns[0].array
            XCTAssertNil(anyArray.asAny(UInt(index)))
        }
    }

    /// Test encoding with nulls at specific byte boundaries
    func testArrowEncoderNullsAtByteBoundaries() throws {
        var array = [UInt8?]()
        let count = 100

        // Place nulls at positions 0, 8, 16, 24... (start of each byte)
        // and at positions 7, 15, 23, 31... (end of each byte)
        for index in 0..<count {
            if index % 8 == 0 || index % 8 == 7 {
                array.append(nil)
            } else {
                array.append(UInt8(truncatingIfNeeded: index))
            }
        }

        let rb = try ArrowEncoder.encode(array)!
        XCTAssertEqual(Int(rb.length), count)

        for index in 0..<count {
            if index % 8 == 0 || index % 8 == 7 {
                let anyArray = rb.columns[0].array
                XCTAssertNil(anyArray.asAny(UInt(index)))
            } else {
                XCTAssertEqual(getArrayValue(rb, colIndex: 0, rowIndex: UInt(index)), UInt8(truncatingIfNeeded: index))
            }
        }
    }

    /// Test encoding Date array with nulls
    func testArrowEncoderLargeDateArray() throws {
        var dateArray = [Date?]()
        let count = 300
        let baseDate = Date(timeIntervalSince1970: 0)

        for index in 0..<count {
            if index % 30 == 0 {
                dateArray.append(nil)
            } else {
                dateArray.append(Date(timeInterval: Double(index * 86400), since: baseDate))
            }
        }

        let rb = try ArrowEncoder.encode(dateArray)!
        XCTAssertEqual(Int(rb.length), count)
        XCTAssertEqual(rb.columns[0].type.id, ArrowTypeId.date64)

        for index in 0..<count {
            if index % 30 == 0 {
                let anyArray = rb.columns[0].array
                XCTAssertNil(anyArray.asAny(UInt(index)))
            }
        }
    }

    /// Test encoding Float array with boundary conditions
    func testArrowEncoderLargeFloatArray() throws {
        var floatArray = [Float?]()
        let count = 500

        for index in 0..<count {
            if index % 8 == 0 {
                floatArray.append(nil)
            } else {
                floatArray.append(Float(index) * 0.1)
            }
        }

        let rb = try ArrowEncoder.encode(floatArray)!
        XCTAssertEqual(Int(rb.length), count)
        XCTAssertEqual(rb.columns[0].type.id, ArrowTypeId.float)

        for index in stride(from: 1, to: count, by: 10) {
            if index % 8 != 0 {
                let expected = Float(index) * 0.1
                let actual: Float? = getArrayValue(rb, colIndex: 0, rowIndex: UInt(index))
                XCTAssertEqual(actual!, expected, accuracy: 0.0001)
            }
        }
    }

    /// Test encoding Double array with boundary conditions
    func testArrowEncoderLargeDoubleArray() throws {
        var doubleArray = [Double?]()
        let count = 500

        for index in 0..<count {
            if index % 16 == 0 {
                doubleArray.append(nil)
            } else {
                doubleArray.append(Double(index) * 0.001)
            }
        }

        let rb = try ArrowEncoder.encode(doubleArray)!
        XCTAssertEqual(Int(rb.length), count)
        XCTAssertEqual(rb.columns[0].type.id, ArrowTypeId.double)

        for index in stride(from: 1, to: count, by: 17) {
            if index % 16 != 0 {
                let expected = Double(index) * 0.001
                let actual: Double? = getArrayValue(rb, colIndex: 0, rowIndex: UInt(index))
                XCTAssertEqual(actual!, expected, accuracy: 0.0000001)
            }
        }
    }
}
