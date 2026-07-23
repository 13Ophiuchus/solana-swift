import SolanaSwift
import Foundation
import Testing

struct BufferLayoutDecodingTests {
    // MARK: - Raw data

    @Test func decodingRawData() throws {
        let string =
            "AQAAAAYa2dBThxVIU37ePiYYSaPft/0C+rx1siPI5GrbhT0MABCl1OgAAAAGAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="

        let data = Data(base64Encoded: string)!

        var binaryReader = BinaryReader(bytes: data.bytes)

        let expectedBytes: [UInt8] = [
            1, 0, 0, 0, 6, 26, 217, 208, 83, 135, 21,
            72, 83, 126, 222, 62, 38, 24, 73, 163, 223, 183,
            253, 2, 250, 188, 117, 178, 35, 200, 228,
            106, 219, 133, 61, 12, 0, 16, 165, 212, 232,
            0, 0, 0, 6, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        ]

        #expect(try Data(from: &binaryReader).bytes == expectedBytes)
    }

    // MARK: - VecU8

    @Test func decodingVecU8() throws {
        let string = "GQCn7dKsGcVAJhtFRDDBcRgD8i3I/WDk4Z2y"
        let data = Data(base64Encoded: string)!
        var binaryReader = BinaryReader(bytes: data.bytes)
        let vecU8 = try VecU8<UInt16>(from: &binaryReader)

        #expect(vecU8.length == 25)
        #expect(vecU8.data.bytes == [
            167, 237, 210, 172, 25, 197,
            64, 38, 27, 69, 68, 48, 193,
            113, 24, 3, 242, 45, 200, 253,
            96, 228, 225, 157, 178,
        ])
    }

    // MARK: - Mint

    @Test func decodingMint() throws {
        #expect(TokenMintState.BUFFER_LENGTH == 82)

        let string =
            "AQAAAAYa2dBThxVIU37ePiYYSaPft/0C+rx1siPI5GrbhT0MABCl1OgAAAAGAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="

        let data = Data(base64Encoded: string)!

        var binaryReader = BinaryReader(bytes: data.bytes)
        let mintLayout = try TokenMintState(from: &binaryReader)

        #expect(mintLayout.mintAuthorityOption == 1)
        #expect(mintLayout.mintAuthority?.base58EncodedString == "QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo")
        #expect(mintLayout.supply == 1_000_000_000_000)
        #expect(mintLayout.decimals == 6)
        #expect(mintLayout.isInitialized == true)
        #expect(mintLayout.freezeAuthorityOption == 0)
        #expect(mintLayout.freezeAuthority == nil)
    }

    // MARK: - Account info

    @Test func decodingAccountInfo() throws {
        #expect(TokenAccountState.BUFFER_LENGTH == 165)

        let string =
            "BhrZ0FOHFUhTft4+JhhJo9+3/QL6vHWyI8jkatuFPQwCqmOzhzy1ve5l2AqL0ottCChJZ1XSIW3k3C7TaBQn7aCGAQAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWqAQAAAAAAAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

        let data = Data(base64Encoded: string)!

        var binaryReader = BinaryReader(bytes: data.bytes)
        let accountInfo = try TokenAccountState(from: &binaryReader)

        #expect("QqCCvshxtqMAL2CVALqiJB7uEeE5mjSPsseQdDzsRUo" == accountInfo.mint.base58EncodedString)
        #expect("BQWWFhzBdw2vKKBUX17NHeFbCoFQHfRARpdztPE2tDJ" == accountInfo.owner.base58EncodedString)
        #expect(accountInfo.lamports == 100_000)
        #expect(accountInfo.delegateOption == 1)
        #expect("GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5" == accountInfo.delegate?.base58EncodedString)
        #expect(accountInfo.isInitialized == true)
        #expect(accountInfo.isFrozen == false)
        #expect(accountInfo.state == 1)
        #expect(accountInfo.isNativeOption == 0)
        #expect(accountInfo.rentExemptReserve == nil)
        #expect(accountInfo.isNativeRaw == 0)
        #expect(accountInfo.isNative == false)
        #expect(accountInfo.delegatedAmount == 100)
        #expect(accountInfo.closeAuthorityOption == 0)
        #expect(accountInfo.closeAuthority?.base58EncodedString == nil)
    }

    @Test func decodingAccountInfo2() throws {
        let string =
            "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWq"

        let data = Data(base64Encoded: string)!

        var binaryReader = BinaryReader(bytes: data.bytes)
        let accountInfo = try TokenAccountState(from: &binaryReader)

        #expect("11111111111111111111111111111111" == accountInfo.mint.base58EncodedString)
        #expect("11111111111111111111111111111111" == accountInfo.owner.base58EncodedString)
        #expect(accountInfo.lamports == 0)
        #expect(accountInfo.delegateOption == 0)
        #expect(accountInfo.delegate == nil)
        #expect(accountInfo.isInitialized == false)
        #expect(accountInfo.isFrozen == false)
        #expect(accountInfo.state == 0)
        #expect(accountInfo.isNativeOption == 0)
        #expect(accountInfo.rentExemptReserve == nil)
        #expect(accountInfo.isNativeRaw == 0)
        #expect(accountInfo.isNative == false)
        #expect(accountInfo.delegatedAmount == 0)
        #expect(accountInfo.closeAuthorityOption == 1)
        #expect(accountInfo.closeAuthority?.base58EncodedString == "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5")

        let string2 =
            "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAOt6vNDYdevCbaGxgaMzmz7yoxaVu3q9vGeCc7ytzeWq"
        let data2 = Data(base64Encoded: string2)!

        var binaryReader2 = BinaryReader(bytes: data2.bytes)
        let accountInfo2 = try TokenAccountState(from: &binaryReader2)

        #expect("11111111111111111111111111111111" == accountInfo2.mint.base58EncodedString)
        #expect("11111111111111111111111111111111" == accountInfo2.owner.base58EncodedString)
        #expect(accountInfo2.lamports == 0)
        #expect(accountInfo2.delegateOption == 0)
        #expect(accountInfo2.delegate == nil)
        #expect(accountInfo2.isInitialized == true)
        #expect(accountInfo2.isFrozen == true)
        #expect(accountInfo2.state == 2)
        #expect(accountInfo2.isNativeOption == 0)
        #expect(accountInfo2.rentExemptReserve == nil)
        #expect(accountInfo2.isNativeRaw == 0)
        #expect(accountInfo2.isNative == false)
        #expect(accountInfo2.delegatedAmount == 0)
        #expect(accountInfo2.closeAuthorityOption == 1)
        #expect(accountInfo2.closeAuthority?.base58EncodedString == "GrDMoeqMLFjeXQ24H56S1RLgT4R76jsuWCd6SvXyGPQ5")
    }

    // MARK: - TokenSwapInfo

    @Test func decodingTokenSwapInfo() throws {
        #expect(TokenSwapInfo.BUFFER_LENGTH == 324)

        let string =
            "AQH/Bt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKkg7XoTWySqouc9rBPiFviH2xU9/fRb+6P90QcOMKupqewjVdppkaFaD9TmikzQc7KAtp/LEF9bATPPnDdGT+7Kj7KrmDRVoZN9WTu3h9wgrrN83pVvcqGHLhOtWWeWCUjG+nrzvtutOj1l82qryXQxsbvkwtL24OR8pgIDRS9dYZqhgojuhD2D9j0JH/1UU78OyY17yIzxSctOkEdQqtVncXgwwKhJB+PCDsVtlUWWQbPgBu+MNnFskXx8qDFMwSAeAAAAAAAAABAnAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        let data = Data(base64Encoded: string)!
        var binaryReader = BinaryReader(bytes: data.bytes)
        let swapInfo = try TokenSwapInfo(from: &binaryReader)

        #expect(swapInfo.version == 1)
        #expect(swapInfo.isInitialized == true)
        #expect(swapInfo.nonce == 255)
        #expect(swapInfo.tokenProgramId.base58EncodedString == "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
        #expect(swapInfo.tokenAccountA.base58EncodedString == "3DY5BRoi2dsBW8XsBep5GXAipbDqUJwLwGxJVTcZ3Xfe")
        #expect(swapInfo.tokenAccountB.base58EncodedString == "GtnU7VTM5bn2Z8LSfAa1Jz3YedeffxzkExkieFQsAjTP")
        #expect(swapInfo.tokenPool.base58EncodedString == "AfwKRiMcANbPdELxAisQY3hCJg9M86fDGQMGPYGswvYX")
        #expect(swapInfo.mintA.base58EncodedString == "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
        #expect(swapInfo.mintB.base58EncodedString == "BQcdHdAQW1hczDbBi9hiegXAR7A98Q9jx3X3iBBBDiq4")
        #expect(swapInfo.feeAccount.base58EncodedString == "8dwNHBvcqG7eXWhDucKXTcS57k9cweopc55Mm648N8B9")
        #expect(swapInfo.tradeFeeNumerator == 30)
        #expect(swapInfo.tradeFeeDenominator == 10000)
        #expect(swapInfo.ownerTradeFeeNumerator == 0)
        #expect(swapInfo.ownerTradeFeeDenominator == 0)
        #expect(swapInfo.ownerWithdrawFeeNumerator == 0)
        #expect(swapInfo.ownerWithdrawFeeDenominator == 0)
        #expect(swapInfo.hostFeeNumerator == 0)
        #expect(swapInfo.hostFeeDenominator == 0)
        #expect(swapInfo.curveType == 0)
        #expect(swapInfo.payer.base58EncodedString == "11111111111111111111111111111111")
    }

    // MARK: - EmptyInfo

    @Test func decodingEmptyInfo() throws {
        let string =
            "AQAAAAYa2dBThxVIU37ePiYYSaPft/0C+rx1siPI5GrbhT0MABCl1OgAAAAGAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
        let data = Data(base64Encoded: string)!
        var binaryReader = BinaryReader(bytes: data.bytes)
        let _ = try EmptyInfo(from: &binaryReader)
    }

    // MARK: - Token2022

    @Test func decodingToken2022MintState() throws {
        let string =
            "AAAAAAT3LznRbp1toHmr0Mjv1bBjc6oSrtihgQu/PG0Sunz6XUTVg3ktAAAFAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEAbAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT3LznRbp1toHmr0Mjv1bBjc6oSrtihgQu/PG0Sunz6N5bilgAAAAASAgAAAAAAAAAgPYh5LQAALAESAgAAAAAAAAAgPYh5LQAALAE="
        let data = Data(base64Encoded: string)!
        var binaryReader = BinaryReader(bytes: data.bytes)
        let state = try Token2022MintState(from: &binaryReader)

        #expect(state.mintAuthorityOption == 0)
        #expect(state.mintAuthority?.base58EncodedString == "LPF354oHyPWL7BoMRySPQLwfvUyqPBWpwC4R7atptrD")
        #expect(state.isInitialized == true)
        #expect(state.freezeAuthorityOption == 0)
        #expect(state.decimals == 5)
        #expect(state.supply == 49_999_926_084_701)
        #expect(state.extensions.count == 1)

        // Assertions for the extension state
        let extensionState = state.getParsedExtension(ofType: TransferFeeConfigExtensionState.self)!
        #expect(extensionState.withheldAmount == 2_531_431_991)
        #expect(extensionState.transferFeeConfigAuthority.base58EncodedString == "11111111111111111111111111111111")
        #expect(extensionState.withdrawWithHeldAuthority.base58EncodedString == "LPF354oHyPWL7BoMRySPQLwfvUyqPBWpwC4R7atptrD")
        #expect(extensionState.olderTransferFee.maximumFee == 50_000_000_000_000)
        #expect(extensionState.olderTransferFee.epoch == 530)
        #expect(extensionState.olderTransferFee.transferFeeBasisPoints == 300)
        #expect(extensionState.newerTransferFee.transferFeeBasisPoints == 300)
        #expect(extensionState.newerTransferFee.maximumFee == 50_000_000_000_000)
        #expect(extensionState.newerTransferFee.epoch == 530)
    }

    @Test func decodingToken2022MintState2() throws {
        // Mint FZYEgCWzzedxcmxYvGXSkMrj7TaA3bXoaEv6XMnwtLKh
        let string =
            "AAAAABdZNqd8UPqRoeBHXdhoEwzZNLf6UnDQ1UDsr4oXimfhquOLA1BVIXECAQAAAAAXWTanfFD6kaHgR13YaBMM2TS3+lJw0NVA7K+KF4pn4QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEAbAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALoDKJKHBCRLpAQAAAAAAAACQI15ZrVt7LAHpAQAAAAAAAACQI15ZrVt7LAEKADQAF1k2p3xQ+pGh4Edd2GgTDNk0t/pScNDVQOyviheKZ+EN9NlkAAAAAAAADfTZZAAAAAAAAAYAAQAB"
        let data = Data(base64Encoded: string)!
        var binaryReader = BinaryReader(bytes: data.bytes)
        let state = try Token2022MintState(from: &binaryReader)

        #expect(state.extensions.count == 3)

        let transferConfig = state.getParsedExtension(
            ofType: TransferFeeConfigExtensionState.self
        )

        #expect(transferConfig?.length == 108)
        #expect(transferConfig?.transferFeeConfigAuthority == "11111111111111111111111111111111")
        #expect(transferConfig?.withdrawWithHeldAuthority == "11111111111111111111111111111111")
        #expect(transferConfig?.withheldAmount == 1_299_782_865_324_245_038)
        #expect(transferConfig?.olderTransferFee.epoch == 489)
        #expect(transferConfig?.olderTransferFee.maximumFee == 8_888_888_888_888_889_344)
        #expect(transferConfig?.olderTransferFee.transferFeeBasisPoints == 300)
        #expect(transferConfig?.newerTransferFee.epoch == 489)
        #expect(transferConfig?.newerTransferFee.maximumFee == 8_888_888_888_888_889_344)
        #expect(transferConfig?.newerTransferFee.transferFeeBasisPoints == 300)

        let interestBearingConfig = state.getParsedExtension(
            ofType: InterestBearingConfigExtensionState.self
        )

        #expect(interestBearingConfig?.length == 52)
        #expect(interestBearingConfig?.rateAuthority == "2a9H7uNfUxt7YdS5yH3ZEijdPqpeBtyq7JPtVyi6XKtk")
        #expect(interestBearingConfig?.initializationTimestamp == 1_692_005_389)
        #expect(interestBearingConfig?.preUpdateAverageRate == 0)
        #expect(interestBearingConfig?.lastUpdateTimestamp == 1_692_005_389)
        #expect(interestBearingConfig?.currentRate == 0)
    }

    @Test func decodingToken2022AccountState() throws {
        let string =
            "c8d675Tc8/enuGEbVogbaWoW6iY9JFkJIswLnf/gvCXDAcw04n4gWtOj5P12Rb7RAxY9RRwFQOwFWCWPS3OnJgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgcAAAA="
        let data = Data(base64Encoded: string)!
        var binaryReader = BinaryReader(bytes: data.bytes)
        let state = try Token2022AccountState(from: &binaryReader)

        #expect(state.isNativeRaw == 0)
        #expect(state.delegatedAmount == 0)
        #expect(state.mint.base58EncodedString == "8nxJnGJDyvehdEHw4PgRc7ccJ1Zi134PhM2USK3WE8mS")
        #expect(state.delegateOption == 0)
        #expect(state.delegate == nil)
        #expect(state.isFrozen == false)
        #expect(state.closeAuthorityOption == 0)
        #expect(state.isNativeOption == 0)
        #expect(state.owner.base58EncodedString == "E8E6GvyCpbGu7YSFxfhTXGx6SW4VhzVmxWh3gbrgXZNd")
        #expect(state.lamports == 0)
        #expect(state.isInitialized == true)
        #expect(state.isNative == false)
        #expect(state.state == 1)

        #expect(state.extensions.count == 1)

        // Assertions for the extension state
        let firstExtension = state.extensions[0]
        #expect(firstExtension.type == Token2022ExtensionType.immutableOwner)

        let extensionState = firstExtension.state as! VecU8<UInt16>
        #expect(extensionState.length == 0)
        #expect(extensionState.data == Data())
    }
}
