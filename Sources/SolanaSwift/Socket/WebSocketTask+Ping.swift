import Foundation

extension WebSocketTask {
    func sendPingAsync() async throws {
        // Use a nonisolated(unsafe) flag to guarantee the continuation
        // is resumed exactly once even if the pong handler fires multiple times
        // (e.g. connection abort fires both the error path and the normal path).
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let box = OnceBox<Result<Void, Error>>()
            self.sendPing { error in
                guard box.trySet() else { return }   // drop any subsequent call
                if let error {
                    continuation.resume(throwing: WebSocketError.connectionFailed(underlying: error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func sendPingWithTimeout(_ timeout: TimeInterval = 10) async throws {
        let ping: @Sendable () async throws -> Void = { [weak self] in
            guard let self else { return }
            try await self.sendPingAsync()
        }
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await ping() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw WebSocketError.pingTimeout
            }
            try await group.next()
            group.cancelAll()
        }
    }
}

/// Thread-safe single-fire gate backed by an atomic flag.
private final class OnceBox<T>: @unchecked Sendable {
    private var _fired = false
    private let lock = NSLock()

    /// Returns true the first time, false on every subsequent call.
    func trySet() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !_fired else { return false }
        _fired = true
        return true
    }
}
