import SolanaSwift
import Testing

struct TokenSwapProgramTests {
    let publicKey: PublicKey = "11111111111111111111111111111111"

    @Test func swapInstruction() throws {
        let instruction = TokenSwapProgram.swapInstruction(
            tokenSwap: publicKey,
            authority: publicKey,
            userTransferAuthority: publicKey,
            userSource: publicKey,
            poolSource: publicKey,
            poolDestination: publicKey,
            userDestination: publicKey,
            poolMint: publicKey,
            feeAccount: publicKey,
            hostFeeAccount: publicKey,
            swapProgramId: publicKey,
            tokenProgramId: publicKey,
            amountIn: 100_000,
            minimumAmountOut: 0
        )

        #expect(instruction.keys.count == 11)
        #expect(instruction.keys[0] == .readonly(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[1] == .readonly(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[2] == .readonly(publicKey: "11111111111111111111111111111111", isSigner: true))
        #expect(instruction.keys[3] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[4] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[5] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[6] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[7] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[8] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[9] == .readonly(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[10] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.programId == publicKey)
        #expect(Base58.decode("tSBHVn49GSCW4DNB1EYv9M") == instruction.data)
    }

    @Test func depositInstruction() throws {
        let instruction = TokenSwapProgram.depositInstruction(
            tokenSwap: publicKey,
            authority: publicKey,
            sourceA: publicKey,
            sourceB: publicKey,
            intoA: publicKey,
            intoB: publicKey,
            poolToken: publicKey,
            poolAccount: publicKey,
            tokenProgramId: publicKey,
            swapProgramId: publicKey,
            poolTokenAmount: 507_788,
            maximumTokenA: 51,
            maximumTokenB: 1038
        )

        #expect(instruction.keys.count == 9)
        #expect(instruction.keys[0] == .readonly(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[1] == .readonly(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[2] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[3] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[4] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[5] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[6] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[7] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[8] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.programId == publicKey)
        #expect(Base58.decode("22WQQtPPUknk68tx2dUGRL1Q4Vj2mkg6Hd") == instruction.data)
    }

    @Test func withdrawInstruction() throws {
        let instruction = TokenSwapProgram.withdrawInstruction(
            tokenSwap: publicKey,
            authority: publicKey,
            poolMint: publicKey,
            feeAccount: publicKey,
            sourcePoolAccount: publicKey,
            fromA: publicKey,
            fromB: publicKey,
            userAccountA: publicKey,
            userAccountB: publicKey,
            swapProgramId: publicKey,
            tokenProgramId: publicKey,
            poolTokenAmount: 498_409,
            minimumTokenA: 49,
            minimumTokenB: 979
        )

        #expect(instruction.keys.count == 10)
        #expect(instruction.keys[0] == .readonly(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[1] == .readonly(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[2] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[3] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[4] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[5] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[6] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[7] == .writable(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[8] == .readonly(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.keys[9] == .readonly(publicKey: "11111111111111111111111111111111", isSigner: false))
        #expect(instruction.programId == publicKey)
        #expect(Base58.decode("2aJyv2ixHWcYWoAKJkYMzSPwTrGUfnSR9R") == instruction.data)
    }
}
