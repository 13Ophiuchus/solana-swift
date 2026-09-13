import Foundation

public enum Base58 {
	static let base58Alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

		// Encode
	public static func encode(_ data: Data) -> String {
		encode(data.bytes)
	}

	public static func encode(_ bytes: [UInt8]) -> String {
		var bytes = bytes
		var zerosCount = 0
		var length = 0

			// Count leading zero bytes
		for b in bytes {
			if b != 0 { break }
			zerosCount += 1
		}

		bytes.removeFirst(zerosCount)

		let size = bytes.count * 138 / 100 + 1

		var base58: [UInt8] = Array(repeating: 0, count: size)
		for b in bytes {
			var carry = Int(b)
			var i = 0

			for j in 0 ..< base58.count where carry != 0 || i < length {
				carry += 256 * Int(base58[base58.count - j - 1])
				base58[base58.count - j - 1] = UInt8(carry % 58)
				carry /= 58
				i += 1
			}

			assert(carry == 0)

			length = i
		}

			// Skip leading zeros in base58 array
		var zerosToRemove = 0
		for b in base58 {
			if b != 0 { break }
			zerosToRemove += 1
		}
		base58.removeFirst(zerosToRemove)

			// Build the result string, preserving original leading zero bytes as '1'
		var str = String(repeating: "1", count: zerosCount)

		for b in base58 {
			let index = base58Alphabet.index(base58Alphabet.startIndex, offsetBy: Int(b))
			str.append(base58Alphabet[index])
		}

		return str
	}

		// Decode
	public static func decode(_ base58: String) -> [UInt8] {
			// Remove leading and trailing whitespaces
		let string = base58.trimmingCharacters(in: .whitespaces)

		guard !string.isEmpty else { return [] }

		var zerosCount = 0
		var length = 0

			// Count leading '1' characters, which represent leading zero bytes
		for c in string {
			if c != "1" { break }
			zerosCount += 1
		}

		let size = string.lengthOfBytes(using: .utf8)
		var base58Bytes: [UInt8] = Array(repeating: 0, count: size)

		for c in string where c != " " {
				// Search for base58 character
			guard let base58Index = base58Alphabet.firstIndex(of: c) else { return [] }

				// Convert String.Index into its integer position (0..<58)
			let digit = base58Alphabet.distance(from: base58Alphabet.startIndex, to: base58Index)

			var carry = digit
			var i = 0
			for j in 0 ..< base58Bytes.count where carry != 0 || i < length {
				carry += 58 * Int(base58Bytes[base58Bytes.count - j - 1])
				base58Bytes[base58Bytes.count - j - 1] = UInt8(carry % 256)
				carry /= 256
				i += 1
			}

			assert(carry == 0)
			length = i
		}

			// Skip leading zeros in decoded byte array
		var zerosToRemove = 0
		for b in base58Bytes {
			if b != 0 { break }
			zerosToRemove += 1
		}
		base58Bytes.removeFirst(zerosToRemove)

			// Reconstruct result, re‑adding the original leading zeros
		var result: [UInt8] = Array(repeating: 0, count: zerosCount)
		result.append(contentsOf: base58Bytes)

		return result
	}
}
