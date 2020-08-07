//: [Previous](@previous)

import Foundation

var str = "Hello, playground"

let testURL = "https://movie.douban.com/subject/34961898/?tag=热门&from=gaia"
URLComponents(string: testURL)
URL(string: testURL)
let encoded = testURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
URL(string: encoded!)

let string2 = "my bad"
URL(string: string2)
string2.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed.union([" "]))
URLComponents(string: string2.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed.union([" "]))!)
