import Foundation

	/// Bignum compatibility alias for BInt
public typealias Bignum = BInt

public extension Bignum {
		/// Representation as Data (big-endian)
	var data: Data {
		let n = limbs.count
		var data = Data(count: n * MemoryLayout<UInt64>.size)

		data.withUnsafeMutableBytes { rawBuffer in
			guard let basePtr = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
			var p = basePtr

			for i in (0 ..< n).reversed() {
					// Write each limb as 8 bytes, big-endian
				for j in (0 ..< 8).reversed() {
					p.pointee = UInt8((limbs[i] >> UInt64(j * 8)) & 0xFF)
					p = p.advanced(by: 1)
				}
			}
		}

		return data
	}

		/// Decimal string representation
	var dec: String { description }

		/// Hexadecimal string representation
	var hex: String { data.hexString }

		///
		/// Initialise a BInt from a hexadecimal string
		///
		/// - Parameter hex: the hexadecimal string to convert to a big integer
	init(hex: String) {
		self.init(number: hex.lowercased(), withBase: 16)
	}

		/// Initialise from an unsigned, 64 bit integer
		///
		/// - Parameter n: the 64 bit unsigned integer to convert to a BInt
	init(_ n: UInt64) {
		self.init(limbs: [n])
	}

		/// Initialise from big-endian data
		///
		/// - Parameter data: the data to convert to a Bignum
	init(data: Data) {
		let n = data.count
		guard n > 0 else {
			self.init(0)
			return
		}

		let m = (n + 7) / 8
		var limbs = Limbs(repeating: 0, count: m)

		data.withUnsafeBytes { rawBuffer in
			guard let ptr = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
			var p = ptr

			let r = n % 8
			let k = r == 0 ? 8 : r

				// Fill most significant limb (possibly partial)
			for j in (0 ..< k).reversed() {
				limbs[m - 1] += UInt64(p.pointee) << UInt64(j * 8)
				p = p.advanced(by: 1)
			}

			guard m > 1 else { return }

				// Fill remaining limbs
			for i in (0 ..< (m - 1)).reversed() {
				for j in (0 ..< 8).reversed() {
					limbs[i] += UInt64(p.pointee) << UInt64(j * 8)
					p = p.advanced(by: 1)
				}
			}
		}

		self.init(limbs: limbs)
	}
}

	/// Extension for Data to interoperate with Bignum
public extension Data {
		/// Hexadecimal string representation of the underlying data
	var hexString: String {
		return withUnsafeBytes { rawBuffer -> String in
			guard let buf = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
				return ""
			}

			let charA = UInt8(UnicodeScalar("a").value)
			let char0 = UInt8(UnicodeScalar("0").value)

			func itoh(_ value: UInt8) -> UInt8 {
				(value > 9) ? (charA + value - 10) : (char0 + value)
			}

			var chars = [UInt8](repeating: 0, count: rawBuffer.count * 2)

			for i in 0 ..< rawBuffer.count {
				let byte = buf[i]
				chars[i * 2]     = itoh((byte >> 4) & 0xF)
				chars[i * 2 + 1] = itoh(byte & 0xF)
			}

			return String(bytes: chars, encoding: .utf8) ?? ""
		}
	}
}
