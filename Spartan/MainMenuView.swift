//
//  MainMenuView.swift
//  Spartan
//
//  App home screen — presented at launch.
//  Lets the user choose between the full-featured Browser and the File Manager.
//

import SwiftUI
import AVKit

struct MainMenuView: View {

    // File-manager launch params (passed through from AppDelegate)
    let directory: String
    let isRootless: Bool
    let scaleFactor: CGFloat
    @Binding var globalAVPlayer: AVPlayer

    @State private var showBrowser     = false
    @State private var showFileManager = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemGray6), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 60) {

                // App title
                VStack(spacing: 10) {
                    Text("Spartan")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                    Text("Browser & File Manager for Apple TV")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)

                // Main tiles
                HStack(spacing: 60) {
                    // ── Browser tile ────────────────────────────────────────
                    appTile(
                        icon:        "globe",
                        iconColor:   .blue,
                        title:       "Browser",
                        subtitle:    "Web • Archive.org • Streaming • Live TV",
                        action:      { showBrowser = true }
                    )

                    // ── File Manager tile ──────────────────────────────────
                    appTile(
                        icon:        "folder.fill",
                        iconColor:   .orange,
                        title:       "File Manager",
                        subtitle:    "Browse, edit and manage files on your Apple TV",
                        action:      { showFileManager = true }
                    )
                }
                .padding(.horizontal, 80)

                Spacer()

                // Footer
                Text("Use the Siri Remote trackpad to navigate • Menu to go back")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
        }
        // ── Full-screen Browser ────────────────────────────────────────────
        .fullScreenCover(isPresented: $showBrowser) {
            BrowserView(isPresented: $showBrowser)
        }
        // ── Full-screen File Manager ───────────────────────────────────────
        .fullScreenCover(isPresented: $showFileManager) {
            ContentView(
                directory:      directory,
                isRootless:     isRootless,
                scaleFactor:    scaleFactor,
                globalAVPlayer: $globalAVPlayer
            )
        }
    }

    // MARK: - Tile builder

    @ViewBuilder
    private func appTile(icon: String,
                         iconColor: Color,
                         title: String,
                         subtitle: String,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .foregroundColor(iconColor)
                }

                VStack(spacing: 10) {
                    Text(title)
                        .font(.system(size: 42, weight: .bold))
                    Text(subtitle)
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: 380)
                }
            }
            .padding(40)
            .frame(width: 480)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemGray6).opacity(0.5))
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            )
        }
        .buttonStyle(TileButtonStyle())
    }
}

// MARK: - Tile button style (focus ring + scale animation)

struct TileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
