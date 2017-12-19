//
//  String+Yams.swift
//  Yams
//
//  Created by Norio Nomura on 12/7/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

import Foundation

extension String {
    typealias LineNumberColumnAndContents = (lineNumber: Int, column: Int, contents: String)

    /// line number, column and contents at offset.
    ///
    /// - parameter offset: Int
    ///
    /// - returns: lineNumber: line number start from 0,
    ///            column: utf16 column start from 0,
    ///            contents: substring of line
    func lineNumberColumnAndContents(at offset: Int) -> LineNumberColumnAndContents? {
        return index(startIndex, offsetBy: offset, limitedBy: endIndex).flatMap(lineNumberColumnAndContents)
    }

    /// line number, column and contents at Index.
    ///
    /// - parameter index: String.Index
    ///
    /// - returns: lineNumber: line number start from 0,
    ///            column: utf16 column start from 0,
    ///            contents: substring of line
    func lineNumberColumnAndContents(at index: Index) -> LineNumberColumnAndContents {
        assert((startIndex..<endIndex).contains(index))
        var number = 0
        var outStartIndex = startIndex, outEndIndex = startIndex, outContentsEndIndex = startIndex
        getLineStart(&outStartIndex, end: &outEndIndex, contentsEnd: &outContentsEndIndex,
                     for: startIndex..<startIndex)
        while outEndIndex <= index && outEndIndex < endIndex {
            number += 1
            let range: Range = outEndIndex..<outEndIndex
            getLineStart(&outStartIndex, end: &outEndIndex, contentsEnd: &outContentsEndIndex,
                         for: range)
        }
        let utf16StartIndex = outStartIndex.samePosition(in: utf16)!
        let utf16Index = index.samePosition(in: utf16)!
        return (
            number,
            utf16.distance(from: utf16StartIndex, to: utf16Index),
            String(self[outStartIndex..<outEndIndex])
        )
    }

    /// substring indicated by line number.
    ///
    /// - parameter line: line number starts from 0.
    ///
    /// - returns: substring of line contains line ending characters
    func substring(at line: Int) -> String {
        var number = 0
        var outStartIndex = startIndex, outEndIndex = startIndex, outContentsEndIndex = startIndex
        getLineStart(&outStartIndex, end: &outEndIndex, contentsEnd: &outContentsEndIndex,
                     for: startIndex..<startIndex)
        while number < line && outEndIndex < endIndex {
            number += 1
            let range: Range = outEndIndex..<outEndIndex
            getLineStart(&outStartIndex, end: &outEndIndex, contentsEnd: &outContentsEndIndex,
                         for: range)
        }
        return String(self[outStartIndex..<outEndIndex])
    }

    /// String appending newline if is not ending with newline.
    var endingWithNewLine: String {
        let isEndsWithNewLines = unicodeScalars.last.map(CharacterSet.newlines.contains) ?? false
        if isEndsWithNewLines {
            return self
        } else {
            return self + "\n"
        }
    }

    /// Returns snake cased string
    ///
    /// Capital characters are determined by testing membership in `CharacterSet.uppercaseLetters` and
    /// `CharacterSet.lowercaseLetters` (Unicode General Categories Lu and Lt).
    /// The conversion to lower case uses `Locale.system`, also known as the ICU "root" locale. This means the result is
    /// consistent regardless of the current user's locale and language preferences.
    ///
    /// Converting from camel case to snake case:
    /// 1. Splits words at the boundary of lower-case to upper-case
    /// 2. Inserts `_` between words
    /// 3. Lowercases the entire string
    /// 4. Preserves starting and ending `_`.
    ///
    /// For example, `oneTwoThree` becomes `one_two_three`. `_oneTwoThree_` becomes `_one_two_three_`.
    var snakecased: String {
        guard !isEmpty else { return self }
        var words = [Range<Index>](), wordStart = startIndex, searchStart = startIndex
        while let upperCaseRange = rangeOfCharacter(from: .uppercaseLetters, range: searchStart..<endIndex) {
            if upperCaseRange.lowerBound != startIndex {
                words.append(wordStart..<upperCaseRange.lowerBound)
            }
            guard let lowerCaseRange = rangeOfCharacter(from: .lowercaseLetters,
                                                        range: upperCaseRange.upperBound..<endIndex) else {
                                                            wordStart = upperCaseRange.lowerBound
                                                            break
            }
            if upperCaseRange.upperBound == lowerCaseRange.lowerBound {
                wordStart = upperCaseRange.lowerBound
            } else {
                wordStart = index(before: lowerCaseRange.lowerBound)
                words.append(upperCaseRange.lowerBound..<wordStart)
            }
            searchStart = lowerCaseRange.upperBound
        }
        words.append(wordStart..<endIndex)
        return words.map({ self[$0] }).joined(separator: "_").lowercased()
    }
}
