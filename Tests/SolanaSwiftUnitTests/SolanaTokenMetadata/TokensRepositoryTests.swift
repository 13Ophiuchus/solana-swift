import Foundation
@testable import SolanaSwift
import Testing

final class TokensRepositoryTests {
    @Test func fill_WithStorageData_ShouldLoadFromStorage() async throws {
        let tokens = Set([TokenMetadata.usdc, TokenMetadata.nativeSolana])

        let source = TestableSolanaTokenListSource()
        source.mockTokens = tokens

        let storage = TestableSolanaTokenListStorage()
        storage.mockTokens = tokens

        let service = SolanaTokenListRepository(
            tokenListSource: source,
            storage: storage
        )

        try await service.fill()

        #expect(storage.getTokensCalled == 1)
        #expect(storage.saveTokensCalled == 0)
        #expect(source.downloadCalled == 0)

        let records = await service.records
        #expect(records[TokenMetadata.usdc.mintAddress]?.generalTokenExtensions.coingeckoId == "usd-coin")
        #expect(records.count == 2)
        #expect(records[TokenMetadata.usdc.mintAddress] != nil)
        #expect(records[TokenMetadata.nativeSolana.mintAddress] != nil)
        #expect(records[TokenMetadata.usdt.mintAddress] == nil)
    }

    @Test func fill_WithoutStorageData_ShouldLoadFromSource() async throws {
        let tokens = Set([TokenMetadata.usdc, TokenMetadata.nativeSolana])

        let source = TestableSolanaTokenListSource()
        source.mockTokens = tokens

        let storage = TestableSolanaTokenListStorage()
        storage.mockTokens = nil

        let service = SolanaTokenListRepository(
            tokenListSource: source,
            storage: storage
        )

        try await service.fill()

        #expect(storage.getTokensCalled == 1)
        #expect(storage.saveTokensCalled == 1)
        #expect(source.downloadCalled == 1)

        let records = await service.records
        #expect(records.count == 2)
        #expect(records[TokenMetadata.usdc.mintAddress] != nil)
        #expect(records[TokenMetadata.nativeSolana.mintAddress] != nil)
        #expect(records[TokenMetadata.usdt.mintAddress] == nil)
    }

    @Test func reset_ShouldRecordBeEmpty() async throws {
        let tokens = Set([TokenMetadata.usdc, TokenMetadata.nativeSolana])

        let source = TestableSolanaTokenListSource()
        source.mockTokens = tokens

        let storage = TestableSolanaTokenListStorage()
        storage.mockTokens = tokens

        let service = SolanaTokenListRepository(
            tokenListSource: source,
            storage: storage
        )

        await service.updateRecords(Dictionary(uniqueKeysWithValues: tokens.map { ($0.mintAddress, $0) }))

        try await service.reset()

        let records = await service.records
        #expect(records.isEmpty)
    }

    @Test func get_RecordsIsEmpty_ShouldFill() async throws {
        let tokens = Set([TokenMetadata.usdc, TokenMetadata.nativeSolana])

        let source = TestableSolanaTokenListSource()
        source.mockTokens = tokens

        let storage = TestableSolanaTokenListStorage()
        storage.mockTokens = []

        let service = SolanaTokenListRepository(
            tokenListSource: source,
            storage: storage
        )

        let token = try await service.get(address: TokenMetadata.usdc.mintAddress)

        #expect(storage.getTokensCalled == 1)
        #expect(storage.saveTokensCalled == 1)
        #expect(source.downloadCalled == 1)

        #expect(token?.name == "USDC")
    }
}

extension SolanaTokenListRepository {
    func updateRecords(_ records: [String: TokenMetadata]) async {
        self.records = records
    }
}
