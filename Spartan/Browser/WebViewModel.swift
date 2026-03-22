//
//  WebViewModel.swift
//  Spartan
//
//  Full-featured WKWebView state management for tvOS browser.
//  Handles navigation, media detection, JavaScript injection,
//  and performance-optimized configuration.
//

import SwiftUI
import WebKit
import Combine
import AVFoundation

// MARK: - Web History Entry

struct WebHistoryEntry: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let visitedAt: Date
}

// MARK: - WebViewModel

class WebViewModel: NSObject, ObservableObject {

    // MARK: Public State

    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var pageTitle: String = ""
    @Published var pageURL: String = ""
    @Published var estimatedProgress: Double = 0
    @Published var detectedStreamURL: String? = nil
    @Published var errorMessage: String? = nil
    @Published var history: [WebHistoryEntry] = []

    // MARK: Internals

    let webView: WKWebView
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    override init() {
        let configuration = WebViewModel.buildConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true

        // Desktop Safari UA so sites serve full experiences
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
            "AppleWebKit/605.1.15 (KHTML, like Gecko) " +
            "Version/17.0 Safari/605.1.15"

        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        setupObservers()
    }

    // MARK: Configuration

    private static func buildConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()

        // Allow inline & auto-play media (critical for streaming)
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true

        // Shared process pool reduces memory overhead across views
        config.processPool = WKProcessPool()

        // Preferences
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        // Message handler for stream URL detection from JS
        let contentController = WKUserContentController()
        contentController.add(StreamMessageHandler(), name: "streamDetected")
        contentController.add(StreamMessageHandler(), name: "chatMessage")

        // Inject TV-friendly CSS/JS on every page load
        let tvNavScript = WKUserScript(
            source: WebViewModel.tvNavigationJS,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(tvNavScript)

        config.userContentController = contentController
        return config
    }

    // MARK: KVO Observers

    private func setupObservers() {
        webView.publisher(for: \.isLoading)
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)

        webView.publisher(for: \.canGoBack)
            .receive(on: DispatchQueue.main)
            .assign(to: \.canGoBack, on: self)
            .store(in: &cancellables)

        webView.publisher(for: \.canGoForward)
            .receive(on: DispatchQueue.main)
            .assign(to: \.canGoForward, on: self)
            .store(in: &cancellables)

        webView.publisher(for: \.title)
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .assign(to: \.pageTitle, on: self)
            .store(in: &cancellables)

        webView.publisher(for: \.url)
            .receive(on: DispatchQueue.main)
            .compactMap { $0?.absoluteString }
            .assign(to: \.pageURL, on: self)
            .store(in: &cancellables)

        webView.publisher(for: \.estimatedProgress)
            .receive(on: DispatchQueue.main)
            .assign(to: \.estimatedProgress, on: self)
            .store(in: &cancellables)
    }

    // MARK: Navigation

    func load(urlString: String) {
        let processed = resolveURL(urlString)
        guard let url = URL(string: processed) else { return }
        errorMessage = nil
        webView.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30))
    }

    func goBack()    { webView.goBack() }
    func goForward() { webView.goForward() }
    func reload()    { webView.reload() }
    func stopLoading() { webView.stopLoading() }

    // MARK: URL Resolution

    /// Turns bare queries and partial URLs into fully qualified https:// URLs.
    private func resolveURL(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        // Looks like a domain (contains dot, no spaces)
        if trimmed.contains(".") && !trimmed.contains(" ") {
            return "https://" + trimmed
        }
        // Treat as search query — use Archive.org full-text search by default
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        return "https://archive.org/search?query=\(encoded)"
    }

    // MARK: History Tracking

    private func recordHistory(title: String, url: String) {
        let entry = WebHistoryEntry(title: title.isEmpty ? url : title, url: url, visitedAt: Date())
        history.insert(entry, at: 0)
        if history.count > 200 { history = Array(history.prefix(200)) }
    }

    // MARK: TV Navigation JavaScript

    /// Injected into every page to improve focus visibility and keyboard interaction on tvOS.
    static let tvNavigationJS: String = """
    (function() {
        'use strict';

        // ── Focus ring ──────────────────────────────────────────────────
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

        // ── Make non-focusable interactive elements reachable ───────────
        var selectors = 'a[href],button,[onclick],[role=button],[role=link]';
        document.querySelectorAll(selectors).forEach(function(el) {
            if (!el.getAttribute('tabindex')) el.setAttribute('tabindex', '0');
        });

        // ── Stream URL detection ─────────────────────────────────────────
        function detectStream(url) {
            if (!url) return;
            var u = url.toLowerCase();
            if (u.indexOf('.m3u8') !== -1 || u.indexOf('.m3u') !== -1 ||
                u.indexOf('.ts') !== -1   || u.indexOf('stream') !== -1 ||
                u.indexOf('live') !== -1  || u.indexOf('manifest') !== -1) {
                try {
                    window.webkit.messageHandlers.streamDetected.postMessage({ url: url });
                } catch(e) {}
            }
        }

        // Intercept XHR to catch dynamically fetched stream manifests
        var origOpen = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function(method, url) {
            detectStream(url);
            return origOpen.apply(this, arguments);
        };

        // Intercept fetch()
        var origFetch = window.fetch;
        window.fetch = function(resource) {
            var url = typeof resource === 'string' ? resource : (resource && resource.url);
            detectStream(url);
            return origFetch.apply(window, arguments);
        };

        // Watch for <video>/<source> elements added to the DOM
        var observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(m) {
                m.addedNodes.forEach(function(node) {
                    if (!node.querySelectorAll) return;
                    node.querySelectorAll('video[src],source[src]').forEach(function(el) {
                        detectStream(el.src || el.getAttribute('src'));
                    });
                    if ((node.tagName === 'VIDEO' || node.tagName === 'SOURCE') && node.src) {
                        detectStream(node.src);
                    }
                });
            });
        });
        observer.observe(document.documentElement, { childList: true, subtree: true });

    })();
    """
}

// MARK: - WKNavigationDelegate

extension WebViewModel: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString, let title = webView.title {
            recordHistory(title: title, url: url)
        }
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { decisionHandler(.allow); return }
        let u = url.absoluteString.lowercased()

        // Auto-detect HLS/stream links in the navigation chain
        if u.hasSuffix(".m3u8") || u.hasSuffix(".m3u") {
            DispatchQueue.main.async { self.detectedStreamURL = url.absoluteString }
            decisionHandler(.cancel)
            return
        }

        // Block known ad/tracker domains for performance
        if PerformanceFilter.shouldBlock(url: url) {
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        // Ignore cancellations (e.g., user navigated away)
        if nsError.code == NSURLErrorCancelled { return }
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled { return }
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - WKUIDelegate

extension WebViewModel: WKUIDelegate {
    // Open new windows / target=_blank in same view
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

// MARK: - JS Message Handler (stream & chat relay)

private class StreamMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                                didReceive message: WKScriptMessage) {
        guard message.name == "streamDetected",
              let body = message.body as? [String: Any],
              let url = body["url"] as? String else { return }
        // Relay via NotificationCenter so BrowserView can react
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

// MARK: - Performance Filter (ad/tracker blocking)

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
        return blockedHosts.contains(where: { host == $0 || host.hasSuffix("." + $0) })
    }
}
