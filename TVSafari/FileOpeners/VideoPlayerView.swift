//
//  VideoPlayerView2.swift
//  TV Safari
//
//  Created by RealKGB on 4/12/23.
//

import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    @Binding var videoPath: String
    @Binding var videoName: String
    @Binding var isPresented: Bool
    @State var player: AVPlayer
    @State private var descriptiveTimestamps = UserDefaults.settings.bool(forKey: "verboseTimestamps")
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var rewindIncrement = 1
    @State private var fastIncrement = 1
    @State private var infoShow = false
    @State private var videoTitle: String = ""
    @State private var fullScreen = false
    @State private var videoInfoMessage: String = "—"

    var body: some View {
        NavigationStack {
            VStack {
                if(!fullScreen) {
                    if(videoTitle == ""){
                        Text(descriptiveTimestamps ? videoPath + videoName : videoName)
                            .if(UserDefaults.settings.bool(forKey: "sheikahFontApply")) { view in
                                view.scaledFont(name: "BotW Sheikah Regular", size: 40)
                            }
                            .font(.system(size: 40))
                            .multilineTextAlignment(.center)
                            .padding(-20)
                    } else {
                        Text(videoTitle)
                            .if(UserDefaults.settings.bool(forKey: "sheikahFontApply")) { view in
                                view.scaledFont(name: "BotW Sheikah Regular", size: 40)
                            }
                            .font(.system(size: 40))
                            .multilineTextAlignment(.center)
                            .padding(-20)
                    }
                }
                VideoPlayerRenderView(player: player)
                    .padding()
                    .background(UIKitTapGesture(action: {
						infoShow = true
					}))
					.focusable(true)
                    .alert(isPresented: $infoShow) {
						Alert(
							title: Text(videoPath + videoName),
							message: Text(videoInfoMessage),
							dismissButton: .default(Text(NSLocalizedString("DISMISS", comment: "- I wonder where they were.")))
						)
					}
                if (!fullScreen) {
                    timeLabel
                    UIKitProgressView(value: $currentTime, total: duration)
                        .padding()
                        .transition(.opacity)
                    HStack {
                        videoStartButton
                            .transition(.opacity)
                        Spacer()
                        controlsView
                            .transition(.opacity)
                        Spacer()
                        Button(action: {
                            withAnimation {
                                fullScreen = true
                            }
                        }) {
                            Image(systemName: "viewfinder")
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
        .onAppear {
            player.replaceCurrentItem(with: AVPlayerItem(url: URL(fileURLWithPath: (videoPath + "/" + videoName))))
            player.play()
            player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 10), queue: DispatchQueue.main) { time in
                self.currentTime = time.seconds
            }
            Task { await loadVideoPresentationState() }
        }
        .onDisappear {
            player.pause()
        }
        .onReceive(player.publisher(for: \.timeControlStatus)) { timeControlStatus in
            isPlaying = timeControlStatus == .playing
        }
        .onExitCommand {
            if(fullScreen) {
                withAnimation {
                    fullScreen = false
                }
            } else {
                isPresented = false
            }
        }
    }
    
    var controlsView: some View {
        HStack {
            rewindButton
            backwardButton
            playPauseButton
            forwardButton
            fastForwardButton
        }
        .padding(.horizontal)
        .onPlayPauseCommand {
            if isPlaying {
                player.pause()
            } else {
                player.play()
            }
            isPlaying.toggle()
        }
    }
    
    @ViewBuilder
    var backwardButton: some View {
        Button(action: {
            let newTime = max(player.currentTime() - CMTime(seconds: 10, preferredTimescale: 1), CMTime.zero)
            player.seek(to: newTime)
        }) {
            Image(systemName: "gobackward.10")
                .tint(.accentColor)
        }
    }
    
    @ViewBuilder
    var timeLabel: some View {
        if(descriptiveTimestamps) {
            Text("\(currentTime) / \(duration)")
                .if(UserDefaults.settings.bool(forKey: "sheikahFontApply")) { view in
                    view.scaledFont(name: "BotW Sheikah Regular", size: 30)
                }
                .font(.system(size: 30))
                .multilineTextAlignment(.leading)
        } else {
            Text("\(currentTime.format()) / \(duration.format())")
                .if(UserDefaults.settings.bool(forKey: "sheikahFontApply")) { view in
                    view.scaledFont(name: "BotW Sheikah Regular", size: 30)
                }
                .font(.system(size: 30))
                .multilineTextAlignment(.leading)
        }
    }
    
    @ViewBuilder
    var forwardButton: some View {
        Button(action: {
            let end = CMTime(seconds: duration, preferredTimescale: 1)
            let newTime = min(player.currentTime() + CMTime(seconds: 10, preferredTimescale: 1), end)
            player.seek(to: newTime)
        }) {
            Image(systemName: "goforward.10")
                .tint(.accentColor)
        }
    }
    
    @ViewBuilder
    var videoStartButton: some View {
        Button(action: {
            let newTime = max(player.currentTime() - player.currentTime(), CMTime.zero)
            player.seek(to: newTime)
        }) {
            let time = max(player.currentTime(), CMTime.zero)
            let newTime = max(player.currentTime() - player.currentTime(), CMTime.zero)
            Image(systemName: time > newTime ? "backward.end.fill" : "backward.end")
                .resizable()
                .frame(width:36, height:32)
                .tint(.accentColor)
        }
    }
    
    @ViewBuilder
    var rewindButton: some View {
        Button(action: {
            if rewindIncrement == 1 {
                player.rate = -1.0
            } else if rewindIncrement == 2 {
                player.rate = -2.0
            } else if rewindIncrement == 3 {
                player.rate = -4.0
            } else if rewindIncrement == 4 {
                player.rate = -8.0
            } else if rewindIncrement == 5 {
                player.rate = 1.0
            }
            if(rewindIncrement == 5){
                rewindIncrement = 1
            } else {
                rewindIncrement += 1
            }
        }) {
            Image(systemName: player.rate < 0.0 ? "backward.fill" : "backward")
                .resizable()
                .frame(width:54, height:31)
                .tint(.accentColor)
        }
    }
    
    @ViewBuilder
    var playPauseButton: some View {
        Button(action: {
            if isPlaying {
                player.pause()
            } else {
                player.play()
            }
        }) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .frame(width:50, height:50)
        }
    }
    
    @ViewBuilder
    var fastForwardButton: some View {
        Button(action: {
            if fastIncrement == 1 {
                player.rate = 2.0
            } else if fastIncrement == 2 {
                player.rate = 4.0
            } else if fastIncrement == 3 {
                player.rate = 8.0
            } else if fastIncrement == 4 {
                player.rate = 1.0
            }
            if(fastIncrement == 4){
                fastIncrement = 1
            } else {
                fastIncrement += 1
            }
        }) {
            Image(systemName: player.rate > 1.0 ? "forward.fill" : "forward")
                .resizable()
                .frame(width:54, height:31)
                .tint(.accentColor)
        }
    }
    
    @MainActor
    private func loadVideoPresentationState() async {
        guard let asset = player.currentItem?.asset else { return }
        do {
            let d = try await asset.load(.duration)
            duration = d.seconds
        } catch {
            duration = 0
        }
        guard let metaAsset = player.currentItem?.asset else { return }
        if let metadataList = try? await metaAsset.load(.commonMetadata) {
            for metadata in metadataList {
                guard let commonKey = metadata.commonKey?.rawValue,
                      commonKey == AVMetadataKey.commonKeyTitle.rawValue else { continue }
                if let title = try? await metadata.load(.value) as? String {
                    videoTitle = title
                }
            }
        }
        videoInfoMessage = await Self.buildVideoInfo(filePath: videoPath + "/" + videoName)
    }

    private static func buildVideoInfo(filePath: String) async -> String {
        let fileURL = URL(fileURLWithPath: filePath)
        let asset = AVURLAsset(url: fileURL)
        do {
            let dur = try await asset.load(.duration)
            let durationStr = String(format: "%.2f", dur.seconds)
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let videoTrack = tracks.first else {
                return NSLocalizedString("VIDEO_ERROR", comment: "Will we pick ourjob today?")
            }
            let naturalSize = try await videoTrack.load(.naturalSize)
            let width2 = String(format: "%.1f", naturalSize.width)
            let height2 = String(format: "%.1f", naturalSize.height)
            return """
            \(NSLocalizedString("VIDEO_FILE", comment: "I heard it's just orientation.") + fileURL.lastPathComponent)
            \(NSLocalizedString("VIDEO_DURATION", comment: "Heads up! Here we go.") + durationStr) \(NSLocalizedString("SECONDS", comment: ""))
            \(NSLocalizedString("DIMENSIONS", comment: "Keep your hands and antennas inside the tram at all times.") + width2) x \(height2) pixels
            """
        } catch {
            return NSLocalizedString("VIDEO_ERROR", comment: "Will we pick ourjob today?")
        }
    }
}

struct VideoPlayerRenderView: UIViewControllerRepresentable {
    @State var player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.player?.rate = 1.0
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        player.play()
        uiViewController.player = player
    }
}
