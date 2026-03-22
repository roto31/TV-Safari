# Lessons learned — TV Safari (Apple TV) reconciliation (Mar 2026)

## Context

Work aimed to reconcile `BrowserView`, `WebViewModel`, and `WebViewRepresentable` after an evaluation found mismatches (missing `webView`, undefined notifications, Archive-only model vs full-browser UI).

## What we learned

### 1. Verify platform SDK facts before choosing WebKit

**Issue:** Assumed `WKWebView` / Swift `import WebKit` could ship in a tvOS app like on iOS.

**Reality:** The **AppleTVOS SDK does not include `WebKit.framework`** (only frameworks such as `BrowserEngineCore` / `BrowserEngineKit`). Swift therefore cannot resolve the WebKit module for tvOS targets even if you add a framework reference in Xcode.

**Takeaway:** For tvOS, **confirm framework availability** (`ls …/AppleTVOS.sdk/…/Frameworks`) or build with `import WebKit` early. Treat “browser” on tvOS as **native UI + AVPlayer + APIs**, or as **future BrowserEngine* integration**, not as dropping in `WKWebView`.

### 2. One public symbol per type per module

**Issue:** `BrowserView` existed in both `TVSafari/Browser/BrowserView.swift` and `TVSafari/BrowserView_Compatibility.swift`, causing invalid redeclaration and hiding which UI actually ran.

**Takeaway:** **Delete or rename** migration shims once superseded; grep for `struct BrowserView` / duplicate type names before merging branches.

### 3. Duplicate type names in Swift break the whole target

**Issue:** `ArchiveSearchResponse` was declared in both `WebViewModel.swift` and `ArchiveOrgView.swift`.

**Takeaway:** **Prefix or nest** JSON envelope types per feature (`ArchiveOrgSearchEnvelope`, private structs) or share one model file.

### 4. UI models must match the view model

**Issue:** `BookmarksView` referenced `WebHistoryEntry` while `WebViewModel` exposed `[BrowseHistoryEntry]`.

**Takeaway:** After refactors, **grep for old type names** and align or add a thin alias (`typealias` / computed `var url` on the real type).

### 5. SwiftUI `#available` branches must be syntactically paired

**Issue:** `ContentView.swift` had `} else {` for a tvOS 13 path **without** a matching `if #available(tvOS 14.0, *)`, which broke parsing (`expected '}' in struct`).

**Takeaway:** When splitting **contextMenu vs fallback**, wrap the modern path in **`if #available(…)`** and ensure **one extra closing brace** for the `ForEach` body if you wrap in `if/else`.

### 6. Notifications must be defined where they are observed

**Issue:** `BrowserView` observed `.webViewStreamDetected` with no `Notification.Name` extension.

**Takeaway:** **Define** `extension Notification.Name` in the same module (or remove dead `onReceive`).

### 7. “Reconciliation” without a build is incomplete

**Issue:** Simulator/sandbox and signing can block CI locally; separate pre-existing errors (e.g. bridging header) from new Swift errors.

**Takeaway:** After architectural fixes, run **`xcodebuild`** (or at least **Swift compile**) and fix **platform** and **pch** issues explicitly.

## Positive patterns to keep

- **Lazy WebView / optional web stack** would have been the right shape on iOS; on tvOS, **optional native paths** (Archive API, `AVPlayer`, curated streams) match the platform.
- **Single `WebViewModel`** can serve both **BrowserView** and **ArchiveBrowserView** if **web-specific state** is not initialized until needed (e.g. no fake `WKWebView` on tvOS).

## 8. tvOS asset catalog: alternate app icon image stacks

**Issue:** `actool` / Xcode reported errors under `Assets.xcassets` for image stacks named Alpha, Beta, Megamind, Terabyte, Summit, Finda — e.g. *must have at least 2 layers with applicable content* while *none have applicable content*.

**Causes:** Middle `imagestacklayer` slots had **no PNGs** (only empty `images` entries). Terabyte’s “empty” front layers could be treated as non-applicable. Root-level **alternate** stacks plus `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` forced strict validation.

**Mitigation applied:** Removed those six `.imagestack` bundles, cleared alternate app icon build settings, set `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = NO`, filled the **primary** `App Icon.imagestack` middle layer from the back layer, and simplified Settings UI that called `setAlternateIconName` for those assets.

**Note:** Headless or CI `xcodebuild` can still fail with *Failed to find device type* for Apple TV assets if no suitable **tvOS Simulator** runtime is available; that is separate from catalog JSON validation.

### 9. Duplicate `extension UserDefaults` causes "Ambiguous use of 'settings'"

**Issue:** `WebViewModel.swift` declared `extension UserDefaults { static var settings: UserDefaults { .standard } }` while `TVSafariApp.swift` already declared the same property returning a named suite (`com.tvsafari.TVSafari.settings`). Every file calling `UserDefaults.settings` then failed with "Ambiguous use of 'settings'."

**Takeaway:** Extensions on Foundation types (especially static properties on `UserDefaults`, `Notification.Name`, `URL`) must exist in **exactly one file**. Before adding a convenience extension, grep for `static var <name>` across the target. Prefer the canonical location (e.g. the App file or a shared `Extensions/` file).

### 10. `posix_spawn` and related APIs are unavailable on tvOS

**Issue:** `External/CommandRunner.swift` called `posix_spawn`, `posix_spawn_file_actions_init`, `posix_spawnattr_init`, etc. — all marked **explicitly unavailable** in the tvOS SDK. The entire file failed to compile.

**Takeaway:** Wrap platform-specific POSIX code in **`#if !os(tvOS)`** and provide a **`#if os(tvOS)` stub** that returns a descriptive message or no-ops. Also guard `import Darwin.POSIX` behind the same conditional. Before using low-level Darwin / POSIX APIs, check availability headers or attempt a tvOS compile early.

### 11. Duplicate helper types appended to feature files

**Issue:** `ArchiveBrowserView.swift` had copies of `URLFieldStyle`, `BrowserActionButtonStyle`, and `StreamingPlayerView` at its bottom — all already defined in `URLInputView.swift` and `StreamingPlayerView.swift`. Swift reported "Invalid redeclaration" for each.

**Takeaway:** When generating or copying supporting types into a feature file, **grep the target first** (`struct TypeName`) to confirm the type doesn't already exist. Place shared styles and reusable views in their own files; don't duplicate them as "placeholders."

### 12. Retroactive protocol conformance on imported types

**Issue:** `extension String: Error { }` in `SpareViews.swift` triggered a warning: "Extension declares a conformance of imported type 'String' to imported protocol 'Error'; this will not behave correctly if the owners of 'Swift' introduce this conformance in the future."

**Takeaway:** When conforming a **stdlib / framework type** to an **imported protocol**, use **`@retroactive`**: `extension String: @retroactive Error { }`. This silences the diagnostic and documents the intent. Prefer a dedicated error type when practical.

### 13. Bridging header PCH: `posix_spawnattr_*` prototypes and `uid_t`

**Issue:** `External/Pogo-BridgingHeader.h` declared Apple-private persona helpers with unnamed parameters and without headers that define **`uid_t`** / **`uint32_t`**. The Swift driver precompiled the bridging header and failed with *type specifier missing, defaults to 'int'* on those lines.

**Takeaway:** In any header included from **`TVSafari-Bridging-Header.h`**, include **`<sys/types.h>`** and **`<stdint.h>`** (or equivalent) before prototypes, and use **named parameters** (e.g. `const posix_spawnattr_t *__restrict attr`, `uid_t uid`). See also `.cursor/rules/tvos-asset-catalog-bridging.mdc`.

### 14. `Color(.systemGray4|5|6)` is unavailable on tvOS

**Issue:** SwiftUI `Color(_ uiColor: UIColor)` with **dynamic UIKit grays** (`systemGray4`, `systemGray5`, `systemGray6`) failed to compile for the tvOS target (*unavailable in tvOS*).

**Takeaway:** For TV Safari tvOS UI, prefer **`Color(white:)`**, **`Color.gray.opacity(...)`**, **`.secondary`**, or SwiftUI **`Material`** (e.g. **`.fill(.ultraThinMaterial)`** on a **`Rectangle`**) for layered / sidebar backgrounds — consistent with Apple’s **Liquid Glass** guidance to use system **materials** ([`Material`](https://developer.apple.com/documentation/swiftui/material), [Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/liquid-glass)). Grep for **`Color(.systemGray`** after porting iOS patterns.

### 15. `swipeActions` is unavailable on tvOS

**Issue:** `LiveStreamView` and `BookmarksView` used `.swipeActions { … }`; the tvOS SDK marks that modifier unavailable.

**Takeaway:** Wrap swipe-only UI in **`#if !os(tvOS)`**. On tvOS, use **`contextMenu`**, **`List`** editing with **`EditMode`** + **`onMove`/`onDelete`** on **`ForEach`** for **reorder and delete** (e.g. **“Edit Order”** / **“Done”** toggling **`$editMode`**). Do **not** use **`onDeleteCommand`** for this — it is **unavailable on tvOS** in current SDKs (tvOS compile fails). On iOS, **`EditButton()`** can drive the same **`editMode`**. Verify with a tvOS **`xcodebuild`**.

### 16. Private stored properties make a struct’s memberwise `init` private

**Issue:** `BookmarksView` had `private var bookmarkManager = …` and no explicit initializer. Swift synthesized an initializer that was **`private`**, so `BrowserView` could not call `BookmarksView(viewModel:)`.

**Takeaway:** For views used from other types, add an **explicit `init(…)`** (at least `internal`) when the struct has **`private`** stored properties, or remove `private` from properties that don’t need it.

### 17. Xcode “Run Script” phases: `python2` and missing `.xcent`

**Issue:** A build phase used **`shellPath = /usr/local/bin/python2`**, which is absent on modern macOS (*bad interpreter*). After switching to Python 3, the entitlements patch script still crashed with **`FileNotFoundError`** for **`…/TV Safari.app.xcent`** when **`CODE_SIGNING_ALLOWED=NO`** (no code-signing → no generated `.xcent` at that path).

**Takeaway:** Use **`/usr/bin/python3`** (or `/usr/bin/env python3`) for Python build scripts. If a script mutates signing artifacts, **guard with `os.path.isfile`** (or equivalent) and **`sys.exit(0)`** when the file is missing so unsigned / analysis builds still succeed.

### 18. CI / local verification command

**Issue:** Regressions piled up until a full **`xcodebuild`** run.

**Takeaway:** For this repo, periodically run:

`xcodebuild -project "TV Safari.xcodeproj" -scheme "TV Safari" -configuration Debug -destination 'generic/platform=tvOS' -derivedDataPath "./build/DerivedData" CODE_SIGNING_ALLOWED=NO build`

Treat **Swift errors** (availability, duplicates) separately from **script / signing** failures.

### 19. Hardcoded `DEVELOPMENT_TEAM` breaks other developers’ Xcode

**Issue:** `project.pbxproj` pinned **`DEVELOPMENT_TEAM = PM529U3B66`** (and previously other IDs) on targets. Xcode reported *No Account for Team "PM529U3B66"* and refused to sign because only the keychain/account owner of that team can satisfy it.

**Takeaway:** Do **not** commit **personal or org-specific** `DEVELOPMENT_TEAM` values for a shared repo unless every contributor is on that team. Prefer **empty team** on the main app target so each developer selects **Signing & Capabilities → Team** locally, or document a single shared team in README and accept that constraint.

### 20. Auxiliary targets (e.g. `RootHelper`) and wrong certificate flavor

**Issue:** The **`RootHelper`** target required signing against a team the machine did not have, which surfaced as *No "iOS Development" signing certificate* (or similar) tied to that team ID—even though the product is **tvOS**.

**Takeaway:** For **dylibs / helpers** not shipped as standalone signed products, set **`CODE_SIGNING_ALLOWED = NO`**, **`CODE_SIGNING_REQUIRED = NO`**, and **`CODE_SIGN_IDENTITY = ""`** on that target so the project still **builds without** that team’s certificates. Re-enable signing only when you intentionally distribute a signed helper. See `.cursor/rules/xcode-signing-team.mdc`.

### 21. Persisted `List` rows need a stable `Identifiable.id`

**Issue:** A model used **`let id = UUID()`** (new UUID every instantiation). Custom streams loaded from **`UserDefaults`** got **new IDs each launch**, so **`ForEach`** identity, reorder, and delete logic were wrong.

**Takeaway:** Store **`UUID`** in **`Codable`** persistence (e.g. **`StoredStream.id`**). Decode with **`decodeIfPresent`** and assign a new UUID only when migrating old data without **`id`**.

### 22. tvOS brand assets: **App Store** icon stack is **1280×768**, not **400×240**

**Issue:** **`App Icon - App Store.imagestack`** in **`App Icon & Top Shelf Image.brandassets`** targets **1280×768**. Reusing **400×240** layers (or empty **`Contents.json`** slots) made **`actool`** error: the back layer must **fill** the stack frame — and builds surfaced **IBAppleTVFramework-*** / device-type style failures.

**Takeaway:** Either add **correct-resolution** layered PNGs for the **App Store** role or **remove** that stack from **`Contents.json`** until art exists. Never point the **1280×768** slot at **400×240** files. See `.cursor/rules/tvos-asset-brand-catalog.mdc`.

### 23. Prefer **`tv`** idiom (and **`scale`**) for tvOS-only raster image sets

**Issue:** Some image sets used **`"idiom" : "universal"`** in a **tvOS-only** target, which can add ambiguity when the asset compiler maps slots for **Apple TV** toolchains.

**Takeaway:** For images used only on tvOS, set **`"idiom" : "tv"`** and an explicit **`scale`** where appropriate (e.g. **`1x`**). See [tvos-asset-brand-catalog skill](.cursor/skills/tvos-asset-brand-catalog/SKILL.md).

### 24. `DEPLOYMENT_LOCATION = YES` + empty `DSTROOT` breaks Run on device

**Issue:** After a **successful build**, **Install on Apple TV** failed with **CoreDeviceError 1005** (*sandbox* / *bookmark data*) and **`NSURL` = `file:///Applications/TV%20Safari.app`** — *file doesn’t exist*. The app target had **`DEPLOYMENT_LOCATION = YES`** and **`DSTROOT = ""`**, so Xcode treated the product as living under the default **`INSTALL_PATH`** (**`/Applications`** on the Mac). CoreDevice could not access that path for install.

**Takeaway:** For normal **Run** to a physical **Apple TV**, use **`DEPLOYMENT_LOCATION = NO`** (default) so the **`.app`** is under **`BUILT_PRODUCTS_DIR`** (e.g. **DerivedData**). Only use **`DEPLOYMENT_LOCATION = YES`** with a **non-empty `DSTROOT`** when intentionally packaging for a **rooted install layout** (e.g. `make install` style), not for IDE device deploy.

### 25. Project-level empty-string signing overrides break device install

**Issue:** After fixing the `DEPLOYMENT_LOCATION` path (§24), the app still failed to install on Apple TV with **MIInstallerErrorDomain 13** / **0xe8008015** (*A valid provisioning profile for this executable was not found*). The **project-level** (`PBXProject`) build settings had **`CODE_SIGN_ENTITLEMENTS = ""`**, **`CODE_SIGN_IDENTITY = "Apple Development"`**, **`OTHER_CODE_SIGN_FLAGS = ""`**, **`DSTROOT = ""`**, and **`PROVISIONING_PROFILE_SPECIFIER = ""`**. These empty strings at the **project** level **overrode** the target's **`CODE_SIGN_STYLE = Automatic`** behavior — Xcode signed the binary but could not embed a valid provisioning profile because the entitlements file path was explicitly blanked.

**Takeaway:** Do **not** set signing-related keys (`CODE_SIGN_ENTITLEMENTS`, `CODE_SIGN_IDENTITY`, `OTHER_CODE_SIGN_FLAGS`, `PROVISIONING_PROFILE_SPECIFIER`) at the **project** level with empty strings. These override target-level automatic signing. If the target uses `CODE_SIGN_STYLE = Automatic`, leave these keys **absent** from the project-level config and let Xcode resolve them. See `.cursor/rules/xcode-pbxproj-signing-hygiene.mdc`.

### 26. Stale DerivedData symlinks after `DEPLOYMENT_LOCATION` change

**Issue:** After changing `DEPLOYMENT_LOCATION` from `YES` to `NO`, the build failed with *unable to create directory `.../TV Safari.app`*. The old setting had left a **symlink** (`TV Safari.app → ../../../../../Applications/TV Safari.app`) in `build/DerivedData/.../Debug-appletvos/`. `mkdir -p` cannot create a directory over an existing symlink.

**Takeaway:** After changing **`DEPLOYMENT_LOCATION`** or **`DSTROOT`**, always **Clean Build Folder** (Shift+Cmd+K) or manually delete `build/DerivedData` to remove stale symlinks. When fixing this setting in code, also remove any stale `Applications/` folder at the repo root that was created by the old rooted install layout.

### 27. SwiftPM: *Missing package product `Zip`* (remote resolution)

**Issue:** Xcode reported **Missing package product `Zip`** for **TV Safari**. The project used **`XCRemoteSwiftPackageReference`** to **`https://github.com/marmelroy/Zip`**. When Swift Package Manager could not resolve or cache that remote dependency (offline machine, flaky network, clean CI without prior checkout, or corrupted **`Package.resolved`**), the workspace failed before compile.

**Takeaway:** For dependencies the app **must** have to build, **vendor** the package under **`Packages/`** (e.g. **`Packages/Zip`**) and reference it with **`XCLocalSwiftPackageReference`** + **`relativePath`**, same pattern as **`Packages/PrivateKits-tvOS`**. Commit the vendored tree. Remove or refresh stale **remote-only** pins in **`Package.resolved`** after switching to local. See `.cursor/rules/swiftpm-local-vendored-packages.mdc`.

## Related project artifacts

- **Rules** (`.cursor/rules/`):
  - `tvos-no-webkit.mdc` — WebKit absence + POSIX spawn unavailability on tvOS.
  - `swift-single-definition.mdc` — duplicate types, extensions, retroactive conformances.
  - `tvos-asset-catalog-bridging.mdc` — asset catalog image stacks + bridging headers.
  - `tvos-build-guardrails.mdc` — SwiftUI tvOS availability, struct inits, Xcode Run Script / unsigned build pitfalls.
  - `tvos-asset-brand-catalog.mdc` — App Icon brandassets, App Store 1280×768 stack, `tv` idiom image sets.
  - `xcode-signing-team.mdc` — no hardcoded `DEVELOPMENT_TEAM`; helper-target signing policy.
  - `xcode-pbxproj-signing-hygiene.mdc` — no empty-string signing overrides at project level; stale DerivedData after deployment path changes.
  - `swiftpm-local-vendored-packages.mdc` — vendored **`Packages/Zip`**; avoid fragile remote-only SPM for required products.
  - `swiftui-availability-balance.mdc` — `#available` brace pairing.
  - `browser-viewmodel-contract.mdc` — view ↔ model consistency.
- **Skills** (`.cursor/skills/`):
  - `tv-safari-browser/SKILL.md` — full pre-flight checklist for browser & architecture edits.
  - `tvos-xcode-assets-bridging/SKILL.md` — asset catalog & PCH verification.
  - `tvos-build-guardrails/SKILL.md` — checklist before claiming a tvOS build is clean.
  - `tvos-asset-brand-catalog/SKILL.md` — brand asset catalog + `actool` icon stack checks.
  - `tv-safari-xcode-signing/SKILL.md` — team IDs, certificates, and `pbxproj` signing settings.
  - `xcode-pbxproj-signing-hygiene/SKILL.md` — project-level signing overrides and DerivedData cleanup.
  - `tv-safari-swiftpm-packages/SKILL.md` — **`Zip`** / local vs remote Swift packages and **`Package.resolved`**.
- **Assets & bridging deep dive:** [LESSONS_LEARNED_XCODE_ASSETS_BRIDGING.md](LESSONS_LEARNED_XCODE_ASSETS_BRIDGING.md).
