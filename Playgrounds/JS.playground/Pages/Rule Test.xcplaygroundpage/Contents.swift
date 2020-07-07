import Foundation
import JavaScriptCore

extension JSContext {
    func evaluateScript(fileNamed fileName: String) -> JSValue! {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "js") else { fatalError() }
        let code = try! String(contentsOfFile: path)
        return evaluateScript(code)
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
    getPageRSSHub({
        url: "https://space.bilibili.com/10330740/?share_source=copy_link&share_medium=ipad&bbid=3b10a683cd17ff81cc0d8f235a5b3058&ts=1594085584",
        html: "",
        rules: rules
    });
    """
)
