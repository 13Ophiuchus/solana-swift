import Foundation
import Testing
@testable import SolanaSwift

// MARK: - Tests

@Suite struct APIClientExtensionsTests {
    let endpoint = APIEndPoint(
        address: "https://api.mainnet-beta.solana.com",
        network: .mainnetBeta
    )

    @Test func checkAccountValidation() async throws {
        let apiClient = BaseAPIClientMock(endpoint: endpoint)
        let isValid1 = try await apiClient
            .checkAccountValidation(account: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG")
        #expect(isValid1 == true)

        let isValid2 = try await apiClient
            .checkAccountValidation(account: "HnXJX1Bvps8piQwDYEYC6oea9GEkvQvahvRj3c97X9xr")
        #expect(isValid2 == false)

        let isValid3 = try await apiClient
            .checkAccountValidation(account: "8J5wZ4Lo7QSwFWwBfWsWUgsbH4Jr44RFsEYj6qFdXYhM")
        #expect(isValid3 == true)
    }

    @Test func findSPLTokenDestinationAddress() async throws {
        let apiClient = BaseAPIClientMock(endpoint: endpoint)
        let result = try await apiClient.findSPLTokenDestinationAddress(
            mintAddress: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            destinationAddress: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG",
            tokenProgramId: TokenProgram.id
        )
        #expect(result.destination == "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3")
        #expect(result.isUnregisteredAsocciatedToken == false)
    }

    @Test func checkIfAssociatedTokenAccountExists() async throws {
        let apiClient = BaseAPIClientMock(endpoint: endpoint)
        let exist = try await apiClient.checkIfAssociatedTokenAccountExists(
            owner: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM",
            mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            tokenProgramId: TokenProgram.id
        )
        #expect(exist == true)

        let exist2 = try await apiClient.checkIfAssociatedTokenAccountExists(
            owner: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM",
            mint: "2FPyTwcZLUg1MDrwsyoP4D6s1tM7hAkHYRjkNb5w6Pxk",
            tokenProgramId: TokenProgram.id
        )
        #expect(exist2 == false)
    }

    @Test func getAccountInfoThrowable() async throws {
        let apiClient = BaseAPIClientMock(endpoint: endpoint)
        await #expect(throws: (any Error).self) {
            let _: BufferInfo<TokenAccountState> = try await apiClient
                .getAccountInfoThrowable(account: "djfijijasdf")
        }
    }
}

// MARK: - BaseAPIClientMock

private final class BaseAPIClientMock: SolanaAPIClient, @unchecked Sendable {
    let endpoint: APIEndPoint

    init(endpoint: APIEndPoint) {
        self.endpoint = endpoint
    }

    // MARK: Implemented stubs used by extension tests

    func getTokenAccountsByOwner<T: TokenAccountLayoutState>(
        pubkey _: String,
        params _: OwnerInfoParams?,
        configs _: RequestConfiguration?,
        decodingTo _: T.Type
    ) async throws -> [TokenAccount<T>] {
        let json = "[{\"account\":{\"data\":[\"ppdSk884LShYnHoHm7XiDlZ28iJVm9BHPgrAEfxU44AJ7HiGa7fztefqNjU2MSBOZ3HPlRmb0eAXj0bEanmyfAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\",\"base64\"],\"executable\":false,\"lamports\":2039280,\"owner\":\"So11111111111111111111111111111111111111112\",\"rentEpoch\":309},\"pubkey\":\"9bNJ7AF8w1Ms4BsqpqbUPZ16vCSePYJpgSBUTRqd8ph4\"}]"
        return try JSONDecoder().decode([TokenAccount<T>].self, from: json.data(using: .utf8)!)
    }

    func getMultipleAccounts<T: BufferLayout>(
        pubkeys _: [String],
        commitment _: Commitment
    ) async throws -> [BufferInfo<T>?] {
        let json = "{\"context\":{\"slot\":132420615},\"value\":[{\"data\":[\"APoAh5MDAAAAAAKLjuya35R64GfrOPbupmMcxJ1pmaH2fciYq9DxSQ88FioLlNul6FnDNF06/RKhMFBVI8fFQKRYcqukjYZitosKxZBjjg9hLR2AsDm2e/itloPtlrPeVDPIVdnO4+dmM2JiSZHdhsj7+Fn94OTNte9elt1ek0p487C2fLrFA9CvUPerjZvfP97EqlF9OXbPSzaGJzdmfWhk4jRnThsg5scAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAObFpMVhxY3CRrzEcywhYTa4a4SsovPp4wKPRTbTJVtzAfQBZAAAAABDU47UFrGnHMTsb0EaE1TBoVQGvCIHKJ4/EvpK3zvIfwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACsWQY44PYS0dgLA5tnv4rZaD7Zaz3lQzyFXZzuPnZjMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\",\"base64\"],\"executable\":false,\"lamports\":1345194,\"owner\":\"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA\",\"rentEpoch\":306}]}"
        // force-cast is safe: mock returns TokenMintState data matching T in these tests
        let box = try JSONDecoder().decode(Rpc<[BufferInfo<TokenMintState>]>.self, from: json.data(using: .utf8)!)
        return box.value as! [BufferInfo<T>?]
    }

    private let responses: [String: String] = [
        "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG": "{\"context\":{\"slot\":134254318},\"value\":{\"data\":[\"\",\"base64\"],\"executable\":false,\"lamports\":9984180,\"owner\":\"11111111111111111111111111111111\",\"rentEpoch\":310}}",
        "HnXJX1Bvps8piQwDYEYC6oea9GEkvQvahvRj3c97X9xr": #"{"context":{"slot":135918577},"value":null}"#,
    ]
    private let defaultAccountJSON = #"{"context":{"slot":134254375},"value":{"data":["xvp6877brTo9ZfNqq8l0MbG75MLS9uDkfKYCA0UvXWEn97kEVYkyppO43UtuZxDeKV73hCs+rPNfzL6PmRAKxebSAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA","base64"],"executable":false,"lamports":2039280,"owner":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA","rentEpoch":310}}"#

    func getAccountInfo<T: BufferLayout>(account: String) async throws -> BufferInfo<T>? {
        let json = responses[account] ?? defaultAccountJSON
        do {
            return try JSONDecoder().decode(Rpc<BufferInfo<T>?>.self, from: json.data(using: .utf8)!).value
        } catch is BinaryReaderError {
            throw APIClientError.couldNotRetrieveAccountInfo
        }
    }

    func getAccountInfoThrowable<T: BufferLayout>(account: String) async throws -> BufferInfo<T> {
        guard let result: BufferInfo<T> = try await getAccountInfo(account: account) else {
            throw APIClientError.couldNotRetrieveAccountInfo
        }
        return result
    }

    // MARK: Unimplemented protocol stubs
    func getBalance(account: String, commitment: Commitment?) async throws -> UInt64 { fatalError() }
    func getBlockCommitment(block: UInt64) async throws -> BlockCommitment { fatalError() }
    func getBlockTime(block: UInt64) async throws -> Date { fatalError() }
    func getClusterNodes() async throws -> [ClusterNodes] { fatalError() }
    func getBlockHeight() async throws -> UInt64 { fatalError() }
    func getConfirmedBlocksWithLimit(startSlot: UInt64, limit: UInt64) async throws -> [UInt64] { fatalError() }
    func getConfirmedBlock(slot: UInt64, encoding: String) async throws -> ConfirmedBlock { fatalError() }
    func getConfirmedSignaturesForAddress(account: String, startSlot: UInt64, endSlot: UInt64) async throws -> [String] { fatalError() }
    func getEpochInfo(commitment: Commitment?) async throws -> EpochInfo { fatalError() }
    func getFees(commitment: Commitment?) async throws -> Fee { fatalError() }
    func getFeeForMessage(message: String, commitment: Commitment?) async throws -> Lamports { fatalError() }
    func getMinimumBalanceForRentExemption(dataLength: UInt64, commitment: Commitment?) async throws -> UInt64 { fatalError() }
    func getSignatureStatuses(signatures: [String], configs: RequestConfiguration?) async throws -> [SignatureStatus?] { fatalError() }
    func getSignatureStatus(signature: String, configs: RequestConfiguration?) async throws -> SignatureStatus { fatalError() }
    func getTokenAccountBalance(pubkey: String, commitment: Commitment?) async throws -> TokenAccountBalance { fatalError() }
    func getTokenAccountsByDelegate<T: TokenAccountLayoutState>(pubkey: String, mint: String?, programId: String?, configs: RequestConfiguration?) async throws -> [TokenAccount<T>] { fatalError() }
    func getTokenLargestAccounts(pubkey: String, commitment: Commitment?) async throws -> [TokenAmount] { fatalError() }
    func getTokenSupply(pubkey: String, commitment: Commitment?) async throws -> TokenAmount { fatalError() }
    func getVersion() async throws -> Version { fatalError() }
    func getVoteAccounts(commitment: Commitment?) async throws -> VoteAccounts { fatalError() }
    func minimumLedgerSlot() async throws -> UInt64 { fatalError() }
    func requestAirdrop(account: String, lamports: UInt64, commitment: Commitment?) async throws -> String { fatalError() }
    func sendTransaction(transaction: String, configs: RequestConfiguration) async throws -> TransactionID { fatalError() }
    func simulateTransaction(transaction: String, configs: RequestConfiguration) async throws -> SimulationResult { fatalError() }
    func setLogFilter(filter: String) async throws -> String? { fatalError() }
    func validatorExit() async throws -> Bool { fatalError() }
    func observeSignatureStatus(signature: String, timeout: Int, delay: Int) -> AsyncStream<PendingTransactionStatus> { fatalError() }
    func getRecentBlockhash(commitment: Commitment?) async throws -> String { fatalError() }
    func getLatestBlockhash(commitment: Commitment?) async throws -> String { fatalError() }
    func getSignaturesForAddress(address: String, configs: RequestConfiguration?) async throws -> [SignatureInfo] { fatalError() }
    func getTransaction(signature: String, commitment: Commitment?) async throws -> TransactionInfo? { fatalError() }
    func request<Entity: Decodable>(method: String, params: [Encodable]) async throws -> Entity { fatalError() }
    func batchRequest(with requests: [JSONRPCRequestEncoder.RequestType]) async throws -> [AnyResponse<JSONRPCRequestEncoder.RequestType.Entity>] { fatalError() }
    func batchRequest<Entity: Decodable>(method: String, params: [[Encodable]]) async throws -> [Entity?] { fatalError() }
    func getRecentPerformanceSamples(limit: [UInt]) async throws -> [PerfomanceSamples] { fatalError() }
    func getSlot() async throws -> UInt64 { fatalError() }
    func getAddressLookupTable(accountKey: PublicKey) async throws -> AddressLookupTableAccount? { fatalError() }
}
