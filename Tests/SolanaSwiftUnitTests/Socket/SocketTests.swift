import Combine
import SolanaSwift
import XCTest

class SocketTests: XCTestCase, @unchecked Sendable {
    var socket: Socket!

    override func setUpWithError() throws {
        socket = Socket(
            url: SocketTestsHelper.url
        )
    }

    override func tearDownWithError() throws {
        socket.disconnect()
        socket = nil
    }

    func testSocketEvents() async throws {
        let expectation = XCTestExpectation()
        let delegate = MockSocketDelegate()
        delegate.onConected = {
            Task { [self] in
                let _ = try await self.socket.accountSubscribe(publickey: "fasdfasdf") // native address

                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    Task { [self] in
                        try await self.socket.accountSubscribe(publickey: "fasdfasdf") // token address
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    Task { [self] in
                        try await self.socket.signatureSubscribe(signature: "fasdfjisf") // signature status
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    Task { [self] in
                        try await self.socket.logsSubscribe(mentions: [""]) // signature status
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {
                    Task { [self] in
                        try await self.socket.programSubscribe(publickey: "") // signature status
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                    Task { [self] in
                        self.socket.disconnect()
                    }
                }
            }
        }
        delegate.onSubscribed = { _, id in
            XCTAssertEqual("ADFB8971-4473-4B16-A8BC-63EFD2F1FC8E", id)
        }
        delegate.onNativeAccountNotification = { notification in
            XCTAssertEqual(notification.lamports, 41_083_620)
        }
        delegate.onTokenAccountNotification = { notification in
            XCTAssertEqual(notification.tokenAmount?.amount, "390000101")
        }
        delegate.onSignatureNotification = { notification in
            XCTAssertEqual(notification.isConfirmed, true)
        }
        delegate.onLogsNotification = { notification in
            XCTAssertEqual(notification.logs?.last, "BPF program 83astBRguLMdt2h5U1Tpdq5tjFoJ6noeGwaY3mDLVcri success")
        }
        delegate.onProgramNotification = { notification in
            XCTAssertEqual(notification.subscription, 24040)
        }
        delegate.onDisconnected = {
            expectation.fulfill()
        }

        socket.delegate = delegate
        socket.connect()
        await fulfillment(of: [expectation], timeout: 20.0)
    }
}

private final class MockSocketTaskProvider: WebSocketTaskProvider, @unchecked Sendable {
    let delegate: URLSessionWebSocketDelegate?
    let mockSession = URLSession(configuration: .default)
    private lazy var mockWSTask = mockSession.webSocketTask(with: SocketTestsHelper.url)

    required init(
        configuration _: URLSessionConfiguration,
        delegate: URLSessionDelegate?,
        delegateQueue _: OperationQueue?
    ) {
        self.delegate = delegate as? URLSessionWebSocketDelegate

        // connect after 0.3 sec
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            self.delegate?.urlSession?(.shared, webSocketTask: self.mockWSTask, didOpenWithProtocol: nil)
        }
    }

    func makeTask(with _: URL) -> WebSocketTask {
        MockSocketTask()
    }
}

private final class MockSocketTask: WebSocketTask, @unchecked Sendable {
    private var keySubject = PassthroughSubject<String, Never>()
    private var subscriptions = [AnyCancellable]()
    private var nativeEmitted: Bool = false

    func resume() {
        // do nothing
    }

    func cancel(with _: URLSessionWebSocketTask.CloseCode, reason _: Data?) {
        // do nothing
    }

    func send(_ message: WebSocketMessage) async throws {
        struct RequestAPI: Decodable {
            let id: String
            let method: String
            let jsonrpc: String
        }

        switch message {
        case .string:
            break
        case .data(let data):
            let requestAPI = try JSONDecoder().decode(RequestAPI.self, from: data)
            let method = SocketMethod(rawValue: requestAPI.method)!
            switch method {
            case .init(.account, .subscribe):
                keySubject.send("subscriptionNotification")
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                    self.keySubject.send("accountNotification#\(self.nativeEmitted ? "Token" : "Native")")
                    self.nativeEmitted = true
                }
            case .init(.account, .unsubscribe):
                keySubject.send("unsubscriptionNotification")
            case .init(.signature, .subscribe):
                keySubject.send("subscriptionNotification")
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                    self.keySubject.send("signatureNotification")
                }
            case .init(.signature, .unsubscribe):
                keySubject.send("unsubscriptionNotification")
            case .init(.logs, .subscribe):
                keySubject.send("subscriptionNotification")
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                    self.keySubject.send("logsNotification")
                }
            case .init(.logs, .unsubscribe):
                keySubject.send("unsubscriptionNotification")
            case .init(.program, .subscribe):
                keySubject.send("subscriptionNotification")

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                    self.keySubject.send("programNotification")
                }
            case .init(.program, .unsubscribe):
                keySubject.send("unsubscriptionNotification")
            case .init(.slot, .subscribe):
                keySubject.send("subscriptionNotification")

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                    self.keySubject.send("slotNotification")
                }
            case .init(.slot, .unsubscribe):
                keySubject.send("unsubscriptionNotification")
            default:
                break
            }
        @unknown default:
            fatalError()
        }
    }

    func receive() async throws -> WebSocketMessage {
        let key = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            self.keySubject.first().sink { key in
                continuation.resume(returning: key)
            }.store(in: &subscriptions)
        }
        return .string(SocketTestsHelper.emittingEvents[key]!)
    }

    func sendPing(pongReceiveHandler _: @escaping @Sendable (Error?) -> Void) {
        debugPrint("Pong!!!")
    }
}

class MockSocketDelegate: SolanaSocketEventsDelegate, @unchecked Sendable {
    var onConected: (() -> Void)?
    var onDisconnected: (() -> Void)?
    var onNativeAccountNotification: ((SocketNativeAccountNotification) -> Void)?
    var onTokenAccountNotification: ((SocketTokenAccountNotification) -> Void)?
    var onSignatureNotification: ((SocketSignatureNotification) -> Void)?
    var onLogsNotification: ((SocketLogsNotification) -> Void)?
    var onProgramNotification: ((SocketProgramAccountNotification) -> Void)?
    var onSubscribed: ((UInt64, String) -> Void)?
    var onUnsubscribed: ((String) -> Void)?

    func connected() {
        onConected?()
    }

    func nativeAccountNotification(notification: SocketNativeAccountNotification) {
        onNativeAccountNotification?(notification)
    }

    func tokenAccountNotification(notification: SocketTokenAccountNotification) {
        onTokenAccountNotification?(notification)
    }

    func signatureNotification(notification: SocketSignatureNotification) {
        onSignatureNotification?(notification)
    }

    func logsNotification(notification: SocketLogsNotification) {
        onLogsNotification?(notification)
    }

    func programNotification(notification: SocketProgramAccountNotification) {
        onProgramNotification?(notification)
    }

    func subscribed(socketId: UInt64, id: String) {
        onSubscribed?(socketId, id)
    }

    func unsubscribed(id: String) {
        onUnsubscribed?(id)
    }

    func disconnected(reason _: String, code _: Int) {
        onDisconnected?()
    }

    func error(error _: Error?) {}
}
