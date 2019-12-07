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

    func testFlatLine() {

        let P0 = CGPoint(x: 0, y: 0)
        let P1 = CGPoint(x: 800, y: 0)

        let path = Path() {
            $0.move(to: P0)
            $0.addLine(to: P1)
        }

        let sections = path.sections()

        XCTAssertEqual(sections.count, 1)

        guard let section = sections.first as? PathLineSection else {
            XCTFail()
            return
        }

        XCTAssertEqual(section.start, P0)
        XCTAssertEqual(section.end, P1)

        let tangents = path.tangents(atLocations: [0, 100, 200, 300, 400, 500, 600, 700])

        XCTAssertEqual(tangents, [
            PathTangent(t: 0, point: CGPoint(x: 0, y: 0), angle: 0),
            PathTangent(t: 0.12500000000000008, point: CGPoint(x: 100.00000000000007, y: 0), angle: 0),
            PathTangent(t: 0.25000000000000017, point: CGPoint(x: 200.00000000000014, y: 0), angle: 0),
            PathTangent(t: 0.3750000000000003, point: CGPoint(x: 300.0000000000002, y: 0), angle: 0),
            PathTangent(t: 0.5000000000000003, point: CGPoint(x: 400.0000000000003, y: 0), angle: 0),
            PathTangent(t: 0.6250000000000004, point: CGPoint(x: 500.00000000000034, y: 0), angle: 0),
            PathTangent(t: 0.7500000000000006, point: CGPoint(x: 600.0000000000005, y: 0), angle: 0),
            PathTangent(t: 0.8750000000000007, point: CGPoint(x: 700.0000000000006, y: 0), angle: 0),
        ])
    }

    func testLine() {

        let P0 = CGPoint(x: 0, y: 0)
        let P1 = CGPoint(x: 800, y: 800)

        let path = Path() {
            $0.move(to: P0)
            $0.addLine(to: P1)
        }

        let sections = path.sections()

        XCTAssertEqual(sections.count, 1)

        guard let section = sections.first as? PathLineSection else {
            XCTFail()
            return
        }

        XCTAssertEqual(section.start, P0)
        XCTAssertEqual(section.end, P1)

        let tangents = path.tangents(atLocations: [0, 100, 200, 300, 400, 500, 600, 700])

        let angle: CGFloat = atan(1)

        XCTAssertEqual(tangents, [
            PathTangent(t: 0.0, point: CGPoint(x: 0.0, y: 0.0), angle: angle),
            PathTangent(t: 0.08900000000000007, point: CGPoint(x: 71.200000000000050, y: 71.200000000000050), angle: angle),
            PathTangent(t: 0.17800000000000013, point: CGPoint(x: 142.40000000000010, y: 142.40000000000010), angle: angle),
            PathTangent(t: 0.26700000000000020, point: CGPoint(x: 213.60000000000014, y: 213.60000000000014), angle: angle),
            PathTangent(t: 0.35600000000000026, point: CGPoint(x: 284.80000000000020, y: 284.80000000000020), angle: angle),
            PathTangent(t: 0.44500000000000034, point: CGPoint(x: 356.00000000000030, y: 356.00000000000030), angle: angle),
            PathTangent(t: 0.53400000000000040, point: CGPoint(x: 427.20000000000030, y: 427.20000000000030), angle: angle),
            PathTangent(t: 0.62300000000000040, point: CGPoint(x: 498.40000000000040, y: 498.40000000000040), angle: angle),
        ])
    }

    func testTwoLines() {

        let P0 = CGPoint(x: 0, y: 0)
        let P1 = CGPoint(x: 400, y: 400)
        let P2 = CGPoint(x: 800, y: 0)

        let path = Path() {
            $0.move(to: P0)
            $0.addLine(to: P1)
            $0.addLine(to: P2)
        }

        let sections = path.sections()

        XCTAssertEqual(sections.count, 2)

        guard let section1 = sections.first as? PathLineSection else {
            XCTFail()
            return
        }

        XCTAssertEqual(section1.start, P0)
        XCTAssertEqual(section1.end, P1)

        guard let section2 = sections.dropFirst().first as? PathLineSection else {
            XCTFail()
            return
        }

        XCTAssertEqual(section2.start, P1)
        XCTAssertEqual(section2.end, P2)


        let tangents = path.tangents(atLocations: [0, 100, 200, 300, 400, 500, 600, 700])

        let angle: CGFloat = atan(1)

        XCTAssertEqual(tangents, [
            PathTangent(t: 0.0, point: CGPoint(x: 0.0, y: 0.0), angle: angle),
            PathTangent(t: 0.08900000000000007, point: CGPoint(x: 71.200000000000050, y: 71.200000000000050), angle: angle),
            PathTangent(t: 0.17800000000000013, point: CGPoint(x: 142.40000000000010, y: 142.40000000000010), angle: angle),
            PathTangent(t: 0.26700000000000020, point: CGPoint(x: 213.60000000000014, y: 213.60000000000014), angle: angle),
            PathTangent(t: 0.35600000000000026, point: CGPoint(x: 284.80000000000020, y: 284.80000000000020), angle: angle),
            PathTangent(t: 0.44500000000000034, point: CGPoint(x: 356.00000000000030, y: 356.00000000000030), angle: angle),
            PathTangent(t: 0.53400000000000040, point: CGPoint(x: 427.20000000000030, y: 427.20000000000030), angle: angle),
            PathTangent(t: 0.62300000000000040, point: CGPoint(x: 498.40000000000040, y: 498.40000000000040), angle: angle),
        ])
    }


    static var allTests = [
        ("testCurve", testCurve),
        ("testFlatLine", testFlatLine),
        ("testLine", testLine),
    ]
}
