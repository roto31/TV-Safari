//
//  WebViewRepresentable.swift
//  Spartan
//
//  Requires tvOS 26+
//

import SwiftUI
import WebKit

struct WebViewRepresentable: UIViewRepresentable {

    var viewModel: WebViewModel   // plain var — @Observable tracks it automatically

    func makeUIView(context: Context) -> WKWebView {
        let wv = viewModel.webView
        wv.scrollView.showsVerticalScrollIndicator = true
        wv.scrollView.showsHorizontalScrollIndicator = false
        wv.scrollView.bounces = true
        wv.isOpaque = false
        wv.backgroundColor = .black
        wv.scrollView.backgroundColor = .black
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
