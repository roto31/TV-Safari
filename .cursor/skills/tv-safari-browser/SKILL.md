---
name: tv-safari-browser
description: Verifies TV Safari (Apple TV) app architecture for consistency after refactors. Use when editing TVSafari/Browser, WebViewModel, WebViewRepresentable, BrowserView, ArchiveOrgView, BookmarksView, LiveStreamView, TVSafari/Assets.xcassets, or when adding web-like / streaming features on Apple TV. For visual design and HIG alignment, also use tvos-safari-design-language.
---

# TV Safari — verification skill

## When to use

- Any change under `TVSafari/Browser/` or to **navigation / history / bookmarks**.
- Adding **URLs**, **streaming**, or **“browser”** behavior on **tvOS**.

## Pre-flight checks

0. **tvOS design language** — For UI/layout changes in `TVSafari/Browser/`, follow [tvos-safari-design-language/SKILL.md](../tvos-safari-design-language/SKILL.md) and [.cursor/rules/tvos-safari-design-language.mdc](../../rules/tvos-safari-design-language.mdc).

1. **Platform SDK availability**  
   - Do not introduce `import WebKit` or `WKWebView` for the tvOS app target.  
   - If full HTML rendering is required, stop and note **BrowserEngine*** / future APIs or a **companion iOS** app — do not assume WebKit.
   - **POSIX spawn APIs** (`posix_spawn`, `posix_spawn_file_actions_*`, `posix_spawnattr_*`) are **unavailable on tvOS**. Any file using them must wrap in `#if !os(tvOS)` with a tvOS stub. Guard `import Darwin.POSIX` the same way.

2. **Single definitions — types, styles, and extensions**  
   - Grep: `struct BrowserView`, duplicate Codable response types (`ArchiveSearchResponse`, etc.), duplicate styles (`URLFieldStyle`, `BrowserActionButtonStyle`), duplicate views (`StreamingPlayerView`).  
   - Ensure no `*Compatibility.swift` duplicates production types.
   - Grep for `static var <name>` before adding `extension UserDefaults`, `extension Notification.Name`, or similar Foundation convenience properties. There must be **exactly one** declaration per static property in the target.

3. **Retroactive conformances**  
   - Conforming imported types to imported protocols (e.g. `String: Error`) requires `@retroactive`: `extension String: @retroactive Error { }`.

4. **View ↔ model**  
   - `BookmarksView` history rows use **`BrowseHistoryEntry`** (or a single alias), with a **`url`** (or `identifier`) that `load(urlString:)` understands.  
   - `Notification.Name` used in SwiftUI **exists** in the module.

5. **SwiftUI availability**  
   - Every `} else {` tied to OS version has a matching **`if #available`**.  
   - `ForEach` + wrapped `if/else` has correct closing braces (see project `LESSONS_LEARNED.md`).

6. **Lists / streams / assets**  
   - **`LiveStreamView`** (and similar): no **`Color(.systemGray*`**; no **`swipeActions`** on tvOS; **`EditMode`/`onMove`/`onDelete`** for custom rows; persisted **`UUID`** for **`Identifiable`**.  
   - **`Assets.xcassets`** (icons): [tvos-asset-brand-catalog/SKILL.md](../tvos-asset-brand-catalog/SKILL.md).

7. **Documentation**  
   - If navigation, remote commands, or user-visible browser/file-manager flows change, follow [tv-safari-documentation-sync/SKILL.md](../tv-safari-documentation-sync/SKILL.md) and update **`docs/TV_SAFARI_USER_GUIDE.md`** + wiki mirror.

8. **Git commits**  
   - Before any commit from this workspace, follow [git-commit-identity/SKILL.md](../git-commit-identity/SKILL.md); do not use placeholder **Chris** / **chris@** identity (see **`LESSONS_LEARNED.md` §29**).

9. **Build**  
   - Run `xcodebuild` for the **TV Safari** scheme (tvOS) when possible; distinguish **new** Swift errors from **bridging header / signing / actool / SwiftPM** issues.  
   - If **`project.pbxproj`** signing or **`DEVELOPMENT_TEAM`** changes: [tv-safari-xcode-signing/SKILL.md](../tv-safari-xcode-signing/SKILL.md).  
   - If **Swift packages** or *Missing package product* errors: [tv-safari-swiftpm-packages/SKILL.md](../tv-safari-swiftpm-packages/SKILL.md).

## Output expectation

After edits, briefly state whether **WebKit was avoided**, **POSIX APIs are guarded**, **duplicates are absent**, **extensions are unique**, and **load/history/notifications** remain consistent.

## Reference

- Project narrative: [LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) (repo root).
- tvOS **xcodebuild** / SwiftUI availability / Run Script pitfalls: [tvos-build-guardrails/SKILL.md](../tvos-build-guardrails/SKILL.md) and [.cursor/rules/tvos-build-guardrails.mdc](../../rules/tvos-build-guardrails.mdc).  
- **Signing / team IDs in pbxproj:** [tv-safari-xcode-signing/SKILL.md](../tv-safari-xcode-signing/SKILL.md), [.cursor/rules/xcode-signing-team.mdc](../../rules/xcode-signing-team.mdc).  
- **Brand asset catalog / App Icon stacks:** [tvos-asset-brand-catalog/SKILL.md](../tvos-asset-brand-catalog/SKILL.md), [.cursor/rules/tvos-asset-brand-catalog.mdc](../../rules/tvos-asset-brand-catalog.mdc).  
- **SwiftPM / vendored `Zip`:** [tv-safari-swiftpm-packages/SKILL.md](../tv-safari-swiftpm-packages/SKILL.md), [.cursor/rules/swiftpm-local-vendored-packages.mdc](../../rules/swiftpm-local-vendored-packages.mdc).  
- **User docs + wiki:** [tv-safari-documentation-sync/SKILL.md](../tv-safari-documentation-sync/SKILL.md), [.cursor/rules/tv-safari-documentation-sync.mdc](../../rules/tv-safari-documentation-sync.mdc).  
- **Git author:** [git-commit-identity/SKILL.md](../git-commit-identity/SKILL.md), [.cursor/rules/git-commit-identity.mdc](../../rules/git-commit-identity.mdc).  
- **tvOS HIG / browser chrome:** [tvos-safari-design-language/SKILL.md](../tvos-safari-design-language/SKILL.md), [.cursor/rules/tvos-safari-design-language.mdc](../../rules/tvos-safari-design-language.mdc).
