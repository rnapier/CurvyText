//
//  UIKit.swift
//  
//
//  Created by Rob Napier on 1/4/20.
//

#if canImport(UIKit)
import UIKit
import SwiftUI

//typealias PlatformFont = UIFont
typealias PlatformColor = UIColor

@available(iOS 13, *)
extension PathText: UIViewRepresentable {
    public func makeUIView(context: Context) -> PathTextView { PathTextView() }

    public func updateUIView(_ uiView: PathTextView, context: Context) {
        uiView.text = text
        uiView.path = path
    }
}

/*
 Draws attributed text along a cubic Bezier path defined by P0, P1, P2, and P3
 */
public class PathTextView: UIView {

    private var layoutManager = PathTextLayoutManager()

    public var text: NSAttributedString {
        get { layoutManager.text }
        set {
            layoutManager.text = newValue
            setNeedsDisplay()
        }
    }

    public var path: CGPath {
        get { layoutManager.path }
        set {
            layoutManager.path = newValue
            setNeedsDisplay()
        }
    }

    public init() {
        super.init(frame: .zero)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        layoutManager.draw(in: context)
    }
}
#endif