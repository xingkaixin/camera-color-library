import XCTest

@MainActor
final class ColorLibraryUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testExtractSaveRelaunchAndShare() throws {
        let app = XCUIApplication()
        app.launchEnvironment["COLOR_LIBRARY_TEST_SESSION"] = UUID().uuidString
        app.launch()
        XCTAssertTrue(app.buttons["sample-Cafe"].waitForExistence(timeout: 10))
        app.buttons["sample-Cafe"].tap()
        let title = app.textFields["entryTitleField"]
        XCTAssertTrue(title.waitForExistence(timeout: 15))
        XCTAssertEqual(title.value as? String, "午后的咖啡馆")
        app.buttons["saveCaptureButton"].tap()
        XCTAssertTrue(app.staticTexts["01"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["01"].waitForExistence(timeout: 10))
        app.buttons["collectionsTab"].tap()
        let folder = app.buttons["collection-日常灵感"]
        XCTAssertTrue(folder.waitForExistence(timeout: 5))
        folder.tap()
        let savedEntry = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'libraryEntry-'")).firstMatch
        XCTAssertTrue(savedEntry.waitForExistence(timeout: 5), app.debugDescription)
        savedEntry.tap()
        XCTAssertTrue(app.buttons["copyHexButton"].waitForExistence(timeout: 5))
        app.buttons["copyHexButton"].tap()
        XCTAssertTrue(app.staticTexts["copyConfirmation"].exists)
        app.buttons["shareCardButton"].tap()
        XCTAssertTrue(app.images["shareCardPreview"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["shareImageButton"].isEnabled)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "分享卡"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["shareImageButton"].tap()
        XCTAssertTrue(app.buttons["Copy"].waitForExistence(timeout: 5) || app.buttons["拷贝"].exists)
    }

    func testCameraFallbackCanExtractSample() {
        let app = XCUIApplication()
        app.launchEnvironment["COLOR_LIBRARY_TEST_SESSION"] = UUID().uuidString
        app.launch()
        app.buttons["captureButton"].tap()
        XCTAssertTrue(app.staticTexts["暂时没有可用的镜头"].waitForExistence(timeout: 10))
        app.swipeUp()
        app.buttons["cameraSampleButton"].tap()
        XCTAssertTrue(app.buttons["saveCaptureButton"].waitForExistence(timeout: 15))
    }
}
