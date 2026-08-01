import Foundation

actor ReconnectionPolicy {
    private var attempt = 0
    private let maxAttempts: Int
    private let base: Duration

    init(maxAttempts: Int = 5, base: Duration = .seconds(1)) {
        self.maxAttempts = maxAttempts
        self.base = base
    }

    func nextDelay() throws -> Duration {
        guard attempt < maxAttempts else { throw WebSocketError.cancelled }
        let delay = base * pow(2.0, Double(attempt))
        attempt += 1
        return min(delay, .seconds(30))
    }

    func reset() { attempt = 0 }
}
