//
//  SwiftUI.swift
//  
//
//  Created by Rob Napier on 1/4/20.
//

import SwiftUI

@available(iOS, introduced: 13)
@available(OSX, introduced: 10.15)
public struct PathText {
    public var text: NSAttributedString
    public var path: CGPath

    public init(text: NSAttributedString, path: Path) {
        self.init(text: text, path: path.cgPath)
    }

    public init(text: NSAttributedString, path: CGPath) {
        self.text = text
        self.path = path
    }
}
