import Foundation
import P256K

struct CKSecp256k1 {

    // MARK: - Public key from private key (called by Keychain.swift)
    // Returns compressed (33-byte) or uncompressed (65-byte) pubkey bytes.

    static func generatePublicKey(withPrivateKey privateKeyBytes: Data,
                                  compression: Bool) throws -> Data {
        let privKey = try P256K.Signing.PrivateKey(dataRepresentation: privateKeyBytes)
        if compression {
            return privKey.publicKey.compressedRepresentation
        } else {
            return privKey.publicKey.uncompressedRepresentation
        }
    }

    // MARK: - Sign
    // Returns a 64-byte compact signature (r || s).

    static func sign(message: Data, with privateKeyBytes: Data) throws -> Data {
        let privKey = try P256K.Signing.PrivateKey(dataRepresentation: privateKeyBytes)
        let sig = try privKey.signature(for: message)
        // compactRepresentation is 64 bytes (r || s big-endian)
        return sig.compactRepresentation
    }

    // MARK: - Verify

    static func verify(signature signatureData: Data,
                       message messageData: Data,
                       publicKeyData: Data) throws -> Bool {
        let pubKey: P256K.Signing.PublicKey
        switch publicKeyData.count {
        case 33:
            pubKey = try P256K.Signing.PublicKey(dataRepresentation: publicKeyData,
                                                  format: .compressed)
        case 65:
            pubKey = try P256K.Signing.PublicKey(dataRepresentation: publicKeyData,
                                                  format: .uncompressed)
        default:
            throw CKSecp256k1Error.invalidPublicKeyLength
        }
        let sig = try P256K.Signing.ECDSASignature(compactRepresentation: signatureData)
        return pubKey.isValidSignature(sig, for: messageData)
    }
}

enum CKSecp256k1Error: Error {
    case invalidPublicKeyLength
}
