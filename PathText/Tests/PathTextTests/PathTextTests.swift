import XCTest
@testable import PathText

#if canImport(UIKit)
import UIKit
private typealias PlatformFont = UIFont
private typealias PlatformColor = UIColor
#elseif canImport(AppKit)
private typealias PlatformFont = NSFont
private typealias PlatformColor = NSColor
#else
#error("Unsupported platform")
#endif

func AssertPathTangentsEqual(_ expression1: [PathTangent], _ expression2: [PathTangent]) {
    for (tangent1, tangent2) in zip(expression1, expression2) {
        XCTAssertEqual(tangent1.t, tangent2.t, accuracy: 0.01)
        XCTAssertEqual(tangent1.angle, tangent2.angle, accuracy: 0.01)
        XCTAssertEqual(tangent1.point.x, tangent2.point.x, accuracy: 1.0)
        XCTAssertEqual(tangent1.point.y, tangent2.point.y, accuracy: 1.0)
    }
}

@available(iOS, introduced: 13.0)
@available(OSX, introduced: 10.15)
final class PathTextTests: XCTestCase {
    static let text: NSAttributedString = {
        let string = NSString("You can display text along a curve, with bold, color, and big text.")

        let s = NSMutableAttributedString(string: string as String,
                                          attributes: [.font: PlatformFont.systemFont(ofSize: 16)])

        s.addAttributes([.font: PlatformFont.boldSystemFont(ofSize: 16)], range: string.range(of: "bold"))
        s.addAttributes([.foregroundColor: PlatformColor.red], range: string.range(of: "color"))
        s.addAttributes([.font: PlatformFont.systemFont(ofSize: 32)], range: string.range(of: "big text"))
        return s
    }()

    func testCurve() {
        let P0 = CGPoint(x: 50, y: 500)
        let P1 = CGPoint(x: 300, y: 300)
        let P2 = CGPoint(x: 400, y: 700)
        let P3 = CGPoint(x: 650, y: 500)

        let path = CGMutablePath()
        path.move(to: P0)
        path.addCurve(to: P3, control1: P1, control2: P2)

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

        var generator = TangentGenerator(path: path)
        let tangents = [0, 100, 200, 300, 400, 500, 600].compactMap{ generator.getTangent(at: $0) }

        AssertPathTangentsEqual(tangents, [
            PathTangent(t: 0,     point: P0,                      angle: -0.674),
            PathTangent(t: 0.124, point: CGPoint(x: 137, y: 451), angle: -0.310),
            PathTangent(t: 0.288, point: CGPoint(x: 236, y: 448), angle:  0.234),
            PathTangent(t: 0.461, point: CGPoint(x: 328, y: 488), angle:  0.510),
            PathTangent(t: 0.628, point: CGPoint(x: 416, y: 536), angle:  0.420),
            PathTangent(t: 0.800, point: CGPoint(x: 513, y: 558), angle: -0.026),
            PathTangent(t: 0.947, point: CGPoint(x: 607, y: 528), angle: -0.522),
        ])
    }

    func testFlatLine() {

        let P0 = CGPoint(x: 0, y: 0)
        let P1 = CGPoint(x: 800, y: 0)

        let path = CGMutablePath()
        path.move(to: P0)
        path.addLine(to: P1)

        let sections = path.sections()

        XCTAssertEqual(sections.count, 1)

        guard let section = sections.first as? PathLineSection else {
            XCTFail()
            return
        }

        XCTAssertEqual(section.start, P0)
        XCTAssertEqual(section.end, P1)

        var generator = TangentGenerator(path: path)
        let tangents = [0, 100, 200, 300, 400, 500, 600, 700].compactMap{ generator.getTangent(at: $0) }

        AssertPathTangentsEqual(tangents, [
            PathTangent(t: 0, point: CGPoint(x: 0, y: 0), angle: 0),
            PathTangent(t: 0.125, point: CGPoint(x: 100, y: 0), angle: 0),
            PathTangent(t: 0.250, point: CGPoint(x: 200, y: 0), angle: 0),
            PathTangent(t: 0.375, point: CGPoint(x: 300, y: 0), angle: 0),
            PathTangent(t: 0.500, point: CGPoint(x: 400, y: 0), angle: 0),
            PathTangent(t: 0.625, point: CGPoint(x: 500, y: 0), angle: 0),
            PathTangent(t: 0.750, point: CGPoint(x: 600, y: 0), angle: 0),
            PathTangent(t: 0.875, point: CGPoint(x: 700, y: 0), angle: 0),
        ])
    }

    func testLine() {

        let P0 = CGPoint(x: 0, y: 0)
        let P1 = CGPoint(x: 800, y: 800)

        let path = CGMutablePath()
        path.move(to: P0)
        path.addLine(to: P1)

        let sections = path.sections()

        XCTAssertEqual(sections.count, 1)

        guard let section = sections.first as? PathLineSection else {
            XCTFail()
            return
        }

        XCTAssertEqual(section.start, P0)
        XCTAssertEqual(section.end, P1)

        var generator = TangentGenerator(path: path)
        let tangents = [0, 100, 200, 300, 400, 500, 600, 700].compactMap{ generator.getTangent(at: $0) }

        let angle: CGFloat = atan(1)

        AssertPathTangentsEqual(tangents, [
            PathTangent(t: 0.000, point: CGPoint(x: 0.0, y: 0.0), angle: angle),
            PathTangent(t: 0.089, point: CGPoint(x:  71, y:  71), angle: angle),
            PathTangent(t: 0.178, point: CGPoint(x: 142, y: 142), angle: angle),
            PathTangent(t: 0.267, point: CGPoint(x: 214, y: 214), angle: angle),
            PathTangent(t: 0.356, point: CGPoint(x: 285, y: 285), angle: angle),
            PathTangent(t: 0.445, point: CGPoint(x: 356, y: 356), angle: angle),
            PathTangent(t: 0.534, point: CGPoint(x: 427, y: 427), angle: angle),
            PathTangent(t: 0.623, point: CGPoint(x: 498, y: 498), angle: angle),
        ])
    }

    func testTwoLines() {

        let P0 = CGPoint(x: 0, y: 0)
        let P1 = CGPoint(x: 400, y: 400)
        let P2 = CGPoint(x: 800, y: 0)

        let path = CGMutablePath()
        path.move(to: P0)
        path.addLine(to: P1)
        path.addLine(to: P2)

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

        var generator = TangentGenerator(path: path)
        let tangents = [0, 100, 200, 300, 400, 500, 600, 700].compactMap{ generator.getTangent(at: $0) }

        AssertPathTangentsEqual(tangents, [
            PathTangent(t: 0.000, point: CGPoint(x:   0, y:   0), angle:  0.785),
            PathTangent(t: 0.177, point: CGPoint(x:  70, y:  71), angle:  0.785),
            PathTangent(t: 0.354, point: CGPoint(x: 141, y: 142), angle:  0.785),
            PathTangent(t: 0.531, point: CGPoint(x: 212, y: 212), angle:  0.785),
            PathTangent(t: 0.708, point: CGPoint(x: 283, y: 283), angle:  0.785),
            PathTangent(t: 0.885, point: CGPoint(x: 354, y: 354), angle:  0.785),
            PathTangent(t: 0.062, point: CGPoint(x: 425, y: 375), angle: -0.785),
            PathTangent(t: 0.239, point: CGPoint(x: 496, y: 304), angle: -0.785),
        ])
    }

    func testQuadCurve() {

        let P0 = CGPoint(x: 50, y: 500)
        let P1 = CGPoint(x: 300, y: 300)
        let P2 = CGPoint(x: 650, y: 500)

        let path = CGMutablePath()
        path.move(to: P0)
        path.addQuadCurve(to: P2, control: P1)

        let sections = path.sections()

        XCTAssertEqual(sections.count, 1)

        guard let section1 = sections.first as? PathQuadCurveSection else {
            XCTFail()
            return
        }

        XCTAssertEqual(section1.p0, P0)
        XCTAssertEqual(section1.p1, P1)
        XCTAssertEqual(section1.p2, P2)

        var generator = TangentGenerator(path: path)
        let tangents = [0, 100, 200, 300, 400, 500, 600, 700].compactMap{ generator.getTangent(at: $0) }

        AssertPathTangentsEqual(tangents, [
            PathTangent(t: 0.000, point: CGPoint(x:  50, y: 500), angle: -0.675),
            PathTangent(t: 0.163, point: CGPoint(x: 134, y: 445), angle: -0.469),
            PathTangent(t: 0.334, point: CGPoint(x: 228, y: 411), angle: -0.230),
            PathTangent(t: 0.505, point: CGPoint(x: 328, y: 400), angle:  0.007),
            PathTangent(t: 0.667, point: CGPoint(x: 427, y: 411), angle:  0.208),
            PathTangent(t: 0.815, point: CGPoint(x: 523, y: 440), angle:  0.363),
            PathTangent(t: 0.950, point: CGPoint(x: 614, y: 481), angle:  0.481),
        ])
    }
}
