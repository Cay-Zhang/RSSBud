import UIKit
import JavaScriptCore

var str = "Hello, playground"
let context = JSContext()

context?.exceptionHandler = { _, value in
    guard let value = value else { return }
    print(value)
}

//guard let path = Bundle.main.path(forResource: "radar-rules", ofType: "js") else { fatalError() }
//let code = try! String(contentsOfFile: path)

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

extension JSContext {
    func evaluateScript(fileNamed fileName: String) -> JSValue! {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "js") else { fatalError() }
        let code = try! String(contentsOfFile: path)
        return evaluateScript(code)
    }
}

context?.evaluateScript(fileNamed: "psl.min")
context?.evaluateScript("""
    var parsed = psl.parse('a.b.c.d.foo.com');
    parsed.domain
    """
)

context?.evaluateScript(fileNamed: "route-recognizer.min")
context?.evaluateScript("""
    var router = new RouteRecognizer();
    router.add([
      { path: "/admin", handler: 'admin' },
      { path: "/posts", handler: 'posts' }
    ]);
    var result = router.recognize("/admin/posts");
    """
)
context?.evaluateScript("router")
context?.evaluateScript("result")
context?.evaluateScript("result[0].handler")


context?.evaluateScript(fileNamed: "utils")
