import XCTest
@testable import PathText

final class PathTextTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(PathText().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
