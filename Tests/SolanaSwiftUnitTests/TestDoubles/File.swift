import Foundation
import SolanaSwift
import Testing

extension KeyPair {
    enum StubFactory {
        static func make() -> KeyPair {
            try! .init(secretKey: .init([UInt8].StubFactory.make(length: 64)))
        }
    }
}
