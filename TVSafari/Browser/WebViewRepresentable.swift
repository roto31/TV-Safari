//
//  WebViewRepresentable.swift
//  TV Safari
//
//  tvOS does not provide WKWebView. Shows URL state and guidance instead.
//

import SwiftUI
import UIKit

struct WebViewRepresentable: UIViewRepresentable {

    var viewModel: WebViewModel

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.text = placeholderText(for: viewModel)
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.text = placeholderText(for: viewModel)
    }

    private func placeholderText(for vm: WebViewModel) -> String {
        if vm.pageURL.isEmpty {
            return "tvOS has no in-app web engine.\nUse the toolbar for Archive.org, Live Streams, and URL entry.\nHLS (.m3u8) links open in the player."
        }
        return "Address\n\(vm.pageURL)\n\nOpen Live Streams for video streams, or Archive.org for catalog browsing."
    }
}
