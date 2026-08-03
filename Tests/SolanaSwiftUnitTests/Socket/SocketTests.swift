import Combine
import SolanaSwift
import Testing
import Foundation

@Suite(.serialized) struct SocketTests {
    var socket: Socket

    init() {
        socket = Socket(url: SocketTestsHelper.url)
    }

    @Test func testSocketEvents() async throws {
        let delegate = MockSocketDelegate()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            delegate.onDisconnected = {
                continuation.resume()
            }

            delegate.onConected = {
                Task {
                    _ = try await socket.accountSubscribe(publickey: "fasdfasdf") // native address

                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    _ = try await socket.accountSubscribe(publickey: "fasdfasdf") // token address

                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    _ = try await socket.signatureSubscribe(signature: "fasdfjisf")

                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    _ = try await socket.logsSubscribe(mentions: [""])

                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    _ = try await socket.programSubscribe(publickey: "")

                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    socket.disconnect()
                }
            }

            delegate.onSubscribed = { _, id in
                #expect("ADFB8971-4473-4B16-A8BC-63EFD2F1FC8E" == id)
            }
            delegate.onNativeAccountNotification = { notification in
                #expect(notification.lamports == 41_083_620)
            }
            delegate.onTokenAccountNotification = { notification in
                #expect(notification.tokenAmount?.amount == "390000101")
            }
            delegate.onSignatureNotification = { notification in
                #expect(notification.isConfirmed == true)
            }
            delegate.onLogsNotification = { notification in
                #expect(notification.logs?.last == "BPF program 83astBRguLMdt2h5U1Tpdq5tjFoJ6noeGwaY3mDLVcri success")
            }
            delegate.onProgramNotification = { notification in
                #expect(notification.subscription == 24040)
            }

            socket.delegate = delegate
            socket.connect()
        }
    }
}

// MARK: - Mocks

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
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [self] in
            self.delegate?.urlSession?(.shared, webSocketTask: self.mockWSTask, didOpenWithProtocol: nil)
        }
    }

    func makeTask(with _: URL) -> WebSocketTask { MockSocketTask() }
}

private final class MockSocketTask: WebSocketTask, @unchecked Sendable {
    private var keySubject = PassthroughSubject<String, Never>()
    private var subscriptions = [AnyCancellable]()
    private var nativeEmitted: Bool = false

    func resume() {}
    func cancel(with _: URLSessionWebSocketTask.CloseCode, reason _: Data?) {}

    func send(_ message: WebSocketMessage) async throws {
        struct RequestAPI: Decodable {
            let id: String; let method: String; let jsonrpc: String
        }
        switch message {
        case .string: break
        case .data(let data):
            let requestAPI = try JSONDecoder().decode(RequestAPI.self, from: data)
            let method = SocketMethod(rawValue: requestAPI.method)!
            switch method {
            case .init(.account, .subscribe):
                keySubject.send("subscriptionNotification")
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [self] in
                    self.keySubject.send("accountNotification#\(self.nativeEmitted ? "Token" : "Native")")
                    self.nativeEmitted = true
                }
            case .init(.account, .unsubscribe):   keySubject.send("unsubscriptionNotification")
            case .init(.signature, .subscribe):
                keySubject.send("subscriptionNotification")
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [self] in
                    self.keySubject.send("signatureNotification")
                }
            case .init(.signature, .unsubscribe): keySubject.send("unsubscriptionNotification")
            case .init(.logs, .subscribe):
                keySubject.send("subscriptionNotification")
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [self] in
                    self.keySubject.send("logsNotification")
                }
            case .init(.logs, .unsubscribe):      keySubject.send("unsubscriptionNotification")
            case .init(.program, .subscribe):
                keySubject.send("subscriptionNotification")
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [self] in
                    self.keySubject.send("programNotification")
                }
            case .init(.program, .unsubscribe):   keySubject.send("unsubscriptionNotification")
            case .init(.slot, .subscribe):
                keySubject.send("subscriptionNotification")
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [self] in
                    self.keySubject.send("slotNotification")
                }
            case .init(.slot, .unsubscribe):      keySubject.send("unsubscriptionNotification")
            default: break
            }
        @unknown default: fatalError()
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

final class MockSocketDelegate: SolanaSocketEventsDelegate, @unchecked Sendable {
    var onConected: (() -> Void)?
    var onDisconnected: (() -> Void)?
    var onNativeAccountNotification: ((SocketNativeAccountNotification) -> Void)?
    var onTokenAccountNotification: ((SocketTokenAccountNotification) -> Void)?
    var onSignatureNotification: ((SocketSignatureNotification) -> Void)?
    var onLogsNotification: ((SocketLogsNotification) -> Void)?
    var onProgramNotification: ((SocketProgramAccountNotification) -> Void)?
    var onSubscribed: ((UInt64, String) -> Void)?
    var onUnsubscribed: ((String) -> Void)?

    func connected() { onConected?() }
    func disconnected(reason _: String, code _: Int) { onDisconnected?() }
    func nativeAccountNotification(notification: SocketNativeAccountNotification) { onNativeAccountNotification?(notification) }
    func tokenAccountNotification(notification: SocketTokenAccountNotification) { onTokenAccountNotification?(notification) }
    func signatureNotification(notification: SocketSignatureNotification) { onSignatureNotification?(notification) }
    func logsNotification(notification: SocketLogsNotification) { onLogsNotification?(notification) }
    func programNotification(notification: SocketProgramAccountNotification) { onProgramNotification?(notification) }
    func subscribed(socketId: UInt64, id: String) { onSubscribed?(socketId, id) }
    func unsubscribed(id: String) { onUnsubscribed?(id) }
    func error(error _: Error?) {}
}
