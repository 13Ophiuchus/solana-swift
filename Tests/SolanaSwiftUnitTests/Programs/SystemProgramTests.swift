import SolanaSwift
import Testing


struct SystemProgramTests {
    @Test
    func testCreateAccountInstruction() throws {
        let instruction = SystemProgram.createAccountInstruction(
            from: "QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo",
            toNewPubkey: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5",
            lamports: 2_039_280,
            space: 165,
            programId: TokenProgram.id
        )

        #expect(instruction.keys.count == 2)
        #expect(
            instruction.keys[0] == .writable(publicKey: "QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo", isSigner: true)
        )
        #expect(
            instruction.keys[1] == .writable(publicKey: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5", isSigner: true)
        )
        #expect(instruction.programId == SystemProgram.id)
        #expect(
            Base58.encode(instruction.data) == "11119os1e9qSs2u7TsThXqkBSRVFxhmYaFKFZ1waB2X7armDmvK3p5GmLdUxYdg3h7QSrL"
        )
    }

    @Test
    func testTransferInstruction() throws {
        let fromPublicKey = try PublicKey(string: "QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo")
        let toPublicKey = try PublicKey(string: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5")

        let instruction = SystemProgram.transferInstruction(
            from: fromPublicKey,
            to: toPublicKey,
            lamports: 3000
        )

        #expect(instruction.keys.count == 2)
        #expect(
            instruction.keys[0] == .writable(publicKey: "QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo", isSigner: true)
        )
        #expect(
            instruction.keys[1] == .writable(publicKey: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5", isSigner: false)
        )
        #expect(instruction.programId == SystemProgram.id)
        #expect(Base58.encode(instruction.data) == "3Bxs4Xe7CKfY5Mkb")
    }
}
