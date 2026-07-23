#!/usr/bin/env python3
"""convert_phase1.py -- mechanical XCTest -> Swift Testing conversion for Phase 1 files.
Usage: python3 convert_phase1.py <file1.swift> <file2.swift> ...
Writes converted output to <file>.testing.swift alongside the original for review.

Fixes vs v1:
- Balances parens instead of using non-greedy regex, so multi-line / nested-paren
  XCTAssert* calls now convert correctly.
- Preserves 'final' modifier when converting class -> struct.
- Reports any XCTAssertThrowsError / other unhandled macros so they aren't silently skipped.
"""
import re
import sys
from pathlib import Path

SIMPLE_ASSERTS = {
    'XCTAssertTrue': 1,
    'XCTAssertFalse': 1,
    'XCTAssertNil': 1,
    'XCTAssertNotNil': 1,
    'XCTFail': 1,
    'XCTAssertEqual': 2,
    'XCTAssertNotEqual': 2,
}

UNHANDLED_MACROS = ['XCTAssertThrowsError', 'XCTAssertNoThrow', 'XCTAssertGreaterThan',
                     'XCTAssertLessThan', 'XCTAssertGreaterThanOrEqual', 'XCTAssertLessThanOrEqual']

CLASS_DECL = re.compile(r'(final\s+)?class (\w+): XCTestCase \{')
FUNC_DECL = re.compile(r'func (test\w+)\(')
IMPORT_XCTEST = re.compile(r'^import XCTest$', re.M)


def find_matching_paren(text, open_idx):
    depth = 0
    i = open_idx
    while i < len(text):
        if text[i] == '(':
            depth += 1
        elif text[i] == ')':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def split_top_level_args(arg_text):
    """Split on top-level commas only (ignoring commas nested in parens/brackets/strings)."""
    parts = []
    depth = 0
    current = []
    in_string = False
    for ch in arg_text:
        if ch == '"' and not in_string:
            in_string = True
        elif ch == '"' and in_string:
            in_string = False
        if not in_string:
            if ch in '([{':
                depth += 1
            elif ch in ')]}':
                depth -= 1
        if ch == ',' and depth == 0 and not in_string:
            parts.append(''.join(current))
            current = []
        else:
            current.append(ch)
    parts.append(''.join(current))
    return [p.strip() for p in parts]


def convert_asserts(text):
    for macro, arity in SIMPLE_ASSERTS.items():
        i = 0
        while True:
            idx = text.find(macro + '(', i)
            if idx == -1:
                break
            open_paren = idx + len(macro)
            close_paren = find_matching_paren(text, open_paren)
            if close_paren == -1:
                i = idx + 1
                continue
            inner = text[open_paren + 1:close_paren]
            args = split_top_level_args(inner)
            # Drop trailing message arg beyond required arity for assert macros (not XCTFail)
            if macro != 'XCTFail' and len(args) > arity:
                args = args[:arity]

            if macro == 'XCTAssertEqual':
                replacement = '#expect(' + args[0] + ' == ' + args[1] + ')'
            elif macro == 'XCTAssertNotEqual':
                replacement = '#expect(' + args[0] + ' != ' + args[1] + ')'
            elif macro == 'XCTAssertTrue':
                replacement = '#expect(' + args[0] + ')'
            elif macro == 'XCTAssertFalse':
                replacement = '#expect(!(' + args[0] + '))'
            elif macro == 'XCTAssertNil':
                replacement = '#expect(' + args[0] + ' == nil)'
            elif macro == 'XCTAssertNotNil':
                replacement = '#expect(' + args[0] + ' != nil)'
            elif macro == 'XCTFail':
                replacement = 'Issue.record(' + inner + ')'
            else:
                replacement = text[idx:close_paren + 1]

            text = text[:idx] + replacement + text[close_paren + 1:]
            i = idx + len(replacement)
    return text


def convert_unwrap(text):
    text = re.sub(r'\btry XCTUnwrap\(', 'try #require(', text)
    return text


def convert(text, filename):
    text = IMPORT_XCTEST.sub('import Testing', text)

    def class_sub(m):
        prefix = m.group(1) or ''
        return prefix + 'struct ' + m.group(2) + ' {'
    text = CLASS_DECL.sub(class_sub, text)

    def rename_test_func(m):
        name = m.group(1)
        rest = name[4:]
        rest = rest[0].lower() + rest[1:] if rest else rest
        if not rest:
            rest = name
        return '@Test func ' + rest + '('
    text = FUNC_DECL.sub(rename_test_func, text)

    text = convert_unwrap(text)
    text = convert_asserts(text)

    for macro in UNHANDLED_MACROS:
        if macro in text:
            print('  WARNING [' + filename + ']: contains ' + macro + ' -- needs manual conversion')

    return text


def main(paths):
    for p in paths:
        path = Path(p)
        original = path.read_text()
        converted = convert(original, str(path))
        out_path = path.with_suffix('.testing.swift')
        out_path.write_text(converted)
        print('Converted: ' + str(path) + ' -> ' + str(out_path))


if __name__ == '__main__':
    main(sys.argv[1:])
