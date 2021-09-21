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
        let _ = Core.jsContext
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
    
    func _testAnalysis(_ name: String, url: URLComponents, rssFeedCount: Int? = nil, rsshubFeedCount: Int? = 1) async throws {
        let result = try await Core.analyzing(contentsOf: url)
            .last()
            .awaitable()
        
        if let rssFeedCount = rssFeedCount {
            XCTAssertEqual(result.rssFeeds.count, rssFeedCount, "Unexpected RSS feed count.")
        } else if let rsshubFeedCount = rsshubFeedCount {
            XCTAssertEqual(result.rsshubFeeds.count, rsshubFeedCount, "Unexpected RSSHub feed count.")
        }
    }
    
    func _testAnalysis(_ name: String? = nil, urlString: String, rssFeedCount: Int? = nil, rsshubFeedCount: Int? = 1) async throws {
        if let url = URLComponents(autoPercentEncoding: urlString) {
            try await _testAnalysis(name ?? "Untitled", url: url, rssFeedCount: rssFeedCount, rsshubFeedCount: rsshubFeedCount)
        } else {
            XCTFail("URL conversion failed.")
        }
    }
    
    func testTrivialDetections() async throws {
        try await _testAnalysis("bilibili 空间", urlString: "https://space.bilibili.com/53456", rsshubFeedCount: 8)
        try await _testAnalysis("企鹅电竞直播间", urlString: "https://egame.qq.com/526905271", rsshubFeedCount: 1)
    }
    
    func testMobileSubdomains() async throws {
        try await _testAnalysis("斋书苑", urlString: "https://m.zhaishuyuan.com/book/38082", rsshubFeedCount: 1)
        try await _testAnalysis("Twitter 用户", urlString: "https://mobile.twitter.com/SwiftUILab", rsshubFeedCount: 3)
    }
    
    func testURLDetections() async throws {
        try await _testAnalysis("bilibili 视频", urlString: "https://www.bilibili.com/video/BV1qK4y1v7yQ?p=2", rsshubFeedCount: 2)
    }
    
    func testDocumentDetections() async throws {
        try await _testAnalysis("谷歌相册", urlString: "https://photos.google.com/share/AF1QipN-3SZHWnuYatO_p13elqJZjhIXBUV_ySkStFuYPXCusNA1U35Nwq5xeWqxEIfRRw?key=dzAzZGtzcUxpYW4wV2t6MXZJWk9VdURoUnJsSk1n", rsshubFeedCount: 1)
        try await _testAnalysis("Telegram 频道", urlString: "https://t.me/RSSBud", rsshubFeedCount: 1)
        try await _testAnalysis("Telegram 群组", urlString: "https://t.me/RSSBud_Discussion", rsshubFeedCount: 0)
        try await _testAnalysis("OneJAV BT 今日种子 & 今日演员", urlString: "https://onejav.com/", rsshubFeedCount: 2)
        try await _testAnalysis("OneJAV BT 页面种子", urlString: "https://onejav.com/search/IPX177", rsshubFeedCount: 1)
        try await _testAnalysis("语雀知识库", urlString: "https://www.yuque.com/pocv40/alcg2a", rsshubFeedCount: 1)
        try await _testAnalysis("即刻用户动态 (转发页面)", urlString: "https://m.okjike.com/reposts/5ef6a99228bd5e0018a94fd1", rsshubFeedCount: 1)
        //        _testProcess("微博博主 (昵称)", urlString: "https://weibo.com/hu_ge", feedCount: 1)
        //        _testProcess("快递 100 快递追踪", urlString: "https://kuaidi100.com/", feedCount: 1)
        //        _testProcess("Behance User", urlString: "https://www.behance.net/mishapetrick", feedCount: 1)
    }
    
    func testRSSFeedDetections() async throws {
        try await _testAnalysis("少数派", urlString: "https://sspai.com/", rssFeedCount: 1, rsshubFeedCount: nil)
        try await _testAnalysis("Moon FM News", urlString: "https://news.moon.fm/", rssFeedCount: 1, rsshubFeedCount: nil)
        try await _testAnalysis("Leetao's Blog", urlString: "https://www.leetao94.cn/", rssFeedCount: 1, rsshubFeedCount: nil)
        try await _testAnalysis("RSSBud GitHub Repo", urlString: "https://github.com/Cay-Zhang/RSSBud", rssFeedCount: 0, rsshubFeedCount: nil)
        try await _testAnalysis("说做", urlString: "https://bearchao.com/", rssFeedCount: 1, rsshubFeedCount: nil)
    }
    
}
