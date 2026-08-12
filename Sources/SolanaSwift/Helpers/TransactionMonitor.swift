import Foundation
import Task_retrying

/// Actor-isolated coordinator that polls `getSignatureStatus` until a
/// transaction is finalized or the timeout elapses.
///
/// All mutable state (`task`, `currentStatus`) is actor-isolated, eliminating
/// the previous `@unchecked Sendable` escape hatch.
actor TransactionMonitor<SolanaAPIClient: SolanaSwift.SolanaAPIClient> {
    let signature: String
    let apiClient: SolanaAPIClient
    let timeout: Int
    let delay: Int

    private var responseHandler: @Sendable (PendingTransactionStatus) -> Void
    private var timedOutHandler: @Sendable () -> Void
    private var task: Task<Void, Error>?
    private var currentStatus: PendingTransactionStatus?

    init(
        apiClient: SolanaAPIClient,
        signature: String,
        timeout: Int,
        delay: Int,
        responseHandler: @escaping @Sendable (PendingTransactionStatus) -> Void,
        timedOutHandler: @escaping @Sendable () -> Void
    ) {
        self.apiClient = apiClient
        self.signature = signature
        self.timeout = timeout
        self.delay = delay
        self.responseHandler = responseHandler
        self.timedOutHandler = timedOutHandler
    }

    func startMonitoring() {
        setStatus(.sending)

        // Capture the handler synchronously so the `where` predicate —
        // which must be a plain (non-async) closure — can call it directly
        // without hopping back onto the actor.
        let onTimeout = timedOutHandler

        task = Task.retrying(
            where: { error in
                if let error = error as? TaskRetryingError, error == .timedOut {
                    onTimeout()
                    return false
                }
                return true
            },
            maxRetryCount: .max,
            retryDelay: TimeInterval(delay),
            timeoutInSeconds: timeout
        ) { [weak self] in
            guard let self else { return }
            try Task.checkCancellation()
            let status = try await self.apiClient
                .getSignatureStatus(signature: self.signature, configs: nil)

            if let confirmations = status.confirmations,
               status.confirmationStatus == "confirmed"
            {
                await self.setStatus(.confirmed(numberOfConfirmations: confirmations, slot: status.slot))
            }
            let finalized = status.confirmations == nil || status.confirmationStatus == "finalized"
            if finalized {
                await self.setStatus(.finalized)
                return
            }
            throw TransactionConfirmationError.unconfirmed
        }
    }

    func stopMonitoring() {
        task?.cancel()
    }

    private func setStatus(_ transactionStatus: PendingTransactionStatus) {
        currentStatus = transactionStatus
        responseHandler(transactionStatus)
    }

}
