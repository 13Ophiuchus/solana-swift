import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol NetworkManager: Sendable {
    func requestData(request: URLRequest) async throws -> Data
}

#if canImport(Darwin)
extension URLSession: @retroactive NetworkManager {
    public func requestData(request: URLRequest) async throws -> Data {
        let (data, _) = try await self.data(for: request)
        return data
    }
}
#endif
