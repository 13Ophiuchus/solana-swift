import Foundation

public typealias BorshCodable = BorshDeserializable & BorshSerializable

public enum BorshCodableError: Error {
    case invalidData
}
