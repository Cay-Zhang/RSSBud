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
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let expectation = XCTestExpectation(description: "Detect the 2 feeds from the url.")
        
        let urlString = "https://space.bilibili.com/53456?spm_id_from=333.788.b_765f7570696e666f.2"
        let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: encoded!)!
        
        Radar.detecting(url: url)
            .sink { _ in
                
            } receiveValue: { feeds in
                XCTAssertEqual(feeds.count, 2, "Unexpected feed count.")
                expectation.fulfill()
            }.store(in: &self.cancelBag)
        
        wait(for: [expectation], timeout: 10.0)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
