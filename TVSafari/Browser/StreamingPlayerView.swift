//
//  StreamingPlayerView.swift
//  TV Safari
//
//  Performance-optimised streaming player.
//  Supports HLS, MPEG-TS, MP4, MOV, MKV, MP3, AAC, FLAC.
//  Uses async/await for player status observation — no Combine needed.
//  Requires tvOS 26+
//

import SwiftUI
import AVKit
import AVFoundation

struct StreamingPlayerView: View {

    let streamURL: String
    @Binding var isPresented: Bool

    @State private var player: AVPlayer?
    @State private var playerItem: AVPlayerItem?
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var isAudioOnly = false
    @State private var statusTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player, !isAudioOnly {
                NativePlayerView(player: player).ignoresSafeArea()
            } else if let player, isAudioOnly {
                AudioStreamView(player: player, streamURL: streamURL)
            }

            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(2)
                    Text("Connecting to stream…")
                        .font(.system(size: 28)).foregroundStyle(.white)
                    Text(streamURL)
                        .font(.system(size: 20, design: .monospaced))
                        .foregroundStyle(.gray)
                        .lineLimit(2).multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                }
            }

            if let error = errorMessage {
                VStack(spacing: 30) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60)).foregroundStyle(.yellow)
                    Text("Stream Error")
                        .font(.system(size: 40, weight: .bold)).foregroundStyle(.white)
                    Text(error)
                        .font(.system(size: 26)).foregroundStyle(.gray)
                        .multilineTextAlignment(.center).padding(.horizontal, 80)
                    HStack(spacing: 40) {
                        Button("Retry") { setupPlayer() }.buttonStyle(StreamButtonStyle(primary: true))
                        Button("Close") { isPresented = false }.buttonStyle(StreamButtonStyle(primary: false))
                    }
                }
            }

            if player != nil && !isLoading && errorMessage == nil {
                VStack {
                    HStack {
                        Spacer()
                        AVRoutePickerViewRepresentable()
                            .frame(width: 44, height: 44)
                            .padding(20)
                    }
                    Spacer()
                }
            }
        }
        .onAppear  { setupPlayer() }
        .onDisappear { teardownPlayer() }
        .onExitCommand { isPresented = false }
    }

    // MARK: - Setup / Teardown

    private func setupPlayer() {
        statusTask?.cancel()
        statusTask = nil
        errorMessage = nil
        isLoading = true
        player = nil

        guard let url = URL(string: streamURL) else {
            errorMessage = "Invalid stream URL"
            isLoading = false
            return
        }

        isAudioOnly = isAudioStream(url)

        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": streamHeaders()])
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = streamURL.contains("live") || streamURL.contains("stream") ? 30 : 120
        item.preferredPeakBitRate = 0

        self.playerItem = item
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        self.player = newPlayer

        // Observe AVPlayerItem status with structured concurrency
        statusTask = Task { @MainActor in
            for await status in item.publisher(for: \.status).values {
                switch status {
                case .readyToPlay:
                    isLoading = false
                    newPlayer.play()
                case .failed:
                    isLoading = false
                    errorMessage = item.error?.localizedDescription ?? "Unknown stream error"
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    private func teardownPlayer() {
        statusTask?.cancel()
        statusTask = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerItem = nil
    }

    // MARK: - Helpers

    private func isAudioStream(_ url: URL) -> Bool {
        ["mp3", "aac", "flac", "ogg", "opus", "m4a", "wav", "aiff"]
            .contains(url.pathExtension.lowercased())
    }

    private func streamHeaders() -> [String: String] {
        [
            "User-Agent": "Mozilla/5.0 (AppleTV; CPU OS 26_0) AppleWebKit/605.1.15 Safari/604.1",
            "Accept": "*/*",
            "Accept-Language": "en-US,en;q=0.9"
        ]
    }
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

// MARK: - Audio-only UI

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
                .foregroundStyle(.accent)
                .symbolEffect(.pulse)

            Text("Audio Stream")
                .font(.system(size: 40, weight: .bold)).foregroundStyle(.white)
            Text(streamURL)
                .font(.system(size: 22, design: .monospaced))
                .foregroundStyle(.gray)
                .lineLimit(2).multilineTextAlignment(.center).padding(.horizontal, 60)

            if duration > 0 {
                VStack(spacing: 10) {
                    ProgressView(value: currentTime, total: duration)
                        .progressViewStyle(.linear).tint(.accent)
                        .padding(.horizontal, 80)
                    Text("\(formatTime(currentTime)) / \(formatTime(duration))")
                        .font(.system(size: 24)).foregroundStyle(.gray)
                }
            }

            HStack(spacing: 50) {
                Button { seek(by: -10) } label: { Image(systemName: "gobackward.10").font(.system(size: 36)) }
                Button { togglePlayPause() } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 70))
                }
                Button { seek(by: 10) } label: { Image(systemName: "goforward.10").font(.system(size: 36)) }
            }
            .foregroundStyle(.white)

            Spacer()
        }
        .onPlayPauseCommand { togglePlayPause() }
        .onAppear { setupObservers() }
    }

    private func setupObservers() {
        player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main
        ) { time in currentTime = time.seconds }
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
        let target = max(0, min(player.currentTime().seconds + seconds, duration))
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
    }

    private func formatTime(_ t: Double) -> String {
        guard t.isFinite else { return "--:--" }
        return String(format: "%02d:%02d", Int(t / 60), Int(t) % 60)
    }
}

// MARK: - AirPlay Picker

struct AVRoutePickerViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView()
        v.activeTintColor = .systemBlue
        v.tintColor = .white
        return v
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// MARK: - Button Style

struct StreamButtonStyle: ButtonStyle {
    let primary: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 28, weight: .semibold)).foregroundStyle(.white)
            .padding(.horizontal, 40).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(primary ? Color.accentColor : Color(white: 0.32)))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
