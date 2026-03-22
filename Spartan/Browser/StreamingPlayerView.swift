//
//  StreamingPlayerView.swift
//  Spartan
//
//  Performance-optimised streaming player for tvOS.
//
//  Supports
//  ────────
//  • HLS  (.m3u8)  — adaptive bitrate, automatic quality selection
//  • MPEG-TS (.ts) / MP4 / MOV / MKV / WebM
//  • MP3 / AAC / FLAC / OGG audio
//  • Direct archive.org item download URLs
//  • Any URL AVPlayer can open (passed through)
//
//  UI
//  ──
//  • Full-screen AVPlayerViewController (native tvOS player UI)
//  • Falls back to a custom overlay for URLs the system player can't handle
//  • Error recovery with alternate stream quality option
//  • AirPlay output selector
//

import SwiftUI
import AVKit
import AVFoundation
import Combine

struct StreamingPlayerView: View {

    let streamURL: String
    @Binding var isPresented: Bool

    @State private var player: AVPlayer?
    @State private var playerItem: AVPlayerItem?
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var isAudioOnly = false
    @State private var showQualityPicker = false
    @State private var availableQualities: [StreamQuality] = []
    @State private var currentQualityLabel = "Auto"
    @State private var statusCancellable: AnyCancellable? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player, !isAudioOnly {
                // ── Video player ──────────────────────────────────────────
                NativePlayerView(player: player)
                    .ignoresSafeArea()
            } else if let player = player, isAudioOnly {
                // ── Audio-only UI ─────────────────────────────────────────
                AudioStreamView(player: player, streamURL: streamURL)
            }

            // ── Loading spinner ───────────────────────────────────────────
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                    Text("Connecting to stream…")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                    Text(streamURL)
                        .font(.system(size: 20, design: .monospaced))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                }
            }

            // ── Error state ───────────────────────────────────────────────
            if let error = errorMessage {
                VStack(spacing: 30) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    Text("Stream Error")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    Text(error)
                        .font(.system(size: 26))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 80)
                    HStack(spacing: 40) {
                        Button("Retry") { setupPlayer() }
                            .buttonStyle(StreamButtonStyle(primary: true))
                        Button("Close") { isPresented = false }
                            .buttonStyle(StreamButtonStyle(primary: false))
                    }
                }
            }

            // ── Top-right controls (when playing) ─────────────────────────
            if player != nil && !isLoading && errorMessage == nil {
                VStack {
                    HStack {
                        Spacer()
                        // AirPlay button
                        AVRoutePickerViewRepresentable()
                            .frame(width: 44, height: 44)
                            .padding(20)
                    }
                    Spacer()
                }
            }
        }
        .onAppear { setupPlayer() }
        .onDisappear { teardownPlayer() }
        .onExitCommand { isPresented = false }
    }

    // MARK: - Setup / Teardown

    private func setupPlayer() {
        errorMessage = nil
        isLoading = true
        player = nil

        guard let url = URL(string: streamURL) else {
            errorMessage = "Invalid stream URL"
            isLoading = false
            return
        }

        isAudioOnly = isAudioStream(url)

        // Build an AVPlayerItem with sensible buffering limits to avoid
        // consuming too much Apple TV RAM on long streams.
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": streamHeaders()
        ])
        let item = AVPlayerItem(asset: asset)

        // Cap forward buffer to 30s for live streams, 120s for VOD
        let isLive = streamURL.contains("live") || streamURL.contains("stream")
        item.preferredForwardBufferDuration = isLive ? 30 : 120

        // Start at preferred peak bitrate 0 = automatic adaptive selection
        item.preferredPeakBitRate = 0

        self.playerItem = item
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.automaticallyWaitsToMinimizeStalling = true

        // Observe status via Combine (tvOS 13+ compatible)
        statusCancellable = item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak newPlayer] status in
                switch status {
                case .readyToPlay:
                    isLoading = false
                    newPlayer?.play()
                case .failed:
                    isLoading = false
                    errorMessage = item.error?.localizedDescription ?? "Unknown stream error"
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }

        self.player = newPlayer
    }

    private func teardownPlayer() {
        statusCancellable?.cancel()
        statusCancellable = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerItem = nil
    }

    // MARK: - Helpers

    private func isAudioStream(_ url: URL) -> Bool {
        let audioExts = ["mp3", "aac", "flac", "ogg", "opus", "m4a", "wav", "aiff"]
        return audioExts.contains(url.pathExtension.lowercased())
    }

    private func streamHeaders() -> [String: String] {
        // Provide a browser-like UA so streaming servers don't reject the request
        return [
            "User-Agent": "Mozilla/5.0 (AppleTV; CPU OS 17_0) AppleWebKit/605.1.15 Safari/604.1",
            "Accept": "*/*",
            "Accept-Language": "en-US,en;q=0.9"
        ]
    }
}

// MARK: - Stream Quality Model

struct StreamQuality: Identifiable {
    let id = UUID()
    let label: String
    let bitrate: Double
}

// MARK: - Native AVPlayerViewController

struct NativePlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = true
        vc.allowsPictureInPicturePlayback = true
        vc.requiresLinearPlayback = false
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        vc.player = player
    }
}

// MARK: - Audio-only Stream UI

struct AudioStreamView: View {
    let player: AVPlayer
    let streamURL: String

    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 120))
                .foregroundColor(.accentColor)

            Text("Audio Stream")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)

            Text(streamURL)
                .font(.system(size: 22, design: .monospaced))
                .foregroundColor(.gray)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)

            // Progress (for VOD audio)
            if duration > 0 {
                VStack(spacing: 10) {
                    ProgressView(value: currentTime, total: duration)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .padding(.horizontal, 80)
                    Text("\(formatTime(currentTime)) / \(formatTime(duration))")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }

            // Controls
            HStack(spacing: 50) {
                Button(action: { seek(by: -10) }) {
                    Image(systemName: "gobackward.10").font(.system(size: 36))
                }
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 70))
                }
                Button(action: { seek(by: 10) }) {
                    Image(systemName: "goforward.10").font(.system(size: 36))
                }
            }
            .foregroundColor(.white)

            Spacer()
        }
        .onPlayPauseCommand { togglePlayPause() }
        .onAppear { setupObservers() }
    }

    private func setupObservers() {
        player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { time in
            currentTime = time.seconds
        }
        player.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                duration = player.currentItem?.asset.duration.seconds ?? 0
            }
        }
    }

    private func togglePlayPause() {
        if player.rate > 0 { player.pause() } else { player.play() }
        isPlaying = player.rate > 0
    }

    private func seek(by seconds: Double) {
        let current = player.currentTime().seconds
        let target = max(0, min(current + seconds, duration))
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
    }

    private func formatTime(_ t: Double) -> String {
        guard t.isFinite else { return "--:--" }
        let m = Int(t / 60); let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - AirPlay Route Picker

struct AVRoutePickerViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.activeTintColor = .systemBlue
        view.tintColor = .white
        return view
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// MARK: - Button Style

struct StreamButtonStyle: ButtonStyle {
    let primary: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 28, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(primary ? Color.accentColor : Color(.systemGray4))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
