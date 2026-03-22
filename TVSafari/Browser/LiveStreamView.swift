//
//  LiveStreamView.swift
//  TV Safari
//
//  Curated live and on-demand stream catalog.
//  Requires tvOS 26+
//

import SwiftUI

// MARK: - Models

struct LiveStream: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let url: String
    let category: StreamCategory
    let icon: String
    var isCustom: Bool = false

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        url: String,
        category: StreamCategory,
        icon: String,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.url = url
        self.category = category
        self.icon = icon
        self.isCustom = isCustom
    }
}

enum StreamCategory: String, CaseIterable {
    case news    = "News"
    case space   = "Space & Science"
    case archive = "Archive.org"
    case music   = "Music"
    case custom  = "My Streams"

    var icon: String {
        switch self {
        case .news:    return "newspaper"
        case .space:   return "moon.stars"
        case .archive: return "archivebox"
        case .music:   return "music.mic"
        case .custom:  return "plus.circle"
        }
    }
    var color: Color {
        switch self {
        case .news:    return .blue
        case .space:   return .purple
        case .archive: return .orange
        case .music:   return .green
        case .custom:  return .gray
        }
    }
}

// MARK: - LiveStreamView

struct LiveStreamView: View {

    let onSelectStream: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: StreamCategory = .news
    @State private var showCustomURLInput = false
    @State private var customURLText      = ""
    @State private var customStreams: [LiveStream] = LiveStreamView.loadCustomStreams()
    @State private var customStreamsListEditMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                sidebar
                Divider()
                streamList
            }
        }
        .sheet(isPresented: $showCustomURLInput) { customURLSheet }
    }

    // MARK: - Sidebar

    var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live Streams")
                .font(.system(size: 32, weight: .bold))
                .padding(.horizontal, 30).padding(.top, 30).padding(.bottom, 10)

            ForEach(StreamCategory.allCases, id: \.rawValue) { cat in
                Button { selectedCategory = cat } label: {
                    HStack(spacing: 16) {
                        Image(systemName: cat.icon).font(.system(size: 24)).foregroundStyle(cat.color).frame(width: 30)
                        Text(cat.rawValue)
                            .font(.system(size: 26, weight: selectedCategory == cat ? .bold : .regular))
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(selectedCategory == cat ? cat.color.opacity(0.15) : .clear)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
            }

            Spacer()

            Button {
                showCustomURLInput = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundStyle(.accent)
                    Text("Add Stream URL").font(.system(size: 24))
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10).padding(.bottom, 30)
        }
        .frame(width: 340)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Stream List

    var streamList: some View {
        let streams = streamsForCategory(selectedCategory)
        return Group {
            if streams.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: selectedCategory.icon).font(.system(size: 60)).foregroundStyle(.secondary)
                    Text("No streams in \(selectedCategory.rawValue)").font(.system(size: 28)).foregroundStyle(.secondary)
                    if selectedCategory == .custom {
                        Button("Add a Stream") { showCustomURLInput = true }
                            .buttonStyle(BrowserActionButtonStyle(isDestructive: false))
                    }
                    Spacer()
                }
            } else if selectedCategory == .custom {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        #if os(tvOS)
                        Button(customStreamsListEditMode == .active ? "Done" : "Edit Order") {
                            customStreamsListEditMode = customStreamsListEditMode == .active ? .inactive : .active
                        }
                        .font(.system(size: 24))
                        #else
                        EditButton()
                            .font(.system(size: 22))
                        #endif
                    }
                    .padding(.trailing, 24).padding(.vertical, 10)

                    List {
                        ForEach(customStreams) { stream in
                            streamRowButton(stream)
                        }
                        .onDelete(perform: deleteCustomStreamsAt)
                        .onMove(perform: moveCustomStreams)
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, $customStreamsListEditMode)
                }
            } else {
                List {
                    ForEach(streams) { stream in
                        streamRowButton(stream)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func streamRowButton(_ stream: LiveStream) -> some View {
        Button {
            onSelectStream(stream.url)
            dismiss()
        } label: {
            streamRow(stream)
        }
        .buttonStyle(.plain)
        #if !os(tvOS)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if stream.isCustom {
                Button(role: .destructive) { removeCustomStream(stream) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        #endif
        .contextMenu {
            if stream.isCustom {
                Button(role: .destructive) { removeCustomStream(stream) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    @ViewBuilder
    func streamRow(_ stream: LiveStream) -> some View {
        HStack(spacing: 20) {
            ZStack {
                Circle().fill(stream.category.color.opacity(0.2)).frame(width: 60, height: 60)
                Image(systemName: stream.icon).font(.system(size: 28)).foregroundStyle(stream.category.color)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(stream.name).font(.system(size: 28, weight: .medium))
                    if !stream.isCustom {
                        Text("LIVE")
                            .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(.red).cornerRadius(4)
                    }
                }
                Text(stream.description).font(.system(size: 22)).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer()
            Image(systemName: "play.fill").font(.system(size: 24)).foregroundStyle(.accent)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Custom URL Sheet

    var customURLSheet: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Add Stream URL").font(.system(size: 40, weight: .bold)).padding(.top, 40)
                Text("Enter an HLS (.m3u8), MP4, or any direct video/audio URL")
                    .font(.system(size: 26)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 60)

                TextField("https://example.com/stream.m3u8", text: $customURLText)
                    .textFieldStyle(URLFieldStyle()).keyboardType(.URL)
                    .autocapitalization(.none).disableAutocorrection(true)
                    .padding(.horizontal, 60)

                HStack(spacing: 30) {
                    Button("Cancel") { showCustomURLInput = false; customURLText = "" }
                        .buttonStyle(BrowserActionButtonStyle(isDestructive: true))

                    Button("Play Now") {
                        let url = customURLText.trimmingCharacters(in: .whitespaces)
                        guard !url.isEmpty else { return }
                        showCustomURLInput = false; customURLText = ""
                        onSelectStream(url); dismiss()
                    }
                    .buttonStyle(BrowserActionButtonStyle(isDestructive: false))
                    .disabled(customURLText.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button("Save & Play") {
                        let url = customURLText.trimmingCharacters(in: .whitespaces)
                        guard !url.isEmpty else { return }
                        let stream = LiveStream(name: url, description: "Custom stream",
                                               url: url, category: .custom, icon: "video", isCustom: true)
                        customStreams.append(stream)
                        LiveStreamView.saveCustomStreams(customStreams)
                        showCustomURLInput = false; customURLText = ""
                        onSelectStream(url); dismiss()
                    }
                    .buttonStyle(BrowserActionButtonStyle(isDestructive: false))
                    .disabled(customURLText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Data

    private func streamsForCategory(_ cat: StreamCategory) -> [LiveStream] {
        cat == .custom ? customStreams : LiveStreamView.builtInStreams.filter { $0.category == cat }
    }

    private func removeCustomStream(_ stream: LiveStream) {
        customStreams.removeAll { $0.id == stream.id }
        LiveStreamView.saveCustomStreams(customStreams)
    }

    private func deleteCustomStreamsAt(_ offsets: IndexSet) {
        customStreams.remove(atOffsets: offsets)
        LiveStreamView.saveCustomStreams(customStreams)
    }

    private func moveCustomStreams(from source: IndexSet, to destination: Int) {
        customStreams.move(fromOffsets: source, toOffset: destination)
        LiveStreamView.saveCustomStreams(customStreams)
    }

    // MARK: - Persistence

    private static let customStreamsKey = "browser.customStreams"

    static func loadCustomStreams() -> [LiveStream] {
        guard let data = UserDefaults.settings.data(forKey: customStreamsKey),
              let stored = try? JSONDecoder().decode([StoredStream].self, from: data)
        else { return [] }
        return stored.map {
            LiveStream(id: $0.id, name: $0.name, description: $0.description, url: $0.url,
                       category: .custom, icon: "video", isCustom: true)
        }
    }

    static func saveCustomStreams(_ streams: [LiveStream]) {
        let stored = streams.map { StoredStream(id: $0.id, name: $0.name, description: $0.description, url: $0.url) }
        if let encoded = try? JSONEncoder().encode(stored) {
            UserDefaults.settings.set(encoded, forKey: customStreamsKey)
        }
    }

    struct StoredStream: Codable {
        var id: UUID
        let name: String
        let description: String
        let url: String

        enum CodingKeys: String, CodingKey { case id, name, description, url }

        init(id: UUID, name: String, description: String, url: String) {
            self.id = id
            self.name = name
            self.description = description
            self.url = url
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
            name = try c.decode(String.self, forKey: .name)
            description = try c.decode(String.self, forKey: .description)
            url = try c.decode(String.self, forKey: .url)
        }
    }

    // MARK: - Built-in Streams

    static let builtInStreams: [LiveStream] = [
        LiveStream(name: "NASA TV", description: "Live NASA television — missions, press conferences & more",
                   url: "https://ntv1.akamaized.net/hls/live/2014075/NTV1/master.m3u8", category: .news, icon: "sparkle"),
        LiveStream(name: "Bloomberg TV", description: "24/7 business and world news",
                   url: "https://bloomberg.com/media-manifest/streams/us.m3u8", category: .news, icon: "chart.bar"),
        LiveStream(name: "Al Jazeera English", description: "Global news network — live stream",
                   url: "https://live-hls-web-aje.getaj.net/AJE/index.m3u8", category: .news, icon: "globe"),
        LiveStream(name: "France 24 English", description: "International news from France 24",
                   url: "https://stream.france24.com/hls/live/2037986/F24_EN_LO_HLS/master.m3u8", category: .news, icon: "newspaper"),
        LiveStream(name: "DW News", description: "Deutsche Welle international news",
                   url: "https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8", category: .news, icon: "newspaper.fill"),

        LiveStream(name: "ISS Live Feed", description: "International Space Station Earth view",
                   url: "https://nasa-i.akamaihd.net/hls/live/253565/NASA-NTV1-Public/master.m3u8", category: .space, icon: "globe.asia.australia"),
        LiveStream(name: "NASA TV 2 (Media)", description: "NASA TV Media Channel — technical feeds",
                   url: "https://ntv2.akamaized.net/hls/live/2014076/NTV2/master.m3u8", category: .space, icon: "moon.stars.fill"),
        LiveStream(name: "ESA Webstream", description: "European Space Agency — when available",
                   url: "https://www.esa.int/esatv", category: .space, icon: "sparkles"),

        LiveStream(name: "Archive.org Live Events", description: "Currently airing events on the Internet Archive",
                   url: "https://archive.org/details/stream_only", category: .archive, icon: "archivebox.fill"),
        LiveStream(name: "Prelinger Films", description: "Public domain industrial and educational films",
                   url: "https://archive.org/details/prelinger", category: .archive, icon: "film"),
        LiveStream(name: "Old Time Radio", description: "Classic radio broadcasts from the archive",
                   url: "https://archive.org/details/oldtimeradio", category: .archive, icon: "antenna.radiowaves.left.and.right"),

        LiveStream(name: "SomaFM: Groove Salad", description: "A nicely chilled plate of ambient/downtempo beats",
                   url: "https://ice1.somafm.com/groovesalad-256-mp3", category: .music, icon: "headphones"),
        LiveStream(name: "SomaFM: Drone Zone", description: "Served chilled: cinematic and ambient space music",
                   url: "https://ice1.somafm.com/dronezone-256-mp3", category: .music, icon: "waveform"),
        LiveStream(name: "SomaFM: Space Station Soma", description: "Tune in, float back. Ambient music for a space voyage.",
                   url: "https://ice1.somafm.com/spacestation-128-mp3", category: .music, icon: "moon.fill"),
        LiveStream(name: "Grateful Dead Archive", description: "Concerts from the Internet Archive",
                   url: "https://archive.org/details/GratefulDead", category: .music, icon: "music.mic"),
    ]
}
