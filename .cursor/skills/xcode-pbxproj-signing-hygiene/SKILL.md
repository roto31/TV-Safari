---
name: xcode-pbxproj-signing-hygiene
description: Catches project-level pbxproj signing overrides that break device install (empty CODE_SIGN_ENTITLEMENTS, DSTROOT, OTHER_CODE_SIGN_FLAGS, PROVISIONING_PROFILE_SPECIFIER), stale DerivedData symlinks from DEPLOYMENT_LOCATION changes. Use when editing project.pbxproj signing settings, debugging "valid provisioning profile not found", CoreDeviceError 1005, MIInstallerErrorDomain 13, or "unable to create directory .app".
---

# Xcode pbxproj signing hygiene

## When to use

- Editing **`*.xcodeproj/project.pbxproj`** signing or deployment settings.
- Errors: *A valid provisioning profile for this executable was not found* (0xe8008015), *MIInstallerErrorDomain 13*, *CoreDeviceError 1005*, *unable to create directory …/YourApp.app*.

## Pre-flight

1. **Project-level overrides** — grep the **PBXProject** build configurations (not target configs) for:
   - `CODE_SIGN_ENTITLEMENTS`, `CODE_SIGN_IDENTITY`, `OTHER_CODE_SIGN_FLAGS`, `PROVISIONING_PROFILE_SPECIFIER`, `DSTROOT`
   - If any are set to **`""`** (empty string), **remove** them — they override target automatic signing.
2. **`DEPLOYMENT_LOCATION`** — must be **absent** or **`NO`** on app targets for normal IDE device runs. Only use `YES` with a real non-empty `DSTROOT` for rooted install layouts.
3. **Stale symlinks** — after changing `DEPLOYMENT_LOCATION` from `YES` to `NO`:
   - Check `build/DerivedData/.../Debug-appletvos/TV Safari.app` — if it's a symlink, delete it.
   - Remove any stale `Applications/` folder at repo root.
   - Or: **Product → Clean Build Folder** (Shift+Cmd+K).

## Verify

```bash
rg 'CODE_SIGN_ENTITLEMENTS|OTHER_CODE_SIGN_FLAGS|PROVISIONING_PROFILE_SPECIFIER|DSTROOT|DEPLOYMENT_LOCATION' --glob '*.pbxproj'
ls -la build/DerivedData/Build/Products/Debug-appletvos/*.app 2>/dev/null | grep -l '\->'
xcodebuild -project "TV Safari.xcodeproj" -scheme "TV Safari" -configuration Debug \
  -destination 'generic/platform=tvOS' -derivedDataPath "./build/DerivedData" \
  CODE_SIGNING_ALLOWED=NO build
```

## Output

Report **project-level** signing keys found (should be none), **symlink status**, and **xcodebuild** result.

## Reference

- [.cursor/rules/xcode-pbxproj-signing-hygiene.mdc](../../rules/xcode-pbxproj-signing-hygiene.mdc)
- [LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) §24–26
- [tv-safari-xcode-signing/SKILL.md](../tv-safari-xcode-signing/SKILL.md)
