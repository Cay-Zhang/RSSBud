function getPageRSS(document) {
    const defaultTitle =
        document.querySelector('title') &&
        document.querySelector('title').innerHTML &&
        document
            .querySelector('title')
            .innerHTML.replace(/<!\[CDATA\[(.*)]]>/, (match, p1) => p1)
            .trim();
    const image = (document.querySelector('link[rel~="icon"]') && completeHref(document.querySelector('link[rel~="icon"]').getAttribute('href'))) || document.location.origin + '/favicon.ico';

    function completeHref(href) {
        if (href.startsWith('//')) {
            href = document.location.protocol + href;
        } else if (href.startsWith('/')) {  // e.g. '/feed'
            href = document.location.origin + href;
        } else if (!/^(http|https):\/\//i.test(href)) {
            href = document.location.href + '/' + href.replace(/^\//g, '');
        }
        return href;
    }


    let feeds = [];
    const unique = {
        data: {},
        save: function (url) {
            this.data[url.replace(/^(https?:)?\/\//, '')] = 1;
        },
        check: function (url) {
            return this.data[url.replace(/^(https?:)?\/\//, '')];
        },
    };

    // links
    const types = [
        'application/rss+xml',
        'application/atom+xml',
        'application/rdf+xml',
        'application/rss',
        'application/atom',
        'application/rdf',
        'text/rss+xml',
        'text/atom+xml',
        'text/rdf+xml',
        'text/rss',
        'text/atom',
        'text/rdf',
    ];
    const links = document.querySelectorAll('link[type]');
    for (let i = 0; i < links.length; i++) {
        if (links[i].hasAttribute('type') && types.indexOf(links[i].getAttribute('type')) !== -1) {
            const feed_url = links[i].getAttribute('href');

            if (feed_url) {
                const feed = {
                    url: completeHref(feed_url),
                    title: links[i].getAttribute('title') || defaultTitle,
                    imageURL: image,
                    isCertain: true,
                };
                if (!unique.check(feed.url)) {
                    feeds.push(feed);
                    unique.save(feed.url);
                }
            }
        }
    }

    // a
    const aEles = document.querySelectorAll('a');
    const check = /([^a-zA-Z]|^)rss([^a-zA-Z]|$)/i;  // 'rss' as a word
    for (let i = 0; i < aEles.length; i++) {
        if (aEles[i].hasAttribute('href')) {
            const href = aEles[i].getAttribute('href');

            if (
                href.match(/\/(feed|rss|atom)(\.(xml|rss|atom))?$/) ||
                (aEles[i].hasAttribute('title') && aEles[i].getAttribute('title').match(check)) ||
                (aEles[i].hasAttribute('class') && aEles[i].getAttribute('class').match(check)) ||
                (aEles[i].innerText && aEles[i].innerText.match(check))
            ) {
                const feed = {
                    url: completeHref(href),
                    title: aEles[i].innerText || aEles[i].getAttribute('title') || defaultTitle,
                    imageURL: image,
                    isCertain: false,
                };
                if (!unique.check(feed.url)) {
                    feeds.push(feed);
                    unique.save(feed.url);
                }
            }
        }
    }

    // page itself is an rss?
    // if (!unique.check(document.location.href)) {
    //     let html;
    //     if (document.body && document.body.childNodes && document.body.childNodes.length === 1 && document.body.childNodes[0].tagName && document.body.childNodes[0].tagName.toLowerCase()) {
    //         html = document.body.childNodes[0].innerText;
    //     } else if (document.querySelector('#webkit-xml-viewer-source-xml')) {
    //         html = document.querySelector('#webkit-xml-viewer-source-xml').innerHTML;
    //     }

    //     if (html) {
    //         rssParser.parseString(html, (err, result) => {
    //             if (!err) {
    //                 chrome.runtime.sendMessage(null, {
    //                     text: 'addPageRSS',
    //                     feed: {
    //                         url: document.location.href,
    //                         title: result.title,
    //                         image,
    //                     },
    //                 });
    //             }
    //         });
    //     }
    // }
    // unique.save(document.location.href);
    return feeds;
}

module.exports = { getPageRSS }
