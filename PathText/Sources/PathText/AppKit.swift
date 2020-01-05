//
//  AppKit.swift
//  
//
//  Created by Rob Napier on 1/4/20.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import SwiftUI

typealias PlatformColor = NSColor

@available(OSX, introduced: 10.15)
extension PathText: NSViewRepresentable {
    public func makeNSView(context: Context) -> PathTextView {
        PathTextView(flipped: true)
    }

    public func updateNSView(_ nsView: PathTextView, context: Context) {
        nsView.text = text
        nsView.path = path
    }
}

public class PathTextView: NSView {
    private var layoutManager = PathTextLayoutManager()

    private let _isFlipped: Bool
    override public var isFlipped: Bool { return _isFlipped }

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

    public init(frame: CGRect = .zero,
                text: NSAttributedString = NSAttributedString(),
                path: CGPath = CGMutablePath(),
                flipped: Bool = false) {

        self._isFlipped = flipped
        super.init(frame: frame)
        self.text = text
        self.path = path
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func draw(_ rect: CGRect) {
        let context = NSGraphicsContext.current!.cgContext

        if isFlipped {
            context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        }

        layoutManager.draw(in: context)
    }
}
#endif
