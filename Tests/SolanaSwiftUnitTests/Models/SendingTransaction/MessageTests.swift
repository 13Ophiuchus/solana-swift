@testable import SolanaSwift
import Foundation
import Testing

struct MessageTests {
    @Test func givenRawMessage_whenFrom_thenReturnsExpectedMessage() throws {
        // given
        let expectedMessge = Message.StubFactory.makeSignedWithInstructions()
        // Base64-encoded message containing two instructions some accounts and signers.
        let base64 = "AgADBSxW7AhRsOx/s4ecSWrcic9vfD5asiW3d287f4uUsKeb7oz2DHCBpIZPzhc3kCRgNxVedAceB6yMl6hi5hPA1OkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAan1RcZLFxRIYzJTD1K8X9Y2u4Im6H9ROPb2YoAAAAABt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKkHQqjYoL28uYrjQx7GX6lt1z+mBGwH0eqdU9JknzvwfQICAgABNAAAAADwHR8AAAAAAKUAAAAAAAAABt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKkEAgADQwAALFbsCFGw7H+zh5xJatyJz298PlqyJbd3bzt/i5Swp5sAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        let rawMessage = try #require(Data(base64Encoded: base64))

        // when
        let result = try Message.from(data: rawMessage)

        // then
        #expect(result.header == expectedMessge.header)
        #expect(result.recentBlockhash == expectedMessge.recentBlockhash)
        #expect(result.accountKeys == expectedMessge.accountKeys)
        zip(result.instructions, expectedMessge.instructions).forEach {
            #expect($0.accounts == $1.accounts)
            #expect($0.data == $1.data)
            #expect($0.dataLength == $1.dataLength)
            #expect($0.keyIndicesCount == $1.keyIndicesCount)
            #expect($0.serializedData == $1.serializedData)
        }
    }
}
