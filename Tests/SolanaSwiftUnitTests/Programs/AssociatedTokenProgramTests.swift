import SolanaSwift
import Testing


struct AssociatedTokenProgramTests {
    @Test
    func testAssociatedTokenAddress() throws {
        let associatedTokenAddress = try PublicKey.associatedTokenAddress(
            walletAddress: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG",
            tokenMintAddress: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            tokenProgramId: TokenProgram.id
        )

        #expect(associatedTokenAddress.base58EncodedString == "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3")
    }

    @Test
    func testCreateAssociatedTokenAccountInstruction() throws {
        let owner: PublicKey = "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG"
        let mintAddress: PublicKey = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"

        let instruction = try AssociatedTokenProgram
            .createAssociatedTokenAccountInstruction(
                mint: mintAddress,
                owner: owner,
                payer: owner,
                tokenProgramId: TokenProgram.id
            )

        #expect(instruction.keys.count == 7)
        #expect(
            instruction.keys[0] == .writable(publicKey: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG", isSigner: true)
        )
        #expect(
            instruction.keys[1] == .writable(publicKey: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3", isSigner: false)
        )
        #expect(
            instruction.keys[2] == .readonly(publicKey: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG", isSigner: false)
        )
        #expect(
            instruction.keys[3] == .readonly(publicKey: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", isSigner: false)
        )
        #expect(instruction.keys[4] == .readonly(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(
            instruction.keys[5] == .readonly(publicKey: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA", isSigner: false)
        )
        #expect(
            instruction.keys[6] == .readonly(publicKey: "SysvarRent111111111111111111111111111111111", isSigner: false)
        )
        #expect(instruction.programId == "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
        #expect("" == Base58.encode(instruction.data))
    }
}
