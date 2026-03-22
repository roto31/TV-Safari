//
//  LiveStreamView.swift
//  Spartan
//
//  Curated live and on-demand stream catalog for tvOS.
//
//  Categories
//  ──────────
//  • News — publicly available 24/7 HLS news streams
//  • Space / Science — NASA, ESA, ISS feeds
//  • Archive.org Live — public domain live events
//  • Music — live concert archives
//  • Custom — user-entered stream URLs (persisted in UserDefaults)
//
//  Selecting a stream opens StreamingPlayerView directly (no web view needed).
//  Custom URL entry allows typing or pasting any HLS / video URL.
//

import SwiftUI

// MARK: - Models

struct LiveStream: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let url: String
    let category: StreamCategory
    let icon: String
    var isCustom: Bool = false
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

    /// Called when the user selects a stream to play
    let onSelectStream: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: StreamCategory = .news
    @State private var showCustomURLInput = false
    @State private var customURLText      = ""
    @State private var customStreams: [LiveStream] = LiveStreamView.loadCustomStreams()

    var body: some View {
        NavigationView {
            HStack(spacing: 0) {

                // ── Category sidebar ───────────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text("Live Streams")
                        .font(.system(size: 32, weight: .bold))
                        .padding(.horizontal, 30)
                        .padding(.top, 30)
                        .padding(.bottom, 10)

                    ForEach(StreamCategory.allCases, id: \.rawValue) { cat in
                        Button(action: { selectedCategory = cat }) {
                            HStack(spacing: 16) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(cat.color)
                                    .frame(width: 30)
                                Text(cat.rawValue)
                                    .font(.system(size: 26, weight: selectedCategory == cat ? .bold : .regular))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                selectedCategory == cat
                                    ? cat.color.opacity(0.15)
                                    : Color.clear
                            )
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 10)
                    }

                    Spacer()

                    // Add custom stream button
                    Button(action: { showCustomURLInput = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.accentColor)
                            Text("Add Stream URL")
                                .font(.system(size: 24))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 10)
                    .padding(.bottom, 30)
                }
                .frame(width: 340)
                .background(Color(.systemGray6).opacity(0.3))

                Divider()

                // ── Stream list ────────────────────────────────────────────
                streamList
            }
        }
        .sheet(isPresented: $showCustomURLInput) {
            customURLSheet
        }
    }

    // MARK: - Stream List

    var streamList: some View {
        let streams = streamsForCategory(selectedCategory)

        return Group {
            if streams.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: selectedCategory.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No streams in \(selectedCategory.rawValue)")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    if selectedCategory == .custom {
                        Button("Add a Stream") {
                            showCustomURLInput = true
                        }
                        .buttonStyle(BrowserActionButtonStyle(isDestructive: false))
                    }
                    Spacer()
                }
            } else {
                List {
                    ForEach(streams) { stream in
                        Button(action: {
                            onSelectStream(stream.url)
                            dismiss()
                        }) {
                            streamRow(stream)
                        }
                        .buttonStyle(PlainButtonStyle())
                        // swipeActions requires tvOS 15+
                        .modifier(DeleteSwipeModifier(
                            enabled: stream.isCustom,
                            action: { removeCustomStream(stream) }
                        ))
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }

    @ViewBuilder
    func streamRow(_ stream: LiveStream) -> some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(stream.category.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: stream.icon)
                    .font(.system(size: 28))
                    .foregroundColor(stream.category.color)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(stream.name)
                        .font(.system(size: 28, weight: .medium))
                    if !stream.isCustom {
                        // Live badge
                        Text("LIVE")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
                Text(stream.description)
                    .font(.system(size: 22))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "play.fill")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Custom URL Sheet

    var customURLSheet: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Add Stream URL")
                    .font(.system(size: 40, weight: .bold))
                    .padding(.top, 40)

                Text("Enter an HLS (.m3u8), MP4, or any direct video/audio URL")
                    .font(.system(size: 26))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)

                TextField("https://example.com/stream.m3u8", text: $customURLText)
                    .textFieldStyle(URLFieldStyle())
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 60)

                HStack(spacing: 30) {
                    Button("Cancel") {
                        showCustomURLInput = false
                        customURLText = ""
                    }
                    .buttonStyle(BrowserActionButtonStyle(isDestructive: true))

                    Button("Play Now") {
                        let url = customURLText.trimmingCharacters(in: .whitespaces)
                        guard !url.isEmpty else { return }
                        showCustomURLInput = false
                        customURLText = ""
                        onSelectStream(url)
                        dismiss()
                    }
                    .buttonStyle(BrowserActionButtonStyle(isDestructive: false))
                    .disabled(customURLText.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button("Save & Play") {
                        let url = customURLText.trimmingCharacters(in: .whitespaces)
                        guard !url.isEmpty else { return }
                        let stream = LiveStream(
                            name: url,
                            description: "Custom stream",
                            url: url,
                            category: .custom,
                            icon: "video",
                            isCustom: true
                        )
                        customStreams.append(stream)
                        LiveStreamView.saveCustomStreams(customStreams)
                        showCustomURLInput = false
                        customURLText = ""
                        onSelectStream(url)
                        dismiss()
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

    private func streamsForCategory(_ category: StreamCategory) -> [LiveStream] {
        if category == .custom { return customStreams }
        return LiveStreamView.builtInStreams.filter { $0.category == category }
    }

    private func removeCustomStream(_ stream: LiveStream) {
        customStreams.removeAll { $0.id == stream.id }
        LiveStreamView.saveCustomStreams(customStreams)
    }

    // MARK: - Custom stream persistence

    private static let customStreamsKey = "browser.customStreams"

    static func loadCustomStreams() -> [LiveStream] {
        guard let data = UserDefaults.settings.data(forKey: customStreamsKey),
              let stored = try? JSONDecoder().decode([StoredStream].self, from: data)
        else { return [] }
        return stored.map {
            LiveStream(name: $0.name, description: $0.description,
                       url: $0.url, category: .custom, icon: "video", isCustom: true)
        }
    }

    static func saveCustomStreams(_ streams: [LiveStream]) {
        let stored = streams.map { StoredStream(name: $0.name, description: $0.description, url: $0.url) }
        if let encoded = try? JSONEncoder().encode(stored) {
            UserDefaults.settings.set(encoded, forKey: customStreamsKey)
        }
    }

    struct StoredStream: Codable {
        let name: String
        let description: String
        let url: String
    }

    // MARK: - Delete Swipe Modifier (tvOS 15+ only)

struct DeleteSwipeModifier: ViewModifier {
    let enabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(tvOS 15.0, *), enabled {
            content.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive, action: action) {
                    Label("Delete", systemImage: "trash")
                }
            }
        } else {
            content
        }
    }
}

// MARK: - Built-in streams

    static let builtInStreams: [LiveStream] = [

        // ── News ──────────────────────────────────────────────────────────
        LiveStream(name: "NASA TV",
                   description: "Live NASA television — missions, press conferences & more",
                   url: "https://ntv1.akamaized.net/hls/live/2014075/NTV1/master.m3u8",
                   category: .news, icon: "sparkle"),

        LiveStream(name: "Bloomberg TV",
                   description: "24/7 business and world news",
                   url: "https://bloomberg.com/media-manifest/streams/us.m3u8",
                   category: .news, icon: "chart.bar"),

        LiveStream(name: "Al Jazeera English",
                   description: "Global news network — live stream",
                   url: "https://live-hls-web-aje.getaj.net/AJE/index.m3u8",
                   category: .news, icon: "globe"),

        LiveStream(name: "France 24 English",
                   description: "International news from France 24",
                   url: "https://stream.france24.com/hls/live/2037986/F24_EN_LO_HLS/master.m3u8",
                   category: .news, icon: "newspaper"),

        LiveStream(name: "DW News",
                   description: "Deutsche Welle international news",
                   url: "https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8",
                   category: .news, icon: "newspaper.fill"),

        // ── Space ─────────────────────────────────────────────────────────
        LiveStream(name: "ISS Live Feed",
                   description: "International Space Station Earth view",
                   url: "https://nasa-i.akamaihd.net/hls/live/253565/NASA-NTV1-Public/master.m3u8",
                   category: .space, icon: "globe.asia.australia"),

        LiveStream(name: "NASA TV 2 (Media)",
                   description: "NASA TV Media Channel — technical feeds",
                   url: "https://ntv2.akamaized.net/hls/live/2014076/NTV2/master.m3u8",
                   category: .space, icon: "moon.stars.fill"),

        LiveStream(name: "ESA Webstream",
                   description: "European Space Agency — when available",
                   url: "https://www.esa.int/esatv",
                   category: .space, icon: "sparkles"),

        // ── Archive.org ────────────────────────────────────────────────────
        LiveStream(name: "Archive.org Live Events",
                   description: "Currently airing events on the Internet Archive",
                   url: "https://archive.org/details/stream_only",
                   category: .archive, icon: "archivebox.fill"),

        LiveStream(name: "Prelinger Films",
                   description: "Public domain industrial and educational films",
                   url: "https://archive.org/details/prelinger",
                   category: .archive, icon: "film"),

        LiveStream(name: "Old Time Radio",
                   description: "Classic radio broadcasts from the archive",
                   url: "https://archive.org/details/oldtimeradio",
                   category: .archive, icon: "antenna.radiowaves.left.and.right"),

        // ── Music ─────────────────────────────────────────────────────────
        LiveStream(name: "SomaFM: Groove Salad",
                   description: "A nicely chilled plate of ambient/downtempo beats",
                   url: "https://ice1.somafm.com/groovesalad-256-mp3",
                   category: .music, icon: "headphones"),

        LiveStream(name: "SomaFM: Drone Zone",
                   description: "Served chilled: cinematic and ambient space music",
                   url: "https://ice1.somafm.com/dronezone-256-mp3",
                   category: .music, icon: "waveform"),

        LiveStream(name: "SomaFM: Lush",
                   description: "Sensuous and mellow female vocals, trip-hop, down-tempo",
                   url: "https://ice1.somafm.com/lush-128-mp3",
                   category: .music, icon: "music.note"),

        LiveStream(name: "SomaFM: Space Station Soma",
                   description: "Tune in, float back. Ambient music for a space voyage.",
                   url: "https://ice1.somafm.com/spacestation-128-mp3",
                   category: .music, icon: "moon.fill"),

        LiveStream(name: "Grateful Dead Archive",
                   description: "Concerts from the Internet Archive",
                   url: "https://archive.org/details/GratefulDead",
                   category: .music, icon: "music.mic"),
    ]
}
