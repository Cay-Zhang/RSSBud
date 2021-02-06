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

    func testBaseURLValidation() {
        XCTAssert(
            RSSHub.BaseURL().validate(string: RSSHub.defaultBaseURLString),
            "Default base URL is invalid."
        )
        XCTAssert(
            RSSHub.BaseURL().validate(string: RSSHub.officialDemoBaseURLString),
            "Official demo's base URL is invalid."
        )
    }
    
    func _testDetection(url: URLComponents, html: String = "", feedCount: Int) {
        let expectation = self.expectation(description: "Detect \(feedCount) feeds with the given url and html.")
        
        RSSHub.Radar.detecting(url: url, html: html)
            .sink { completion in
                if case let .failure(error) = completion {
                    XCTFail(error.localizedDescription)
                }
                expectation.fulfill()
            } receiveValue: { feeds in
                XCTAssertEqual(feeds.count, feedCount, "Unexpected feed count.")
            }.store(in: &self.cancelBag)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func _testProcess(_ name: String, url: URLComponents, feedCount: Int) {
        let expectation = self.expectation(description: "Detect \(feedCount) feeds from \(name).")
        
        RSSHub.Radar.asyncExpandURLAndGetHTML(for: url)
            .prepend((url: url, html: ""))
            .flatMap { tuple in
                RSSHub.Radar.detecting(url: tuple.url, html: tuple.html ?? "")
            }.scan([]) {
                $0.count < $1.count ? $1 : $0
            }.replaceEmpty(with: [])
            .last()
            .sink { completion in
                if case let .failure(error) = completion {
                    XCTFail(error.localizedDescription)
                }
                expectation.fulfill()
            } receiveValue: { feeds in
                XCTAssertEqual(feeds.count, feedCount, "Unexpected feed count.")
            }.store(in: &self.cancelBag)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func _testProcess(_ name: String? = nil, urlString: String, feedCount: Int = 1) {
        if let url = URLComponents(autoPercentEncoding: urlString) {
            _testProcess(name ?? "Untitled", url: url, feedCount: feedCount)
        } else {
            XCTFail("URL conversion failed.")
        }
    }
    
    func testBilibiliSpace() throws {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let expectation = XCTestExpectation(description: "Detect the 8 feeds from the url.")
            
            let urlString = "https://space.bilibili.com/53456"
            let url = URLComponents(autoPercentEncoding: urlString)!
            
            startMeasuring()
            
            RSSHub.Radar.detecting(url: url)
                .sink { _ in
                    
                } receiveValue: { feeds in
                    self.stopMeasuring()
                    XCTAssertEqual(feeds.count, 8, "Unexpected feed count.")
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
    
    func testMobileSubdomains() {
        let expectation1 = XCTestExpectation(description: "Detect the feed from the url containing a mobile subdomain.")
        let urlString1 = "https://m.zhaishuyuan.com/book/38082"
        let url1 = URLComponents(autoPercentEncoding: urlString1)!
        
        RSSHub.Radar.detecting(url: url1)
            .sink { _ in
                
            } receiveValue: { feeds in
                XCTAssertEqual(feeds.count, 1, "Unexpected feed count.")
                expectation1.fulfill()
            }.store(in: &self.cancelBag)
        
        let expectation2 = XCTestExpectation(description: "Detect the feed from the url containing a mobile subdomain.")
        let urlString2 = "https://mobile.twitter.com/SwiftUILab"
        let url2 = URLComponents(autoPercentEncoding: urlString2)!
        
        RSSHub.Radar.detecting(url: url2)
            .sink { _ in
                
            } receiveValue: { feeds in
                XCTAssertEqual(feeds.count, 3, "Unexpected feed count.")
                expectation2.fulfill()
            }.store(in: &self.cancelBag)
        
        wait(for: [expectation1, expectation2], timeout: 6.0)
    }
    
    func testHTMLParsing() {
        _testProcess("谷歌相册", urlString: "https://photos.google.com/share/AF1QipN-3SZHWnuYatO_p13elqJZjhIXBUV_ySkStFuYPXCusNA1U35Nwq5xeWqxEIfRRw?key=dzAzZGtzcUxpYW4wV2t6MXZJWk9VdURoUnJsSk1n", feedCount: 1)
        _testProcess("Telegram 频道", urlString: "https://t.me/RSSBud", feedCount: 1)
        _testProcess("Telegram 群组", urlString: "https://t.me/RSSBud_Discussion", feedCount: 0)
        _testProcess("OneJAV BT 今日种子 & 今日演员", urlString: "https://onejav.com/", feedCount: 2)
        _testProcess("OneJAV BT 页面种子", urlString: "https://onejav.com/search/IPX177", feedCount: 1)
        _testProcess("语雀知识库", urlString: "https://www.yuque.com/pocv40/alcg2a", feedCount: 1)
        _testProcess("即刻用户动态 (转发页面)", urlString: "https://m.okjike.com/reposts/5ef6a99228bd5e0018a94fd1", feedCount: 1)
        //        _testProcess("微博博主 (昵称)", urlString: "https://weibo.com/hu_ge", feedCount: 1)
        //        _testProcess("快递 100 快递追踪", urlString: "https://kuaidi100.com/", feedCount: 1)
        //        _testProcess("Behance User", urlString: "https://www.behance.net/mishapetrick", feedCount: 1)
    }
    
    func testRSSHubRadarRulesConsistency() {
        let expectation = XCTestExpectation(description: "Remote rules are equal to bundled rules.")
        
        let path = Bundle.main.path(forResource: "radar-rules", ofType: "js")!
        let bundledRules = try! String(contentsOfFile: path)
        
        RuleManager.shared.remoteRules()
            .sink { _ in } receiveValue: { remoteRules in
                XCTAssertEqual(remoteRules, bundledRules, "Remote rules and bundled rules are different.")
                expectation.fulfill()
            }.store(in: &self.cancelBag)
        
        wait(for: [expectation], timeout: 3.0)
    }

}
