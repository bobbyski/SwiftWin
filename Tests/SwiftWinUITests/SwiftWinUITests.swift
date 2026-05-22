import XCTest
@testable import SwiftWinUI

final class SwiftWinUITests: XCTestCase {
    func testWindowDescriptorStoresSizeAndTitle() {
        let descriptor = WindowDescriptor(title: "Hello", width: 800, height: 600)

        XCTAssertEqual(descriptor.title, "Hello")
        XCTAssertEqual(descriptor.width, 800)
        XCTAssertEqual(descriptor.height, 600)
    }

    func testTextStyleStoresFontInformation() {
        let style = TextStyle(size: 18, weight: .bold)

        XCTAssertEqual(style.size, 18)
        XCTAssertEqual(style.weight, .bold)
    }
}
