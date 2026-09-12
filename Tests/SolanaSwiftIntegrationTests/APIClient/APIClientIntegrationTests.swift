import SolanaSwift
import XCTest

class APIClientIntegrationTests: XCTestCase {
    private let apiClient = JSONRPCAPIClient(endpoint: .init(address: "https://api.devnet.solana.com", network: .devnet))

    func testGenericRequest() async throws {
        let result: String = try await apiClient.request(method: "getHealth")
        XCTAssertEqual(result, "ok")
    }
}
