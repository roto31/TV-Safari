---
name: tv-safari-xcode-signing
description: Prevents Xcode signing regressions in this repo — hardcoded DEVELOPMENT_TEAM, RootHelper-style helpers, iOS vs tvOS cert confusion. Use when editing any *.xcodeproj/project.pbxproj, fixing "No Account for Team", missing Development certificate errors, or before merging signing-related PRs.
---

# TV Safari — Xcode signing sanity

## When to use

- Editing **`*.xcodeproj/project.pbxproj`** signing or team settings.
- Errors: *No Account for Team*, *No "iOS Development" signing certificate*, signing failures on **CI** without Apple accounts.

## Pre-flight (grep from repo root)

1. **`DEVELOPMENT_TEAM`** — list every occurrence; ensure **no** stray third-party team IDs unless documented. Current project team ID: **`PM529U3B66`** (only keep if project explicitly standardizes on one team).
2. **`RootHelper`** (or similar dylib/helper) — if it still has **`DEVELOPMENT_TEAM`** and **`CODE_SIGNING_ALLOWED = YES`**, confirm every machine has that team; otherwise align with **unsigned helper** flags (see rule).
3. **`CODE_SIGN_IDENTITY = "iPhone Developer"`** / **`iOS Development`** on **tvOS** targets — verify SDK expectations; prefer **Automatic** or empty identity for helpers with signing off.
4. **Project-level** (`PBXProject`) configs — **no** `CODE_SIGN_ENTITLEMENTS`, `OTHER_CODE_SIGN_FLAGS`, `PROVISIONING_PROFILE_SPECIFIER`, or `DSTROOT` set to `""` — see [xcode-pbxproj-signing-hygiene/SKILL.md](../xcode-pbxproj-signing-hygiene/SKILL.md).

## Policy (must match rule)

- App target: **no** committed personal team ID unless org-wide agreement.
- Non-shipped helpers: **`CODE_SIGNING_ALLOWED = NO`**, **`CODE_SIGNING_REQUIRED = NO`**, **`CODE_SIGN_IDENTITY = ""`**, drop **`DEVELOPMENT_TEAM`**.

## Verify

```bash
rg 'DEVELOPMENT_TEAM|CODE_SIGNING_ALLOWED|CODE_SIGN_IDENTITY' --glob '*.pbxproj'
xcodebuild -project "TV Safari.xcodeproj" -scheme "TV Safari" -configuration Debug \
  -destination 'generic/platform=tvOS' -derivedDataPath "./build/DerivedData" \
  CODE_SIGNING_ALLOWED=NO build
```

If the repo also builds **Spartan.xcodeproj**, repeat **`xcodebuild`** for that scheme when touching its **`pbxproj`**.

## Output

Report **grep hits** (teams + signing flags per target), policy applied, and **xcodebuild** result or first signing error.

## Reference

- [.cursor/rules/xcode-signing-team.mdc](../../rules/xcode-signing-team.mdc)
- [LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) §18–20, §24–26
- [xcode-pbxproj-signing-hygiene/SKILL.md](../xcode-pbxproj-signing-hygiene/SKILL.md)
