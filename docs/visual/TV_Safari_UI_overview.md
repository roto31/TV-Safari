# TV Safari — visual overview

Illustrative **16×9** mockups (not pixel-perfect screenshots) of three primary experiences. For exact behavior and copy, see [`docs/TV_SAFARI_USER_GUIDE.md`](../TV_SAFARI_USER_GUIDE.md).

---

## 1. Cold launch (`LaunchScreen.storyboard`)

Full-screen still shown briefly before `MainMenuView`. Art comes from **`LaunchScreenArt`** in Assets.

![Launch / splash mockup](tv-safari-01-launch.png)

---

## 2. Main menu (`MainMenuView`)

Choose **Browser** or **File Manager**; footer explains Siri Remote navigation.

![Main menu mockup](tv-safari-02-main-menu.png)

---

## 3. Browser (`BrowserView` + `WebViewRepresentable`)

Frosted **top chrome** (navigation clusters, **address** control, actions). Main area is the **status canvas** (large SF Symbol + typography) — tvOS has no in-app HTML engine.

![Browser mockup](tv-safari-03-browser.png)

---

## Flow (Mermaid)

```mermaid
flowchart TD
    LS[LaunchScreen.storyboard] --> MM[MainMenuView]
    MM -->|Select Browser| BR[BrowserView fullScreenCover]
    MM -->|Select File Manager| CV[ContentView fullScreenCover]
    BR -->|Menu: back or exit| MM
    CV -->|Menu chain| MM
```

## Browser chrome layout (Mermaid)

```mermaid
flowchart TB
    subgraph bar[Top chrome — regularMaterial + shadow]
        L[Cluster: Back • Forward • Reload/Stop]
        A[Address: caption e.g. Encrypted + title line]
        R[Cluster: Archive • Live • Bookmark • List]
    end
    bar --> prog[Optional linear ProgressView]
    bar --> canvas[Gradient canvas + hero symbol + status copy]
```

## File Manager (conceptual)

```mermaid
flowchart LR
    subgraph FM[ContentView]
        P[Path TextField + actions]
        L[List of files/folders]
        S[Sheets: settings, players, editors, …]
    end
    P --> L
    L --> S
```

---

*Mockup images: `docs/visual/tv-safari-01-launch.png`, `tv-safari-02-main-menu.png`, `tv-safari-03-browser.png`.*
