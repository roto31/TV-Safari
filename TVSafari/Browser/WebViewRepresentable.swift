//
//  WebViewRepresentable.swift
//  TV Safari
//
//  tvOS does not provide WKWebView. This view is the main canvas: clear hierarchy,
//  large type, and SF Symbols — aligned with Apple’s tvOS design language.
//

import SwiftUI

/// Primary content area when no HTML engine is available (tvOS).
struct WebViewRepresentable: View {

    var viewModel: WebViewModel

    var body: some View {
        VStack(spacing: BrowserLayout.canvasSectionSpacing) {
            Spacer(minLength: BrowserLayout.canvasTopSpacer)

            Image(systemName: "globe.americas.fill")
                .font(.system(size: BrowserLayout.heroSymbolPointSize, weight: .thin))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)

            VStack(spacing: BrowserLayout.canvasTextSpacing) {
                Text(heroTitle)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(heroBody)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: BrowserLayout.canvasCopyMaxWidth)
                if !detailLine.isEmpty {
                    Text(detailLine)
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: BrowserLayout.canvasCopyMaxWidth)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, BrowserLayout.canvasHorizontalPadding)

            Spacer()
            Spacer(minLength: BrowserLayout.canvasBottomSpacer)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilitySummary))
    }

    private var heroTitle: String {
        if viewModel.pageURL.isEmpty {
            return "Browse on Apple TV"
        }
        return viewModel.pageTitle.isEmpty ? "Current address" : viewModel.pageTitle
    }

    private var heroBody: String {
        if viewModel.pageURL.isEmpty {
            return "Apple TV doesn’t include a built-in web page renderer. Enter an address, open Internet Archive, or pick a live stream — video streams play in full screen when supported."
        }
        return "This page isn’t rendered as a full website here. Use the toolbar to open streams, Archive.org, or another destination."
    }

    private var detailLine: String {
        guard !viewModel.pageURL.isEmpty else { return "" }
        return viewModel.pageURL
    }

    private var accessibilitySummary: String {
        heroTitle + ". " + heroBody + (detailLine.isEmpty ? "" : " " + detailLine)
    }
}

// MARK: - Layout constants (tvOS — comfortable viewing distance)

enum BrowserLayout {
    static let chromeHorizontalMargin: CGFloat = 48
    static let chromeVerticalPadding: CGFloat = 22
    static let toolbarClusterSpacing: CGFloat = 14
    static let iconButtonSide: CGFloat = 56
    static let iconCornerRadius: CGFloat = 14
    static let addressBarMinHeight: CGFloat = 68
    static let addressBarCornerRadius: CGFloat = 16
    static let canvasSectionSpacing: CGFloat = 28
    static let canvasTextSpacing: CGFloat = 12
    static let canvasHorizontalPadding: CGFloat = 80
    static let canvasCopyMaxWidth: CGFloat = 820
    static let canvasTopSpacer: CGFloat = 72
    static let canvasBottomSpacer: CGFloat = 120
    static let heroSymbolPointSize: CGFloat = 96
    /// Approximate height of the top bar (toolbar + optional progress) for overlay layout.
    static var topChromeBaseHeight: CGFloat { chromeVerticalPadding * 2 + max(addressBarMinHeight + 36, iconButtonSide + 28) }
}
