import SolanaSwift
import Testing

struct TransactionTests {
    @Test func givenSigner_whenPartialSign_thenSignerAppended() throws {
        // given
        let signer = KeyPair.StubFactory.make()
        var transaction = Self.makeTransaction(signer: signer)

        // when
        try transaction.partialSign(signers: [signer])

        // then
        #expect(transaction.signatures.contains(where: { $0.publicKey == signer.publicKey }))
    }

    @Test func givenSignerAndInvalidTransaction_whenPartialSign_thenThrowsError() throws {
        // given
        let signer = KeyPair.StubFactory.make()
        var transaction = Transaction(
            instructions: [],
            recentBlockhash: "",
            feePayer: .StubFactory.make()
        )

        // when
        // then
        #expect(throws: (any Error).self) {
            try transaction.partialSign(signers: [signer])
        }
    }

    @Test func givenPartiallySignedTransactionAndSameSigner_whenPartialSign_thenSignerNotAdded() throws {
        // given
        let signer = KeyPair.StubFactory.make()
        var transaction = Self.makeTransaction(signer: signer)
        try transaction.partialSign(signers: [signer])
        let numberOfSignatures = transaction.signatures.count

        // when
        try transaction.partialSign(signers: [signer])

        // then
        #expect(numberOfSignatures == transaction.signatures.count)
    }

    @Test func givenEmptySigners_whenPartialSign_thenThrowsError() throws {
        // given
        let signer = KeyPair.StubFactory.make()
        var transaction = Self.makeTransaction(signer: signer)

        // when
        // then
        #expect(throws: (any Error).self) {
            try transaction.partialSign(signers: [])
        }
    }
}

extension TransactionTests {
    static func makeTransaction(
        signer: KeyPair,
        feePayer: PublicKey = .StubFactory.make()
    ) -> Transaction {
        .init(
            instructions: [
                .init(
                    keys: [
                        .init(
                            publicKey: signer.publicKey,
                            isSigner: true,
                            isWritable: true
                        ),
                    ],
                    programId: .fake,
                    data: [UInt8]([0])
                ),
            ],
            recentBlockhash: "",
            feePayer: feePayer
        )
    }
}
