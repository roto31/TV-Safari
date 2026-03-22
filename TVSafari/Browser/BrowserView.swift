//
//  BrowserView.swift
//  TV Safari
//
//  Full-featured tvOS web browser.
//  Requires tvOS 26+
//

import SwiftUI

struct BrowserView: View {

    @Binding var isPresented: Bool

    @State private var viewModel   = WebViewModel()
    @State private var bookmarks   = BrowserBookmarkManager.shared

    @State private var showURLInput     = false
    @State private var showBookmarks    = false
    @State private var showStreamPlayer = false
    @State private var showArchiveOrg   = false
    @State private var showLiveStreams  = false
    @State private var detectedStream   = ""
    @State private var showErrorBanner  = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            WebViewRepresentable(viewModel: viewModel)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar
                    .background(.ultraThinMaterial)
                loadingBar
                Spacer()
            }

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
            StreamingPlayerView(streamURL: detectedStream, isPresented: $showStreamPlayer)
        }
        .onChange(of: viewModel.detectedStreamURL) { _, url in
            guard let url, !url.isEmpty else { return }
            detectedStream = url
            viewModel.detectedStreamURL = nil
            showStreamPlayer = true
        }
        .onChange(of: viewModel.errorMessage) { _, msg in
            guard msg != nil else { showErrorBanner = false; return }
            withAnimation { showErrorBanner = true }
            Task {
                try? await Task.sleep(for: .seconds(5))
                withAnimation { showErrorBanner = false }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .webViewStreamDetected)) { note in
            guard let url = note.userInfo?["url"] as? String, !url.isEmpty else { return }
            detectedStream = url
            showStreamPlayer = true
        }
        .onExitCommand {
            if viewModel.canGoBack { viewModel.goBack() } else { isPresented = false }
        }
        .onAppear {
            viewModel.load(urlString: "https://archive.org")
        }
    }

    // MARK: - Navigation Bar

    private let navBarHeight: CGFloat = 80

    var navigationBar: some View {
        HStack(spacing: 12) {
            navButton(icon: "chevron.left",  enabled: viewModel.canGoBack)    { viewModel.goBack() }
            navButton(icon: "chevron.right", enabled: viewModel.canGoForward) { viewModel.goForward() }
            navButton(icon: viewModel.isLoading ? "xmark" : "arrow.clockwise", enabled: true) {
                viewModel.isLoading ? viewModel.stopLoading() : viewModel.reload()
            }

            Button { showURLInput = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.pageURL.hasPrefix("https") ? "lock.fill" : "lock.open")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(viewModel.pageURL.hasPrefix("https") ? .green : .orange)
                    Text(urlBarText)
                        .font(.system(size: 22))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(white: 0.22).opacity(0.7))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            navButton(icon: "archivebox",                          enabled: true) { showArchiveOrg  = true }
            navButton(icon: "antenna.radiowaves.left.and.right",   enabled: true) { showLiveStreams  = true }
            navButton(icon: "bookmark",   enabled: !viewModel.pageURL.isEmpty) {
                bookmarks.addBookmark(title: viewModel.pageTitle, url: viewModel.pageURL)
            }
            navButton(icon: "list.bullet", enabled: true) { showBookmarks = true }
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
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
            Text(message).font(.system(size: 22)).lineLimit(2)
            Spacer()
            Button { withAnimation { showErrorBanner = false } } label: {
                Image(systemName: "xmark")
            }
        }
        .padding(.horizontal, 30).padding(.vertical, 14)
        .background(Color(white: 0.26).opacity(0.95))
    }

    // MARK: - Helpers

    private var urlBarText: String {
        if viewModel.isLoading      { return "Loading…" }
        if !viewModel.pageTitle.isEmpty { return viewModel.pageTitle }
        if !viewModel.pageURL.isEmpty   { return viewModel.pageURL }
        return "Enter URL or search…"
    }

    @ViewBuilder
    private func navButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(enabled ? .primary : .secondary)
                .frame(width: 50, height: 50)
                .background(Color(white: 0.22).opacity(0.6))
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
