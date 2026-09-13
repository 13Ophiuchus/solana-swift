import Foundation

extension Array where Element == UInt8 {
	func toUInt32() -> UInt32? {
		let data = Data(self)
		return data.withUnsafeBytes { rawBuffer in
			guard rawBuffer.count >= MemoryLayout<UInt32>.size else { return nil }
			let value = rawBuffer.load(as: UInt32.self)
			return UInt32(littleEndian: value)
		}
	}

	func toUInt64() -> UInt64? {
		let data = Data(self)
		return data.withUnsafeBytes { rawBuffer in
			guard rawBuffer.count >= MemoryLayout<UInt64>.size else { return nil }
			let value = rawBuffer.load(as: UInt64.self)
			return UInt64(littleEndian: value)
		}
	}
}
