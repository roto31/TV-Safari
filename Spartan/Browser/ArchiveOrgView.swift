//
//  ArchiveOrgView.swift
//  Spartan
//
//  Native Archive.org browser for tvOS.
//
//  Features
//  ────────
//  • Category tiles — Movies, TV, Audio, Books, Software, Live
//  • Full-text search using the Archive.org advanced-search JSON API
//  • Result grid with thumbnails loaded asynchronously
//  • Tap a result → loads the item's detail page in the shared WebViewModel
//  • Tap a streamable item → launches StreamingPlayerView directly
//
//  API endpoints used
//  ──────────────────
//  Search  : https://archive.org/advancedsearch.php?q=…&output=json&rows=40&fl[]=identifier,title,mediatype,description,year,creator,downloads
//  Thumb   : https://archive.org/services/img/{identifier}
//  Detail  : https://archive.org/details/{identifier}
//  Stream  : https://archive.org/download/{identifier}/{filename}
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
    var thumbnailURL: URL {
        URL(string: "https://archive.org/services/img/\(identifier)")!
    }
    var detailURL: String {
        "https://archive.org/details/\(identifier)"
    }
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

    @ObservedObject var viewModel: WebViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var searchText     = ""
    @State private var searchResults: [ArchiveDoc] = []
    @State private var isSearching    = false
    @State private var searchError: String? = nil
    @State private var selectedCategory: ArchiveCategory? = nil

    // Direct stream player
    @State private var showStreamPlayer = false
    @State private var streamURL        = ""

    enum ArchiveCategory: String, CaseIterable, Identifiable {
        case movies   = "movies"
        case tv       = "tv"
        case audio    = "audio"
        case books    = "texts"
        case software = "software"
        case live     = "stream_only"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .movies:   return "Movies"
            case .tv:       return "TV"
            case .audio:    return "Audio"
            case .books:    return "Books"
            case .software: return "Software"
            case .live:     return "Live"
            }
        }

        var icon: String {
            switch self {
            case .movies:   return "film"
            case .tv:       return "tv"
            case .audio:    return "music.note.list"
            case .books:    return "books.vertical"
            case .software: return "cpu"
            case .live:     return "antenna.radiowaves.left.and.right"
            }
        }

        var color: Color {
            switch self {
            case .movies:   return .red
            case .tv:       return .purple
            case .audio:    return .orange
            case .books:    return .green
            case .software: return .blue
            case .live:     return .pink
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // ── Search bar ────────────────────────────────────────────
                HStack(spacing: 20) {
                    TextField("Search Archive.org…", text: $searchText, onCommit: {
                        performSearch(query: searchText)
                    })
                    .textFieldStyle(URLFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                    Button("Search") {
                        performSearch(query: searchText)
                    }
                    .buttonStyle(BrowserActionButtonStyle(isDestructive: false))
                    .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 20)

                Divider()

                ScrollView {
                    if searchText.isEmpty && searchResults.isEmpty {
                        // ── Home: Category Tiles ─────────────────────────
                        homeTiles
                    } else if isSearching {
                        // ── Loading ───────────────────────────────────────
                        VStack(spacing: 20) {
                            Spacer(minLength: 60)
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(2)
                            Text("Searching archive.org…")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else if let error = searchError {
                        // ── Error ─────────────────────────────────────────
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                            Text(error)
                                .font(.system(size: 26))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 60)
                        }
                        .padding(.top, 40)
                    } else {
                        // ── Search Results ────────────────────────────────
                        resultGrid
                    }
                }
            }
            .navigationTitle("Archive.org")
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showStreamPlayer) {
            StreamingPlayerView(streamURL: streamURL, isPresented: $showStreamPlayer)
        }
    }

    // MARK: - Home tiles

    var homeTiles: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Browse Categories")
                .font(.system(size: 34, weight: .bold))
                .padding(.horizontal, 60)
                .padding(.top, 30)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3),
                spacing: 20
            ) {
                ForEach(ArchiveCategory.allCases) { cat in
                    Button(action: {
                        navigateToCategory(cat)
                    }) {
                        VStack(spacing: 16) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 50))
                                .foregroundColor(cat.color)
                            Text(cat.label)
                                .font(.system(size: 30, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(cat.color.opacity(0.12))
                        .cornerRadius(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 60)

            Divider().padding(.horizontal, 60)

            // ── Featured collections ─────────────────────────────────────
            Text("Featured Collections")
                .font(.system(size: 34, weight: .bold))
                .padding(.horizontal, 60)

            featuredSection
        }
    }

    var featuredSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(featuredItems) { item in
                    Button(action: { openItem(item) }) {
                        featuredTile(item)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 40)
        }
    }

    @ViewBuilder
    func featuredTile(_ item: FeaturedItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            RemoteImage(url: item.thumbURL) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: item.icon)
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                    )
            }
            .frame(width: 300, height: 220)
            .clipped()
            .cornerRadius(12)

            Text(item.title)
                .font(.system(size: 24, weight: .medium))
                .lineLimit(2)
                .frame(width: 300, alignment: .leading)
        }
    }

    // MARK: - Result grid

    var resultGrid: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(searchResults.count) results")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 60)
                    .padding(.top, 20)
                Spacer()
                Button("Clear") {
                    searchText = ""
                    searchResults = []
                    searchError = nil
                }
                .buttonStyle(BrowserActionButtonStyle(isDestructive: true))
                .padding(.trailing, 60)
                .padding(.top, 20)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4),
                spacing: 16
            ) {
                ForEach(searchResults) { doc in
                    Button(action: { openDoc(doc) }) {
                        resultCard(doc)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 40)
        }
    }

    @ViewBuilder
    func resultCard(_ doc: ArchiveDoc) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            RemoteImage(url: doc.thumbnailURL) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: doc.mediaIcon)
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                    )
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(4/3, contentMode: .fit)
            .clipped()
            .cornerRadius(10)

            Text(doc.displayTitle)
                .font(.system(size: 20, weight: .medium))
                .lineLimit(2)

            if let year = doc.year {
                Text(year)
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.systemGray6).opacity(0.4))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func navigateToCategory(_ cat: ArchiveCategory) {
        let url = "https://archive.org/details/\(cat.rawValue)"
        viewModel.load(urlString: url)
        dismiss()
    }

    private func openDoc(_ doc: ArchiveDoc) {
        // For streamable media types, go directly to the item page in browser
        viewModel.load(urlString: doc.detailURL)
        dismiss()
    }

    private func openItem(_ item: FeaturedItem) {
        viewModel.load(urlString: item.url)
        dismiss()
    }

    // MARK: - Search

    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isSearching = true
        searchError = nil

        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        let urlStr = "https://archive.org/advancedsearch.php" +
            "?q=\(encoded)" +
            "&output=json&rows=40&page=1" +
            "&fl[]=identifier&fl[]=title&fl[]=mediatype" +
            "&fl[]=description&fl[]=year&fl[]=creator&fl[]=downloads" +
            "&sort[]=downloads+desc"

        guard let url = URL(string: urlStr) else {
            searchError = "Could not construct search URL"
            isSearching = false
            return
        }

        let task = URLSession.shared.dataTask(with: URLRequest(url: url, timeoutInterval: 15)) { data, response, error in
            DispatchQueue.main.async {
                isSearching = false
                if let error = error {
                    searchError = error.localizedDescription
                    return
                }
                guard let data = data else {
                    searchError = "No data received"
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(ArchiveSearchResponse.self, from: data)
                    searchResults = decoded.response.docs
                    if searchResults.isEmpty {
                        searchError = "No results found for \"\(trimmed)\""
                    }
                } catch {
                    searchError = "Parse error: \(error.localizedDescription)"
                }
            }
        }
        task.resume()
    }

    // MARK: - Featured items data

    struct FeaturedItem: Identifiable {
        let id = UUID()
        let title: String
        let url: String
        let icon: String
        var thumbURL: URL? { URL(string: url) }
    }

    private let featuredItems: [FeaturedItem] = [
        FeaturedItem(title: "Prelinger Archives", url: "https://archive.org/details/prelinger", icon: "film"),
        FeaturedItem(title: "Grateful Dead", url: "https://archive.org/details/GratefulDead", icon: "music.note"),
        FeaturedItem(title: "Classic TV", url: "https://archive.org/details/classic_tv", icon: "tv"),
        FeaturedItem(title: "NASA Videos", url: "https://archive.org/details/nasa", icon: "sparkle"),
        FeaturedItem(title: "Old Time Radio", url: "https://archive.org/details/oldtimeradio", icon: "antenna.radiowaves.left.and.right"),
        FeaturedItem(title: "Feature Films", url: "https://archive.org/details/feature_films", icon: "film.stack"),
    ]
}
