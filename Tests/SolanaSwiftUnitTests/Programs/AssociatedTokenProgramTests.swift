import SolanaSwift
import Testing

struct AssociatedTokenProgramTests {
	private let owner: PublicKey = "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG"
	private let mintAddress: PublicKey = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
	private let associatedTokenAddress: PublicKey = "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3"

	@Test
	func testAssociatedTokenAddress() throws {
		let address = try PublicKey.associatedTokenAddress(
			walletAddress: owner,
			tokenMintAddress: mintAddress,
			tokenProgramId: TokenProgram.id
		)

		#expect(address == associatedTokenAddress)
	}

	@Test
	func testCreateAssociatedTokenAccountInstruction() throws {
		let instruction = try AssociatedTokenProgram.createAssociatedTokenAccountInstruction(
			mint: mintAddress,
			owner: owner,
			payer: owner,
			tokenProgramId: TokenProgram.id
		)

		assertExpectedAccountMetas(instruction)

		#expect(instruction.programId == AssociatedTokenProgram.id)
		#expect(instruction.data.isEmpty)
	}

	@Test
	func testCreateIdempotentAssociatedTokenAccountInstruction() throws {
		let instruction = try AssociatedTokenProgram.createIdempotentAssociatedTokenAccountInstruction(
			mint: mintAddress,
			owner: owner,
			payer: owner,
			tokenProgramId: TokenProgram.id
		)

		assertExpectedAccountMetas(instruction)

		#expect(instruction.programId == AssociatedTokenProgram.id)
		#expect(instruction.data == [1])
	}

	private func assertExpectedAccountMetas(
		_ instruction: TransactionInstruction,
		sourceLocation: SourceLocation = #_sourceLocation
	) {
		#expect(instruction.keys.count == 7, sourceLocation: sourceLocation)

		#expect(
			instruction.keys[0] == .writable(
				publicKey: owner,
				isSigner: true
			),
			sourceLocation: sourceLocation
		)

		#expect(
			instruction.keys[1] == .writable(
				publicKey: associatedTokenAddress,
				isSigner: false
			),
			sourceLocation: sourceLocation
		)

		#expect(
			instruction.keys[2] == .readonly(
				publicKey: owner,
				isSigner: false
			),
			sourceLocation: sourceLocation
		)

		#expect(
			instruction.keys[3] == .readonly(
				publicKey: mintAddress,
				isSigner: false
			),
			sourceLocation: sourceLocation
		)

		#expect(
			instruction.keys[4] == .readonly(
				publicKey: SystemProgram.id,
				isSigner: false
			),
			sourceLocation: sourceLocation
		)

		#expect(
			instruction.keys[5] == .readonly(
				publicKey: TokenProgram.id,
				isSigner: false
			),
			sourceLocation: sourceLocation
		)

		#expect(
			instruction.keys[6] == .readonly(
				publicKey: .sysvarRent,
				isSigner: false
			),
			sourceLocation: sourceLocation
		)
	}
}
