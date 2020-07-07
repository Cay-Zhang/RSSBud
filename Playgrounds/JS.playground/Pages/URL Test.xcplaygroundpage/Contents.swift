//: [Previous](@previous)

import Foundation

var str = "Hello, playground"

let testURL = "https://movie.douban.com/subject/34961898/?tag=热门&from=gaia"
URL(string: testURL)
let encoded = testURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
URL(string: encoded!)
