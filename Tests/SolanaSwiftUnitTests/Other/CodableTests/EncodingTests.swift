import SolanaSwift
import Foundation
import Testing

struct EncodingTests {
    @Test func encodingBytesLength() throws {
        #expect(Data([0]) == Data.encodeLength(0))
        #expect(Data([1]) == Data.encodeLength(1))
        #expect(Data([5]) == Data.encodeLength(5))
        #expect(Data([0x7F]) == Data.encodeLength(127))
        #expect(Data([128, 1]) == Data.encodeLength(128))
        #expect(Data([0xFF, 0x01]) == Data.encodeLength(255))
        #expect(Data([0x80, 0x02]) == Data.encodeLength(256))
        #expect(Data([0xFF, 0xFF, 0x01]) == Data.encodeLength(32767))
        #expect(Data([0x80, 0x80, 0x80, 0x01]) == Data.encodeLength(2_097_152))
    }

    @Test func givenBytes_whenDecodeLength_thenReturnsExpectedLength() throws {
        // given
        var bytes = Data([5, 3, 1, 2, 3, 7, 8, 5, 4])

        // when
        let result = bytes.decodeLength()

        // then
        #expect(result == 5)
    }

    @Test func givenBytes_whenDecodeLengthTwice_thenReturnsExpectedLengths() throws {
        // given
        var bytes = Data([5, 0xF3, 1, 2, 3, 7, 8, 5, 4])

        // when
        let result1 = bytes.decodeLength()
        let result2 = bytes.decodeLength()

        // then
        #expect(result1 == 5)
        #expect(result2 == 0xF3)
    }

    @Test func givenBytes_whenDecodeLength_thenRemovesFirstByte() throws {
        // given
        var bytes = Data([5, 1, 2, 3, 7, 8, 3, 4])
        let numberOfBytes = bytes.count

        // when
        _ = bytes.decodeLength()

        // then
        #expect(!(bytes.contains(5)))
        #expect(bytes.count == numberOfBytes - 1)
    }

    @Test func givenZeroBytes_whenDecodeLength_thenReturnsZero() throws {
        // given
        var bytes = Data()

        // when
        let result = bytes.decodeLength()

        // then
        #expect(result == 0)
    }
}
