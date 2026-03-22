---
name: tvos-asset-brand-catalog
description: Validates TV Safari tvOS App Icon brandassets and image sets before actool failures — App Store 1280×768 stack completeness, primary 400×240 stack, tv idiom vs universal. Use when editing TVSafari/Assets.xcassets, fixing IBAppleTVFramework / image stack errors, or adding alternate app icons.
---

# TV Safari — tvOS brand asset catalog

## When to use

- Editing **`TVSafari/Assets.xcassets`**, especially **`App Icon & Top Shelf Image.brandassets`**.
- Build errors from **`actool`**, **image stack** size / layer fill, or **IBAppleTVFramework-***.

## Pre-flight

1. Open **`App Icon & Top Shelf Image.brandassets/Contents.json`**. If **`App Icon - App Store.imagestack`** is listed, open each layer’s **`Content.imageset/Contents.json`**: every **1280×768** slot needs **real** files and **matching scales** — not **400×240** art. If incomplete, **remove** that asset entry and folder until proper art exists ([LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) §22).
2. **`App Icon.imagestack`** (400×240): Front/Back layers should have **`filename`**, **`idiom` : `tv`**, **`scale`** **1x** / **2x** as required by Xcode.
3. Grep **`"idiom" : "universal"`** under **`TVSafari/Assets.xcassets`** for tvOS-only rasters; consider **`tv`** + **`scale`** ([LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) §23).

## Verify

```bash
xcodebuild -project "TV Safari.xcodeproj" -scheme "TV Safari" -configuration Debug \
  -destination 'generic/platform=tvOS' -derivedDataPath "./build/DerivedData" \
  CODE_SIGNING_ALLOWED=NO build
```

Capture the first **`actool`** / **assetcatalog** error if any.

## Output

State **brandassets** entries checked, **App Store** stack status (complete / removed / needs art), **universal** image sets found, and **xcodebuild** result.

## Reference

- [.cursor/rules/tvos-asset-brand-catalog.mdc](../../rules/tvos-asset-brand-catalog.mdc)
- [LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) §14–15, §21–23
