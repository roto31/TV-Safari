# Lessons learned — Xcode asset catalogs & Objective-C bridging (TV Safari / tvOS)

## 1. tvOS app icon `imagestack` layers must have real images

**Symptom:** Build fails with errors pointing at `TVSafari/Assets.xcassets`, e.g.  
*The image stack "…" must have at least 2 layers with applicable content. Although it has 3 layers, none have applicable content.*

**Cause:** An `imagestack` has three `imagestacklayer` folders (Front / Middle / Back), but **`Middle.imagestacklayer/Content.imageset/Contents.json`** listed `idiom` + `scale` with **no `filename`**, so no PNGs were present. Tooling treats that as “no applicable content.” Fully transparent or placeholder “empty” layers may also be rejected for **alternate app icons**.

**Fix pattern:** Every layer that participates in the stack must reference **actual PNG files** at the correct **tv** scales (e.g. 400×240 @1x, 800×480 @2x for the 400×240 icon). For a non-visual middle layer, still supply valid images (e.g. duplicate the back layer) if the compiler requires it.

**Prevention:** After editing icons in Xcode or by hand, run **`xcrun actool`** against `Assets.xcassets` with `--platform appletvos` and `--app-icon "<Brand assets name>"` to surface errors before a full build.

---

## 2. Alternate app icon stacks + build settings

**Symptom:** Root-level `*.imagestack` bundles (e.g. Alpha, Megamind) fail validation when **`ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`** references them or **`ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES`** pulls them all into strict app-icon validation.

**Fix pattern:** Either **fully populate** every alternate stack like the primary icon, or **remove** unused/broken stacks and **clear** alternate icon names in the target’s build settings; set **`ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = NO`** if you are not shipping every icon variant.

**Code/UI:** Any `UIApplication.shared.setAlternateIconName(_:)` or `UIImage(named:)` must match **asset names that still exist** after cleanup.

---

## 3. “Failed to find device type” / `IBAppleTVFramework-seventeenAndLater`

**Symptom:** Error on `Assets.xcassets` mentioning **device type** or **IBAppleTVFramework** during `actool` or `CompileAssetCatalog`.

**Cause:** Often **environmental**: missing or mismatched **tvOS Simulator** runtimes, headless CI, or CoreSimulator not exposing a suitable Apple TV device type for the SDK’s asset slicing.

**Distinction:** This is **not** the same as invalid `Contents.json` / empty layers. Fix catalog data first; if the message persists only in CI, install/select an **Apple TV** simulator runtime or build for a **generic tvOS device** on a machine with a full Xcode install.

---

## 4. Objective-C bridging headers: prototypes must be valid C

**Symptom:** `failed to emit precompiled header` for `TVSafari-Bridging-Header.h`; errors in an included header like *type specifier missing, defaults to 'int'* at `posix_spawnattr_t*` / `__restrict`.

**Causes:**
- **Unnamed parameters** in function prototypes inside headers parsed as Objective-C for the Swift PCH can confuse Clang’s diagnostic path; use **explicit parameter names** (e.g. `attr`, `uid`, `flags`).
- Types like **`uid_t`** and **`uint32_t`** are not guaranteed visible after only `#include <spawn.h>`; include **`<sys/types.h>`** and **`<stdint.h>`** (or equivalent) **before** those declarations.

**Verification:** From the repo root:

```bash
xcrun clang -isysroot "$(xcrun --sdk appletvsimulator --show-sdk-path)" \
  -target arm64-apple-tvos17.0-simulator -c -x objective-c -fobjc-arc \
  -I./External -include TVSafari/TVSafari-Bridging-Header.h -fsyntax-only /dev/null
```

Exit code **0** means the bridging chain parses cleanly.

---

## 5. Checklist before merging UI or infrastructure changes

| Check | Action |
|--------|--------|
| Asset catalog | `actool` compile for `appletvos` with correct `--app-icon` name |
| Alternate icons | Build settings align with on-disk stacks; no orphan names in Swift |
| Bridging | `clang -fsyntax-only` on bridging header as above |
| Settings / icons | No `UIImage(named:)` or `setAlternateIconName` for removed assets |

---

## Related Cursor artifacts

- **Rule:** `.cursor/rules/tvos-asset-catalog-bridging.mdc`
- **Skill:** `.cursor/skills/tvos-xcode-assets-bridging/SKILL.md`
