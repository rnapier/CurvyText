//
//  ContentView.swift
//  CurvyText
//
//  Created by Rob Napier on 12/6/19.
//  Copyright © 2019 Rob Napier. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var P0 = CGPoint(x: 50, y: 500)
    @State var P1 = CGPoint(x: 300, y: 300)
    @State var P2 = CGPoint(x: 400, y: 700)
    @State var P3 = CGPoint(x: 650, y: 500)

    let text: NSAttributedString = {
        let string = NSString("You can display text along a curve, with bold, color, and big text.")

        let s = NSMutableAttributedString(string: string as String,
                                          attributes: [.font: UIFont.systemFont(ofSize: 16)])

        s.addAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], range: string.range(of: "bold"))
        s.addAttributes([.foregroundColor: UIColor.red], range: string.range(of: "color"))
        s.addAttributes([.font: UIFont.systemFont(ofSize: 32)], range: string.range(of: "big text"))
        return s
    }()

    var body: some View {
        ZStack{
            Path() {
                $0.move(to: P0)
                $0.addCurve(to: P3, control1: P1, control2: P2)
            }
            .stroke(Color.blue, lineWidth: 2)

            PathText(text: text, P0: P0, P1: P1, P2: P2, P3: P3)

            ControlPoint(position: $P0)
                .foregroundColor(.green)

            ControlPoint(position: $P1)
                .foregroundColor(.black)

            ControlPoint(position: $P2)
                .foregroundColor(.black)

            ControlPoint(position: $P3)
                .foregroundColor(.red)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ControlPoint: View {
    let size = CGSize(width: 13, height: 13)

    @Binding var position: CGPoint

    var body: some View {
        Rectangle()
            .frame(width: size.width, height: size.height)
            .position(position)
            .gesture(
                DragGesture().onChanged {
                    self.position = $0.location
            })
    }
}

struct PathText: UIViewRepresentable {
    var text: NSAttributedString
    var P0: CGPoint
    var P1: CGPoint
    var P2: CGPoint
    var P3: CGPoint

    func makeUIView(context: UIViewRepresentableContext<PathText>) -> PathTextView {
        PathTextView()
    }

    func updateUIView(_ uiView: PathText.UIViewType, context: UIViewRepresentableContext<PathText>) {
        uiView.text = text
        uiView.P0 = P0
        uiView.P1 = P1
        uiView.P2 = P2
        uiView.P3 = P3
        uiView.setNeedsDisplay()
    }
}

/*
 Draws attributed text along a cubic Bezier path defined by P0, P1, P2, and P3
 */
class PathTextView: UIView {

    var P0 = CGPoint.zero
    var P1 = CGPoint.zero
    var P2 = CGPoint.zero
    var P3 = CGPoint.zero

    var text: NSAttributedString {
        get { textStorage }
        set {
            textStorage.setAttributedString(newValue)
            locations = (0..<layoutManager.numberOfGlyphs).map { [layoutManager] glyphIndex in
                layoutManager.location(forGlyphAt: glyphIndex)
            }

            lineFragmentOrigin = layoutManager
                .lineFragmentRect(forGlyphAt: 0, effectiveRange: nil)
                .origin
        }
    }

    private let layoutManager = NSLayoutManager()
    private let textStorage = NSTextStorage()

    private var locations: [CGPoint] = []
    private var lineFragmentOrigin = CGPoint.zero

    init() {
        textStorage.addLayoutManager(layoutManager)
        super.init(frame: .zero)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {

        let context = UIGraphicsGetCurrentContext()!

        var offset: CGFloat = 0.0
        var lastGlyphPoint = P0
        var lastX: CGFloat = 0.0

        // Compute location for each glyph, transform the context, and then draw
        for (index, location) in locations.enumerated() {
            context.saveGState()

            let distance = location.x - lastX
            offset = getOffset(atDistance: distance, from: lastGlyphPoint, offset: offset)

            let glyphPoint = getPoint(forOffset: offset)
            let angle = getAngle(forOffset: offset)

            lastGlyphPoint = glyphPoint
            lastX = location.x

            context.translateBy(x: glyphPoint.x, y: glyphPoint.y)
            context.rotate(by: angle)

            // The "at:" in drawGlyphs is the origin of the line fragment. We've already adjusted the
            // context, so take that back out.
            let adjustedOrigin = CGPoint(x: -(lineFragmentOrigin.x + location.x),
                                         y: -(lineFragmentOrigin.y + location.y))

            layoutManager.drawGlyphs(forGlyphRange: NSRange(location: index, length: 1),
                                     at: adjustedOrigin)

            context.restoreGState()
        }
    }

    func getPoint(forOffset t: CGFloat) -> CGPoint {
        CGPoint(x: bezier(t, P0.x, P1.x, P2.x, P3.x),
                y: bezier(t, P0.y, P1.y, P2.y, P3.y))
    }

    func getAngle(forOffset t: CGFloat) -> CGFloat {
        let dx = bezierPrime(t, P0.x, P1.x, P2.x, P3.x)
        let dy = bezierPrime(t, P0.y, P1.y, P2.y, P3.y)
        return atan2(dy, dx)
    }

    // Simplistic routine to find the offset along Bezier that is
    // aDistance away from aPoint. anOffset is the offset used to
    // generate aPoint, and saves us the trouble of recalculating it
    // This routine just walks forward until it finds a point at least
    // aDistance away. Good optimizations here would reduce the number
    // of guesses, but this is tricky since if we go too far out, the
    // curve might loop back on leading to incorrect results. Tuning
    // kStep is good start.
    func getOffset(atDistance distance: CGFloat, from point: CGPoint, offset: CGFloat) -> CGFloat {
        let kStep: CGFloat = 0.001 // 0.0001 - 0.001 work well
        var newDistance: CGFloat = 0
        var newOffset = offset + kStep
        while newDistance <= distance && newOffset < 1.0 {
            newOffset += kStep
            newDistance = point.distance(to: getPoint(forOffset: newOffset))
        }
        return newOffset
    }
}

// The Bezier function at t
func bezier(_ t: CGFloat, _ P0: CGFloat, _ P1: CGFloat, _ P2: CGFloat, _ P3: CGFloat) -> CGFloat {
           (1-t)*(1-t)*(1-t)         * P0
     + 3 *       (1-t)*(1-t) *     t * P1
     + 3 *             (1-t) *   t*t * P2
     +                         t*t*t * P3
}

// The slope of the Bezier function at t
func bezierPrime(_ t: CGFloat, _ P0: CGFloat, _ P1: CGFloat, _ P2: CGFloat, _ P3: CGFloat) -> CGFloat {
       0
    -  3 * (1-t)*(1-t) * P0
    + (3 * (1-t)*(1-t) * P1) - (6 * t * (1-t) * P1)
    - (3 *         t*t * P2) + (6 * t * (1-t) * P2)
    +  3 * t*t * P3
}

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return hypot(dx, dy)
    }
}
