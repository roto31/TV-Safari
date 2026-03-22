//
//  RemoteImage.swift
//  Spartan
//
//  Async remote image loader compatible with tvOS 13+.
//  Replaces AsyncImage (tvOS 15+) for backward compatibility.
//

import SwiftUI

final class RemoteImageModel: ObservableObject {
    @Published var image: UIImage? = nil
    private var task: URLSessionDataTask?
    private static var cache = NSCache<NSURL, UIImage>()

    func load(url: URL?) {
        guard let url = url else { return }
        if let cached = RemoteImageModel.cache.object(forKey: url as NSURL) {
            image = cached; return
        }
        task?.cancel()
        task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let img = UIImage(data: data) else { return }
            RemoteImageModel.cache.setObject(img, forKey: url as NSURL)
            DispatchQueue.main.async { self?.image = img }
        }
        task?.resume()
    }
}

/// Drop-in remote image with placeholder support — works on tvOS 13+.
struct RemoteImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder

    @StateObject private var model = RemoteImageModel()

    var body: some View {
        Group {
            if let img = model.image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder()
            }
        }
        .onAppear { model.load(url: url) }
        .onChange(of: url?.absoluteString) { _ in model.load(url: url) }
    }
}
