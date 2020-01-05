//
//  Previews.swift
//  
//
//  Created by Rob Napier on 1/5/20.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
private typealias PlatformFont = UIFont
#elseif canImport(AppKit)
private typealias PlatformFont = NSFont
#else
#error("Unsupported platform")
#endif

@available(iOS, introduced: 13)
@available(OSX, introduced: 10.15)
struct PathText_Previews: PreviewProvider {
//    static let text: NSAttributedString = {
//        let string = NSString("You can display text along a curve, with bold, color, and big text.")
//
//        let s = NSMutableAttributedString(string: string as String,
//                                          attributes: [.font: PlatformFont.systemFont(ofSize: 16)])
//
//        s.addAttributes([.font: PlatformFont.boldSystemFont(ofSize: 16)], range: string.range(of: "bold"))
//        s.addAttributes([.foregroundColor: PlatformColor.red], range: string.range(of: "color"))
//        s.addAttributes([.font: PlatformFont.systemFont(ofSize: 32)], range: string.range(of: "big text"))
//        return s
//    }()

    static let text: NSAttributedString = {
        let string = NSString("mmii can d\u{030a}isplay العربية tëxt along a cu\u{0327}rve, with bold, color, and big text.")

        let s = NSMutableAttributedString(string: string as String,
                                          attributes: [.font: PlatformFont.systemFont(ofSize: 48)])

        s.addAttribute(.font, value: PlatformFont.boldSystemFont(ofSize: 48), range: string.range(of: "tëxt"))
        s.addAttribute(.foregroundColor, value: PlatformColor.red, range: string.range(of: "d\u{030a}isplay"))
        s.addAttribute(.font, value: PlatformFont.systemFont(ofSize: 32), range: string.range(of: "big text"))

        s.addAttribute(.strokeColor, value: PlatformColor.blue, range: string.range(of: "can"))
        s.addAttribute(.strokeWidth, value: 2, range: string.range(of: "can"))

        s.addAttribute(.baselineOffset, value: 20, range: string.range(of: "along"))

        let shadow = NSShadow()
        shadow.shadowBlurRadius = 5
        shadow.shadowColor = PlatformColor.green
        shadow.shadowOffset = CGSize(width: 5, height: 10)
        s.addAttribute(.shadow, value: shadow, range: string.range(of: "can"))

        s.addAttribute(.writingDirection, value: [3], range: string.range(of: "mmii"))

        return s
    }()

    static func CurveView() -> some View {
        let P0 = CGPoint(x: 50, y: 300)
        let P1 = CGPoint(x: 300, y: 100)
        let P2 = CGPoint(x: 400, y: 500)
        let P3 = CGPoint(x: 650, y: 300)

        let path = Path() {
            $0.move(to: P0)
            $0.addCurve(to: P3, control1: P1, control2: P2)
        }

        return ZStack {
            PathText(text: text, path: path)
            path.stroke(Color.blue, lineWidth: 2)
        }
    }

    static func LineView() -> some View {
        let P0 = CGPoint(x: 50, y: 300)
        let P1 = CGPoint(x: 650, y: 300)

        let path = Path() {
            $0.move(to: P0)
            $0.addLine(to: P1)
        }

        return VStack {
            Text(verbatim: text.string)
                .font(.system(size: 48))
                .padding()
                .lineLimit(1)
            ZStack {
                PathText(text: text, path: path)
                path.stroke(Color.blue, lineWidth: 2)
            }
        }
    }

    static func LinesView() -> some View {
        let P0 = CGPoint(x: 50, y: 400)
        let P1 = CGPoint(x: 150, y: 100)
        let P2 = CGPoint(x: 650, y: 400)

        let path = Path() {
            $0.move(to: P0)
            $0.addLine(to: P1)
            $0.addLine(to: P2)
        }

        return ZStack {
            PathText(text: text, path: path)
            path.stroke(Color.blue, lineWidth: 2)
        }
    }

    static func LineAndCurveView() -> some View {
        let P0 = CGPoint(x: 50, y: 400)
        let P1 = CGPoint(x: 150, y: 200)
        let C1 = CGPoint(x: 300, y: 100)
        let C2 = CGPoint(x: 300, y: 400)
        let P3 = CGPoint(x: 650, y: 400)

        let path = Path() {
            $0.move(to: P0)
            $0.addLine(to: P1)
            $0.addCurve(to: P3, control1: C1, control2: C2)
        }

        return ZStack {
            PathText(text: text, path: path)
            path.stroke(Color.blue, lineWidth: 2)
        }
    }

    static func QuadCurveView() -> some View {
        let P0 = CGPoint(x: 50, y: 300)
        let P1 = CGPoint(x: 300, y: 100)
        let P2 = CGPoint(x: 650, y: 300)

        let path = Path() {
            $0.move(to: P0)
            $0.addQuadCurve(to: P2, control: P1)
        }

        return PathText(text: text, path: path)
    }

    static func RoundedRectView() -> some View {

        let P0 = CGPoint(x: 100, y: 100)
        let size = CGSize(width: 300, height: 200)
        let cornerSize = CGSize(width: 50, height: 50)

        let path = Path() {
            $0.addRoundedRect(in: CGRect(origin: P0, size: size), cornerSize: cornerSize)
        }

        return ZStack {
            PathText(text: text, path: path)
//            path.stroke(Color.blue, lineWidth: 2)
        }
    }

    static func TwoGlyphCharacter() -> some View {
        let P0 = CGPoint(x: 50, y: 300)
        let P1 = CGPoint(x: 650, y: 300)

        let path = Path() {
            $0.move(to: P0)
            $0.addLine(to: P1)
        }

        return VStack {
            Text("ÅX̊") // "X\u{030A}")
                .font(.system(size: 48))
            ZStack {
                PathText(text: NSAttributedString(string: "ÅX̊Z",
                                                  attributes: [.font: PlatformFont.systemFont(ofSize: 48)]), path: path)
                path.stroke(Color.blue, lineWidth: 2)
            }
        }
    }
    static var previews: some View {
        Group {
            CurveView()
            LineView()
            LinesView()
            LineAndCurveView()
            QuadCurveView()
            RoundedRectView()
            TwoGlyphCharacter()
        }.previewLayout(.fixed(width: 700, height: 500))
    }
}
