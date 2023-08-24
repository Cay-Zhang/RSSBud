<div align=center>
<img src="Readme Assets/Icon with Shadow.png" width="140" height="140">
</div>
<h1 align=center>RSSBud</h1>

<p align=center>
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift-5.8-fe562e?style=flat-square"></a>
<a href="https://developer.apple.com/ios"><img src="https://img.shields.io/badge/iOS-15%2B-blue?style=flat-square"></a>
<a href="https://developer.apple.com/macos"><img src="https://img.shields.io/badge/macOS%20(Apple%20Silicon)-12%2B-blue?style=flat-square"></a>
<a href="https://github.com/Cay-Zhang/RSSBud/blob/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat-square"></a>
</p>

> RSSBud 可以帮助你快速发现和订阅适用于网站或 App 内分享的 RSS 源和 [RSSHub](https://github.com/DIYgod/RSSHub) 源。他支持 RSSHub 的通用参数 (可实现过滤、获取全文等功能)。

[Telegram 群](https://t.me/RSSBud_Discussion) | [Telegram 频道](https://t.me/RSSBud)

https://github.com/Cay-Zhang/RSSBud/assets/13341339/0b02c0a6-faf1-490c-b4d0-b03b84de5145

## 下载
<a href="https://apps.apple.com/cn/app/rssbud/id1531443645?itsct=apps_box&amp;itscg=30200"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/zh-CN?size=250x83&amp;releaseDate=1605052800&h=3dc9b44d4b825017f8746f19cec2b07f" alt="Download on the App Store" width="200"></a>

<img src="https://tools-qr-production.s3.amazonaws.com/output/apple-toolbox/dace82ddc6942d582d27ad4d2ba31d58/c6e9f5d0-cee7-4523-ac64-ca89de19e8dc.png" width="200">

订阅 [Telegram 频道](https://t.me/RSSBud) 以获取更新信息。

## 功能
- [x] 检测网页中的 RSS 源
- [x] 检测适用于网页 (或 App 内分享) 的 RSSHub 源 (几乎支持所有 RSSHub Radar 的规则)
- [x] 检测其他适用于网页的 RSS 源 (由 [RSSBud 规则](#规则) 驱动)
- [x] 移动端 URL 适配 (自动展开、常见移动子域名适配)
- [x] 分享菜单插件 (Action Extension)
- [x] 快速订阅到 Reeder, Fiery Feeds, Ego Reader 和系统默认 RSS 阅读器
- [x] 快速订阅到 Tiny Tiny RSS, Miniflux, Fresh RSS, Feedly, Inoreader, Feedbin, The Old Reader, Feeds Pub 网页端
- [x] 自定义 RSSHub 通用参数
- [x] 自动更新规则
- [x] 自定义远程规则文件
- [x] 同时匹配多个规则文件
- [x] RSSHub访问控制 (自动生成 MD5 访问码)
- [x] 支持 x-callback-url，可结合 "快捷指令" App 编写捷径实现各种强大功能 (详见 [捷径工坊](#捷径工坊) 和 [Scheme](#x-callback-url-scheme))

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

## PopClip 插件
如果你在 macOS 上同时使用 RSSBud 和 [PopClip](https://pilotmoon.com/popclip/)，这个插件可以让你在 PopClip 中分析选中的 URL。只需选中下面代码块中的所有内容，你就会在 PopClip 中看到安装该插件的选项。

```yaml
#popclip
name: RSSBud
icon: iconify:ph:rss-bold
url: rssbud:///analyze?url=***
```

## 自行编译须知
RSSBud 的核心功能来自 [RSSBud Core](https://github.com/Cay-Zhang/RSSBud/tree/main/Shared/Core)，一个用 JavaScript 编写的子项目。代码主要参考 [RSSHub Radar](https://github.com/DIYgod/RSSHub-Radar)。

因此，编译本项目需要安装 [Node.js](https://nodejs.org/zh-cn/)。

若要使用分享菜单插件 (Action Extension)，请在 iOS 和 Action Extension 这两个 Target 中设置你自己的 App Group 并修改 `RSSBud.appGroupIdentifier`。

## 规则
RSSBud 的功能主要来源于两个开源项目提供的**规则**。如果你发现一个无法被 RSSBud 识别的源，请考虑向合适的项目提交新的规则。

- [RSSHub Radar 规则](https://rsshub.js.org/build/radar-rules.js) 来自 RSSHub (Radar) 项目。它被用来识别 RSSHub 源。

    [提交新的 RSSHub Radar 规则](https://docs.rsshub.app/joinus/new-radar.html#bian-xie-gui-ze)

- [RSSBud 规则](https://github.com/Cay-Zhang/RSSBudRules) 是 RSSHub Radar 规则的扩展。这使它能够被用来识别非 RSSHub 源，比如不包含在网站 HTML 中的官方 RSS 源。如果你要提交的规则是用来识别 RSSHub 源的，请优先向 RSSHub Radar 项目提交该规则。

    [提交新的 RSSBud 规则](https://github.com/Cay-Zhang/RSSBudRules)

## 同类项目
- [RSSHub Radar by DIYgod (浏览器扩展)](https://github.com/DIYgod/RSSHub-Radar)
- [RSSAid by Leetao (Flutter)](https://github.com/LeetaoGoooo/RSSAid)

## 作者
RSSBud 由 cayZ 制作，在 **[MIT 协议](https://choosealicense.com/licenses/mit/)** 下开源。
