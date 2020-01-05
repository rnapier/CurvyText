//
//  ViewController.swift
//  PathTextDemoMac
//
//  Created by Rob Napier on 1/5/20.
//  Copyright © 2020 Rob Napier. All rights reserved.
//

import Cocoa
import PathText

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let P0 = CGPoint(x: 50, y: 100)
        let P1 = CGPoint(x: 300, y: 0)
        let P2 = CGPoint(x: 400, y: 200)
        let P3 = CGPoint(x: 650, y: 100)

        let path = CGMutablePath()
        path.move(to: P0)
        path.addCurve(to: P3, control1: P1, control2: P2)

        let text: NSAttributedString = {
            let string = NSString("You can display text along a curve, with bold, color, and big text.")

            let s = NSMutableAttributedString(string: string as String,
                                              attributes: [.font: NSFont.systemFont(ofSize: 16)])

            s.addAttributes([.font: NSFont.boldSystemFont(ofSize: 16)], range: string.range(of: "bold"))
            s.addAttributes([.foregroundColor: NSColor.red], range: string.range(of: "color"))
            s.addAttributes([.font: NSFont.systemFont(ofSize: 32)], range: string.range(of: "big text"))
            return s
        }()

        let frame = CGRect(origin: CGPoint(x: 50, y: 100),
                           size: CGSize(width: 650, height: 200))

        let textView = PathTextView(frame: frame, text: text, path: path)

        textView.wantsLayer = true
        textView.layer?.borderColor = NSColor.red.cgColor
        textView.layer?.borderWidth = 1
        view.addSubview(textView)

        let pathView = PathView(frame: frame, path: path)
        view.addSubview(pathView)

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

class PathView: NSView {
    var path: CGPath
    init(frame: NSRect = .zero, path: CGPath) {
        self.path = path
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.addPath(path)
        ctx.strokePath()
    }
}
