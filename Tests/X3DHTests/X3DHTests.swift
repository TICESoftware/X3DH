import XCTest
@testable import X3DH

final class X3DHTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(X3DH().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
