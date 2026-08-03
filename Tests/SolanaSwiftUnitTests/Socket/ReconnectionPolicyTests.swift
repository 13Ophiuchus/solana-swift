import Testing
@testable import SolanaSwift

@Suite("ReconnectionPolicy")
struct ReconnectionPolicyTests {

    @Test("first delay equals base")
    func firstDelayEqualsBase() async throws {
        let policy = ReconnectionPolicy(maxAttempts: 5, baseSeconds: 0.1)
        let d = try await policy.nextDelay()
        #expect(abs(d - 0.1) < 1e-9)
    }

    @Test("delays double on each attempt")
    func delaysDouble() async throws {
        let policy = ReconnectionPolicy(maxAttempts: 5, baseSeconds: 0.1)
        let d1 = try await policy.nextDelay()
        let d2 = try await policy.nextDelay()
        let d3 = try await policy.nextDelay()
        #expect(abs(d2 - d1 * 2) < 1e-9)
        #expect(abs(d3 - d1 * 4) < 1e-9)
    }

    @Test("delay is capped at 30 seconds")
    func delayCappedAt30s() async throws {
        let policy = ReconnectionPolicy(maxAttempts: 10, baseSeconds: 16.0)
        _ = try await policy.nextDelay()
        let d2 = try await policy.nextDelay()
        #expect(d2 <= 30.0)
    }

    @Test("throws cancelled after maxAttempts exhausted")
    func throwsCancelledWhenExhausted() async throws {
        let policy = ReconnectionPolicy(maxAttempts: 2, baseSeconds: 0.01)
        _ = try await policy.nextDelay()
        _ = try await policy.nextDelay()
        await #expect(throws: WebSocketError.cancelled) {
            _ = try await policy.nextDelay()
        }
    }

    @Test("single-attempt policy exhausts after one call")
    func singleAttemptExhausts() async throws {
        let policy = ReconnectionPolicy(maxAttempts: 1, baseSeconds: 0.01)
        _ = try await policy.nextDelay()
        await #expect(throws: WebSocketError.cancelled) {
            _ = try await policy.nextDelay()
        }
    }

    @Test("reset restores attempt counter so delays restart from base")
    func resetRestoresCounter() async throws {
        let policy = ReconnectionPolicy(maxAttempts: 2, baseSeconds: 0.1)
        _ = try await policy.nextDelay()
        _ = try await policy.nextDelay()
        await policy.reset()
        let d = try await policy.nextDelay()
        #expect(abs(d - 0.1) < 1e-9)
    }

    @Test("reset allows full attempt sequence to repeat")
    func resetAllowsFullSequenceRepeat() async throws {
        let policy = ReconnectionPolicy(maxAttempts: 2, baseSeconds: 0.01)
        _ = try await policy.nextDelay()
        _ = try await policy.nextDelay()
        await policy.reset()
        _ = try await policy.nextDelay()
        _ = try await policy.nextDelay()
        await #expect(throws: WebSocketError.cancelled) {
            _ = try await policy.nextDelay()
        }
    }
}
