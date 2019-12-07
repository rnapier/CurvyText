import XCTest
import SwiftUI
@testable import PathText

@available(iOS 13.0, *)
final class PathTextTests: XCTestCase {
    static let text: NSAttributedString = {
        let string = NSString("You can display text along a curve, with bold, color, and big text.")

        let s = NSMutableAttributedString(string: string as String,
                                          attributes: [.font: UIFont.systemFont(ofSize: 16)])

        s.addAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], range: string.range(of: "bold"))
        s.addAttributes([.foregroundColor: UIColor.red], range: string.range(of: "color"))
        s.addAttributes([.font: UIFont.systemFont(ofSize: 32)], range: string.range(of: "big text"))
        return s
    }()

    func testCurve() {

        let P0 = CGPoint(x: 50, y: 500)
        let P1 = CGPoint(x: 300, y: 300)
        let P2 = CGPoint(x: 400, y: 700)
        let P3 = CGPoint(x: 650, y: 500)

        let path = Path() {
            $0.move(to: P0)
            $0.addCurve(to: P3, control1: P1, control2: P2)
        }

        let sections = path.sections()

        XCTAssertEqual(sections.count, 1)

        guard let section = sections.first as? PathCurveSection else {
            XCTFail()
            return
        }

        XCTAssertEqual(section.p0, P0)
        XCTAssertEqual(section.p1, P1)
        XCTAssertEqual(section.p2, P2)
        XCTAssertEqual(section.p3, P3)

        let tangents = path.tangents(atLocations: [0, 100, 200, 300, 400, 500, 600])
        print(tangents)
        XCTAssertEqual(tangents, [
            PathTangent(t: 0,
                        point: P0,
                        angle: -0.6747409422235526),
            PathTangent(t: 0.12500000000000008,
                        point: CGPoint(x: 137.30468750000003, y: 450.7812499999999),
                        angle: -0.3065673394544241),
            PathTangent(t: 0.2910000000000002,
                        point: CGPoint(x: 237.5362013000002, y: 448.2551948000002),
                        angle: 0.24776228093719516),
            PathTangent(t: 0.46100000000000035,
                        point: CGPoint(x: 329.50720430000024, y: 488.3711828000002),
                        angle: 0.5101379919705208),
            PathTangent(t: 0.6280000000000004,
                        point: CGPoint(x: 417.8291456000003, y: 535.8834176000001),
                        angle: 0.4199722465802793),
            PathTangent(t: 0.8000000000000006,
                        point: CGPoint(x: 515.6000000000005, y: 557.6000000000001),
                        angle: -0.03958327393709937),
            PathTangent(t: 0.9470000000000007,
                        point: CGPoint(x: 611.4693869000005, y: 526.9224523999997),
                        angle: -0.5366717117124462),
        ])
    }

    static var allTests = [
        ("testCurve", testCurve),
    ]
}
