var psl = require('psl');
var RouteRecognizer = require('route-recognizer');
var { URL } = require('whatwg-url');
var { JSDOM } = require('jsdom');
var { getPageRSS } = require('./page-rss.js');

function ruleHandler(rule, params, url, html, success, fail) {
    const run = () => {
        let resultWithParams;
        if (typeof rule.target === 'function') {
            const document = (new JSDOM(html, { url })).window.document;
            document.location.href = url;
            resultWithParams = rule.target(params, url, document);
        } else if (typeof rule.target === 'string') {
            resultWithParams = rule.target;
        }

        if (resultWithParams) {
            for (const param in params) {
                resultWithParams = resultWithParams.replace(`/:${param}`, `/${params[param]}`);
            }
        }

        return resultWithParams;
    };
    const path = run();
    if (path && (!rule.verification || rule.verification(params))) {
        success(path);
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
    const rules = parseRules(data.rules);

    const parsedDomain = psl.parse(new URL(url).hostname);
    if (parsedDomain && parsedDomain.domain) {
        const subdomain = parsedDomain.subdomain;
        const domain = parsedDomain.domain;
        if (rules[domain]) {
            let rulesForSubdomain = rules[domain][subdomain || '.'];
            if (!rulesForSubdomain) {
                if (subdomain === 'www' || subdomain === 'mobile' || subdomain === 'm') {
                    rulesForSubdomain = rules[domain]['.'];
                } else if (!subdomain) {
                    rulesForSubdomain = rules[domain].www;
                }
            }
            if (rulesForSubdomain) {
                const recognized = [];
                rulesForSubdomain.forEach((rule, index) => {
                    if (rule.source !== undefined) {
                        if (Object.prototype.toString.call(rule.source) === '[object Array]') {
                            rule.source.forEach((source) => {
                                const router = new RouteRecognizer();
                                router.add([{
                                    path: source,
                                    handler: index,
                                }, ]);
                                const result = router.recognize(new URL(url).pathname.replace(/\/$/, ''));
                                if (result && result[0]) {
                                    recognized.push(result[0]);
                                }
                            });
                        } else if (typeof rule.source === 'string') {
                            const router = new RouteRecognizer();
                            router.add([{
                                path: rule.source,
                                handler: index,
                            }, ]);
                            const result = router.recognize(new URL(url).pathname.replace(/\/$/, ''));
                            if (result && result[0]) {
                                recognized.push(result[0]);
                            }
                        }
                    } else {
                        // source is undefined
                        // add website feed
                    }
                });
                
                const pageFeeds = [];
                Promise.all(
                    recognized.map(
                        (recog) =>
                        new Promise((resolve) => {
                            ruleHandler(
                                rulesForSubdomain[recog.handler],
                                recog.params,
                                url,
                                html,
                                (path) => {
                                    // path resolved
                                    // add page feed
                                    if (path) {
                                        pageFeeds.push({
                                            title: rulesForSubdomain[recog.handler].title,
                                            url: '{rsshubDomain}' + path,
                                            path: path,
                                        });
                                    } else {
                                        // this will never be run
                                        pageFeeds.push({
                                            title: rulesForSubdomain[recog.handler].title,
                                            url: rulesForSubdomain[recog.handler].docs,
                                            isDocs: true,
                                        });
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
                return pageFeeds;
            } else {
                return [];
            }
        } else {
            return [];
        }
    } else {
        return [];
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

function analyze(url, html, rules) {
    let rssFeeds = [];
    let debugInfo = "";
    if (html) {
        const document = (new JSDOM(html, { url })).window.document;
        debugInfo = document.location.href;
        rssFeeds = getPageRSS(document);
    }
    const rsshubFeeds = getPageRSSHub({ url, html, rules });
    return {
        rssFeeds, rsshubFeeds, debugInfo
    };
}

module.exports = {
    getPageRSS,
    getPageRSSHub,
    getWebsiteRSSHub,
    analyze
}
