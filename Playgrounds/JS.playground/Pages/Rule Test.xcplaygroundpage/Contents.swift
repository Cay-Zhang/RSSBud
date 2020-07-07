import Foundation
import JavaScriptCore

extension JSContext {
    func evaluateScript(fileNamed fileName: String) -> JSValue! {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "js") else { fatalError() }
        let code = try! String(contentsOfFile: path)
        return evaluateScript(code, withSourceURL: URL(string: path))
    }
}

let context = JSContext()!

context.exceptionHandler = { _, value in
    guard let value = value else { return }
    print(value)
}

// Load Dependencies
context.evaluateScript(fileNamed: "psl.min")
context.evaluateScript(fileNamed: "route-recognizer.min")

// Load Rules
context.evaluateScript(fileNamed: "radar-rules")

// Load Utils
context.evaluateScript(fileNamed: "utils")

// Prepare Test Data
context.evaluateScript("""
    var results = getPageRSSHub({
        url: "https://space.bilibili.com/10330740/?share_source=copy_link&share_medium=ipad&bbid=3b10a683cd17ff81cc0d8f235a5b3058&ts=1594085584",
        host: "space.bilibili.com",
        path: "/10330740/",
        html: "",
        rules: rules
    });
    results[0].url
    """
)

context.evaluateScript("""
    var results = getPageRSSHub({
        url: "https://matters.news/@mh111000/comments",
        host: "matters.news",
        path: "/@mh111000/comments/",
        html: "",
        rules: rules
    });
    results[0].url
    """
)

context.evaluateScript("""
    params = { id: '@mh111000' };
    const uid = params.id.replace('@', '');
    uid ? `/matters/author/${uid}` : '';
    """
)
