---
name: tvos-safari-design-language
description: Apply Apple tvOS Human Interface Guidelines to TV Safari UI. Use when designing or editing BrowserView, URLInputView, WebViewRepresentable, sheets, toolbars, empty states, materials, typography, or spacing in TVSafari.
---

# TV Safari — tvOS design language

## When to use

- Any change to **browser chrome**, **address UI**, **empty / placeholder canvas**, **error banners**, or **sheet** layouts under `TVSafari/Browser/`.
- Adding new **toolbar** or **full-screen** flows that should feel native on **Apple TV**.

## Authority

1. **Apple:** [Designing for tvOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-tvos) — distance, focus, clarity.
2. **Repo — browser-specific:** [.cursor/rules/tvos-safari-design-language.mdc](../../rules/tvos-safari-design-language.mdc) and **`BrowserView.swift`**, **`WebViewRepresentable.swift`**, **`URLInputView.swift`**.
3. **Repo — full tvOS HIG:** [.cursor/rules/tvos-design-rules.mdc](../../rules/tvos-design-rules.mdc), [.cursor/rules/apple-hig-design-governance.mdc](../../rules/apple-hig-design-governance.mdc), [apple-hig-tvos-watchos-design/SKILL.md](../apple-hig-tvos-watchos-design/SKILL.md).

## Checklist (before merging UI)

1. **Typography:** Primary strings at **TV distance** (no body-only primary titles for main chrome).
2. **Materials:** Bars and cards use **`Material`**; no **`Color(.systemGray4|5|6)`** on tvOS.
3. **Corners:** **`RoundedRectangle(…, style: .continuous)`** for rounded surfaces unless a system component dictates otherwise.
4. **Symbols:** SF Symbols; **hierarchical** rendering where it aids status (lock, warnings).
5. **Spacing & sizes:** New dimensions go into **`BrowserLayout`** (or shared layout enum), not ad hoc literals in multiple files.
6. **Clusters:** Related icon buttons grouped in one **material** container; address field visually primary and wide.
7. **Focus:** Minimum sizes in line with **`BrowserLayout`**; full hit areas with **`contentShape`** where needed.
8. **Platform API:** No **`navigationBarTitleDisplayMode`** (or other iOS-only modifiers) without **`#if !os(tvOS)`** — confirm **tvOS** compile.
9. **Docs:** If user-visible behavior or chrome layout changes, follow [tv-safari-documentation-sync/SKILL.md](../tv-safari-documentation-sync/SKILL.md).

## Anti-patterns

- iOS **compact** navigation and title display modes on tvOS.
- **Tiny** icon-only rows as the only way to complete a task.
- **Flat** medium-gray fills instead of **material** stacks.
- **Duplicating** `BrowserLayout` constants in another file.

## Reference

- [LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) §30.
- [docs/design/Apple_HIG_Design_Rules_watchOS_tvOS.md](../../../docs/design/Apple_HIG_Design_Rules_watchOS_tvOS.md) — compiled HIG reference.
- Build / availability guardrails: [tvos-build-guardrails/SKILL.md](../tvos-build-guardrails/SKILL.md).
