# Swift Testing Migration — solana-swift-patched

Migration plan from XCTest to Swift Testing for the SolanaSwiftUnitTests and SolanaSwiftIntegrationTests targets. Package.swift already declares swift-tools-version: 6.0, so Swift Testing ships with the toolchain — no new package dependency is required.

Status legend: [ ] not started, [~] in progress, [x] done

---

## Discovery baseline (already run)

Commands used:

    cd /Users/nicreich/AetherAG-mono/solana-swift-patched
    find Tests -name '*.swift' | xargs wc -l | sort -n
    grep -rl 'XCTestCase\|XCTAssert\|XCTestExpectation\|XCTFail\|XCTUnwrap' Tests/ | sort
    grep -rl 'setUpWithError\|tearDownWithError\|override func setUp\|override func tearDown' Tests/ | sort
    grep -rl 'XCTestExpectation\|fulfillment(of\|wait(for' Tests/ | sort
    grep -rl 'func test.*async' Tests/ | sort

Result: 30 files, 4219 lines total use XCTest.

| Category | Files |
|---|---|
| setUp/tearDown lifecycle | SocketIntegrationTests, ObserveTransactionStatusTests, BlockchainClientWithNativeSOLTests, BlockchainClientWithTokenProgramTests, FeeCalculatorTests, SocketTests, GetAccountBalancesTests |
| XCTestExpectation / fulfillment | SocketIntegrationTests, SocketTests, TokensRepositoryPerformanceTests |
| async test funcs | APIClientTests (unit + integration), SocketIntegrationTests, APIClientExtensionsTests, APIClientSendTransactionTests, ObserveTransactionStatusTests, BlockchainClientWithNativeSOLTests, BlockchainClientWithTokenProgramTests, KeyPairTests, SocketTests, GetAccountBalancesTests, TokensRepositoryPerformanceTests, TokensRepositoryTests |

Phase 1 = pure assertions (none of the above). Phase 2 = lifecycle hooks, no expectations. Phase 3 = expectation-based async socket/timing tests.

---

## Core API mapping reference

| XCTest | Swift Testing |
|---|---|
| import XCTest | import Testing |
| class Foo: XCTestCase | struct Foo (or final class Foo if reference semantics needed) |
| func testX() | @Test func x() |
| XCTAssertEqual(a, b) | #expect(a == b) |
| XCTAssertTrue(x) / XCTAssertFalse(x) | #expect(x) / #expect(!x) |
| XCTAssertNil(x) / XCTAssertNotNil(x) | #expect(x == nil) / #expect(x != nil) |
| XCTFail("msg") | Issue.record("msg") |
| try XCTUnwrap(x) | try #require(x) |
| XCTAssertThrowsError | #expect(throws: ErrorType.self) { try ... } |
| XCTestExpectation + wait/fulfillment | await confirmation("desc") { confirm in ... } |
| setUpWithError() / tearDownWithError() | init() / deinit on a struct/final class |
| @testable import SolanaSwift | unchanged |

---

## Phase 1 — Pure assertion files (no setUp/tearDown, no expectations)

Mechanical XCTAssert* -> #expect conversions. Lowest risk, no async restructuring.

Files:
- Tests/SolanaSwiftUnitTests/Other/RegexTests.swift
- Tests/SolanaSwiftUnitTests/Programs/MemoProgramTests.swift
- Tests/SolanaSwiftUnitTests/Programs/OwnerValidationProgramTests.swift
- Tests/SolanaSwiftUnitTests/Other/PublicKeyTests.swift
- Tests/SolanaSwiftUnitTests/Other/KeyPairTests.swift (has async funcs, no lifecycle/expectations — still Phase 1)
- Tests/SolanaSwiftUnitTests/Other/CodableTests/EncodingTests.swift
- Tests/SolanaSwiftUnitTests/Models/SendingTransaction/MessageTests.swift
- Tests/SolanaSwiftUnitTests/Models/SendingTransaction/TransactionTests.swift
- Tests/SolanaSwiftUnitTests/Programs/SystemProgramTests.swift
- Tests/SolanaSwiftUnitTests/Programs/AssociatedTokenProgramTests.swift
- Tests/SolanaSwiftUnitTests/Programs/TokenProgramTests.swift
- Tests/SolanaSwiftUnitTests/Programs/Token2022ProgramTests.swift
- Tests/SolanaSwiftUnitTests/Programs/TokenSwapProgramTests.swift
- Tests/SolanaSwiftUnitTests/Other/BufferLayout/BufferLayoutDecodingTests.swift
- Tests/SolanaSwiftUnitTests/Other/BufferLayout/BufferLayoutEncodingTests.swift
- Tests/SolanaSwiftUnitTests/Socket/SocketDecodingTests.swift

### Step 1.1 — Discovery: inventory assertion calls per file

    cd /Users/nicreich/AetherAG-mono/solana-swift-patched
    for f in Tests/SolanaSwiftUnitTests/Other/RegexTests.swift Tests/SolanaSwiftUnitTests/Programs/MemoProgramTests.swift Tests/SolanaSwiftUnitTests/Programs/OwnerValidationProgramTests.swift Tests/SolanaSwiftUnitTests/Other/PublicKeyTests.swift Tests/SolanaSwiftUnitTests/Other/KeyPairTests.swift Tests/SolanaSwiftUnitTests/Other/CodableTests/EncodingTests.swift Tests/SolanaSwiftUnitTests/Models/SendingTransaction/MessageTests.swift Tests/SolanaSwiftUnitTests/Models/SendingTransaction/TransactionTests.swift Tests/SolanaSwiftUnitTests/Programs/SystemProgramTests.swift Tests/SolanaSwiftUnitTests/Programs/AssociatedTokenProgramTests.swift Tests/SolanaSwiftUnitTests/Programs/TokenProgramTests.swift Tests/SolanaSwiftUnitTests/Programs/Token2022ProgramTests.swift Tests/SolanaSwiftUnitTests/Programs/TokenSwapProgramTests.swift Tests/SolanaSwiftUnitTests/Other/BufferLayout/BufferLayoutDecodingTests.swift Tests/SolanaSwiftUnitTests/Other/BufferLayout/BufferLayoutEncodingTests.swift Tests/SolanaSwiftUnitTests/Socket/SocketDecodingTests.swift; do
        echo "== $f =="
        grep -oE 'XCTAssert[A-Za-z]*|XCTFail|XCTUnwrap' "$f" | sort | uniq -c
    done

### Step 1.2 — Development: automated conversion script (Python)

Save this as convert_phase1.py in the repo root:

    #!/usr/bin/env python3
    """convert_phase1.py -- mechanical XCTest -> Swift Testing conversion for Phase 1 files.
    Usage: python3 convert_phase1.py <file1.swift> <file2.swift> ...
    Writes converted output to <file>.testing.swift alongside the original for review.
    """
    import re
    import sys
    from pathlib import Path

    ASSERT_PATTERNS = [
        (re.compile(r'XCTAssertEqual\\((.\*?),\\s\*(.\*?)\\)$', re.M), r'#expect(\1 == \2)'),
        (re.compile(r'XCTAssertNotEqual\\((.\*?),\\s\*(.\*?)\\)$', re.M), r'#expect(\1 != \2)'),
        (re.compile(r'XCTAssertTrue\\((.\*?)\\)$', re.M), r'#expect(\1)'),
        (re.compile(r'XCTAssertFalse\\((.\*?)\\)$', re.M), r'#expect(!(\1))'),
        (re.compile(r'XCTAssertNil\\((.\*?)\\)$', re.M), r'#expect(\1 == nil)'),
        (re.compile(r'XCTAssertNotNil\\((.\*?)\\)$', re.M), r'#expect(\1 != nil)'),
        (re.compile(r'try XCTUnwrap\\((.\*?)\\)'), r'try #require(\1)'),
        (re.compile(r'XCTFail\\((.\*?)\\)$', re.M), r'Issue.record(\1)'),
    ]

    CLASS_DECL = re.compile(r'class (\w+): XCTestCase \{')
    FUNC_DECL = re.compile(r'func (test\w+)\(')
    IMPORT_XCTEST = re.compile(r'^import XCTest$', re.M)

    def convert(text):
        text = IMPORT_XCTEST.sub('import Testing', text)
        text = CLASS_DECL.sub(lambda m: 'struct ' + m.group(1) + ' {', text)

        def rename_test_func(m):
            name = m.group(1)
            stripped = name[4].lower() + name[5:] if len(name) > 4 else name
            return '@Test func ' + stripped + '('
        text = FUNC_DECL.sub(rename_test_func, text)

        for pattern, replacement in ASSERT_PATTERNS:
            text = pattern.sub(replacement, text)
        return text

    def main(paths):
        for p in paths:
            path = Path(p)
            original = path.read_text()
            converted = convert(original)
            out_path = path.with_suffix('.testing.swift')
            out_path.write_text(converted)
            print('Converted: ' + str(path) + ' -> ' + str(out_path))

    if __name__ == '__main__':
        main(sys.argv[1:])

### Step 1.3 — Review and promote

    for f in Tests/**/*.testing.swift; do
      diff -u "${f%.testing.swift}.swift" "$f"
    done
    for f in Tests/**/*.testing.swift; do
      mv "$f" "${f%.testing.swift}.swift"
    done

### Step 1.4 — Build and verify

    swift build
    swift test --filter RegexTests
    swift test 2>&1 | grep -E "^/Users.*error:" | sort -u -t: -k1,1
    swift test

---

## Phase 2 — Lifecycle hooks, no expectations

Convert setUpWithError/tearDownWithError to struct/final class init() (and deinit if teardown logic exists). Still fully async/await-compatible without confirmation().

Files:
- Tests/SolanaSwiftUnitTests/APIClient/APIClientTests.swift
- Tests/SolanaSwiftUnitTests/APIClient/APIClientExtensionsTests.swift
- Tests/SolanaSwiftUnitTests/APIClient/APIClientSendTransactionTests.swift
- Tests/SolanaSwiftUnitTests/APIClient/ObserveTransactionStatusTests.swift
- Tests/SolanaSwiftUnitTests/BlockchainClient/FeeCalculatorTests.swift
- Tests/SolanaSwiftUnitTests/BlockchainClient/BlockchainClientWithNativeSOLTests.swift
- Tests/SolanaSwiftUnitTests/BlockchainClient/BlockchainClientWithTokenProgramTests.swift
- Tests/SolanaSwiftUnitTests/SolanaTokenMetadata/TokensRepositoryTests.swift
- Tests/SolanaSwiftUnitTests/SolanaTokenMetadata/GetAccountBalancesTests.swift
- Tests/SolanaSwiftIntegrationTests/APIClient/APIClientTests.swift

### Step 2.1 — Discovery: catalog setUp/tearDown bodies

    cd /Users/nicreich/AetherAG-mono/solana-swift-patched
    for f in Tests/SolanaSwiftUnitTests/APIClient/APIClientTests.swift Tests/SolanaSwiftUnitTests/APIClient/APIClientExtensionsTests.swift Tests/SolanaSwiftUnitTests/APIClient/APIClientSendTransactionTests.swift Tests/SolanaSwiftUnitTests/APIClient/ObserveTransactionStatusTests.swift Tests/SolanaSwiftUnitTests/BlockchainClient/FeeCalculatorTests.swift Tests/SolanaSwiftUnitTests/BlockchainClient/BlockchainClientWithNativeSOLTests.swift Tests/SolanaSwiftUnitTests/BlockchainClient/BlockchainClientWithTokenProgramTests.swift Tests/SolanaSwiftUnitTests/SolanaTokenMetadata/TokensRepositoryTests.swift Tests/SolanaSwiftUnitTests/SolanaTokenMetadata/GetAccountBalancesTests.swift Tests/SolanaSwiftIntegrationTests/APIClient/APIClientTests.swift; do
        echo "== $f =="
        grep -n 'override func setUp\|override func tearDown\|var \w\+.*!' "$f"
    done

This surfaces every implicitly unwrapped `var x: T!` instance property set up per-test — these become `let` properties initialized directly in the new init().

### Step 2.2 — Development: setUp/tearDown to init/deinit converter (Python)

Save this as convert_phase2.py in the repo root:

    #!/usr/bin/env python3
    """convert_phase2.py -- convert XCTest lifecycle hooks to Swift Testing init/deinit.
    Usage: python3 convert_phase2.py <file.swift>
    Heuristic-based; always hand-review output before promoting.
    """
    import re
    import sys
    from pathlib import Path

    SETUP_RE = re.compile(r'override func setUpWithError\\(\\) throws \{(.*?)\n    \}\n', re.S)
    TEARDOWN_RE = re.compile(r'override func tearDownWithError\\(\\) throws \{(.*?)\n    \}\n', re.S)
    CLASS_DECL = re.compile(r'class (\w+): XCTestCase \{')

    def convert(text):
        setup_match = SETUP_RE.search(text)
        teardown_match = TEARDOWN_RE.search(text)

        text = SETUP_RE.sub('', text)
        text = TEARDOWN_RE.sub('', text)

        if setup_match:
            init_body = setup_match.group(1)
            init_block = '    init() throws {' + init_body + '\n    }\n\n'
            text = CLASS_DECL.sub(lambda m: 'final class ' + m.group(1) + ' {\n' + init_block, text, count=1)
        else:
            text = CLASS_DECL.sub(lambda m: 'final class ' + m.group(1) + ' {', text)

        if teardown_match:
            deinit_body = teardown_match.group(1)
            marker = '    // TODO(manual-review): deinit cannot throw/await -- verify teardown logic below\n'
            deinit_block = marker + '    deinit {' + deinit_body + '\n    }\n'
            text = text.rstrip().rstrip('}') + '\n' + deinit_block + '}\n'

        return text

    if __name__ == '__main__':
        for p in sys.argv[1:]:
            path = Path(p)
            converted = convert(path.read_text())
            out_path = path.with_suffix('.testing.swift')
            out_path.write_text(converted)
            print('Converted: ' + str(path) + ' -> ' + str(out_path) + ' (hand-review required)')

Run it, then re-run convert_phase1.py against the .testing.swift outputs to catch XCTAssert* calls in these same files too — the two scripts are composable.

### Step 2.3 — Manual review checklist per file

- Every deinit marked TODO(manual-review) — confirm no await/throws calls leaked in (not permitted in deinit); move async cleanup into a defer inside the @Test function body if needed, or drop teardown if it just resets local mock state that a fresh struct instance naturally discards.
- Any var properties only ever set once in setUp should become let in the new init().
- Confirm final class (not struct) is appropriate — use final class only if identity/reference semantics matter; otherwise prefer struct.

### Step 2.4 — Build and verify

    for f in Tests/**/*.testing.swift; do mv "$f" "${f%.testing.swift}.swift"; done
    swift build
    swift test 2>&1 | grep -E "^/Users.*error:" | sort -u -t: -k1,1
    swift test

---

## Phase 3 — Expectation-based async Socket/timing tests

The highest-risk phase: XCTestExpectation + wait/fulfillment(of:timeout:) patterns must become confirmation(). This is also where the Swift 6 concurrency fixes already applied (@unchecked Sendable mocks, removing self captures) pay off, since Swift Testing's confirmation closures are natively concurrency-safe.

Files:
- Tests/SolanaSwiftUnitTests/Socket/SocketTests.swift
- Tests/SolanaSwiftIntegrationTests/Socket/SocketIntegrationTests.swift
- Tests/SolanaSwiftUnitTests/SolanaTokenMetadata/TokensRepositoryPerformanceTests.swift

### Step 3.1 — Discovery: map every expectation to its fulfillment site

    cd /Users/nicreich/AetherAG-mono/solana-swift-patched
    for f in Tests/SolanaSwiftUnitTests/Socket/SocketTests.swift Tests/SolanaSwiftIntegrationTests/Socket/SocketIntegrationTests.swift Tests/SolanaSwiftUnitTests/SolanaTokenMetadata/TokensRepositoryPerformanceTests.swift; do
        echo "== $f =="
        grep -n 'XCTestExpectation\|\.fulfill(\|fulfillment(of\|expectedFulfillmentCount' "$f"
    done

For each XCTestExpectation, note: (1) how many .fulfill() call sites feed it, mapping to confirmation(expectedCount:); (2) whether it awaits a single async callback or multiple concurrent callbacks.

### Step 3.2 — Development: expectation to confirmation converter (Python, semi-automated)

Given the structural complexity (nested closures, DispatchQueue.main.asyncAfter, delegate callbacks), full automation is not safe here — this script only extracts a reviewable summary; the actual rewrite is manual. Save as analyze_expectations.py:

    #!/usr/bin/env python3
    """analyze_expectations.py -- extract expectation/fulfill call graph for manual Phase 3 conversion.
    Usage: python3 analyze_expectations.py <file.swift>
    """
    import re
    import sys
    from pathlib import Path

    EXPECTATION_DECL = re.compile(r'let (\w+) = XCTestExpectation\\(\\)')
    FULFILL_CALL = re.compile(r'(\w+)\.fulfill\\(\\)')
    WAIT_CALL = re.compile(r'wait\\(for:\\s\*\\\[(.\\\*?)\\\\],\\s\*timeout:\\s\*([\\d.]+)\\)')
    FULFILLMENT_CALL = re.compile(r'fulfillment\\(of:\\s\*\\\[(.\\\*?)\\\\],\\s\*timeout:\\s\*([\\d.]+)\\)')

    def analyze(path):
        text = path.read_text()
        declarations = EXPECTATION_DECL.findall(text)
        fulfills = FULFILL_CALL.findall(text)
        waits = WAIT_CALL.findall(text) + FULFILLMENT_CALL.findall(text)

        print('--- ' + str(path) + ' ---')
        print('Expectations declared: ' + str(declarations))
        for name in declarations:
            count = fulfills.count(name)
            print('  ' + name + ': fulfilled ' + str(count) + 'x -> confirmation(expectedCount: ' + str(max(count, 1)) + ')')
        print('wait/fulfillment call sites: ' + str(waits))
        print()

    if __name__ == '__main__':
        for p in sys.argv[1:]:
            analyze(Path(p))

### Step 3.3 — Manual conversion pattern

Reference pattern for a single-fulfillment expectation:

Before (XCTest):

    func testSocketEvents() async throws {
        let expectation = XCTestExpectation()
        let delegate = MockSocketDelegate()
        let socket = self.socket!
        delegate.onDisconnected = { expectation.fulfill() }
        socket.delegate = delegate
        socket.connect()
        await fulfillment(of: [expectation], timeout: 20.0)
    }

After (Swift Testing):

    @Test func socketEvents() async throws {
        let delegate = MockSocketDelegate()
        let socket = self.socket!
        await confirmation("socket disconnects") { confirm in
            delegate.onDisconnected = { confirm() }
            socket.delegate = delegate
            socket.connect()
            try await Task.sleep(for: .seconds(20))
        }
    }

For multi-fulfillment cases (e.g. TokensRepositoryPerformanceTests firing several concurrent callbacks), use confirmation(expectedCount: N) per the count discovered in Step 3.2.

### Step 3.4 — Rebuild the setUp/tearDown wrapper for these 3 files

These files also have lifecycle hooks (see Phase 2 discovery) — apply convert_phase2.py first, then hand-convert the expectation blocks per Step 3.3.

    python3 convert_phase2.py Tests/SolanaSwiftUnitTests/Socket/SocketTests.swift Tests/SolanaSwiftIntegrationTests/Socket/SocketIntegrationTests.swift

TokensRepositoryPerformanceTests.swift has no lifecycle hooks per discovery — skip phase 2 script, go straight to manual confirmation rewrite.

### Step 3.5 — Build and verify (full suite)

    cd /Users/nicreich/AetherAG-mono/solana-swift-patched
    for f in Tests/**/*.testing.swift; do mv "$f" "${f%.testing.swift}.swift"; done
    swift build
    swift test 2>&1 | grep -E "^/Users.*error:" | sort -u -t: -k1,1
    swift test

---

## Final cleanup

### Step 4.1 — Remove any residual XCTest imports

    cd /Users/nicreich/AetherAG-mono/solana-swift-patched
    grep -rl 'import XCTest' Tests/ | sort

Expect empty output once all 3 phases are complete.

### Step 4.2 — Remove now-unneeded @unchecked Sendable mocks

    grep -rn '@unchecked Sendable' Tests/ | sort

Review each: struct-based tests plus confirmation() closures are naturally Sendable-safe, so some @unchecked Sendable mock annotations added during the earlier Swift 6 concurrency pass may become unnecessary. Remove only after confirming swift build stays clean.

### Step 4.3 — Full regression pass

    swift test 2>&1 | tee /tmp/final_test_run.log
    grep -c 'Passed\|Failed' /tmp/final_test_run.log

### Step 4.4 — Update Package.swift comment / docs (optional)

No Package.swift changes are required (Swift Testing ships with tools-version 6.0), but consider adding a comment noting the framework in use for future contributors.

---

## Progress tracker

| Phase | Files | Status |
|---|---|---|
| Phase 1 — pure assertions | 15 files | [ ] |
| Phase 2 — lifecycle hooks | 10 files | [ ] |
| Phase 3 — expectation-based async | 3 files | [ ] |
| Final cleanup | -- | [ ] |

Total: 28 of 30 identified XCTest files accounted for explicitly above (TestDoubles/*.swift and SocketTestsHelper.swift are support files, not test-case files, and do not require @Test conversion — only import/reference cleanup once dependent test files migrate).
