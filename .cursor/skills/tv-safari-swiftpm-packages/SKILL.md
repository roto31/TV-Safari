---
name: tv-safari-swiftpm-packages
description: Prevents SwiftPM regressions for TV Safari — Missing package product Zip, remote vs local XCLocalSwiftPackageReference, Packages/Zip vendoring, Package.resolved. Use when editing TV Safari.xcodeproj package references, adding SPM dependencies, or fixing package resolution / CI clone builds.
---

# TV Safari — SwiftPM packages

## When to use

- Xcode error: *Missing package product `Zip`* (or similar).
- Editing **`TV Safari.xcodeproj/project.pbxproj`** **`packageReferences`**, **`XCLocalSwiftPackageReference`**, **`XCRemoteSwiftPackageReference`**, or **`swiftpm/Package.resolved`**.

## Pre-flight

1. Confirm **`Packages/Zip/Package.swift`** exists and defines product **`Zip`**.
2. In **`project.pbxproj`**, **`Zip`** must use **`XCLocalSwiftPackageReference`** + **`relativePath = "Packages/Zip"`** — not **`XCRemoteSwiftPackageReference`** to **`marmelroy/Zip`** unless vendoring is intentionally reverted and documented.
3. Grep **`marmelroy/Zip`** / **`XCRemoteSwiftPackageReference "Zip"`** — should be **absent** for the TV Safari project when following §27.
4. If **`Package.resolved`** still pins remote Zip after a local switch, **reset package caches** in Xcode or align / remove stale pins.

## Verify

```bash
test -f "Packages/Zip/Package.swift" && echo "Packages/Zip OK"
xcodebuild -project "TV Safari.xcodeproj" -scheme "TV Safari" -configuration Debug \
  -destination 'generic/platform=tvOS' -derivedDataPath "./build/DerivedData" \
  CODE_SIGNING_ALLOWED=NO build
```

## Output

Report **local vs remote** Zip wiring, **`Package.resolved`** notes, and **xcodebuild** result or first SPM error.

## Reference

- [.cursor/rules/swiftpm-local-vendored-packages.mdc](../../rules/swiftpm-local-vendored-packages.mdc)
- [LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) §27
