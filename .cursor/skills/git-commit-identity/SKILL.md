---
name: git-commit-identity
description: Before git commit or push, ensure user.name and user.email match the repository maintainer. Use when git says committer identity unknown, when setting up a clone, or before any automated commit to TV-Safari or its wiki.
---

# Git commit identity skill

## When to use

- Before **`git commit`**, **`git merge`** (with commit), or **`git filter-branch`** follow-up.
- When Git prints **Committer identity unknown** or **Please tell me who you are**.
- Before pushing to **[roto31/TV-Safari](https://github.com/roto31/TV-Safari)** or **`TV-Safari.wiki.git`**.

## Checklist

1. **Read current identity** (repo-local preferred):
   - `git config user.name` / `git config user.email`
   - `git config --local --list | grep user`  
   If unset, check `git log -1 --format='%an <%ae>'` on **`origin/main`** for the canonical maintainer pair.

2. **For this repository (TV Safari / roto31)**  
   If the maintainer is **roto31** and no other instruction was given, set:
   - `git config user.name "roto31"`
   - `git config user.email "47955141+roto31@users.noreply.github.com"`  
   Use **`--local`** inside the clone so it does not affect other projects.

3. **Do not**
   - Use **Chris**, **chris@…**, or another person’s GitHub handle as a default.
   - Rely on **auto-detected** hostname emails for serious repos without maintainer confirmation.

4. **After mistaken pushes**  
   See **`LESSONS_LEARNED.md` §29**: filter-branch / filter-repo, force-push, wiki parity, collaborator reset.

## Reference

- Narrative: [LESSONS_LEARNED.md](../../../LESSONS_LEARNED.md) §29.
- Rule: [.cursor/rules/git-commit-identity.mdc](../../rules/git-commit-identity.mdc).
