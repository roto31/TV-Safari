//
//  BrowserBookmarkManager.swift
//  Spartan
//
//  @Observable bookmark manager — no ObservableObject / @Published needed.
//  Requires tvOS 26+
//

import SwiftUI
import Observation

// MARK: - Model

struct BrowserBookmark: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var url: String
    var dateAdded: Date = Date()

    var displayURL: String {
        var d = url
        for scheme in ["https://", "http://"] {
            if d.hasPrefix(scheme) { d = String(d.dropFirst(scheme.count)); break }
        }
        if d.hasSuffix("/") { d = String(d.dropLast()) }
        return d
    }
}

// MARK: - Manager

@Observable
final class BrowserBookmarkManager {

    static let shared = BrowserBookmarkManager()

    var bookmarks: [BrowserBookmark] = []

    private let storageKey = "browser.bookmarks"

    private init() {
        load()
        if bookmarks.isEmpty { bookmarks = BrowserBookmarkManager.defaults }
    }

    // MARK: CRUD

    func addBookmark(title: String, url: String) {
        guard !url.isEmpty else { return }
        if bookmarks.contains(where: { $0.url == url }) { return }
        bookmarks.insert(BrowserBookmark(title: title.isEmpty ? url : title, url: url), at: 0)
        save()
    }

    func removeBookmark(_ bookmark: BrowserBookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        save()
    }

    func remove(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        bookmarks.move(fromOffsets: source, toOffset: destination)
        save()
    }

    // MARK: Persistence

    private func load() {
        guard let data = UserDefaults.settings.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([BrowserBookmark].self, from: data)
        else { return }
        bookmarks = decoded
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(bookmarks) else { return }
        UserDefaults.settings.set(encoded, forKey: storageKey)
    }

    // MARK: Defaults

    static let defaults: [BrowserBookmark] = [
        BrowserBookmark(title: "Archive.org Home",    url: "https://archive.org"),
        BrowserBookmark(title: "Archive.org Movies",  url: "https://archive.org/details/movies"),
        BrowserBookmark(title: "Archive.org TV",      url: "https://archive.org/details/tv"),
        BrowserBookmark(title: "Archive.org Audio",   url: "https://archive.org/details/audio"),
        BrowserBookmark(title: "Archive.org Books",   url: "https://archive.org/details/texts"),
        BrowserBookmark(title: "Archive.org Live",    url: "https://archive.org/details/stream_only"),
        BrowserBookmark(title: "NASA TV",             url: "https://www.nasa.gov/nasatv"),
        BrowserBookmark(title: "YouTube",             url: "https://www.youtube.com"),
        BrowserBookmark(title: "Twitch",              url: "https://www.twitch.tv"),
        BrowserBookmark(title: "Discord",             url: "https://discord.com/app"),
        BrowserBookmark(title: "Reddit",              url: "https://old.reddit.com"),
        BrowserBookmark(title: "Wikipedia",           url: "https://en.wikipedia.org"),
    ]
}
