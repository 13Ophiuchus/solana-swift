import Foundation

extension WebSocketTask {
    /// Bridges the callback-based sendPing into async/await with a 10-second timeout.
    func sendPingAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.sendPing { error in
                if let error {
                    continuation.resume(throwing: WebSocketError.connectionFailed(underlying: error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Sends a ping and throws `WebSocketError.pingTimeout` if no pong arrives within `timeout`.
    func sendPingWithTimeout(_ timeout: Duration = .seconds(10)) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.sendPingAsync() }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw WebSocketError.pingTimeout
            }
            try await group.next()
            group.cancelAll()
        }
    }
}
