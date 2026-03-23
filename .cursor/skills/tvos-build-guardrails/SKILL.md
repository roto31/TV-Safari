---
name: tvos-build-guardrails
description: Applies TV Safari tvOS xcodebuild guardrails after lessons from real failures — SwiftUI Color/systemGray, Material sidebars, swipeActions vs EditMode/onMove/onDelete, no onDeleteCommand on tvOS, stable List IDs, private struct inits, bridging PCH, CommandRunner POSIX, Python 3 scripts, missing .xcent, brandassets/actool, pbxproj signing hygiene, DEPLOYMENT_LOCATION, SwiftPM vendored Zip, AVFoundation async load APIs and UIScreen.main (tvos-sdk-deprecation-hygiene). Use when fixing build errors, before saying "build is green", or when editing TVSafari/Spartan Browser UI, Assets, External/CommandRunner.swift, *BridgingHeader.h, project.pbxproj, or Swift packages.
---

# TV Safari — tvOS build guardrails

## When to use

- User asks to **build**, **fix compile errors**, or **verify CI**.
- Editing **`TVSafari/**/*.swift`**, **`Spartan/**/*.swift`**, **`TVSafari/Assets.xcassets`**, **`Packages/**`**, **`External/CommandRunner.swift`**, **bridging headers**, or **`project.pbxproj`** Run Script / package phases.

## Pre-flight (fast grep)

1. **`Color(.systemGray`** → **Material** / safe grays (see rule).
2. **`swipeActions(`** → **`#if !os(tvOS)`**; tvOS: **`EditMode`** + **`onMove`/`onDelete`**. Grep **`onDeleteCommand`** → remove on tvOS (unavailable).
3. **Persisted `List` models** → stable **`UUID`** in **`Codable`** (§21).
4. **`posix_spawn` / `posix_spawn_file_actions` / `posix_spawnattr` / `import Darwin.POSIX`** → **`#if !os(tvOS)`** + stub ([tvos-no-webkit.mdc](../../rules/tvos-no-webkit.mdc)).
5. **Structs** with **`private var`** in other files → explicit **`init`**.
6. **`project.pbxproj`**: **`python2`** → **`python3`**; entitlements scripts → file-exists guard.
7. **`DEPLOYMENT_LOCATION`** / **`DSTROOT`** / **project-level signing overrides** — [xcode-pbxproj-signing-hygiene/SKILL.md](../xcode-pbxproj-signing-hygiene/SKILL.md) (§24–26).
8. **`DEVELOPMENT_TEAM` / `CODE_SIGNING_*`** — [xcode-signing-team.mdc](../../rules/xcode-signing-team.mdc), [tv-safari-xcode-signing/SKILL.md](../tv-safari-xcode-signing/SKILL.md).
9. **`Assets.xcassets` / brandassets** — [tvos-asset-brand-catalog/SKILL.md](../tvos-asset-brand-catalog/SKILL.md).
10. **SwiftPM / `Zip`** — [tv-safari-swiftpm-packages/SKILL.md](../tv-safari-swiftpm-packages/SKILL.md) (§27).
11. **AVFoundation / `UIScreen.main` / plist / Obj-C nullability** — [tvos-sdk-deprecation-hygiene/SKILL.md](../tvos-sdk-deprecation-hygiene/SKILL.md) (§32).

## Bridging header (PCH)

- Prototypes using **`uid_t`**, **`uint32_t`**, **`posix_spawnattr_t`**: includes + **named parameters** — [tvos-asset-catalog-bridging skill](../tvos-xcode-assets-bridging/SKILL.md), [LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) §13.

## Verify

From repo root:

```bash
xcodebuild -project "TV Safari.xcodeproj" -scheme "TV Safari" -configuration Debug \
  -destination 'generic/platform=tvOS' -derivedDataPath "./build/DerivedData" \
  CODE_SIGNING_ALLOWED=NO build
```

If the **Run Script** phase fails on a missing **`.xcent`**, the script must skip when unsigned (see §17 in lessons).

## Output

State **grep results** (systemGray, swipeActions, onDeleteCommand, posix_spawn, python2, DEVELOPMENT_TEAM, CODE_SIGN_ENTITLEMENTS, DEPLOYMENT_LOCATION, marmelroy/Zip, XCRemoteSwiftPackageReference), **assets / brand** if touched, **bridging header** risk, and **xcodebuild** outcome or the **first actionable error**.

## Reference

- [LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) §13–27, §32–33, and "Related project artifacts".
- [.cursor/rules/tvos-build-guardrails.mdc](../../rules/tvos-build-guardrails.mdc), [.cursor/rules/tvos-sdk-deprecation-hygiene.mdc](../../rules/tvos-sdk-deprecation-hygiene.mdc), [.cursor/rules/tvos-asset-brand-catalog.mdc](../../rules/tvos-asset-brand-catalog.mdc), [.cursor/rules/xcode-signing-team.mdc](../../rules/xcode-signing-team.mdc), [.cursor/rules/xcode-pbxproj-signing-hygiene.mdc](../../rules/xcode-pbxproj-signing-hygiene.mdc), [.cursor/rules/swiftpm-local-vendored-packages.mdc](../../rules/swiftpm-local-vendored-packages.mdc)
