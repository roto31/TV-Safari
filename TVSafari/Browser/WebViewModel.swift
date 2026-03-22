//
//  WebViewModel.swift
//  TV Safari
//
//  tvOS has no WebKit. This model tracks URL/title/history and flags HLS-style URLs
//  for StreamingPlayerView; web pages are not rendered in-app.
//

import Foundation
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
final class WebViewModel {

    var isLoading: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var pageTitle: String = ""
    var pageURL: String = ""
    var estimatedProgress: Double = 1.0
    var detectedStreamURL: String? = nil
    var errorMessage: String? = nil
    var history: [WebHistoryEntry] = []

    init() {}

    // MARK: Navigation

    func load(urlString: String) {
        let resolved = resolveURL(urlString)
        errorMessage = nil
        isLoading = true
        estimatedProgress = 0.3

        let lower = resolved.lowercased()
        if lower.hasSuffix(".m3u8") || lower.hasSuffix(".m3u")
            || lower.contains(".m3u8?") || lower.contains("/master.m3u8") {
            detectedStreamURL = resolved
            pageURL = resolved
            pageTitle = "Stream"
            recordHistory(title: pageTitle, url: resolved)
            finishLoad()
            return
        }

        pageURL = resolved
        pageTitle = URL(string: resolved)?.host ?? resolved
        recordHistory(title: pageTitle, url: resolved)
        finishLoad()
    }

    func goBack() {}
    func goForward() {}

    func reload() {
        guard !pageURL.isEmpty else { return }
        load(urlString: pageURL)
    }

    func stopLoading() {
        isLoading = false
        estimatedProgress = 1.0
    }

    private func finishLoad() {
        isLoading = false
        estimatedProgress = 1.0
    }

    private func resolveURL(_ raw: String) -> String {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("http://") || s.hasPrefix("https://") { return s }
        if s.contains(".") && !s.contains(" ") { return "https://" + s }
        let q = s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
        return "https://archive.org/search?query=\(q)"
    }

    private func recordHistory(title: String, url: String) {
        let entry = WebHistoryEntry(title: title.isEmpty ? url : title, url: url, visitedAt: Date())
        history.insert(entry, at: 0)
        if history.count > 200 { history = Array(history.prefix(200)) }
    }
}

extension Notification.Name {
    static let webViewStreamDetected = Notification.Name("webViewStreamDetected")
}

// MARK: - Ad / Tracker Blocker (reserved for future URL filtering)

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
