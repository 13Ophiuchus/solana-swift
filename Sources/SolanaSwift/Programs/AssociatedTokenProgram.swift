import Foundation

public enum AssociatedTokenProgram: SolanaBasicProgram {
		// MARK: - Properties

	public static var id: PublicKey {
		"ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
	}

		// MARK: - Instruction Builder

		/// Creates an associated token account.
		///
		/// This instruction fails if the deterministic associated token account
		/// already exists.
	public static func createAssociatedTokenAccountInstruction(
		mint: PublicKey,
		owner: PublicKey,
		payer: PublicKey,
		tokenProgramId: PublicKey
	) throws -> TransactionInstruction {
		try makeCreateAssociatedTokenAccountInstruction(
			mint: mint,
			owner: owner,
			payer: payer,
			tokenProgramId: tokenProgramId,
			instructionData: []
		)
	}

		/// Creates an associated token account if it does not already exist.
		///
		/// This uses the Associated Token Program's idempotent-create instruction
		/// discriminator (`1`), avoiding a race when another transaction creates
		/// the same deterministic ATA before this transaction executes.
	public static func createIdempotentAssociatedTokenAccountInstruction(
		mint: PublicKey,
		owner: PublicKey,
		payer: PublicKey,
		tokenProgramId: PublicKey
	) throws -> TransactionInstruction {
		try makeCreateAssociatedTokenAccountInstruction(
			mint: mint,
			owner: owner,
			payer: payer,
			tokenProgramId: tokenProgramId,
			instructionData: [UInt8(1)]
		)
	}

		// MARK: - Private Helpers

	private static func makeCreateAssociatedTokenAccountInstruction(
		mint: PublicKey,
		owner: PublicKey,
		payer: PublicKey,
		tokenProgramId: PublicKey,
		instructionData: [any BytesEncodable]
	) throws -> TransactionInstruction {
		let associatedTokenAddress = try PublicKey.associatedTokenAddress(
			walletAddress: owner,
			tokenMintAddress: mint,
			tokenProgramId: tokenProgramId
		)

		return TransactionInstruction(  // Removed the unnecessary 'try' here
			keys: [
				.init(publicKey: payer, isSigner: true, isWritable: true),
				.init(
					publicKey: associatedTokenAddress,
					isSigner: false,
					isWritable: true
				),
				.init(publicKey: owner, isSigner: false, isWritable: false),
				.init(publicKey: mint, isSigner: false, isWritable: false),
				.init(publicKey: SystemProgram.id, isSigner: false, isWritable: false),
				.init(publicKey: tokenProgramId, isSigner: false, isWritable: false),
				.init(publicKey: .sysvarRent, isSigner: false, isWritable: false),
			],
			programId: AssociatedTokenProgram.id,
			data: instructionData
		)
	}
}
