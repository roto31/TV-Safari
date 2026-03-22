//
//  URLInputView.swift
//  TV Safari
//
//  Address sheet — tvOS HIG: clear title, large type, grouped quick actions.
//

import SwiftUI

struct URLInputView: View {

    let currentURL: String
    let onCommit: (String) -> Void

    @State private var text = ""
    @Environment(\.dismiss) private var dismiss

    private let suggestions: [(icon: String, label: String, url: String)] = [
        ("archivebox.fill",  "Internet Archive", "https://archive.org"),
        ("film",             "Archive Movies",   "https://archive.org/details/movies"),
        ("music.note",       "Archive Audio",    "https://archive.org/details/audio"),
        ("tv",               "Archive TV",       "https://archive.org/details/tv"),
        ("video",            "NASA TV",          "https://www.nasa.gov/nasatv"),
        ("play.rectangle",   "YouTube",          "https://www.youtube.com"),
        ("waveform",         "Twitch",           "https://www.twitch.tv"),
        ("bubble.left.and.bubble.right", "Discord", "https://discord.com/app"),
    ]

    private let gridColumns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Website or search")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        TextField("Enter URL or search…", text: $text)
                            .textFieldStyle(URLFieldStyle())
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onSubmit { commit() }
                    }
                    .padding(.top, 8)

                    HStack(spacing: 24) {
                        Button("Cancel", role: .cancel) { dismiss() }
                            .buttonStyle(BrowserSheetActionStyle(role: .cancel))
                        Button("Go") { commit() }
                            .buttonStyle(BrowserSheetActionStyle(role: .primary))
                            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Quick open")
                            .font(.title3.weight(.semibold))
                        Text("Choose a destination or type an address above.")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: gridColumns, spacing: 24) {
                            ForEach(suggestions, id: \.url) { item in
                                Button {
                                    onCommit(item.url)
                                    dismiss()
                                } label: {
                                    VStack(spacing: 16) {
                                        Image(systemName: item.icon)
                                            .font(.system(size: 40, weight: .medium))
                                            .symbolRenderingMode(.hierarchical)
                                            .frame(height: 44)
                                        Text(item.label)
                                            .font(.body.weight(.medium))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.85)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 132)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 8)
                                    .background {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(.thinMaterial)
                                    }
                                }
                                .buttonStyle(BrowserQuickLinkButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 56)
                .padding(.bottom, 48)
            }
            .navigationTitle("Address")
        }
        .onAppear { text = currentURL }
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onCommit(trimmed)
        dismiss()
    }
}

// MARK: - Field & button styles

/// Large, legible URL field for living-room distance.
struct URLFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .font(.system(size: 32, weight: .regular, design: .monospaced))
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
            }
    }
}

private enum BrowserSheetActionRole {
    case cancel
    case primary
}

private struct BrowserSheetActionStyle: ButtonStyle {
    let role: BrowserSheetActionRole

    func makeBody(configuration: Configuration) -> some View {
        Group {
            switch role {
            case .cancel:
                configuration.label
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
            case .primary:
                configuration.label
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.accentColor)
                    }
            }
        }
        .opacity(configuration.isPressed ? 0.88 : 1)
        .scaleEffect(configuration.isPressed ? 0.97 : 1)
        .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

private struct BrowserQuickLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Shared (Bookmarks, etc.)

struct BrowserActionButtonStyle: ButtonStyle {
    let isDestructive: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .padding(.horizontal, 36)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isDestructive
                        ? Color.red.opacity(0.22)
                        : Color.accentColor.opacity(configuration.isPressed ? 0.85 : 1)
                    )
            }
            .foregroundStyle(isDestructive ? Color.red : Color.white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
