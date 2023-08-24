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

[中文文档](README.zh-CN.md)

> RSSBud can help you quickly discover and subscribe to RSS feeds from websites or apps, especially those provided by [RSSHub](https://github.com/DIYgod/RSSHub). It supports the parameters feature of RSSHub which facilitates extra functionalities such as filtering by feed content and full text fetching.

[Telegram Group](https://t.me/RSSBud_Discussion)

https://github.com/Cay-Zhang/RSSBud/assets/13341339/f68fde0b-1e81-4cda-99af-f1b0deeb68f7

## Download
<a href="https://apps.apple.com/us/app/rssbud/id1531443645?itsct=apps_box_link&itscg=30200"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-US?size=250x83&amp;releaseDate=1605052800&h=3dc9b44d4b825017f8746f19cec2b07f" alt="Download on the App Store" width="200"></a>

<img src="https://tools-qr-production.s3.amazonaws.com/output/apple-toolbox/dace82ddc6942d582d27ad4d2ba31d58/c6e9f5d0-cee7-4523-ac64-ca89de19e8dc.png" width="200">

## Features
- [x] Detects RSS feeds in web pages
- [x] Detects RSSHub feeds applicable for web pages (supports almost all rules of RSSHub Radar)
- [x] Detects other RSS feeds applicable for web pages (powered by [RSSBud Rules](#rules))
- [x] Optimized for mobile environment (automatically expands URLs and adapts to common mobile sub-domains)
- [x] Share sheet extension
- [x] Quick subscription to Reeder, Fiery Feeds, Ego Reader, and system default RSS reader
- [x] Quick subscription to Tiny Tiny RSS, Miniflux, Fresh RSS, Feedly, Inoreader, Feedbin, The Old Reader, Feeds Pub
- [x] Parameter editor for RSSHub feeds
- [x] Rules kept up-to-date automatically
- [x] Customizable remote rules files
- [x] Simultaneously matches against multiple rules files
- [x] RSSHub access control (automatically generates MD5 access code)
- [x] Supports x-callback-url; can be used in "Shortcuts" app to facilitate a variety of powerful functions (see [Shortcut Workshop](#shortcut-workshop) and [Scheme](#x-callback-url-scheme))

## Shortcut Workshop
If RSSBud doesn't support your RSS reader/service, or you want to integrate RSSBud into your workflow, you can write shortcuts utilizing RSSBud's support for x-callback-url to fulfill your needs. Let's start with the following ones!

[RSSBud Starter Shortcut](https://www.icloud.com/shortcuts/0db563bf6ca24af296264ebb561e485a) by cayZ | A template for RSSBud related shortcuts that sets up the variables and supports share sheets.

[Analyze with RSSBud and Send with Telegram](https://www.icloud.com/shortcuts/512b781474da4c868113aba21889ab56) by cayZ | Send RSSBud analysis results to Telegram with customizable message template and recipient.

[Analyze with RSSBud and Subscribe with Pocket Casts](https://www.icloud.com/shortcuts/3cf4b0660bfb441c9dabd21e6de523bf) by cayZ | Send RSSBud analysis results to Pocket Casts (podcast RSS only).

[Scan QR and Analyze with RSSBud](https://www.icloud.com/shortcuts/997677502579494881f66d661bb2f773) by cayZ | Get URL from scanned QR code and analyze with RSSBud.

> If you think you've got an idea of a shortcut that can benefit a larger audience, you're welcomed to submit an issue!

## X-callback-url Scheme
RSSBud has implemented the [x-callback-url](http://x-callback-url.com/) protocol, which provides a standardized means for iOS developers to expose and document the methods they make available to other apps via custom URL schemes.

You can open the following URL to let RSSBud analyze the provided URL and return the RSS feed chosen by the user:
```
rssbud://x-callback-url/analyze?url[&x-callback-parameters...]
```

#### Parameters
- **url** The URL you want RSSBud to analyze
#### x-success
- **feed_title** The name of the RSS feed chosen by the user
- **feed_url** The URL of the RSS feed chosen by the user

## PopClip Extension
If you happen use both RSSBud and [PopClip](https://pilotmoon.com/popclip/) on macOS, here's a handy  extension that can be used to analyze selected URLs with RSSBud. Simply select everything in the code block below and you will see an option to install the extension in PopClip.

```yaml
#popclip
name: RSSBud
icon: iconify:ph:rss-bold
url: rssbud:///analyze?url=***
```

## Notes for Building from Source
The core functionality of RSSBud comes from [RSSBud Core](https://github.com/Cay-Zhang/RSSBud/tree/main/Shared/Core), a sub-project written in JavaScript. The code is mainly referenced from [RSSHub Radar](https://github.com/DIYgod/RSSHub-Radar).

Make sure you have [Node.js](https://nodejs.org/) installed before you build with Xcode.

If you wish to use the action extension, please set up your own App Group in both the iOS and Action Extension targets and modify `RSSBud.appGroupIdentifier` accordingly.

## Rules
RSSBud’s functionality is largely powered by **rules** from two open-source projects. Please consider contributing to the appropriate rules if a particular feed can’t be discovered by RSSBud.

- [RSSHub Radar Rules](https://rsshub.js.org/build/radar-rules.js) are created and maintained by the **RSSHub** community. They are used to discover **RSSHub feeds**.

    [Submit new RSSHub Radar rules](https://docs.rsshub.app/en/joinus/new-radar.html)

- [RSSBud Rules](https://github.com/Cay-Zhang/RSSBudRules) are a superset of RSSHub Radar rules. The extended schema allows **non-RSSHub feeds** (e.g. official RSS feeds that are not discoverable by parsing HTML) to be discovered. Please consider contributing to RSSHub Radar rules first if the feed is an **RSSHub feed**.

    [Submit new RSSBud rules](https://github.com/Cay-Zhang/RSSBudRules)

## Similar projects
- [RSSHub Radar by DIYgod (Browser extension)](https://github.com/DIYgod/RSSHub-Radar)
- [RSSAid by Leetao (Flutter)](https://github.com/LeetaoGoooo/RSSAid)

## Author
RSSBud is made by cayZ and is open-source under the **[MIT License](https://choosealicense.com/licenses/mit/)**.
