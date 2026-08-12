import SolanaSwift
import Testing


struct SocketDecodingTests {
    @Test
    func testDecodingSocketSubscription() throws {
        let string = SocketTestsHelper.emittingEvents["subscriptionNotification"]!
        let result = try JSONDecoder().decode(SocketSubscriptionResponse.self, from: string.data(using: .utf8)!)

        #expect(result.id == "ADFB8971-4473-4B16-A8BC-63EFD2F1FC8E")
        #expect(result.result == 22_529_999)
    }

    @Test
    func testDecodingSocketUnsubscription() throws {
        let string = SocketTestsHelper.emittingEvents["unsubscriptionNotification"]!
        let result = try JSONDecoder().decode(SocketUnsubscriptionResponse.self, from: string.data(using: .utf8)!)

        #expect(result.id == "ADFB8971-4473-4B16-A8BC-63EFD2F1FC8E")
        #expect(result.result == true)
    }

    @Test
    func testDecodingSOLAccountNotification() throws {
        let string = SocketTestsHelper.emittingEvents["accountNotification#Native"]!
        let result = try JSONDecoder().decode(SocketNativeAccountNotification.self, from: string.data(using: .utf8)!)

        #expect(result.method == "accountNotification")
        #expect(result.lamports == 41_083_620)
    }

    @Test
    func testDecodingProgramNotification() throws {
        let string = SocketTestsHelper.emittingEvents["programNotification"]!
        let result = try JSONDecoder().decode(SocketProgramAccountNotification.self, from: string.data(using: .utf8)!)

        #expect(result.method == "programNotification")
        #expect(result.subscription == 24040)
    }

    @Test
    func testDecodingTokenAccountNotification() throws {
        let string = SocketTestsHelper.emittingEvents["accountNotification#Token"]!
        let result = try JSONDecoder().decode(SocketTokenAccountNotification.self, from: string.data(using: .utf8)!)

        #expect(result.method == "accountNotification")
        #expect(result.tokenAmount?.amount == "390000101")
    }

    @Test
    func testDecodingSignatureNotification() throws {
        let string = SocketTestsHelper.emittingEvents["signatureNotification"]!
        let result = try JSONDecoder().decode(SocketSignatureNotification.self, from: string.data(using: .utf8)!)

        #expect(result.method == "signatureNotification")
        #expect(result.isConfirmed == true)
    }

    @Test
    func testDecodingLogsNotification() throws {
        let string = SocketTestsHelper.emittingEvents["logsNotification"]!
        let result = try JSONDecoder().decode(SocketLogsNotification.self, from: string.data(using: .utf8)!)

        #expect(result.method == "logsNotification")
        #expect(result.logs?.first == "BPF program 83astBRguLMdt2h5U1Tpdq5tjFoJ6noeGwaY3mDLVcri success")
    }
}
