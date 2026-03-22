---
name: tvos-xcode-assets-bridging
description: Validates TV Safari tvOS asset catalogs (especially app icon image stacks) and Objective-C bridging headers before changes break actool or Swift PCH. Use when editing TVSafari/Assets.xcassets, *BridgingHeader.h, External/Pogo-BridgingHeader.h, TVSafari-Bridging-Header.h, Xcode ASSETCATALOG_* build settings, or Settings/alternate app icon code.
---

# tvOS Xcode assets & bridging — verification skill

## When to use

- Any edit under **`TVSafari/Assets.xcassets`** (especially **`.imagestack`**, **`.brandassets`**, app icons, Top Shelf).
- Changes to **`ASSETCATALOG_COMPILER_*`**, alternate app icon names, or **`UIApplication.setAlternateIconName`** / **`UIImage(named:)`** for icon names.
- Changes to **`TVSafari/TVSafari-Bridging-Header.h`**, **`External/Pogo-BridgingHeader.h`**, or other headers pulled into the Swift bridging PCH.

## Asset catalog checks

1. **Image stacks:** Open each `*.imagestack` → Front / Middle / Back → `Content.imageset/Contents.json`. Every scale entry that must carry pixels has a **`filename`** and the file exists beside `Contents.json`.
2. **Brand app icon (1280×768 App Store vs 400×240):** [tvos-asset-brand-catalog/SKILL.md](../tvos-asset-brand-catalog/SKILL.md).
3. **Primary vs alternate:** If the target sets **`ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`**, every named stack must be complete; otherwise remove the name or the stack.
4. **Optional CLI:** From repo root, run `xcrun actool` on `TVSafari/Assets.xcassets` with `--platform appletvos`, `--minimum-deployment-target` matching the project, `--app-icon` set to the **brand assets folder name** (e.g. `App Icon & Top Shelf Image`), and `--accent-color` if used. Fix any **`com.apple.actool.document.errors`** (ignore simulator *device type* issues only if the environment has no Apple TV runtime).

## Bridging header checks

1. Every type in a prototype is defined: e.g. **`uid_t`** → `#include <sys/types.h>`; **`uint32_t`** → `#include <stdint.h>`.
2. Function declarations use **parameter names**, not only types.
3. Run **`clang -fsyntax-only`** (tvOS simulator SDK, `-include TVSafari/TVSafari-Bridging-Header.h`, `-I./External`) as in [LESSONS_LEARNED_XCODE_ASSETS_BRIDGING.md](../../../LESSONS_LEARNED_XCODE_ASSETS_BRIDGING.md).

## Output

State whether **layers are populated**, **alternate icon settings match disk**, and **bridging header parses**; call out any actool error that is **catalog** vs **simulator / device type**.

## Reference

- [LESSONS_LEARNED_XCODE_ASSETS_BRIDGING.md](../../../LESSONS_LEARNED_XCODE_ASSETS_BRIDGING.md)
- [tvos-asset-brand-catalog/SKILL.md](../tvos-asset-brand-catalog/SKILL.md), [LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) §22–23
