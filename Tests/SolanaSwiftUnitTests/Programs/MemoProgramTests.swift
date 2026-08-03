import SolanaSwift
import Testing


struct MemoProgramTests {
    @Test
    func testCreateMemoInstruction() throws {
        let instruction = try MemoProgram.createMemoInstruction(memo: "HelloWorld")
        #expect(instruction.keys.count == 0)
        #expect(instruction.programId == "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr")
        #expect(Base58.encode(instruction.data) == "54uZdajEaDdN6F")
    }
}
