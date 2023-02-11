<h1 align=center>RSSBud</h1>

<p align=center>
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift-5.5-fe562e?style=flat-square"></a>
<a href="https://developer.apple.com/ios"><img src="https://img.shields.io/badge/iOS-15%2B-blue?style=flat-square"></a>
<a href="https://github.com/Cay-Zhang/SwiftSpeech/blob/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat-square"></a>
</p>

> RSSBud 是一个 [RSSHub](https://github.com/DIYgod/RSSHub) 的辅助 iOS App，和 [RSSHub Radar](https://github.com/DIYgod/RSSHub-Radar) 类似，他可以帮助你快速发现和订阅网站的 RSS。此外，他还支持 RSSHub 的通用参数 (实现过滤、获取全文等功能)。

[Telegram 群](https://t.me/RSSBud_Discussion) | [Telegram 频道](https://t.me/RSSBud)

<p align=center>
<img src="Readme Assets/RSSBud.jpg" align=center width="375">
</p>

## 下载

> [RSSBud v2 TestFlight 公测](https://testflight.apple.com/join/HxiUd6tx) 现已开启！

<a href="https://apps.apple.com/cn/app/rssbud/id1531443645?itsct=apps_box&amp;itscg=30200"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/zh-CN?size=250x83&amp;releaseDate=1605052800&h=3dc9b44d4b825017f8746f19cec2b07f" alt="Download on the App Store" width="200"></a>

<img src="https://tools-qr-production.s3.amazonaws.com/output/apple-toolbox/dace82ddc6942d582d27ad4d2ba31d58/c6e9f5d0-cee7-4523-ac64-ca89de19e8dc.png" width="200">

订阅 [Telegram 频道](https://t.me/RSSBud) 以获取更新信息。

## 功能
- [x] 检测网页中的 RSS 源
- [x] 检测适用于网页 (或 App 内分享) 的 RSSHub 源 (几乎支持所有 RSSHub Radar 的规则)
- [x] 移动端 URL 适配 (自动展开、常见移动子域名适配)
- [x] 读取剪贴板 URL
- [x] 分享菜单插件 (Action Extension)
- [x] 快速订阅到 Reeder, Fiery Feeds, Ego Reader 和系统默认 RSS 阅读器
- [x] 快速订阅到 Tiny Tiny RSS, Miniflux, Fresh RSS, Feedly, Inoreader, Feedbin, The Old Reader, Feeds Pub 网页端
- [x] 自定义通用参数
- [x] 自定义 RSSHub 域名
- [x] 自动更新 RSSHub Radar 规则
- [x] 访问控制 (自动生成 MD5 访问码)
- [x] 支持 x-callback-url，可结合 "快捷指令" App 编写捷径实现各种强大功能 (详见 [捷径工坊](#捷径工坊) 和 [Scheme](#x-callback-url-scheme))
- [ ] 检测适用于网站的 RSSHub 源

## 参与 Beta 测试
加入 [Telegram 群](https://t.me/RSSBud_Discussion) 以获得 Beta 测试详情。

## 捷径工坊
如果 RSSBud 不支持你想要的 RSS 阅读器/服务，或者你想将 RSSBud 整合进你的工作流中，你可以编写捷径来满足你的需求。就从下面这些开始吧：

[RSSBud 捷径起手式](https://www.icloud.com/shortcuts/55ca2d7e3ee748ceb27cb759bf23f622) by cayZ | RSSBud 捷径的模板，支持从分享菜单启动，变量都已设置好

[用 RSSBud 分析并发送到 Telegram](https://www.icloud.com/shortcuts/c18bd2d4ef71427ab2b25f397a920067) by cayZ | 基于起手式，将分析结果发送到 Telegram，可以自定义消息模板和接受者用户名

[用 RSSBud 分析并订阅到 Pocket Casts](https://www.icloud.com/shortcuts/1eb2893bd14743f3a85db1a8f1aa43c3) by cayZ | 基于起手式，将分析结果发送到 Pocket Casts (仅限播客 RSS)

[扫描二维码并用 RSSBud 分析](https://www.icloud.com/shortcuts/0f95219b79b14afb92f299a8a2889baf) by cayZ | 扫描二维码，获取 URL，跳转 RSSBud 分析

> 如果你觉得你写的捷径很 Cooooool，欢迎来 [Telegram 群](https://t.me/RSSBud_Discussion) 投稿！

## X-callback-url Scheme
RSSBud 实现了 [x-callback-url](http://x-callback-url.com/) 协议，它允许 iOS 和 Mac 开发者公开和记录他们向其他应用程序提供的 API 方法并返回数据。

你可以打开如下的 URL 让 RSSBud 分析提供的 URL 并返回用户选择的 RSS 源：
```
rssbud://x-callback-url/analyze?url[&x-callback-parameters...]
```

#### 参数
- **url** 你想要 RSSBud 分析的 URL
#### x-success
- **feed_title** 用户选择的 RSS 源的名称
- **feed_url** 用户选择的 RSS 源的 URL

## 自行编译须知
RSSBud 的核心功能来自 [RSSBud Core](https://github.com/Cay-Zhang/RSSBud/tree/main/Shared/Core)，一个用 JavaScript 编写的子项目。代码主要参考 [RSSHub Radar](https://github.com/DIYgod/RSSHub-Radar)。

在使用 Xcode 进行编译前，你需要先在工程文件夹下执行以下命令来编译 RSSBud Core (需要 [Node.js](https://nodejs.org/zh-cn/))：
```sh
cd Shared/Core/
npm install
npm run build
```

若要使用分享菜单插件 (Action Extension)，请在 iOS 和 Action Extension 这两个 Target 中设置你自己的 App Group 并修改 `RSSBud.appGroupIdentifier`。

## 规则
RSSBud 和 [RSSHub Radar](https://github.com/DIYgod/RSSHub-Radar) 使用同一份 [规则](https://github.com/DIYgod/RSSHub/blob/master/assets/radar-rules.js)，且均支持自动更新。

[为 RSSHub Radar 和 RSSBud 提交新的规则](https://docs.rsshub.app/joinus/quick-start.html#ti-jiao-xin-de-rsshub-radar-gui-ze)

> 一些网站的移动端和电脑端页面 URL 不同。由于 RSSHub Radar 的规则是适配电脑端的，在你发现 RSSBud 无法识别 RSSHub Radar 可以识别的网站时，可以尝试使用电脑端的 URL 并在 Telegram 向作者反馈。

## 作者
RSSBud 由 cayZ 制作，在 **[MIT 协议](https://choosealicense.com/licenses/mit/)** 下开源。
