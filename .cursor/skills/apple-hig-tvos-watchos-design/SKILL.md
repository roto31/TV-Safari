---
name: apple-hig-tvos-watchos-design
description: Apply Apple Human Interface Guidelines for tvOS and watchOS using project rules and the design reference doc. Use for UI/UX review, new screens, assets, accessibility, focus, Siri Remote, Top Shelf, app icons, or when extending TV Safari / Spartan.
---

# Apple HIG — tvOS & watchOS (project skill)

## When to use

- Any **new or revised UI** in **`TVSafari/`** or **`Spartan/`** on **tvOS**.
- **Asset work** (app icon layers, Top Shelf, colors, typography).
- **Accessibility** (VoiceOver labels, Reduce Motion, Dynamic Type).
- Planning **watchOS** features if a Watch target is added later.

## Authority stack (read in order)

1. **[.cursor/rules/apple-hig-design-governance.mdc](../../rules/apple-hig-design-governance.mdc)** — Clarity, Deference, Depth, Consistency; typography/color/icons/accessibility baselines (**alwaysApply**).
2. **[.cursor/rules/tvos-design-rules.mdc](../../rules/tvos-design-rules.mdc)** — 10-foot UI, focus engine, Siri Remote, icons, Top Shelf, tab bar, text input.
3. **[.cursor/rules/tvos-safari-design-language.mdc](../../rules/tvos-safari-design-language.mdc)** — TV Safari browser chrome: **Material**, **`BrowserLayout`**, sheet rules.
4. **[.cursor/rules/watchos-design-rules.mdc](../../rules/watchos-design-rules.mdc)** — watchOS only when relevant.
5. **[docs/design/Apple_HIG_Design_Rules_watchOS_tvOS.md](../../../docs/design/Apple_HIG_Design_Rules_watchOS_tvOS.md)** — long-form rules + sources (synced from project design kit).

## Quick checklist (tvOS / TV Safari)

- [ ] Type large enough for **10-foot** viewing; no **iOS-only** nav modifiers on tvOS paths.
- [ ] **Focus** predictable; custom controls have **labels** / **contentShape** / minimum sizes.
- [ ] **Materials** or system colors — no **`Color(.systemGray4|5|6)`** on tvOS ([tvos-build-guardrails](../../rules/tvos-build-guardrails.mdc)).
- [ ] **SF Symbols** where appropriate; **Reduce Motion** respected for heavy animation.
- [ ] **Browser** flows: extend **`BrowserLayout`**, match **`BrowserView`** patterns.
- [ ] **Launch**: storyboard + imageset, not deprecated **`.launchimage`** ([LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) §31).
- [ ] User-visible changes → [tv-safari-documentation-sync](../tv-safari-documentation-sync/SKILL.md).

## Output expectation

State which of **governance / tvos-design-rules / tv-safari-design-language** you applied and whether **docs** need updating.
