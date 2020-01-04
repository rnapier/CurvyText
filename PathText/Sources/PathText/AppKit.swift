//
//  AppKit.swift
//  
//
//  Created by Rob Napier on 1/4/20.
//

#if canImport(AppKit)
import AppKit
import SwiftUI

typealias PlatformFont = NSFont
typealias PlatformColor = NSColor

@available(OSX, introduced: 10.15)
extension PathText: NSViewRepresentable {
    public func makeNSView(context: Context) -> PathTextView { PathTextView() }

    public func updateNSView(_ nsView: PathTextView, context: Context) {
        nsView.text = text
        nsView.path = path
    }
}

public class PathTextView: NSView {

    private var layoutManager = PathTextLayoutManager()

    public var text: NSAttributedString {
        get { layoutManager.text }
        set {
            layoutManager.text = newValue
            setNeedsDisplay(self.bounds)
        }
    }

    public var path: CGPath {
        get { layoutManager.path }
        set {
            layoutManager.path = newValue
            setNeedsDisplay(self.bounds)
        }
    }

    public init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func draw(_ rect: CGRect) {
        let context = NSGraphicsContext.current!.cgContext
        layoutManager.draw(in: context)
    }
}
#endif
