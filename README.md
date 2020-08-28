<h1 align=center>RSSBud</h1>

<p align=center>
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift-5.3-fe562e?style=flat-square"></a>
<a href="https://developer.apple.com/ios"><img src="https://img.shields.io/badge/iOS-14%2B-blue?style=flat-square"></a>
<a href="https://github.com/Cay-Zhang/SwiftSpeech/blob/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat-square"></a>
</p>

> RSSBud 是 **Apple 生态** 中 [RSSHub](https://github.com/DIYgod/RSSHub) 的辅助 App，和 [RSSHub Radar](https://github.com/DIYgod/RSSHub-Radar) 类似，他可以帮助你快速发现和订阅网站的 RSS。

[Telegram 群](https://t.me/RSSBud_Discussion) | [Telegram 频道](https://t.me/RSSBud)

<p align=center>
<img src="Readme Assets/RSSBud.jpg" align=center width="375" align=center>
</p>

## 功能
- [x] 检测适用于网页 (或 App 内分享) 的 RSSHub 源 (几乎支持所有 RSSHub Radar 的规则)
- [x] 读取剪贴板 URL
- [x] 分享菜单插件 (Action Extension)
- [x] 快速订阅到 Reeder, Fiery Feeds 和系统默认 RSS 阅读器
- [x] 快速订阅到 Feedly, Inoreader, Feedbin, The Old Reader, Feeds Pub 网页端
- [x] 自定义通用参数
- [x] 自定义 RSSHub 域名
- [x] 自动更新 RSSHub Radar 规则
- [ ] 检测适用于网站的 RSSHub 源
- [ ] 主动搜寻 RSS 源

## 使用 Xcode 安装
[安装](https://developer.apple.com/download/) 并打开最新版的 **Xcode 12 beta**，打开下面的 URL 克隆仓库，在设置好开发者信息之后即可在实机/虚拟机上运行。记得先在右上角设置中填写 RSSHub 域名。

> 若要使用分享菜单插件 (Action Extension)，请在 iOS 和 Action Extension 这两个 Target 中设置你自己的 App Group 并修改 `RSSBud.appGroupIdentifier`。

```
xcode://clone?repo=https%3A%2F%2Fgithub.com%2FCay-Zhang%2FRSSBud
```

## 作者
RSSBud 由 cayZ 制作，在 **[MIT 协议](https://choosealicense.com/licenses/mit/)** 下开源。
