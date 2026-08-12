import SolanaSwift
import Testing


struct OwnerValidationProgramTests {
    @Test
    func testAssertOwnerInstruction() throws {
        let instruction = OwnerValidationProgram.assertOwnerInstruction(
            account: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5",
            programId: SystemProgram.id
        )
        #expect(instruction.keys.count == 1)
        #expect(
            instruction.keys[0] == .readonly(publicKey: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5", isSigner: false)
        )
        #expect(instruction.programId == "4MNPdKu9wFMvEeZBMt3Eipfs5ovVWTJb31pEXDJAAxX5")
        #expect(Base58.encode(instruction.data) == "11111111111111111111111111111111")
    }
}
