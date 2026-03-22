---
name: tv-safari-documentation-sync
description: After changing TV Safari UX, navigation, Siri Remote handling, browser, or file manager flows, update user docs and the GitHub wiki mirror. Use when editing TVSafari SwiftUI views, onExitCommand/onPlayPauseCommand, MainMenuView, BrowserView, ContentView, or user-visible sheets.
---

# TV Safari — documentation sync skill

## When to use

- Any PR/commit that touches **user-visible** behavior under **`TVSafari/`** (especially **`MainMenuView`**, **`Browser/`**, **`ContentView`**, **`ButtonActions/`**, **`FileOpeners/`**).
- Changes to **remote commands**: **`.onExitCommand`**, **`.onPlayPauseCommand`**, focus-heavy **Buttons** / lists.
- New **fullScreenCover** / **sheet** entry points that change “how to use” or “how to go back”.

## Checklist

1. **`docs/TV_SAFARI_USER_GUIDE.md`**
   - Update prose if flows changed.
   - Update **Mermaid** diagrams if nodes/edges changed (new views, renamed types, different dismiss rules).
   - Update the **Siri Remote** table if applicable.

2. **`docs/wiki/TV-Safari.md`**
   - Mirror the guide: either paste the updated body or copy from step 1.
   - Preserve the **top callout** (link to canonical `docs/TV_SAFARI_USER_GUIDE.md` on GitHub).

3. **README** (only if needed)
   - If the doc location or wiki link policy changes, adjust the documentation line in **`README.md`**.

4. **GitHub Wiki** (maintainer)
   - Follow **`docs/wiki/WIKI_SYNC.md`**: clone **`TV-Safari.wiki.git`**, copy **`TV-Safari.md`**, commit, push.
   - Wiki URL: [TV Safari wiki page](https://github.com/roto31/TV-Safari/wiki/TV-Safari).

5. **LESSONS_LEARNED**
   - Do not repeat full lesson text each time; §28 already states the policy. Only extend §28 if the **process** changes (e.g. new doc files).

## Verification

- Grep the guide for **outdated type names** or **removed** features after refactors.
- Ensure Mermaid blocks still render on GitHub (wiki and repo preview).

## Related

- **`tv-safari-browser`** skill — architecture / WebKit / browser consistency.
- **Rule:** `.cursor/rules/tv-safari-documentation-sync.mdc`
