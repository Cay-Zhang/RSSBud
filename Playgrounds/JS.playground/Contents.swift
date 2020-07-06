import UIKit
import JavaScriptCore

var str = "Hello, playground"
let context = JSContext()

guard let path = Bundle.main.path(forResource: "radar-rules", ofType: "js") else { fatalError() }
let code = try! String(contentsOfFile: path)

//context?.evaluateScript(code)
//context?.evaluateScript("rules['bilibili.com']._name")
//
//let target = context?.evaluateScript("""
//    let params = {
//        bid: "md45324235"
//    };
//    rules['bilibili.com'].www[3].target(params);
//    """
//)?.toString()


extension URLComponents {
    var domain: String? {
        host?.components(separatedBy: ".").suffix(2).joined(separator: ".")
    }
    
    var subdomain: String? {
        host?.components(separatedBy: ".").dropLast(2).joined(separator: ".")
    }
}

let urlComponents = URLComponents(string: "https://space.bilibili.com/10330740/?share_source=copy_link&share_medium=ipad&bbid=3b10a683cd17ff81cc0d8f235a5b3058&ts=1594015458")!

guard let domain = urlComponents.domain,
      let subdomain = urlComponents.subdomain
else { fatalError() }


domain
subdomain

context?.evaluateScript("""
    const parser = new DOMParser();
    const document = parser.parseFromString(html, 'text/html');
    """
)

context?.exception
