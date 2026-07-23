import SolanaSwift
import Testing

struct Token2022ProgramTests {
    @Test func initializeMintInstruction() throws {
        let instruction = Token2022Program.initializeMintInstruction(
            mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            decimals: 6,
            authority: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG",
            freezeAuthority: nil
        )

        #expect(instruction.keys.count == 2)
        #expect(instruction.keys[0] == .writable(publicKey: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", isSigner: false))
        #expect(instruction.keys[1] == .readonly(publicKey: "SysvarRent111111111111111111111111111111111", isSigner: false))
        #expect(instruction.programId == Token2022Program.id)
        #expect(Base58.encode(instruction.data) == "195AHs4ykNczn89ynGjJ5v7rSfaK9giG1eL2bNrmUqn1oNw")
    }

    @Test func initializeAccountInstruction() throws {
        let instruction = Token2022Program.initializeAccountInstruction(
            account: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5",
            mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            owner: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG"
        )

        #expect(instruction.keys.count == 4)
        #expect(instruction.keys[0] == .writable(publicKey: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5", isSigner: false))
        #expect(instruction.keys[1] == .readonly(publicKey: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", isSigner: false))
        #expect(instruction.keys[2] == .readonly(publicKey: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG", isSigner: false))
        #expect(instruction.keys[3] == .readonly(publicKey: "SysvarRent111111111111111111111111111111111", isSigner: false))
        #expect(instruction.programId == Token2022Program.id)
        #expect(Base58.encode(instruction.data) == "2")
    }

    @Test func transferInstruction() throws {
        let instruction = Token2022Program.transferInstruction(
            source: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5",
            destination: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3",
            owner: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG",
            amount: 100
        )

        #expect(instruction.keys.count == 3)
        #expect(instruction.keys[0] == .writable(publicKey: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5", isSigner: false))
        #expect(instruction.keys[1] == .writable(publicKey: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3", isSigner: false))
        #expect(instruction.keys[2] == .writable(publicKey: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG", isSigner: true))
        #expect(instruction.programId == Token2022Program.id)
        #expect("3WBgs5fm8oDy" == Base58.encode(instruction.data))
    }

    @Test func transferCheckedInstruction() throws {
        let instruction = Token2022Program.transferCheckedInstruction(
            source: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5",
            mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            destination: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3",
            owner: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG",
            multiSigners: [],
            amount: 100,
            decimals: 6
        )

        #expect(instruction.keys.count == 4)
        #expect(instruction.keys[0] == .writable(publicKey: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5", isSigner: false))
        #expect(instruction.keys[1] == .readonly(publicKey: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", isSigner: false))
        #expect(instruction.keys[2] == .writable(publicKey: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3", isSigner: false))
        #expect(instruction.keys[3] == .readonly(publicKey: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG", isSigner: true))
        #expect(instruction.programId == Token2022Program.id)
        #expect("hNmtbNYibdzwf" == Base58.encode(instruction.data))
    }

    @Test func burnCheckedInstruction() throws {
        let instruction = Token2022Program.burnCheckedInstruction(
            mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            account: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5",
            owner: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG",
            amount: 100,
            decimals: 6
        )

        #expect(instruction.keys.count == 3)
        #expect(instruction.keys[0] == .writable(publicKey: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5", isSigner: false))
        #expect(instruction.keys[1] == .writable(publicKey: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", isSigner: false))
        #expect(instruction.keys[2] == .readonly(publicKey: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG", isSigner: true))
        #expect(instruction.programId == Token2022Program.id)
        #expect("s9m8UUrvs3fBT" == Base58.encode(instruction.data))
    }

    @Test func approveInstruction() throws {
        let instruction = Token2022Program.approveInstruction(
            account: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5",
            delegate: "QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo",
            owner: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG",
            multiSigners: [],
            amount: 1000
        )

        #expect(instruction.keys.count == 3)
        #expect(instruction.keys[0] == .writable(publicKey: "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5", isSigner: false))
        #expect(instruction.keys[1] == .readonly(publicKey: "QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo", isSigner: false))
        #expect(instruction.keys[2] == .readonly(publicKey: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG", isSigner: true))
        #expect(instruction.programId == Token2022Program.id)
        #expect("4d5tSvUuzUVM" == Base58.encode(instruction.data))
    }

    @Test func mintToInstruction() throws {
        let instruction = Token2022Program.mintToInstruction(
            mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            destination: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3",
            authority: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG",
            amount: 1_000_000_000
        )

        #expect(instruction.keys.count == 3)
        #expect(instruction.keys[0] == .writable(publicKey: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", isSigner: false))
        #expect(instruction.keys[1] == .writable(publicKey: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3", isSigner: false))
        #expect(instruction.keys[2] == .writable(publicKey: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG", isSigner: true))
        #expect(instruction.programId == Token2022Program.id)
        #expect("6AsKhot84V8s" == Base58.encode(instruction.data))
    }

    @Test func closeAccountInstruction() throws {
        let instruction = Token2022Program.closeAccountInstruction(
            account: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3",
            destination: "QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo",
            owner: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG"
        )

        #expect(instruction.keys.count == 3)
        #expect(instruction.keys[0] == .writable(publicKey: "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3", isSigner: false))
        #expect(instruction.keys[1] == .writable(publicKey: "QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo", isSigner: false))
        #expect(instruction.keys[2] == .readonly(publicKey: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG", isSigner: false))
        #expect(instruction.programId == Token2022Program.id)
        #expect("A" == Base58.encode(instruction.data))
    }
}
