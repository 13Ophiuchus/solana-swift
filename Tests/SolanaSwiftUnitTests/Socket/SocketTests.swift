import Combine
import SolanaSwift
import Testing
import Foundation

@MainActor
final class SocketTests {
    var socket: Socket!

    init() {
        socket = Socket(
            url: SocketTestsHelper.url,
            socketTaskProviderType: MockSocketTaskProvider.self
        )
    }

    deinit {
        socket.disconnect()
        socket = nil
    }

    @Test @MainActor func socketEvents() async throws {
        let delegate = MockSocketDelegate()
        let socket = self.socket!

        final class ResumeGuard: @unchecked Sendable {
            private let lock = NSLock()
            private var didResume = false
            func runOnce(_ block: () -> Void) {
                lock.lock()
                defer { lock.unlock() }
                guard !didResume else { return }
                didResume = true
                block()
            }
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let resumeGuard = ResumeGuard()
            func resumeOnce(_ block: () -> Void) {
                resumeGuard.runOnce(block)
            }

            delegate.onConected = {
                Task {
                    let _ = try await socket.accountSubscribe(publickey: "fasdfasdf") // native address

                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        Task {
                            try await socket.accountSubscribe(publickey: "fasdfasdf") // token address
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                        Task {
                            try await socket.signatureSubscribe(signature: "fasdfjisf") // signature status
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                        Task {
                            try await socket.logsSubscribe(mentions: [""]) // signature status
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {
                        Task {
                            try await socket.programSubscribe(publickey: "") // signature status
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                        Task {
                            socket.disconnect()
                        }
                    }
                }
            }
            delegate.onSubscribed = { _, id in
                #expect(id == "ADFB8971-4473-4B16-A8BC-63EFD2F1FC8E")
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
            delegate.onDisconnected = {
                resumeOnce {
                    continuation.resume()
                }
            }

            socket.delegate = delegate
            socket.connect()

            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(20)) {
                resumeOnce {
                    continuation.resume(throwing: SocketTestTimeoutError())
                }
            }
        }
    }
}

private struct SocketTestTimeoutError: Error {}

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

    func createWebSocketTask(with _: URL) -> WebSocketTask {
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

    func cancel() {
        // do nothing
    }

    func send(_ message: URLSessionWebSocketTask.Message) async throws {
        struct RequestAPI: Decodable {
            let id: String
            let method: String
            let jsonrpc: String
        }

        switch message {
        case .string:
            break
        case let .data(data):
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
            break
        @unknown default:
            fatalError()
        }
    }

    func receive() async throws -> URLSessionWebSocketTask.Message {
        let key = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            self.keySubject.first().sink { key in
                continuation.resume(returning: key)
            }.store(in: &subscriptions)
        }
        return .string(SocketTestsHelper.emittingEvents[key]!)
    }

    func sendPing(pongReceiveHandler _: @escaping (Error?) -> Void) {
        debugPrint("Pong!!!")
    }
}

class MockSocketDelegate: SolanaSocketEventsDelegate {
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
