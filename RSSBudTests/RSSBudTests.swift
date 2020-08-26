//
//  RSSBudTests.swift
//  RSSBudTests
//
//  Created by Cay Zhang on 2020/8/7.
//

import XCTest
import Combine

class RSSBudTests: XCTestCase {

    var cancelBag = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let _ = RSSHub.Radar.jsContext
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDefaultBaseURLValidation() {
        XCTAssert(
            RSSHub.BaseURL().validate(string: RSSHub.defaultBaseURLString),
            "Default base URL is invalid."
        )
    }
    
    func testBilibiliSpace() throws {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let expectation = XCTestExpectation(description: "Detect the 2 feeds from the url.")
            
            let urlString = "https://space.bilibili.com/53456"
            let url = URLComponents(autoPercentEncoding: urlString)!
            
            startMeasuring()
            
            RSSHub.Radar.detecting(url: url)
                .sink { _ in
                    
                } receiveValue: { feeds in
                    self.stopMeasuring()
                    XCTAssertEqual(feeds.count, 2, "Unexpected feed count.")
                    expectation.fulfill()
                }.store(in: &self.cancelBag)
            
            wait(for: [expectation], timeout: 3.0)
        }
    }

    func testBilibiliVideo() {
        let expectation = XCTestExpectation(description: "Detect the 2 feeds from the url.")
        
        let urlString = "https://www.bilibili.com/video/BV1qK4y1v7yQ?p=2"
        let url = URLComponents(autoPercentEncoding: urlString)!
        
        RSSHub.Radar.detecting(url: url)
            .sink { _ in
                
            } receiveValue: { feeds in
                XCTAssertEqual(feeds.count, 2, "Unexpected feed count.")
                expectation.fulfill()
            }.store(in: &self.cancelBag)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testQQEgame() {
        
        let expectation = XCTestExpectation(description: "Detect the feed from the url.")
        
        let urlString = "https://egame.qq.com/526905271"
        let url = URLComponents(autoPercentEncoding: urlString)!
        
        RSSHub.Radar.detecting(url: url)
            .sink { _ in
                
            } receiveValue: { feeds in
                XCTAssertEqual(feeds.count, 1, "Unexpected feed count.")
                expectation.fulfill()
            }.store(in: &self.cancelBag)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testRSSHubRadarRulesConsistency() {
        let expectation = XCTestExpectation(description: "Remote rules are equal to bundled rules.")
        
        RSSHub.Radar.rulesCenter.remoteRules()
            .sink { _ in } receiveValue: { remoteRules in
                XCTAssertEqual(remoteRules, RSSHub.Radar.rulesCenter.bundledRules(), "Remote rules and bundled rules are different.")
                expectation.fulfill()
            }.store(in: &self.cancelBag)
        
        wait(for: [expectation], timeout: 3.0)
    }

}
