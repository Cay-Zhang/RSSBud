//
//  PromoAssetGeneration.swift
//  PromoAssetGeneration
//
//  Created by Cay Zhang on 2020/11/7.
//

import XCTest

class PromoAssetGeneration: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testScreenshot1() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-promo-asset-generation", "1"]
        app.launch()
        _ = app.wait(for: .unknown, timeout: 2)
        takeScreenshot(name: "Page 1")
    }
    
    func testScreenshot2() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-promo-asset-generation", "2"]
        app.launch()
        app.navigationBars["RSSBud"].buttons["gearshape.fill"].tap()
        _ = app.wait(for: .unknown, timeout: 2)
        takeScreenshot(name: "Page 2")
    }
}

extension PromoAssetGeneration {
    func takeScreenshot(name: String? = nil) {
        let fullScreenshot = XCUIScreen.main.screenshot()
        let screenshot = XCTAttachment(screenshot: fullScreenshot, quality: .original)
        screenshot.name = name ?? "\(name ?? "Untitled")-\(UIDevice.current.name).png"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
