import XCTest
@testable import STPDFKit

final class STPDFKitTests: XCTestCase {

    func testVersionExists() {
        XCTAssertFalse(STPDFKit.version.isEmpty)
    }

    func testDefaultConfiguration() {
        let config = STPDFConfiguration.default
        XCTAssertTrue(config.showThumbnails)
        XCTAssertTrue(config.showBookmarks)
        XCTAssertTrue(config.showSearch)
        XCTAssertTrue(config.showSettings)
        XCTAssertTrue(config.allowAnnotationEditing)
        XCTAssertTrue(config.allowDocumentEditing)
    }

    func testLicenseManagerInitiallyUnlicensed() async {
        let isLicensed = await STLicenseManager.shared.isLicensed
        XCTAssertFalse(isLicensed)
    }
}
