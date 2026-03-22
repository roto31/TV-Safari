//
//  ArchiveOrgView.swift
//  Spartan
//
//  Native Archive.org browser with search, categories, and featured collections.
//  Requires tvOS 26+
//

import SwiftUI

// MARK: - Models

struct ArchiveSearchResponse: Codable {
    let response: ArchiveResponseBody
}
struct ArchiveResponseBody: Codable {
    let docs: [ArchiveDoc]
    let numFound: Int
}
struct ArchiveDoc: Codable, Identifiable {
    var id: String { identifier }
    let identifier: String
    let title: String?
    let mediatype: String?
    let description: String?
    let year: String?
    let creator: String?
    let downloads: Int?

    var displayTitle: String { title ?? identifier }
    var thumbnailURL: URL { URL(string: "https://archive.org/services/img/\(identifier)")! }
    var detailURL: String  { "https://archive.org/details/\(identifier)" }
    var mediaIcon: String {
        switch mediatype ?? "" {
        case "movies": return "film"
        case "audio":  return "music.note"
        case "texts":  return "book"
        case "software": return "cpu"
        case "collection": return "folder"
        case "etree":  return "music.mic"
        case "image":  return "photo"
        default:       return "doc"
        }
    }
}

// MARK: - ArchiveOrgView

struct ArchiveOrgView: View {

    var viewModel: WebViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var searchText    = ""
    @State private var searchResults: [ArchiveDoc] = []
    @State private var isSearching   = false
    @State private var searchError: String? = nil
    @State private var searchTask: Task<Void, Never>? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 20) {
                    TextField("Search Archive.org…", text: $searchText)
                        .textFieldStyle(URLFieldStyle())
                        .autocapitalization(.none).disableAutocorrection(true)
                        .onSubmit { performSearch(query: searchText) }
                    Button("Search") { performSearch(query: searchText) }
                        .buttonStyle(BrowserActionButtonStyle(isDestructive: false))
                        .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 60).padding(.vertical, 20)

                Divider()

                ScrollView {
                    if searchText.isEmpty && searchResults.isEmpty {
                        homeTiles
                    } else if isSearching {
                        VStack(spacing: 20) {
                            Spacer(minLength: 60)
                            ProgressView().progressViewStyle(.circular).scaleEffect(2)
                            Text("Searching archive.org…").font(.system(size: 28)).foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                    } else if let error = searchError {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle").font(.system(size: 60)).foregroundStyle(.yellow)
                            Text(error).font(.system(size: 26)).multilineTextAlignment(.center).padding(.horizontal, 60)
                        }
                        .padding(.top, 40)
                    } else {
                        resultGrid
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Category Tiles

    enum ArchiveCategory: String, CaseIterable, Identifiable {
        case movies = "movies"; case tv = "tv"; case audio = "audio"
        case books = "texts"; case software = "software"; case live = "stream_only"
        var id: String { rawValue }
        var label: String {
            switch self {
            case .movies: return "Movies"; case .tv: return "TV"; case .audio: return "Audio"
            case .books: return "Books"; case .software: return "Software"; case .live: return "Live"
            }
        }
        var icon: String {
            switch self {
            case .movies: return "film"; case .tv: return "tv"; case .audio: return "music.note.list"
            case .books: return "books.vertical"; case .software: return "cpu"
            case .live: return "antenna.radiowaves.left.and.right"
            }
        }
        var color: Color {
            switch self {
            case .movies: return .red; case .tv: return .purple; case .audio: return .orange
            case .books: return .green; case .software: return .blue; case .live: return .pink
            }
        }
    }

    var homeTiles: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Browse Categories")
                .font(.system(size: 34, weight: .bold))
                .padding(.horizontal, 60).padding(.top, 30)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                ForEach(ArchiveCategory.allCases) { cat in
                    Button { navigateToCategory(cat) } label: {
                        VStack(spacing: 16) {
                            Image(systemName: cat.icon).font(.system(size: 50)).foregroundStyle(cat.color)
                            Text(cat.label).font(.system(size: 30, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 30)
                        .background(cat.color.opacity(0.12)).cornerRadius(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 60)

            Divider().padding(.horizontal, 60)

            Text("Featured Collections").font(.system(size: 34, weight: .bold)).padding(.horizontal, 60)
            featuredSection
        }
    }

    var featuredSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(featuredItems) { item in
                    Button { openItem(item) } label: { featuredTile(item) }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 60).padding(.bottom, 40)
        }
    }

    @ViewBuilder
    func featuredTile(_ item: FeaturedItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: URL(string: item.url)) { image in
                image.resizable().aspectRatio(4/3, contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color(.systemGray5))
                    .overlay(Image(systemName: item.icon).font(.system(size: 40)).foregroundStyle(.secondary))
            }
            .frame(width: 300, height: 220).clipped().cornerRadius(12)
            Text(item.title).font(.system(size: 24, weight: .medium)).lineLimit(2).frame(width: 300, alignment: .leading)
        }
    }

    // MARK: - Result Grid

    var resultGrid: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(searchResults.count) results").font(.system(size: 28)).foregroundStyle(.secondary)
                    .padding(.horizontal, 60).padding(.top, 20)
                Spacer()
                Button("Clear") { searchText = ""; searchResults = []; searchError = nil }
                    .buttonStyle(BrowserActionButtonStyle(isDestructive: true))
                    .padding(.trailing, 60).padding(.top, 20)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                ForEach(searchResults) { doc in
                    Button { openDoc(doc) } label: { resultCard(doc) }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 60).padding(.bottom, 40)
        }
    }

    @ViewBuilder
    func resultCard(_ doc: ArchiveDoc) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            AsyncImage(url: doc.thumbnailURL) { image in
                image.resizable().aspectRatio(4/3, contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color(.systemGray5))
                    .overlay(Image(systemName: doc.mediaIcon).font(.system(size: 36)).foregroundStyle(.secondary))
            }
            .frame(maxWidth: .infinity).aspectRatio(4/3, contentMode: .fit).clipped().cornerRadius(10)
            Text(doc.displayTitle).font(.system(size: 20, weight: .medium)).lineLimit(2)
            if let year = doc.year { Text(year).font(.system(size: 18)).foregroundStyle(.secondary) }
        }
        .padding(10).background(Color(.systemGray6).opacity(0.4)).cornerRadius(12)
    }

    // MARK: - Actions

    private func navigateToCategory(_ cat: ArchiveCategory) {
        viewModel.load(urlString: "https://archive.org/details/\(cat.rawValue)")
        dismiss()
    }
    private func openDoc(_ doc: ArchiveDoc) { viewModel.load(urlString: doc.detailURL); dismiss() }
    private func openItem(_ item: FeaturedItem) { viewModel.load(urlString: item.url); dismiss() }

    // MARK: - Search

    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        searchTask?.cancel()
        isSearching = true
        searchError = nil

        searchTask = Task {
            let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            let urlStr = "https://archive.org/advancedsearch.php" +
                "?q=\(encoded)&output=json&rows=40&page=1" +
                "&fl[]=identifier&fl[]=title&fl[]=mediatype" +
                "&fl[]=description&fl[]=year&fl[]=creator&fl[]=downloads" +
                "&sort[]=downloads+desc"

            guard let url = URL(string: urlStr) else {
                await MainActor.run { searchError = "Could not construct search URL"; isSearching = false }
                return
            }
            do {
                let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url, timeoutInterval: 15))
                let decoded = try JSONDecoder().decode(ArchiveSearchResponse.self, from: data)
                await MainActor.run {
                    isSearching = false
                    searchResults = decoded.response.docs
                    if searchResults.isEmpty { searchError = "No results for \"\(trimmed)\"" }
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    searchError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Featured Items

    struct FeaturedItem: Identifiable {
        let id = UUID()
        let title: String
        let url: String
        let icon: String
    }

    private let featuredItems: [FeaturedItem] = [
        FeaturedItem(title: "Prelinger Archives",  url: "https://archive.org/details/prelinger",        icon: "film"),
        FeaturedItem(title: "Grateful Dead",        url: "https://archive.org/details/GratefulDead",     icon: "music.note"),
        FeaturedItem(title: "Classic TV",           url: "https://archive.org/details/classic_tv",       icon: "tv"),
        FeaturedItem(title: "NASA Videos",          url: "https://archive.org/details/nasa",             icon: "sparkle"),
        FeaturedItem(title: "Old Time Radio",       url: "https://archive.org/details/oldtimeradio",     icon: "antenna.radiowaves.left.and.right"),
        FeaturedItem(title: "Feature Films",        url: "https://archive.org/details/feature_films",    icon: "film.stack"),
    ]
}
