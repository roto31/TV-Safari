//
//  BookmarksView.swift
//  Spartan
//
//  Requires tvOS 26+
//

import SwiftUI

struct BookmarksView: View {

    var viewModel: WebViewModel
    private var bookmarkManager = BrowserBookmarkManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: BookmarksTab = .bookmarks
    @State private var searchText = ""

    enum BookmarksTab: String, CaseIterable {
        case bookmarks = "Bookmarks"
        case history   = "History"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    ForEach(BookmarksTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 60).padding(.vertical, 20)

                TextField("Search…", text: $searchText)
                    .textFieldStyle(URLFieldStyle())
                    .autocapitalization(.none).disableAutocorrection(true)
                    .padding(.horizontal, 60).padding(.bottom, 10)

                Divider()

                if selectedTab == .bookmarks { bookmarkList } else { historyList }
            }
            .navigationTitle(selectedTab.rawValue)
            .navigationBarHidden(true)
        }
    }

    // MARK: Bookmark List

    var bookmarkList: some View {
        Group {
            if filteredBookmarks.isEmpty {
                emptyState(icon: "bookmark", message: "No bookmarks yet.\nBrowse a page and tap + to save it.")
            } else {
                List {
                    ForEach(filteredBookmarks) { bookmark in
                        Button {
                            viewModel.load(urlString: bookmark.url)
                            dismiss()
                        } label: {
                            bookmarkRow(bookmark)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: bookmarkManager.remove)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) { }
                }
                .listStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func bookmarkRow(_ bookmark: BrowserBookmark) -> some View {
        HStack(spacing: 20) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 28)).foregroundStyle(.accent).frame(width: 40)
            VStack(alignment: .leading, spacing: 6) {
                Text(bookmark.title).font(.system(size: 28, weight: .medium)).lineLimit(1)
                Text(bookmark.displayURL).font(.system(size: 22)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var filteredBookmarks: [BrowserBookmark] {
        guard !searchText.isEmpty else { return bookmarkManager.bookmarks }
        return bookmarkManager.bookmarks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.url.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: History List

    var historyList: some View {
        Group {
            if filteredHistory.isEmpty {
                emptyState(icon: "clock", message: "No browsing history yet.")
            } else {
                List {
                    ForEach(filteredHistory) { entry in
                        Button {
                            viewModel.load(urlString: entry.url)
                            dismiss()
                        } label: {
                            historyRow(entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func historyRow(_ entry: WebHistoryEntry) -> some View {
        HStack(spacing: 20) {
            Image(systemName: "clock").font(.system(size: 28)).foregroundStyle(.secondary).frame(width: 40)
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title).font(.system(size: 28, weight: .medium)).lineLimit(1)
                Text(entry.url).font(.system(size: 22)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text(relativeDate(entry.visitedAt)).font(.system(size: 20)).foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var filteredHistory: [WebHistoryEntry] {
        guard !searchText.isEmpty else { return viewModel.history }
        return viewModel.history.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.url.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: Helpers

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: icon).font(.system(size: 60)).foregroundStyle(.secondary)
            Text(message).font(.system(size: 26)).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }

    private func relativeDate(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 60    { return "Just now" }
        if diff < 3600  { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }
}
