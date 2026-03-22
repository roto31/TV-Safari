//
//  BrowserView.swift
//  TV Safari
//
//  tvOS browser shell — layout and materials aligned with Apple’s tvOS design guidance
//  (legibility at distance, materials, grouped controls, SF Symbols).
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
            canvasBackground

            WebViewRepresentable(viewModel: viewModel)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topChrome
                Spacer(minLength: 0)
            }

            if showErrorBanner, let msg = viewModel.errorMessage {
                errorBanner(message: msg)
                    .padding(.top, errorBannerTopPadding)
                    .transition(.move(edge: .top).combined(with: .opacity))
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
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) { showErrorBanner = true }
            Task {
                try? await Task.sleep(for: .seconds(6))
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

    // MARK: - Canvas

    private var canvasBackground: some View {
        LinearGradient(
            colors: [
                Color(white: 0.08),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Top chrome

    private var topChrome: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 20) {
                toolbarCluster {
                    navIconButton(icon: "chevron.backward", enabled: viewModel.canGoBack) {
                        viewModel.goBack()
                    }
                    navIconButton(icon: "chevron.forward", enabled: viewModel.canGoForward) {
                        viewModel.goForward()
                    }
                    navIconButton(
                        icon: viewModel.isLoading ? "xmark" : "arrow.clockwise",
                        enabled: true
                    ) {
                        if viewModel.isLoading { viewModel.stopLoading() } else { viewModel.reload() }
                    }
                }

                addressBarButton
                    .layoutPriority(1)

                toolbarCluster {
                    navIconButton(icon: "archivebox.fill", enabled: true) { showArchiveOrg = true }
                    navIconButton(icon: "antenna.radiowaves.left.and.right", enabled: true) { showLiveStreams = true }
                    navIconButton(icon: "bookmark.fill", enabled: !viewModel.pageURL.isEmpty) {
                        bookmarks.addBookmark(title: viewModel.pageTitle, url: viewModel.pageURL)
                    }
                    navIconButton(icon: "list.bullet", enabled: true) { showBookmarks = true }
                }
            }
            .padding(.horizontal, BrowserLayout.chromeHorizontalMargin)
            .padding(.vertical, BrowserLayout.chromeVerticalPadding)

            if viewModel.isLoading {
                ProgressView(value: viewModel.estimatedProgress)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
                    .padding(.horizontal, BrowserLayout.chromeHorizontalMargin)
                    .padding(.bottom, 14)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.estimatedProgress)
            }
        }
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
        }
    }

    private func toolbarCluster<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: BrowserLayout.toolbarClusterSpacing) {
            content()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: BrowserLayout.iconCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    private var addressBarButton: some View {
        Button {
            showURLInput = true
        } label: {
            HStack(alignment: .center, spacing: 18) {
                Image(systemName: securityIconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(securityIconColor)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 36, alignment: .center)

                VStack(alignment: .leading, spacing: 6) {
                    Text(addressCaption)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(addressPrimaryLine)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: BrowserLayout.addressBarMinHeight, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: BrowserLayout.addressBarCornerRadius, style: .continuous)
                    .fill(.thinMaterial)
            }
        }
        .buttonStyle(BrowserAddressButtonStyle())
    }

    private var securityIconName: String {
        if viewModel.pageURL.isEmpty { return "globe" }
        return viewModel.pageURL.lowercased().hasPrefix("https") ? "lock.fill" : "lock.open.fill"
    }

    private var securityIconColor: Color {
        if viewModel.pageURL.isEmpty { return .secondary }
        return viewModel.pageURL.lowercased().hasPrefix("https") ? .green : .orange
    }

    private var addressCaption: String {
        if viewModel.isLoading { return "Loading" }
        if viewModel.pageURL.isEmpty { return "Address" }
        if viewModel.pageURL.lowercased().hasPrefix("https") { return "Encrypted" }
        if viewModel.pageURL.lowercased().hasPrefix("http://") { return "Not encrypted" }
        return "Address"
    }

    private var addressPrimaryLine: String {
        if viewModel.isLoading { return "Please wait…" }
        if !viewModel.pageTitle.isEmpty { return viewModel.pageTitle }
        if !viewModel.pageURL.isEmpty { return simplifiedHostOrURL }
        return "Search or enter a website"
    }

    private var simplifiedHostOrURL: String {
        guard let u = URL(string: viewModel.pageURL), let host = u.host else {
            return viewModel.pageURL
        }
        return host
    }

    // MARK: - Error

    private var errorBannerTopPadding: CGFloat {
        var h = BrowserLayout.topChromeBaseHeight
        if viewModel.isLoading { h += 36 }
        return h + 8
    }

    private func errorBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
                .symbolRenderingMode(.hierarchical)
            VStack(alignment: .leading, spacing: 6) {
                Text("Something went wrong")
                    .font(.headline.weight(.semibold))
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
            Button {
                withAnimation { showErrorBanner = false }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thickMaterial)
        }
        .padding(.horizontal, BrowserLayout.chromeHorizontalMargin)
    }

    // MARK: - Toolbar buttons

    @ViewBuilder
    private func navIconButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .frame(width: BrowserLayout.iconButtonSide, height: BrowserLayout.iconButtonSide)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
        .buttonStyle(BrowserToolbarIconButtonStyle())
    }
}

// MARK: - Button styles (focus-friendly, tvOS)

/// Primary control for the address field — keeps system focus treatment readable on tvOS.
private struct BrowserAddressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct BrowserToolbarIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.12 : 0.06))
            }
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Legacy name (used by ArchiveOrgView and similar)

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
