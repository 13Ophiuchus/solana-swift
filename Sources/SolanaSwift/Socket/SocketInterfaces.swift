import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The abstract websocket task provider, default is URLSession
public protocol WebSocketTaskProvider: AnyObject {
    func createWebSocketTask(with url: URL) -> WebSocketTask
}

#if canImport(FoundationNetworking) || canImport(Darwin)
extension URLSession: WebSocketTaskProvider {
    public func createWebSocketTask(with url: URL) -> WebSocketTask {
        webSocketTask(with: url)
    }
}
#endif

/// Abstract websocket task, default is URLSessionWebSocketTask
public enum WebSocketMessage {
    case string(String)
    case data(Data)
}

public protocol WebSocketTask {
    func resume()
    func cancel()
    func send(_ message: WebSocketMessage) async throws
    func receive() async throws -> WebSocketMessage
    func sendPing(pongReceiveHandler: @escaping @Sendable (Error?) -> Void)
}

#if canImport(FoundationNetworking) || canImport(Darwin)
extension URLSessionWebSocketTask: WebSocketTask {
    public func send(_ message: WebSocketMessage) async throws {
        switch message {
        case .string(let text): try await send(.string(text))
        case .data(let data):   try await send(.data(data))
        }
    }

    public func receive() async throws -> WebSocketMessage {
        let raw = try await receive()
        switch raw {
        case .string(let text): return .string(text)
        case .data(let data):   return .data(data)
        @unknown default:       throw URLError(.badServerResponse)
        }
    }
}
#endif

/// Delegate for listening socket's events
public protocol SolanaSocketEventsDelegate: AnyObject {
    func connected()
    func nativeAccountNotification(notification: SocketNativeAccountNotification)
    func tokenAccountNotification(notification: SocketTokenAccountNotification)
    func programNotification(notification: SocketProgramAccountNotification)
    func signatureNotification(notification: SocketSignatureNotification)
    func logsNotification(notification: SocketLogsNotification)
    func unsubscribed(id: String)
    func subscribed(socketId: UInt64, id: String)
    func disconnected(reason: String, code: Int)
    func error(error: Error?)
}

public extension SolanaSocketEventsDelegate {
    func connected() {}

    func nativeAccountNotification(notification _: SocketNativeAccountNotification) {}

    func tokenAccountNotification(notification _: SocketTokenAccountNotification) {}

    func programNotification(notification _: SocketProgramAccountNotification) {}

    func signatureNotification(notification _: SocketSignatureNotification) {}

    func logsNotification(notification _: SocketLogsNotification) {}

    func unsubscribed(id _: String) {}

    func subscribed(socketId _: UInt64, id _: String) {}

    func disconnected(reason _: String, code _: Int) {}

    func error(error _: Error?) {}
}
