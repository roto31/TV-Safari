//
//  WebViewModel.swift
//  Spartan
//
//  WKWebView state management using Swift Observation (@Observable).
//  Combines KVO-via-Combine for WKWebView property observation with
//  first-class async/await navigation APIs.
//
//  Requires tvOS 26+
//

import SwiftUI
import WebKit
import Combine
import Observation

// MARK: - Web History Entry

struct WebHistoryEntry: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let visitedAt: Date
}

// MARK: - WebViewModel

@Observable
final class WebViewModel: NSObject {

    // MARK: Published State (tracked by @Observable)

    var isLoading: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var pageTitle: String = ""
    var pageURL: String = ""
    var estimatedProgress: Double = 0
    var detectedStreamURL: String? = nil
    var errorMessage: String? = nil
    var history: [WebHistoryEntry] = []

    // MARK: Web View

    let webView: WKWebView

    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    override init() {
        webView = WKWebView(frame: .zero, configuration: WebViewModel.buildConfiguration())
        webView.allowsBackForwardNavigationGestures = true
        // Desktop Safari UA — sites serve their full experience
        webView.customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
            "AppleWebKit/605.1.15 (KHTML, like Gecko) " +
            "Version/18.0 Safari/605.1.15"
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        setupObservers()
    }

    // MARK: WKWebView Configuration

    private static func buildConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        config.processPool = WKProcessPool()

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let contentController = WKUserContentController()
        contentController.add(StreamMessageHandler(), name: "streamDetected")

        let tvScript = WKUserScript(
            source: WebViewModel.tvNavigationJS,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(tvScript)
        config.userContentController = contentController
        return config
    }

    // MARK: KVO → @Observable bridging via Combine

    private func setupObservers() {
        webView.publisher(for: \.isLoading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.isLoading = v }
            .store(in: &cancellables)

        webView.publisher(for: \.canGoBack)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.canGoBack = v }
            .store(in: &cancellables)

        webView.publisher(for: \.canGoForward)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.canGoForward = v }
            .store(in: &cancellables)

        webView.publisher(for: \.title)
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }.filter { !$0.isEmpty }
            .sink { [weak self] v in self?.pageTitle = v }
            .store(in: &cancellables)

        webView.publisher(for: \.url)
            .receive(on: DispatchQueue.main)
            .compactMap { $0?.absoluteString }
            .sink { [weak self] v in self?.pageURL = v }
            .store(in: &cancellables)

        webView.publisher(for: \.estimatedProgress)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.estimatedProgress = v }
            .store(in: &cancellables)
    }

    // MARK: Navigation

    func load(urlString: String) {
        let resolved = resolveURL(urlString)
        guard let url = URL(string: resolved) else { return }
        errorMessage = nil
        webView.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30))
    }

    func goBack()      { webView.goBack() }
    func goForward()   { webView.goForward() }
    func reload()      { webView.reload() }
    func stopLoading() { webView.stopLoading() }

    // MARK: URL Resolution

    private func resolveURL(_ raw: String) -> String {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("http://") || s.hasPrefix("https://") { return s }
        if s.contains(".") && !s.contains(" ") { return "https://" + s }
        let q = s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
        return "https://archive.org/search?query=\(q)"
    }

    // MARK: History

    private func recordHistory(title: String, url: String) {
        let entry = WebHistoryEntry(title: title.isEmpty ? url : title, url: url, visitedAt: Date())
        history.insert(entry, at: 0)
        if history.count > 200 { history = Array(history.prefix(200)) }
    }

    // MARK: TV Navigation JS

    static let tvNavigationJS: String = """
    (function() {
        'use strict';

        var style = document.createElement('style');
        style.id = '__tv_focus_style';
        style.textContent = [
            'a:focus,button:focus,input:focus,select:focus,',
            '[tabindex]:focus,[role=button]:focus,[role=link]:focus {',
            '  outline: 4px solid #007AFF !important;',
            '  outline-offset: 3px !important;',
            '  border-radius: 4px;',
            '}',
            'video,audio { outline: none; }',
            '::-webkit-scrollbar { width: 8px; height: 8px; }',
            '::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.3); border-radius:4px; }'
        ].join('');
        if (!document.getElementById('__tv_focus_style')) {
            document.head.appendChild(style);
        }

        document.querySelectorAll('a[href],button,[onclick],[role=button],[role=link]').forEach(function(el) {
            if (!el.getAttribute('tabindex')) el.setAttribute('tabindex', '0');
        });

        function detectStream(url) {
            if (!url) return;
            var u = url.toLowerCase();
            if (u.indexOf('.m3u8') !== -1 || u.indexOf('.m3u') !== -1 ||
                u.indexOf('.ts') !== -1   || u.indexOf('stream') !== -1 ||
                u.indexOf('live') !== -1  || u.indexOf('manifest') !== -1) {
                try { window.webkit.messageHandlers.streamDetected.postMessage({ url: url }); } catch(e) {}
            }
        }

        var origOpen = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function(method, url) {
            detectStream(url); return origOpen.apply(this, arguments);
        };

        var origFetch = window.fetch;
        window.fetch = function(resource) {
            detectStream(typeof resource === 'string' ? resource : (resource && resource.url));
            return origFetch.apply(window, arguments);
        };

        new MutationObserver(function(mutations) {
            mutations.forEach(function(m) {
                m.addedNodes.forEach(function(node) {
                    if (!node.querySelectorAll) return;
                    node.querySelectorAll('video[src],source[src]').forEach(function(el) {
                        detectStream(el.src || el.getAttribute('src'));
                    });
                    if ((node.tagName === 'VIDEO' || node.tagName === 'SOURCE') && node.src)
                        detectStream(node.src);
                });
            });
        }).observe(document.documentElement, { childList: true, subtree: true });
    })();
    """
}

// MARK: - WKNavigationDelegate

extension WebViewModel: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            recordHistory(title: webView.title ?? "", url: url)
        }
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { decisionHandler(.allow); return }
        let u = url.absoluteString.lowercased()
        if u.hasSuffix(".m3u8") || u.hasSuffix(".m3u") {
            DispatchQueue.main.async { self.detectedStreamURL = url.absoluteString }
            decisionHandler(.cancel)
            return
        }
        if PerformanceFilter.shouldBlock(url: url) { decisionHandler(.cancel); return }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let e = error as NSError
        guard e.code != NSURLErrorCancelled else { return }
        DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        let e = error as NSError
        guard e.code != NSURLErrorCancelled else { return }
        DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
    }
}

// MARK: - WKUIDelegate

extension WebViewModel: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith _: WKWebViewConfiguration,
                 for action: WKNavigationAction,
                 windowFeatures _: WKWindowFeatures) -> WKWebView? {
        if action.targetFrame == nil { webView.load(action.request) }
        return nil
    }
}

// MARK: - JS Message Handler

private final class StreamMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ controller: WKUserContentController,
                                didReceive message: WKScriptMessage) {
        guard message.name == "streamDetected",
              let body = message.body as? [String: Any],
              let url = body["url"] as? String else { return }
        NotificationCenter.default.post(
            name: .webViewStreamDetected,
            object: nil,
            userInfo: ["url": url]
        )
    }
}

extension Notification.Name {
    static let webViewStreamDetected = Notification.Name("webViewStreamDetected")
}

// MARK: - Ad / Tracker Blocker

enum PerformanceFilter {
    private static let blockedHosts: Set<String> = [
        "doubleclick.net", "googleadservices.com", "googlesyndication.com",
        "google-analytics.com", "googletagmanager.com", "facebook.net",
        "fbcdn.net", "ads.yahoo.com", "adservice.google.com",
        "scorecardresearch.com", "quantserve.com", "outbrain.com",
        "taboola.com", "moatads.com", "adsymptotic.com"
    ]
    static func shouldBlock(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return blockedHosts.contains { host == $0 || host.hasSuffix("." + $0) }
    }
}
