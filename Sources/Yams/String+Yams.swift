//
//  String+Yams.swift
//  Yams
//
//  Created by Norio Nomura on 12/7/16.
//  Copyright (c) 2016 Yams. All rights reserved.
//

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
        var lineStart = startIndex
        var lineEnd = startIndex

        findLine(containing: startIndex, lineStart: &lineStart, lineEnd: &lineEnd)
        while lineEnd <= index && lineEnd < endIndex {
            number += 1
            findLine(containing: lineEnd, lineStart: &lineStart, lineEnd: &lineEnd)
        }
        let utf16StartIndex = lineStart.samePosition(in: utf16)!
        let utf16Index = index.samePosition(in: utf16)!
        return (
            number,
            utf16.distance(from: utf16StartIndex, to: utf16Index),
            String(self[lineStart..<lineEnd])
        )
    }

    /// substring indicated by line number.
    ///
    /// - parameter line: line number starts from 0.
    ///
    /// - returns: substring of line contains line ending characters
    func substring(at line: Int) -> String {
        var number = 0
        var lineStart = startIndex
        var lineEnd = startIndex

        findLine(containing: startIndex, lineStart: &lineStart, lineEnd: &lineEnd)
        while number < line && lineEnd < endIndex {
            number += 1
            findLine(containing: lineEnd, lineStart: &lineStart, lineEnd: &lineEnd)
        }
        return String(self[lineStart..<lineEnd])
    }

    /// String appending newline if is not ending with newline.
    var endingWithNewLine: String {
        let isEndsWithNewLines = last?.isNewline ?? false
        if isEndsWithNewLines {
            return self
        } else {
            return self + "\n"
        }
    }

    /// Find the line containing the given index, setting lineStart and lineEnd
    /// (lineEnd points past the line terminator).
    private func findLine(containing position: Index, lineStart: inout Index, lineEnd: inout Index) {
        lineStart = position
        var i = position
        while i < endIndex {
            let c = self[i]
            let next = self.index(after: i)
            if c == "\r" {
                // Handle \r\n as a single line ending
                if next < endIndex && self[next] == "\n" {
                    lineEnd = self.index(after: next)
                } else {
                    lineEnd = next
                }
                return
            } else if c == "\n" || c == "\r\n" {
                lineEnd = next
                return
            }
            i = next
        }
        lineEnd = endIndex
    }
}
