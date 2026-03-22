# Syncing documentation to the GitHub Wiki

The wiki for [TV-Safari](https://github.com/roto31/TV-Safari/wiki) is a **separate Git repository**. The page **[TV Safari](https://github.com/roto31/TV-Safari/wiki/TV-Safari)** should stay aligned with:

- `docs/TV_SAFARI_USER_GUIDE.md` (canonical in the main repo)
- `docs/wiki/TV-Safari.md` (mirror used as the wiki page source)

## One-time setup

```bash
git clone https://github.com/roto31/TV-Safari.wiki.git
cd TV-Safari.wiki
```

Use HTTPS with a [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) or SSH if you have wiki push access.

## After editing docs in the main repo

1. Edit **`docs/TV_SAFARI_USER_GUIDE.md`** in the **TV-Safari** code repository.
2. Copy the same content into **`docs/wiki/TV-Safari.md`**, keeping the wiki **callout block** at the top (link back to the canonical file).
3. Copy **`docs/wiki/TV-Safari.md`** to the wiki clone as **`TV-Safari.md`** (GitHub wiki filename for the “TV Safari” page):

```bash
cp "/path/to/TV-Safari/docs/wiki/TV-Safari.md" "/path/to/TV-Safari.wiki/TV-Safari.md"
cd /path/to/TV-Safari.wiki
git add TV-Safari.md
git commit -m "Docs: sync TV Safari user guide and diagrams"
git push
```

## Home page

The repo holds a mirror at **`docs/wiki/Home.md`**. Copy it to **`Home.md`** in the wiki clone when you change the landing links.

GitHub Docs: [Adding or editing wiki pages](https://docs.github.com/en/communities/documenting-your-project-with-wikis/adding-or-editing-wiki-pages).
