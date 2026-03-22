//
//  WebViewRepresentable.swift
//  Spartan
//
//  UIViewRepresentable wrapper for WKWebView on tvOS.
//  Handles focus integration so the Siri Remote trackpad
//  scrolls and interacts with web content naturally.
//

import SwiftUI
import WebKit

struct WebViewRepresentable: UIViewRepresentable {

    @ObservedObject var viewModel: WebViewModel

    func makeUIView(context: Context) -> WKWebView {
        let wv = viewModel.webView
        wv.scrollView.showsVerticalScrollIndicator = true
        wv.scrollView.showsHorizontalScrollIndicator = false
        // Bounce looks natural on tvOS trackpad scrolling
        wv.scrollView.bounces = true
        wv.scrollView.bouncesZoom = false
        // Transparent background so our ZStack background shows
        wv.isOpaque = false
        wv.backgroundColor = .black
        wv.scrollView.backgroundColor = .black
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // State-driven updates are handled through WebViewModel's KVO;
        // nothing needs to be pushed imperatively from SwiftUI here.
    }
}
