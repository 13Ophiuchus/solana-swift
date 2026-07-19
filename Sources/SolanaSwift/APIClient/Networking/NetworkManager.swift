import Foundation

public protocol NetworkManager: Sendable {
    func requestData(request: URLRequest) async throws -> Data
}
