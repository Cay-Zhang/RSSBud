var psl = require('psl');
var RouteRecognizer = require('route-recognizer');
var { URL } = require('whatwg-url');
var { JSDOM } = require('jsdom');
var { getPageRSS } = require('./page-rss.js');

function ruleHandler(rule, params, url, html, success, fail) {
    function resolveTarget() {
        let target = null;
        if (typeof rule.target === 'function') {
            const document = (new JSDOM(html, { url })).window.document;
            document.location.href = url;
            target = rule.target(params, url, document).toString();
        } else if (typeof rule.target === 'string') {
            target = rule.target;
        }

        if (target) {
            const optionalParamRegex = /\/:([^\?\/]+)\?/g;
            target = target.replaceAll(optionalParamRegex, (match, param) => params[param] ? `/${params[param]}` : ``);
            const requiredParamRegex = /\/:([^\/]+)/g;
            let failedToReplace = false;
            target = target.replaceAll(requiredParamRegex, (match, param) => {
                if (!params[param]) failedToReplace = true;
                return `/${params[param]}`;
            });
            if (failedToReplace) return null;
        }

        return target;
    }

    function buildResult(resolvedTarget) {
        targetType = (typeof rule.targetType !== 'undefined') ? rule.targetType : undefined;
        if (!resolvedTarget) {
            // TODO: return doc only feed
            return null;
        }
        switch (targetType) {
            case "url":
                return {
                    isRSSFeed: true,
                    feed: {
                        url: resolvedTarget,
                        title: rule.title,
                        imageURL: "",
                        isCertain: true,
                    }
                };
                break;
            case "pathForOriginal":
                return {
                    isRSSFeed: true,
                    feed: {
                        url: new URL(resolvedTarget, (new URL(url)).origin).toString(),
                        title: rule.title,
                        imageURL: "",
                        isCertain: true,
                    }
                };
                break;
            default:
                return {
                    isRSSFeed: false,
                    feed: {
                        title: rule.title,
                        path: resolvedTarget,
                        docsURL: rule.docs,
                    }
                };
                break;
        }
    }

    const result = buildResult(resolveTarget());
    if (result && (!rule.verification || rule.verification(params))) {
        success(result);
    } else {
        fail();
    }
}

function formatBlank(str1, str2) {
    if (str1 && str2) {
        return str1 + (str1[str1.length - 1].match(/[a-zA-Z0-9]/) || str2[0].match(/[a-zA-Z0-9]/) ? ' ' : '') + str2;
    } else {
        return (str1 || '') + (str2 || '');
    }
}

function parseRules(rules) {
    return typeof rules === 'string' ? window['lave'.split('').reverse().join('')](rules) : rules;
}

function getPageRSSHub(data) {
    const { url, html } = data;
    const ruleFile = parseRules(data.ruleFile);

    const parsedDomain = psl.parse(new URL(url).hostname);
    if (parsedDomain && parsedDomain.domain) {
        const subdomain = parsedDomain.subdomain;
        const domain = parsedDomain.domain;
        if (ruleFile[domain]) {
            let rulesForSubdomain = ruleFile[domain][subdomain || '.'];
            if (!rulesForSubdomain) {
                if (subdomain === 'www' || subdomain === 'mobile' || subdomain === 'm') {
                    rulesForSubdomain = ruleFile[domain]['.'];
                } else if (!subdomain) {
                    rulesForSubdomain = ruleFile[domain].www;
                }
            }
            if (rulesForSubdomain) {
                const recognized = [];

                rulesForSubdomain.forEach((rule, index) => {
                    let sources;
                    if (Object.prototype.toString.call(rule.source) === '[object Array]') {
                        sources = rule.source;
                    } else if (typeof (rule.source) === 'string') {
                        sources = [rule.source];
                    } else {
                        sources = ["/", "/*"];
                    }
                    sources.forEach((source) => {
                        const router = new RouteRecognizer();
                        router.add([{
                            path: source,
                            handler: index,
                        },]);
                        const result = router.recognize(new URL(url).pathname.replace(/\/$/, ''));
                        if (result && result[0]) {
                            recognized.push(result[0]);
                        }
                    });
                });

                const rssFeeds = [];
                const rssHubFeeds = [];
                Promise.all(
                    recognized.map(
                        (recog) =>
                            new Promise((resolve) => {
                                ruleHandler(
                                    rulesForSubdomain[recog.handler],
                                    recog.params,
                                    url,
                                    html,
                                    ({ isRSSFeed, feed }) => {
                                        if (isRSSFeed) {
                                            rssFeeds.push(feed);
                                        } else {
                                            rssHubFeeds.push(feed);
                                        }
                                        resolve();
                                    },
                                    () => {
                                        // path not resolved
                                        // add website feed
                                        resolve();
                                    }
                                );
                            })
                    )
                );
                return { rssFeeds, rssHubFeeds };
            } else {
                return { rssFeeds: [], rssHubFeeds: [] };
            }
        } else {
            return { rssFeeds: [], rssHubFeeds: [] };
        }
    } else {
        return { rssFeeds: [], rssHubFeeds: [] };
    }
}

function getWebsiteRSSHub(data) {
    const { url } = data;
    const rules = parseRules(data.rules);
    const parsedDomain = psl.parse(new URL(url).hostname);
    if (parsedDomain && parsedDomain.domain) {
        const domain = parsedDomain.domain;
        if (rules[domain]) {
            const domainRules = [];
            for (const subdomainRules in rules[domain]) {
                if (subdomainRules[0] !== '_') {
                    domainRules.push(...rules[domain][subdomainRules]);
                }
            }
            return domainRules.map((rule) => ({
                title: formatBlank(rules[domain]._name, rule.title),
                url: rule.docs,
                isDocs: true,
            }));
        } else {
            return [];
        }
    } else {
        return [];
    }
}

function getList(data) {
    const rules = parseRules(data.rules);
    for (const rule in rules) {
        for (const subrule in rules[rule]) {
            if (subrule[0] !== '_') {
                rules[rule][subrule].forEach((item) => {
                    delete item.source;
                    delete item.target;
                    delete item.script;
                    delete item.verification;
                });
            }
        }
    }
    return rules;
}

function analyze(url, html, ruleFile) {
    let rssFeedsFromHTML = [];
    let debugInfo = "";
    if (html) {
        const document = (new JSDOM(html, { url })).window.document;
        debugInfo = document.location.href;
        rssFeedsFromHTML = getPageRSS(document);
    }
    const { rssFeeds: rssFeedsFromRules, rssHubFeeds } = getPageRSSHub({ url, html, ruleFile });
    return {
        rssFeeds: rssFeedsFromRules.concat(rssFeedsFromHTML), rssHubFeeds, debugInfo
    };
}

module.exports = {
    getPageRSS,
    getPageRSSHub,
    getWebsiteRSSHub,
    analyze
}
