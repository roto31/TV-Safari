---
name: tvos-sdk-deprecation-hygiene
description: Checklist for tvOS 16–26 SDK warnings — AVFoundation load/async APIs, UIScreen.main replacements, Info.plist MinimumOSVersion vs deployment target, Obj-C nullability in PrivateKits headers, StringError instead of String: Error. Use when fixing Xcode warnings after SDK bumps, editing TVSafari or Spartan media/FileInfo/Hex/EThree/StreamingPlayer views, or touching CSIGenerator.h-style bridged headers.
---

# TV Safari — tvOS SDK deprecation hygiene

## When to use

- User or **Xcode** reports **deprecated** **`AVAsset` / `AVMetadataItem` / `loadValuesAsynchronously`** / **`UIScreen.main`** / **nullability** / **`MinimumOSVersion`** mismatches.
- Editing **`TVSafari/**/*.swift`**, **`Spartan/**/*.swift`**, **`Packages/PrivateKits-tvOS/**/*.h`**, or app **`Info.plist`** files.

## Checklist (grep + fix)

1. **`loadValuesAsynchronously`**, **`.duration`** (property, not `load`), **`tracks(withMedia`**, **`AVAsset(url:`** — replace with **`load(.duration)`**, **`loadTracks(…)`**, **`AVURLAsset(url:)`**, **`Task { @MainActor … }`** as in [tvos-sdk-deprecation-hygiene.mdc](../../rules/tvos-sdk-deprecation-hygiene.mdc).
2. **`metadata`**, **`commonMetadata`**, **`metadata.value`** — use **`try await asset.load(.metadata)`** / **`load(.commonMetadata)`** and **`try? await item.load(.value)`** per row.
3. **`UIScreen.main`** — **`GeometryReader`** for layout size; or **`UIApplication.shared.connectedScenes`** → **`UIWindowScene`** → **`screen`** for native metrics.
4. **`MinimumOSVersion`** in **`TVSafari/Info.plist`** and **`Spartan/Info.plist`** — match **`TVOS_DEPLOYMENT_TARGET`** (e.g. **26.0**).
5. **Obj-C headers** imported by Swift — every pointer on the method; **`nil` from Swift ⇒ `_Nullable`**. Verify Swift call sites after adding **`_Nonnull`**.
6. **`extension String: Error`** — replace with **`StringError`**; grep **`throw "`** in the target.
7. **`if let x = x {`** with **unused** `x` — **`if x != nil`** or **`guard`** + use the value.
8. **Spartan parity** — if the same file exists under **`Spartan/`**, mirror fixes to avoid divergent warnings.

## Verify

- Build the **same destination** you care about (**device** vs **simulator**). Simulator **ld** failures from device **`.tbd`** are separate (LESSONS_LEARNED §33).
- Grep for regressions:  
  `loadValuesAsynchronously`, `UIScreen.main`, `extension String: Error`, `AVAsset(url:`

## Reference

- [LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) §12, §32–33
- [.cursor/rules/tvos-sdk-deprecation-hygiene.mdc](../../rules/tvos-sdk-deprecation-hygiene.mdc)
- [.cursor/rules/tvos-build-guardrails.mdc](../../rules/tvos-build-guardrails.mdc)
