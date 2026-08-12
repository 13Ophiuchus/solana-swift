import Testing
import Foundation
@testable import SolanaSwift

@Suite(.serialized) struct ObserveTransactionStatusTests {
    enum CustomError: Error { case unknownNetworkError }

    let endpoint = APIEndPoint(
        address: "https://api.mainnet-beta.solana.com",
        network: .mainnetBeta
    )

    // MARK: - Helpers

    func makeAPIClient(customResponse: [Result<String, Error>]? = nil) -> JSONRPCAPIClient {
        let responses = customResponse ?? [
            .success(mockResponse(confirmations: 0, confirmationStatus: "processed")),
            .failure(CustomError.unknownNetworkError),
            .success(mockResponse(confirmations: 1, confirmationStatus: "confirmed")),
            .failure(CustomError.unknownNetworkError),
            .failure(APIClientError.invalidResponse),
            .success(mockResponse(confirmations: 5, confirmationStatus: "confirmed")),
            .success(mockResponse(confirmations: 10, confirmationStatus: "confirmed")),
            .failure(APIClientError.invalidResponse),
            .success(mockResponse(confirmations: nil, confirmationStatus: "finalized")),
        ]
        return JSONRPCAPIClient(endpoint: endpoint, networkManager: MultiResponseNetworkManagerMock(responses))
    }

    func mockResponse(confirmations: Int?, confirmationStatus: String) -> String {
        #"{"jsonrpc":"2.0","result":{"context":{"slot":82},"value":[{"slot":72,"confirmations":\#(confirmations.map(String.init) ?? "null"),"err":null,"status":{"Ok":null},"confirmationStatus":"\#(confirmationStatus)"},null]},"id":1}"#
    }

    // MARK: - Tests

    @Test func observingTransactionStatusExceededTimeout1() async throws {
        let apiClient = makeAPIClient()
        var statuses: [PendingTransactionStatus] = []
        for try await status in apiClient.observeSignatureStatus(signature: "jaiojsdfoijvaij", timeout: 5, delay: 1) {
            statuses.append(status)
        }
        #expect(statuses.last?.numberOfConfirmations == 1)
    }

    @Test func observingTransactionStatusExceededTimeout2() async throws {
        let apiClient = makeAPIClient()
        var statuses: [PendingTransactionStatus] = []
        for try await status in apiClient.observeSignatureStatus(signature: "jijviajidsfjiaj", timeout: 7, delay: 1) {
            statuses.append(status)
        }
        #expect(statuses.last?.numberOfConfirmations == 10)
    }

    @Test func observingTransactionStatusFinalized() async throws {
        let apiClient = makeAPIClient()
        var statuses: [PendingTransactionStatus] = []
        for try await status in apiClient.observeSignatureStatus(signature: "jijviajidsfjiaj", delay: 1) {
            statuses.append(status)
        }
        #expect(statuses.last == .finalized)
    }

    @Test func waitForConfirmationIgnoreStatus() async throws {
        let response: [Result<String, Error>] = [
            .failure(CustomError.unknownNetworkError),
            .failure(CustomError.unknownNetworkError),
            .failure(APIClientError.invalidResponse),
            .success(mockResponse(confirmations: 5, confirmationStatus: "confirmed")),
            .success(mockResponse(confirmations: 10, confirmationStatus: "confirmed")),
            .failure(APIClientError.invalidResponse),
            .success(mockResponse(confirmations: nil, confirmationStatus: "finalized")),
        ]
        try await makeAPIClient(customResponse: response)
            .waitForConfirmation(signature: "adfijidjfaisdf", ignoreStatus: true, timeout: 1, delay: 1)
        try await makeAPIClient(customResponse: response)
            .waitForConfirmation(signature: "adfijidjfaisdf", ignoreStatus: true)
    }

    @Test func waitForConfirmationNotIgnoreStatus() async throws {
        let response: [Result<String, Error>] = [
            .failure(CustomError.unknownNetworkError),
            .failure(CustomError.unknownNetworkError),
            .failure(APIClientError.invalidResponse),
            .success(mockResponse(confirmations: 5, confirmationStatus: "confirmed")),
            .success(mockResponse(confirmations: 10, confirmationStatus: "confirmed")),
            .failure(APIClientError.invalidResponse),
            .success(mockResponse(confirmations: nil, confirmationStatus: "finalized")),
        ]
        do {
            try await makeAPIClient(customResponse: response)
                .waitForConfirmation(signature: "adfijidjfaisdf", ignoreStatus: true, timeout: 1, delay: 1)
        } catch {
            #expect(error.isEqualTo(TransactionConfirmationError.unconfirmed))
        }
        do {
            try await makeAPIClient(customResponse: response)
                .waitForConfirmation(signature: "adfijidjfaisdf", ignoreStatus: true, timeout: 3, delay: 1)
        } catch {
            #expect(error.isEqualTo(TransactionConfirmationError.unconfirmed))
        }
        try await makeAPIClient(customResponse: response)
            .waitForConfirmation(signature: "adfijidjfaisdf", ignoreStatus: true, timeout: 7, delay: 1)
        try await makeAPIClient(customResponse: response)
            .waitForConfirmation(signature: "adfijidjfaisdf", ignoreStatus: true, delay: 1)
    }
}

// MARK: - Mock
private final class MultiResponseNetworkManagerMock: NetworkManager, @unchecked Sendable {
    private var count = 0
    private let results: [Result<String, Error>]
    init(_ results: [Result<String, Error>]) { self.results = results }
    func requestData(request _: URLRequest) async throws -> Data {
        let result = results[count]; count += 1
        switch result {
        case let .success(s): return s.data(using: .utf8)!
        case let .failure(e): throw e
        }
    }
}
