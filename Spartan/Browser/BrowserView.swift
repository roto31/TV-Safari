//
//  BrowserView.swift
//  Spartan
//
//  Full-featured tvOS web browser view.
//
//  UI layout
//  ─────────
//  • Persistent top navigation bar (back, forward, reload, URL bar, bookmark,
//    bookmarks list, archive shortcut, live-streams shortcut).
//  • Full-screen WKWebView beneath the bar.
//  • Thin progress bar appears at the bottom of the nav bar while loading.
//  • Error banner slides in from the top when a page fails to load.
//  • Stream URLs detected in the page automatically open the streaming player.
//
//  Navigation (Siri Remote)
//  ────────────────────────
//  • Trackpad swipe — scrolls the web page when the webview has focus.
//  • Click — activates focused link / button.
//  • Menu — go back in history; if at root, close browser.
//  • Play/Pause — passed through to in-page media.
//  • Focus ring injected via JS so elements are always visible.
//

import SwiftUI
import WebKit
import AVKit

struct BrowserView: View {

    @Binding var isPresented: Bool

    @StateObject private var viewModel  = WebViewModel()
    @StateObject private var bookmarks  = BrowserBookmarkManager.shared

    // Sheet / overlay states
    @State private var showURLInput     = false
    @State private var showBookmarks    = false
    @State private var showStreamPlayer = false
    @State private var showArchiveOrg   = false
    @State private var showLiveStreams  = false

    @State private var detectedStream: String = ""
    @State private var showErrorBanner  = false

    var body: some View {
        ZStack(alignment: .top) {

            // ── Background ────────────────────────────────────────────────
            Color.black.ignoresSafeArea()

            // ── Web content ───────────────────────────────────────────────
            WebViewRepresentable(viewModel: viewModel)
                .ignoresSafeArea()

            // ── Navigation bar (always visible) ──────────────────────────
            VStack(spacing: 0) {
                navigationBar
                    .background(.ultraThinMaterial)
                loadingBar
                Spacer()
            }

            // ── Error banner ──────────────────────────────────────────────
            if showErrorBanner, let msg = viewModel.errorMessage {
                VStack {
                    errorBanner(message: msg)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .padding(.top, navBarHeight + 4)
                .zIndex(10)
            }
        }
        // ── Sheets ────────────────────────────────────────────────────────
        .sheet(isPresented: $showURLInput) {
            URLInputView(currentURL: viewModel.pageURL) { url in
                viewModel.load(urlString: url)
            }
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksView(viewModel: viewModel)
        }
        .sheet(isPresented: $showArchiveOrg) {
            ArchiveOrgView(viewModel: viewModel)
        }
        .sheet(isPresented: $showLiveStreams) {
            LiveStreamView { url in
                detectedStream = url
                showStreamPlayer = true
            }
        }
        .fullScreenCover(isPresented: $showStreamPlayer) {
            StreamingPlayerView(streamURL: detectedStream,
                                isPresented: $showStreamPlayer)
        }
        // ── Reactive updates ───────────────────────────────────────────────
        .onChange(of: viewModel.detectedStreamURL) { url in
            guard let url = url, !url.isEmpty else { return }
            detectedStream = url
            viewModel.detectedStreamURL = nil
            showStreamPlayer = true
        }
        .onChange(of: viewModel.errorMessage) { msg in
            guard msg != nil else { showErrorBanner = false; return }
            withAnimation { showErrorBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation { showErrorBanner = false }
            }
        }
        // Stream notifications from JavaScript
        .onReceive(NotificationCenter.default.publisher(for: .webViewStreamDetected)) { note in
            guard let url = note.userInfo?["url"] as? String, !url.isEmpty else { return }
            detectedStream = url
            showStreamPlayer = true
        }
        // ── Exit handling ──────────────────────────────────────────────────
        .onExitCommand {
            if viewModel.canGoBack {
                viewModel.goBack()
            } else {
                isPresented = false
            }
        }
        .onAppear {
            viewModel.load(urlString: "https://archive.org")
        }
    }

    // MARK: - Navigation Bar

    private let navBarHeight: CGFloat = 80

    var navigationBar: some View {
        HStack(spacing: 12) {

            // Back
            navButton(icon: "chevron.left", enabled: viewModel.canGoBack) {
                viewModel.goBack()
            }

            // Forward
            navButton(icon: "chevron.right", enabled: viewModel.canGoForward) {
                viewModel.goForward()
            }

            // Reload / Stop
            navButton(icon: viewModel.isLoading ? "xmark" : "arrow.clockwise", enabled: true) {
                viewModel.isLoading ? viewModel.stopLoading() : viewModel.reload()
            }

            // ── URL Bar ──────────────────────────────────────────────────
            Button(action: { showURLInput = true }) {
                HStack(spacing: 10) {
                    Image(systemName: lockIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(lockColor)
                    Text(urlBarText)
                        .font(.system(size: 22))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(.systemGray6).opacity(0.7))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())

            // Archive.org shortcut
            navButton(icon: "archivebox", enabled: true) {
                showArchiveOrg = true
            }

            // Live streams shortcut
            navButton(icon: "antenna.radiowaves.left.and.right", enabled: true) {
                showLiveStreams = true
            }

            // Save bookmark
            navButton(icon: "bookmark", enabled: !viewModel.pageURL.isEmpty) {
                bookmarks.addBookmark(title: viewModel.pageTitle, url: viewModel.pageURL)
            }

            // Bookmarks list
            navButton(icon: "list.bullet", enabled: true) {
                showBookmarks = true
            }
        }
        .padding(.horizontal, 30)
        .frame(height: navBarHeight)
    }

    // MARK: - Loading Bar

    var loadingBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.clear.frame(height: 3)
                if viewModel.isLoading {
                    Color.accentColor
                        .frame(width: geo.size.width * viewModel.estimatedProgress, height: 3)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.estimatedProgress)
                }
            }
        }
        .frame(height: 3)
    }

    // MARK: - Error Banner

    func errorBanner(message: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 24))
            Text(message)
                .font(.system(size: 22))
                .lineLimit(2)
            Spacer()
            Button(action: { withAnimation { showErrorBanner = false } }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 14)
        .background(Color(.systemGray5).opacity(0.95))
    }

    // MARK: - Computed Helpers

    private var urlBarText: String {
        if viewModel.isLoading { return "Loading…" }
        if !viewModel.pageTitle.isEmpty { return viewModel.pageTitle }
        if !viewModel.pageURL.isEmpty   { return viewModel.pageURL }
        return "Enter URL or search…"
    }

    private var lockIcon: String {
        viewModel.pageURL.hasPrefix("https") ? "lock.fill" : "lock.open"
    }

    private var lockColor: Color {
        viewModel.pageURL.hasPrefix("https") ? .green : .orange
    }

    // MARK: - Reusable Nav Button

    @ViewBuilder
    private func navButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(enabled ? .primary : .secondary)
                .frame(width: 50, height: 50)
                .background(Color(.systemGray6).opacity(0.6))
                .cornerRadius(10)
        }
        .disabled(!enabled)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
