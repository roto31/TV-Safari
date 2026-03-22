//
//  TVSafariApp.swift
//  TV Safari
//
//  Modern @main App entry point for tvOS 26+.
//  All UIKit app-delegate / UIWindow / UIHostingController boilerplate removed.
//

import SwiftUI
import AVKit
@_exported import LaunchServicesBridge

@main
struct TVSafariApp: App {

    @State private var player = AVPlayer()

    init() {
        // One-time default-settings seed
        if UserDefaults.settings.string(forKey: "tvapothecary") == nil {
            UserDefaults.settings.set(randomString(length: 24), forKey: "tvapothecary")
        }
        if !UserDefaults.settings.bool(forKey: "haveLaunchedBefore") {
            UserDefaults.settings.set(25,               forKey: "logWindowFontSize")
            UserDefaults.settings.set(true,             forKey: "autoComplete")
            UserDefaults.settings.set(true,             forKey: "haveLaunchedBefore")
            UserDefaults.settings.set("MM-dd-yyyy HH:mm", forKey: "dateFormat")
            UserDefaults.settings.synchronize()
        }
        // Ensure trash directory exists
        if !FileManager.default.fileExists(atPath: "/private/var/mobile/Media/.Trash") {
            RootHelperActs.mkdir("/private/var/mobile/Media/.Trash")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainMenuView(
                directory:      startDirectory,
                isRootless:     isRootless,
                scaleFactor:    UIScreen.main.nativeBounds.height / 1080,
                globalAVPlayer: $player
            )
        }
    }

    // MARK: - Helpers

    private var startDirectory: String {
        FileManager.default.isReadableFile(atPath: "/private/var/mobile/")
            ? "/private/var/mobile/"
            : "/Developer/"
    }

    private var isRootless: Bool {
        FileManager.default.fileExists(atPath: "/private/var/jb/")
    }
}

// MARK: - UserDefaults suites

extension UserDefaults {
    static var favorites: UserDefaults {
        UserDefaults(suiteName: "com.spartanbrowser.tvos.favorites") ?? .standard
    }
    static var settings: UserDefaults {
        UserDefaults(suiteName: "com.spartanbrowser.tvos.settings") ?? .standard
    }
}
