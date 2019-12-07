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
            PathTangent(offset: 0.002,
                        point: CGPoint(x: 51.4982024, y: 498.8071904),
                        angle: -0.670038571121991),
            PathTangent(offset: 0.12800000000000009,
                        point: CGPoint(x: 139.25634560000006, y: 450.1746176),
                        angle: -0.29613760444176973),
            PathTangent(offset: 0.2950000000000002,
                        point: CGPoint(x: 239.79046250000016, y: 448.83815000000016),
                        angle: 0.25831849679090235),
            PathTangent(offset: 0.46500000000000036,
                        point: CGPoint(x: 331.6121375000003, y: 489.55145000000016),
                        angle: 0.5118945583160195),
            PathTangent(offset: 0.6320000000000005,
                        point: CGPoint(x: 419.98999040000024, y: 536.8400384000001),
                        angle: 0.4135359843433216),
            PathTangent(offset: 0.8040000000000006,
                        point: CGPoint(x: 518.0283392000003, y: 557.4866431999999),
                        angle: -0.0537118139239379),
            PathTangent(offset: 0.9500000000000007,
                        point: CGPoint(x: 613.5875000000005, y: 525.6499999999997),
                        angle: -0.5452398641168388),
        ])
    }

    static var allTests = [
        ("testCurve", testCurve),
    ]
}
