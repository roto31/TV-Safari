//
//  URLInputView.swift
//  Spartan
//
//  URL / search input sheet that invokes the Apple TV's system keyboard.
//  Presented modally over the browser whenever the user activates the URL bar.
//

import SwiftUI

struct URLInputView: View {

    /// The URL currently shown in the bar — pre-fills the text field.
    let currentURL: String
    /// Called when the user confirms a new URL or search query.
    let onCommit: (String) -> Void

    @State private var text: String = ""
    @Environment(\.dismiss) private var dismiss

    // Quick-access suggestions shown beneath the field
    private let suggestions: [(icon: String, label: String, url: String)] = [
        ("archivebox.fill",  "Archive.org",          "https://archive.org"),
        ("film",             "Archive Movies",        "https://archive.org/details/movies"),
        ("music.note",       "Archive Audio",         "https://archive.org/details/audio"),
        ("tv",               "Archive TV",            "https://archive.org/details/tv"),
        ("video",            "NASA TV",               "https://www.nasa.gov/nasatv"),
        ("play.rectangle",   "YouTube",               "https://www.youtube.com"),
        ("waveform",         "Twitch",                "https://www.twitch.tv"),
        ("bubble.left.and.bubble.right", "Discord",   "https://discord.com/app"),
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {

                // ── Text field ──────────────────────────────────────────
                TextField("Enter URL or search…", text: $text, onCommit: commit)
                    .textFieldStyle(URLFieldStyle())
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 60)
                    .padding(.top, 40)

                // ── Action buttons ───────────────────────────────────────
                HStack(spacing: 30) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(BrowserActionButtonStyle(isDestructive: true))

                    Button("Go") {
                        commit()
                    }
                    .buttonStyle(BrowserActionButtonStyle(isDestructive: false))
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Divider().padding(.horizontal, 60)

                // ── Quick-access tiles ───────────────────────────────────
                Text("Quick Access")
                    .font(.system(size: 28, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 60)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4),
                    spacing: 20
                ) {
                    ForEach(suggestions, id: \.url) { item in
                        Button(action: {
                            onCommit(item.url)
                            dismiss()
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 36))
                                Text(item.label)
                                    .font(.system(size: 22))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color(.systemGray5).opacity(0.4))
                            .cornerRadius(14)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 60)

                Spacer()
            }
            .navigationTitle("Address Bar")
            .navigationBarHidden(true)
        }
        .onAppear {
            // Pre-fill with current page URL, selected so user can type over it
            text = currentURL
        }
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onCommit(trimmed)
        dismiss()
    }
}

// MARK: - Styles

struct URLFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .font(.system(size: 30, design: .monospaced))
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(.systemGray6).opacity(0.8))
            .cornerRadius(12)
    }
}

struct BrowserActionButtonStyle: ButtonStyle {
    let isDestructive: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 28, weight: .semibold))
            .foregroundColor(isDestructive ? .red : .white)
            .padding(.horizontal, 40)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDestructive
                          ? Color.red.opacity(0.15)
                          : Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
