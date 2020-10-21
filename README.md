<h1 align=center>RSSBud</h1>

<p align=center>
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift-5.3-fe562e?style=flat-square"></a>
<a href="https://developer.apple.com/ios"><img src="https://img.shields.io/badge/iOS-14%2B-blue?style=flat-square"></a>
<a href="https://github.com/Cay-Zhang/SwiftSpeech/blob/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat-square"></a>
</p>

> RSSBud 是一个 [RSSHub](https://github.com/DIYgod/RSSHub) 的辅助 iOS App，和 [RSSHub Radar](https://github.com/DIYgod/RSSHub-Radar) 类似，他可以帮助你快速发现和订阅网站的 RSS。此外，他还支持编辑 RSSHub 的通用参数 (用于过滤等)。

[Telegram 群](https://t.me/RSSBud_Discussion) | [Telegram 频道](https://t.me/RSSBud)

<p align=center>
<img src="Readme Assets/RSSBud.jpg" align=center width="375" align=center>
</p>

## 功能
- [x] 检测适用于网页 (或 App 内分享) 的 RSSHub 源 (几乎支持所有 RSSHub Radar 的规则)
- [x] 移动端 URL 适配 (自动展开、常见移动子域名适配)
- [x] 读取剪贴板 URL
- [x] 分享菜单插件 (Action Extension)
- [x] 快速订阅到 Reeder, Fiery Feeds, Ego Reader 和系统默认 RSS 阅读器
- [x] 快速订阅到 Tiny Tiny RSS, Miniflux, Fresh RSS, Feedly, Inoreader, Feedbin, The Old Reader, Feeds Pub 网页端
- [x] 自定义通用参数
- [x] 自定义 RSSHub 域名
- [x] 自动更新 RSSHub Radar 规则
- [ ] 检测适用于网站的 RSSHub 源
- [ ] 主动搜寻 RSS 源

## 参与公测
[TestFlight Public Link](https://testflight.apple.com/join/rjCVzzHP)

欢迎加入 [Telegram 群](https://t.me/RSSBud_Discussion) 进行反馈。

> 记得先右上角设置 RSSHub 域名和快速订阅选项。

## 使用 Xcode 12 编译
[安装](https://developer.apple.com/download/) 并打开 **Xcode 12**，打开下面的 URL 克隆仓库，在设置好开发者信息之后即可在实机/虚拟机上运行。

> 若要使用分享菜单插件 (Action Extension)，请在 iOS 和 Action Extension 这两个 Target 中设置你自己的 App Group 并修改 `RSSBud.appGroupIdentifier`。

```
xcode://clone?repo=https%3A%2F%2Fgithub.com%2FCay-Zhang%2FRSSBud
```

## 规则
RSSBud 和 [RSSHub Radar](https://github.com/DIYgod/RSSHub-Radar) 使用同一份 [规则](https://github.com/DIYgod/RSSHub/blob/master/assets/radar-rules.js)，且均支持自动更新。

[为 RSSHub Radar 和 RSSBud 提交新的规则](https://docs.rsshub.app/joinus/#ti-jiao-xin-de-rsshub-radar-gui-ze)

> 请注意，在 `target` 中使用 `document` 的规则并不适用 RSSBud。RSSBud 并不是一个浏览器插件，他只获取并分析网站的 URL。

> 一些网站的移动端和电脑端页面 URL 不同。由于 RSSHub Radar 的规则是适配电脑端的，在你发现 RSSBud 无法识别 RSSHub Radar 可以识别的网站时，可以尝试使用电脑端的 URL 并在 Telegram 向作者反馈。

## 作者
RSSBud 由 cayZ 制作，在 **[MIT 协议](https://choosealicense.com/licenses/mit/)** 下开源。
