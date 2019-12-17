//
//  File.swift
//  
//
//  Created by Rob Napier on 12/16/19.
//

import Foundation
import CoreText

#if canImport(UIKit)
import UIKit
typealias PlatformFont = UIFont
#elseif canImport(AppKit)
typealias PlatformFont = NSFont
#else
#error("Unsupported platform")
#endif

extension CTLine {
    var glyphRuns: [CTRun] { CTLineGetGlyphRuns(self) as! [CTRun] }
}

extension CTRun {
    var glyphCount: Int { CTRunGetGlyphCount(self) }

    var stringIndices: [Int] {
        let size = glyphCount
        return Array(unsafeUninitializedCapacity: size) { buffer, initializedCount in
            initializedCount = size
            CTRunGetStringIndices(self, CFRange(), buffer.baseAddress!)
        }
    }

    var attributes: [NSAttributedString.Key: Any] {
        CTRunGetAttributes(self) as! [NSAttributedString.Key: Any]
    }

    var font: PlatformFont { attributes[.font] as! PlatformFont }

    var stringRange: CFRange { CTRunGetStringRange(self) }

    // Remember, it's possible to have one character made up of multiple glyphs (Ö can be two glyphs)
    // Also, one glyph can be multiple characters (ff ligature)
    var glyphCharacterMapping: [(glyphRange: CFRange, characterRange: NSRange)] {
        var mapping: [(glyphRange: CFRange, characterRange: NSRange)] = []
        let stringIndexes = self.stringIndices + [stringRange.location + stringRange.length] // Add the end of the string

        var glyphIndex = 0
        while glyphIndex < glyphCount {
            let currentCharacterIndex = stringIndexes[glyphIndex]
            var nextCharacterIndex = stringIndexes[glyphIndex + 1]
            let characterRange = NSRange(location: currentCharacterIndex, length: nextCharacterIndex - currentCharacterIndex)

            var glyphLength = 1
            while nextCharacterIndex == currentCharacterIndex && glyphIndex + glyphLength < glyphCount {
                glyphLength += 1
                nextCharacterIndex = stringIndexes[glyphIndex + glyphLength]
            }

            let glyphRange = CFRange(location: glyphIndex, length: glyphLength)

            mapping.append((glyphRange: glyphRange, characterRange: characterRange))

            glyphIndex += glyphLength
        }
        return mapping
    }

    func typographicFrame(glyphRange: CFRange) -> CGRect {
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var position: CGPoint = .zero
        let width = CTRunGetTypographicBounds(self, glyphRange, &ascent, &descent, nil)
        CTRunGetPositions(self, glyphRange, &position)
        return CGRect(origin: position,
                      size: CGSize(width: CGFloat(width), height: ascent + descent))
    }
}
