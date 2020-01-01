//
//  File.swift
//  
//
//  Created by Rob Napier on 12/8/19.
//

import CoreGraphics

protocol PathSection {
    var start: CGPoint { get }
    var end: CGPoint { get }
    func getTangent(t: CGFloat) -> PathTangent
    func nextTangent(linearDistance: CGFloat, after: PathTangent) -> NextTangent
}

extension PathSection {
    // Default impl
    func nextTangent(linearDistance: CGFloat, after lastTangent: PathTangent) -> NextTangent {
        // Simplistic routine to find the t along Bezier that is a linear distance away from a previous tangent.
        // This routine just walks forward, accumulating Euclidean approximations until it finds
        // a point at least linearDistance away. Good optimizations here would reduce the number
        // of guesses, but this is tricky since if we go too far out, the
        // curve might loop back on leading to incorrect results. Tuning
        // kStep is good start.
        let step: CGFloat = 0.001 // 0.0001 - 0.001 work well
        var lastTangent = lastTangent

        var approximateLinearDistance: CGFloat = 0

        var nextTangent = lastTangent
        while approximateLinearDistance < linearDistance && nextTangent.t <= 1.0 {
            lastTangent = nextTangent
            nextTangent = getTangent(t: nextTangent.t + step)
            approximateLinearDistance += lastTangent.point.distance(to: nextTangent.point)
        }

        if nextTangent.t > 1.0 {
            return .insufficient(remainingLinearDistance: approximateLinearDistance)
        } else {
            return .found(nextTangent)
        }
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return hypot(dx, dy)
    }
}

struct PathTangent: Equatable {
    var t: CGFloat
    var point: CGPoint
    var angle: CGFloat
}

enum NextTangent {
    case found(PathTangent)
    case insufficient(remainingLinearDistance: CGFloat)
}

struct TangentGenerator {
    private var sections: ArraySlice<PathSection>
    private var lastLocation: CGFloat = 0
    private var lastTangent: PathTangent?

    init(path: CGPath) {
        sections = path.sections()[...]
    }

    // Locations must be in ascending order
    mutating func getTangent(at location: CGFloat) -> PathTangent? {
        assert(location >= lastLocation)

        while let section = sections.first  {
            let currentTangent = lastTangent ?? section.getTangent(t: 0)
            let linearDistance = location - lastLocation

            switch section.nextTangent(linearDistance: linearDistance,
                                       after: currentTangent) {
            case .found(let tangent):
                lastTangent = tangent
                lastLocation = location
                return tangent

            case let .insufficient(remainingLinearDistance: remain):
                lastLocation += remain
                lastTangent = nil
                sections.removeFirst()
            }
        }

        return nil
    }
}

extension CGPath {
    func sections() -> [PathSection] {
        class Applier {
            var sections: [PathSection] = []
            var start: CGPoint?
            var current: CGPoint?

            func add(element: CGPathElement) {
                // FIXME: Filter zero-length?
                switch element.type {
                case .closeSubpath:
                    sections.append(PathLineSection(start: current ?? .zero, end: start ?? .zero))
                    current = start
                    start = nil

                case .moveToPoint:
                    let p = element.points[0]
                    start = start ?? p
                    current = p

                case .addCurveToPoint:
                    let points = element.points
                    let (p1, p2, p3) = (points[0], points[1], points[2])
                    sections.append(PathCurveSection(p0: current ?? .zero, p1: p1, p2: p2, p3: p3))
                    start = start ?? .zero
                    current = p3

                case .addLineToPoint:
                    let p = element.points[0]
                    sections.append(PathLineSection(start: current ?? .zero, end: p))
                    start = start ?? .zero
                    current = p

                case .addQuadCurveToPoint:
                    let points = element.points
                    let (p1, p2) = (points[0], points[1])
                    sections.append(PathQuadCurveSection(p0: current ?? .zero, p1: p1, p2: p2))
                    start = start ?? .zero
                    current = p2

                @unknown default:
                    break
                }
            }
        }

        func f(info: UnsafeMutableRawPointer?, elementPtr: UnsafePointer<CGPathElement>) {
            info?
                .assumingMemoryBound(to: Applier.self)
                .pointee
                .add(element: elementPtr.pointee)
        }

        var applier = Applier()

        self.apply(info: &applier, function: f)

        return applier.sections
    }
}

struct PathLineSection: PathSection {
    let start, end: CGPoint

    func getTangent(t: CGFloat) -> PathTangent {
        let dx = end.x - start.x
        let dy = end.y - start.y

        let x = start.x + dx * t
        let y = start.y + dy * t

        return PathTangent(t: t,
                           point: CGPoint(x: x, y: y),
                           angle: atan2(dy, dx))
    }
}

struct PathQuadCurveSection: PathSection {
    let p0, p1, p2: CGPoint
    var start: CGPoint { p0 }
    var end: CGPoint { p2 }

    func getTangent(t: CGFloat) -> PathTangent {
        let dx = bezierPrime(t, p0.x, p1.x, p2.x)
        let dy = bezierPrime(t, p0.y, p1.y, p2.y)

        let x = bezier(t, p0.x, p1.x, p2.x)
        let y = bezier(t, p0.y, p1.y, p2.y)

        return PathTangent(t: t,
                           point: CGPoint(x: x, y: y),
                           angle: atan2(dy, dx))
    }

    // The quadratic Bezier function at t
    private func bezier(_ t: CGFloat, _ P0: CGFloat, _ P1: CGFloat, _ P2: CGFloat) -> CGFloat {
               (1-t)*(1-t)       * P0
         + 2 *       (1-t) *   t * P1
         +                   t*t * P2
    }

    // The slope of the quadratic Bezier function at t
    private func bezierPrime(_ t: CGFloat, _ P0: CGFloat, _ P1: CGFloat, _ P2: CGFloat) -> CGFloat {
          2 * (1-t) * (P1 - P0)
        + 2 * t * (P2 - P1)
    }
}

struct PathCurveSection: PathSection {

    let p0, p1, p2, p3: CGPoint
    var start: CGPoint { p0 }
    var end: CGPoint { p3 }

    func getTangent(t: CGFloat) -> PathTangent {
        let dx = bezierPrime(t, p0.x, p1.x, p2.x, p3.x)
        let dy = bezierPrime(t, p0.y, p1.y, p2.y, p3.y)

        let x = bezier(t, p0.x, p1.x, p2.x, p3.x)
        let y = bezier(t, p0.y, p1.y, p2.y, p3.y)

        return PathTangent(t: t,
                           point: CGPoint(x: x, y: y),
                           angle: atan2(dy, dx))
    }

    // The cubic Bezier function at t
    private func bezier(_ t: CGFloat, _ P0: CGFloat, _ P1: CGFloat, _ P2: CGFloat, _ P3: CGFloat) -> CGFloat {
               (1-t)*(1-t)*(1-t)         * P0
         + 3 *       (1-t)*(1-t) *     t * P1
         + 3 *             (1-t) *   t*t * P2
         +                         t*t*t * P3
    }

    // The slope of the cubic Bezier function at t
    private func bezierPrime(_ t: CGFloat, _ P0: CGFloat, _ P1: CGFloat, _ P2: CGFloat, _ P3: CGFloat) -> CGFloat {
           0
        -  3 * (1-t)*(1-t) * P0
        + (3 * (1-t)*(1-t) * P1) - (6 * t * (1-t) * P1)
        - (3 *         t*t * P2) + (6 * t * (1-t) * P2)
        +  3 * t*t * P3
    }
}
