# Apple HIG Design Rules & Skills Guide
## watchOS & tvOS Application Development

> **TV Safari repo note:** This project uses **`LaunchScreen.storyboard`** + an imageset for cold launch (not a deprecated `LaunchImage.launchimage` catalog). See **`LESSONS_LEARNED.md` §31** and **`.cursor/rules/tvos-design-rules.mdc`**. Where this guide mentions static launch PNGs for tvOS, prefer the storyboard pattern for new work.

> **Source of Truth for Design Governance**
> Compiled from Apple Human Interface Guidelines (2025), WWDC design sessions, and Apple Developer documentation. Every rule is anchored to Apple's published materials.

---

## 1. FOUNDATIONAL DESIGN PRINCIPLES

These four principles govern every Apple platform and must be applied to all watchOS and tvOS design decisions.

### 1.1 Clarity
Interfaces must be legible, precise, and unambiguous. Text must be readable at the intended viewing distance. Icons must be instantly recognizable. Visual hierarchy must communicate what is most important.
> **Source:** Apple HIG — Foundations > Design Principles
> **URL:** https://developer.apple.com/design/human-interface-guidelines/

### 1.2 Deference
The UI should recede to let content take center stage. Avoid unnecessary visual clutter. Use translucent materials and subtle UI elements that support—rather than compete with—the user's content.
> **Source:** Apple HIG — Foundations > Design Principles

### 1.3 Depth
Visual layers and realistic motion convey hierarchy and facilitate understanding. On tvOS, this manifests as the parallax focus effect. On watchOS, this appears in layered complications and navigation transitions.
> **Source:** Apple HIG — Foundations > Design Principles

### 1.4 Consistency
Use standard UI elements, familiar patterns, and system-provided components. When users encounter standard controls behaving in expected ways, they focus on your app's value rather than learning new interaction paradigms.
> **Source:** Apple HIG — Foundations > Design Principles

---

## 2. TVOS DESIGN RULES

### 2.1 The 10-Foot Experience

**RULE: Design for 10-foot viewing distance.** All UI elements, text, graphics, and controls must be sized and spaced for comfortable viewing from approximately 3 meters (10 feet) away.
> **Source:** Apple HIG — Platforms > Designing for tvOS; WWDC 2016 Session 802 "Designing for tvOS"
> **URL:** https://developer.apple.com/design/human-interface-guidelines/designing-for-tvos

**RULE: Use larger graphics and interface elements.** Everything in the user interface should be larger than its iOS equivalent. Buttons, controls, images, and icons must be scaled for distance viewing.

**RULE: Provide generous spacing between elements.** Adequate spacing makes individual items easier to see, navigate, and select. Grid layouts with consistent gutters work exceptionally well on tvOS.

**RULE: Design for a shared environment.** Apple TV is the most communal device in the Apple ecosystem. Multiple people may be viewing simultaneously. Design for group consumption, not private use.

### 2.2 Focus-Based Navigation

**RULE: tvOS uses a focus model, not direct touch.** Users navigate by moving focus between elements using the Siri Remote's touch surface. There is no cursor and no tap-to-target.
> **Source:** Apple HIG — Inputs > Focus and selection (tvOS)
> **URL:** https://developer.apple.com/design/human-interface-guidelines/focus-and-selection

**RULE: Make the focused element immediately obvious.** The user must always know at a glance which element is currently in focus. Use scaling, elevation, shadows, and parallax to indicate focus.

**RULE: Focused items must elevate and scale.** The standard focus behavior raises the item, increases its size, and adds a shadow. Higher layers overlap lower layers to produce a 3D effect.

**RULE: Ensure predictable focus movement.** Focus should move logically in the direction the user swipes. Avoid layouts where focus movement is ambiguous or skips elements unexpectedly.

**RULE: Never break the focus engine.** Use system-provided focus behaviors. Custom focus behaviors that contradict user expectations cause confusion and navigation failures.

### 2.3 Siri Remote Input

**RULE: Distinguish between swipe, tap, and click.**
- **Swipe:** Moves focus directionally (up, down, left, right). Movement starts fast and decelerates.
- **Tap:** Navigates through collections one-by-one. Tapping different regions navigates directionally.
- **Click:** Activates a control or selects an item. Click-and-hold for context-specific actions (e.g., edit mode).
> **Source:** Apple HIG — Inputs > Remotes; GitHub BasThomas/tvOS-guidelines (derived from Apple HIG)

**RULE: Avoid unintentional activations.** Users rest their thumb on the touch surface, pick it up, move it around, and hand the remote to others. Design interactions that tolerate incidental touch.

**RULE: The MENU button always navigates back.** At the top level of an app, MENU returns to the tvOS home screen. Never override this behavior.

**RULE: The HOME button always goes home.** Never intercept the HOME button.

**RULE: Play/Pause should immediately start media playback** or skip cutscenes/tutorials where applicable.

### 2.4 Typography (tvOS)

**RULE: Use San Francisco (SF Pro) as the system font.** SF Pro is the system font for tvOS. The system automatically selects SF Text (≤39pt) or SF Display (≥40pt) variants based on point size.
> **Source:** Apple HIG — Foundations > Typography; Apple Developer Fonts page
> **URL:** https://developer.apple.com/design/human-interface-guidelines/typography; https://developer.apple.com/fonts/

**RULE: Text must be legible from 10 feet.** Use large point sizes and heavier font weights. Do not be afraid to go big and bold. Minimum recommended body text size is approximately 29pt. Never go below 18pt for any visible text.

**RULE: Custom fonts must remain legible at distance.** If using a custom font, choose heavier weights. The #1 reason third-party tvOS apps look bad is poor custom font choices.

**RULE: Minimize on-screen text.** People don't want to read paragraphs on television. Use short labels, concise descriptions, and visual communication wherever possible.

### 2.5 Layout & Grid (tvOS)

**RULE: Use grid-based layouts.** Organize content in rows and columns. Grid layouts with horizontal scrolling work exceptionally well on tvOS.
> **Source:** WWDC 2016 Session 802 "Designing for tvOS"; Apple HIG — Platforms > Designing for tvOS

**RULE: Screen resolution is 1920×1080 at 1x.** The tvOS coordinate system is 1920×1080 points.

**RULE: Respect safe areas.** Content must stay within the safe area to avoid being clipped by TV bezels. The system defines safe areas; always respect them.

**RULE: Show 10–20% of off-screen content.** When rows or columns extend beyond the screen edge, align content to reveal a partial peek of the next item. This signals to users that more content is available.

**RULE: Use consistent spacing.** Apple recommends 40pt horizontal spacing in multi-column layouts. Maintain uniform gutters throughout.

### 2.6 App Icons (tvOS)

**RULE: App icons MUST be layered images.** tvOS app icons use 2–5 layers to create depth via the parallax effect. This is mandatory, not optional.
> **Source:** Apple HIG — Foundations > App icons (tvOS); Xamarin tvOS documentation
> **URL:** https://developer.apple.com/design/human-interface-guidelines/app-icons

**RULE: The background layer MUST be fully opaque.** No transparency is permitted on the bottom layer.

**RULE: Provide a single centered focus point.** Design the icon with one focal element placed directly in the center.

**RULE: Do NOT include text on the icon.** The system renders the app name below the icon automatically.

**RULE: Fill the entire canvas.** The icon should use the full available space. No floating elements on dark backgrounds.

**RULE: Maintain safe zones for parallax cropping.** Keep primary content within approximately 5% inset from edges, as layers scale and shift during the parallax effect.

**RULE: Required icon sizes:**
- Home Screen: 400×240 @1x / 800×480 @2x (layered)
- App Store: 1280×768 @1x (layered)
> **Source:** Apple HIG — Foundations > App icons; GitHub SRGSSR/layered-image-generation-apple

### 2.7 Top Shelf

**RULE: At minimum, provide one static Top Shelf image.** This is required for App Store submission.
> **Source:** Apple HIG — Technologies > Top Shelf
> **URL:** https://developer.apple.com/design/human-interface-guidelines/top-shelf

**RULE: Required Top Shelf sizes:**
- Standard: 1920×720
- Wide (required since tvOS 10): 2320×720

**RULE: Consider implementing dynamic Top Shelf content.** Dynamic content showcasing recent, personalized, or featured items is strongly recommended over static images.

**RULE: Never show advertisements on the Top Shelf.** Showing purchasable content is acceptable, but never display prices.

**RULE: Deep-link Top Shelf items into the application.** Each item should launch the user directly to relevant content.

### 2.8 Parallax & Visual Effects

**RULE: Parallax is mandatory for app icons** and strongly recommended for all focusable image-based content.
> **Source:** Apple HIG — Foundations > App icons (tvOS); GitHub BasThomas/tvOS-guidelines

**RULE: Foreground layers contain prominent elements** (characters, text, logos). Background layers are opaque backdrops. Middle layers contain secondary content and shadow effects.

**RULE: Text belongs on the front layer** so it is not obscured during the parallax tilt effect.

### 2.9 Tab Bar (tvOS)

**RULE: The Tab Bar is the primary top-level navigation.** It sits at the top of the screen and appears fully only when in focus.
> **Source:** Apple HIG — Components > Tab bars (tvOS)

**RULE: All tabs must fit on screen at once.** Do not create scrolling tab bars.

**RULE: Do not use the tab bar as a junk drawer.** Each tab should provide clear value and direct navigation.

**RULE: Place app settings in System Settings**, not in the tab bar. Users configure settings once and rarely return.

### 2.10 Text Input (tvOS)

**RULE: Minimize text entry.** Text input on tvOS is cumbersome. Use system keyboards, recent searches, and pre-populated suggestions.
> **Source:** Apple HIG — Components > Text fields (tvOS); GitHub BasThomas/tvOS-guidelines

**RULE: Always provide a placeholder** in text fields.

**RULE: Provide recent searches** before the user starts typing.

**RULE: Use appropriate keyboard types** (email, URL, numeric, etc.).

### 2.11 Color & Theming (tvOS)

**RULE: Support both light and dark appearances.** tvOS supports system-wide appearance switching based on room lighting conditions.
> **Source:** Apple HIG — Foundations > Color; Apple tvOS Get Started page
> **URL:** https://developer.apple.com/tvos/get-started/

**RULE: Use high-contrast visuals.** Content must be clearly visible at distance. Ensure sufficient contrast between text and backgrounds.

**RULE: Use system colors where possible.** System colors automatically adapt to light/dark mode, accessibility settings, and platform conventions.

### 2.12 Animation & Motion (tvOS)

**RULE: Use subtle, purposeful animations.** Animation should enhance comprehension and provide feedback, never slow users down or distract from content.
> **Source:** Apple HIG — Foundations > Motion

**RULE: Respect the Reduce Motion accessibility setting.** Replace sliding transitions with crossfades, minimize parallax effects, and avoid autoplay animations when this setting is active.

---

## 3. WATCHOS DESIGN RULES

### 3.1 Glanceable Interfaces

**RULE: Design for brief, glanceable interactions.** Apple Watch interactions should take seconds, not minutes. Present the most critical information immediately.
> **Source:** Apple HIG — Platforms > Designing for watchOS
> **URL:** https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos

**RULE: Minimize text.** Use icon-based communication, short labels, and visual indicators wherever possible. People raise their wrist for quick information, not to read paragraphs.

**RULE: Prioritize at-a-glance data.** The most important information must be visible without scrolling or interaction.

### 3.2 Display & Layout (watchOS)

**RULE: Design for the compact rectangular display.** watchOS screen sizes vary by model:
- 40mm: 324×394 pixels @2x
- 41mm: 352×430 pixels @2x
- 44mm: 368×448 pixels @2x
- 45mm: 396×484 pixels @2x
- 49mm (Ultra): 410×502 pixels @2x
> **Source:** Apple HIG — Platforms > Designing for watchOS; Apple Design Resources

**RULE: Always use dark backgrounds.** watchOS uses a black background by default. Design all content against dark backgrounds to blend with the watch bezel and conserve OLED power.

**RULE: Minimize padding to maximize content.** Screen real estate is extremely limited. Use minimal padding while maintaining touch target sizes.

**RULE: Use full-width layouts.** Extend content to the edges of the screen. Avoid excessive margins that waste precious display area.

### 3.3 Typography (watchOS)

**RULE: Use SF Compact as the system font.** SF Compact is specifically designed for watchOS. Its flat-sided letterforms provide better legibility at small sizes and in narrow columns.
> **Source:** Apple HIG — Foundations > Typography; Apple Developer Fonts page
> **URL:** https://developer.apple.com/fonts/

**RULE: SF Compact has flat sides on round letters** (o, e, s), unlike SF Pro. This allows more inter-character space, improving readability on the small watch display.

**RULE: Use bright, high-contrast colors for text.** Against the dark background, text must use bright, saturated colors for readability.

**RULE: Support Dynamic Type.** Allow users to adjust text sizes for accessibility. Use system text styles that scale appropriately.

### 3.4 Navigation (watchOS)

**RULE: Only two navigation models are available:** Hierarchical and Page-based. Choose one; do not mix them within the same app level.
> **Source:** Apple HIG — Patterns > Navigation (watchOS)

**RULE: Hierarchical navigation** uses a stack model (push/pop) similar to iOS NavigationStack. Use for drill-down content structures.

**RULE: Page-based navigation** uses horizontal swiping between peer screens. Use for flat content structures where screens are equally weighted.

**RULE: No back buttons.** The system provides back navigation via the left edge swipe or the Digital Crown. Never add custom back buttons.

### 3.5 Digital Crown

**RULE: Use the Digital Crown for scrolling** without obstructing the display. The crown is especially valuable for scrolling through longer content.
> **Source:** Apple HIG — Inputs > Digital Crown
> **URL:** https://developer.apple.com/design/human-interface-guidelines/digital-crown

**RULE: Use the Digital Crown for precise value selection.** It excels at incrementing/decrementing values, adjusting volume, and picking from ranges.

**RULE: Provide haptic feedback through the crown** to indicate detents, boundaries, and selection changes.

### 3.6 Gestures (watchOS)

**RULE: Supported gestures are tap and swipe.** Multi-touch gestures like pinch-to-zoom are NOT available on Apple Watch.
> **Source:** Apple HIG — Inputs > Gestures (watchOS)

**RULE: Distinguish between tap and press.** The watch display detects pressure differences. Use long press for context menus (replaces Force Touch on newer models).

**RULE: Swipe left on notifications to dismiss or take action.** Follow system notification patterns.

### 3.7 Complications

**RULE: Complications provide at-a-glance data on the watch face.** They are the most visible surface of your app and the primary reason users engage.
> **Source:** Apple HIG — Components > Complications
> **URL:** https://developer.apple.com/design/human-interface-guidelines/complications

**RULE: Keep complications simple and data-focused.** Display one or two key pieces of information. Never overload a complication with detail.

**RULE: Update complications with relevant, timely data.** Stale data erodes trust. Use timeline entries to keep complications current.

**RULE: Tapping a complication launches your app.** Ensure the transition is seamless and contextual.

### 3.8 Always On Display

**RULE: Support Always On display.** When the user lowers their wrist, the display dims but remains visible. Your app must provide a reduced-luminance, simplified version of its interface.
> **Source:** Apple HIG — Technologies > Always On (watchOS)

**RULE: Remove sensitive information in Always On state.** Health data, messages, and personal information should be obscured or hidden.

**RULE: Dim the interface, don't blank it.** The dimmed state should still show useful information at a glance.

### 3.9 App Icons (watchOS)

**RULE: watchOS app icons are circular.** The system applies a circular mask automatically. Design within the circle.
> **Source:** Apple HIG — Foundations > App icons (watchOS)

**RULE: Provide a single 1024×1024 icon.** The system generates all required sizes from this master icon.

**RULE: No transparency.** Icons must be fully opaque with no alpha channel.

**RULE: No text on icons.** The app name appears below the icon on the home screen.

### 3.10 Color (watchOS)

**RULE: Use bright, saturated colors against the dark background.** The OLED display and dark UI demand vivid, high-contrast color choices.
> **Source:** Apple HIG — Foundations > Color (watchOS)

**RULE: Define a "key color" for your app.** This appears in the status bar title string and in notification headers. It should represent your brand.

**RULE: Use color for branding and functional communication**, not decoration. Color should convey meaning (status, categories, actions).

### 3.11 Animation (watchOS)

**RULE: Animations must be fast and purposeful.** On a wrist-worn device, slow animations prevent users from getting information quickly.
> **Source:** Apple HIG — Foundations > Motion (watchOS)

**RULE: Use frame-based animations.** Provide separate static images for each frame of animation. watchOS renders canned animations from image sequences for smoothness and performance.

**RULE: Never let animation delay information delivery.** If an animation is slowing down information access, remove it.

### 3.12 Haptics (watchOS)

**RULE: Use haptic feedback to reinforce interactions.** The Taptic Engine provides tactile confirmation for actions, navigation boundaries, and data changes.
> **Source:** Apple HIG — Inputs > Haptics (watchOS)

**RULE: Use system-defined haptic patterns.** Apple provides predefined patterns (notification, success, failure, start, stop, click) that users already recognize.

**RULE: Don't overuse haptics.** Excessive vibration becomes noise. Reserve haptics for meaningful moments.

---

## 4. ACCESSIBILITY REQUIREMENTS

These requirements apply to BOTH watchOS and tvOS.

### 4.1 VoiceOver

**RULE: Support VoiceOver on all platforms.** Every interactive element must have an accessibility label. Every image conveying information must have a description.
> **Source:** Apple HIG — Foundations > Accessibility
> **URL:** https://developer.apple.com/design/human-interface-guidelines/accessibility

**RULE: Use system-provided components.** UIKit/SwiftUI components include VoiceOver support automatically. Custom controls require manual accessibility implementation.

### 4.2 Dynamic Type

**RULE: Support Dynamic Type** so users can adjust text sizes. Use system text styles that scale proportionally to user preferences.
> **Source:** Apple HIG — Foundations > Accessibility > Dynamic Type

**RULE: Custom fonts must integrate Dynamic Type** using UIFontMetrics for scalability.

### 4.3 Color & Contrast

**RULE: Never rely solely on color to convey information.** Approximately 8% of men have color vision deficiency. Always provide alternative indicators (icons, patterns, labels).
> **Source:** Apple HIG — Foundations > Accessibility

**RULE: Minimum contrast ratios (per WCAG):**
- Normal text: 4.5:1
- Large text (18pt+ regular or 14pt+ bold): 3:1
> **Source:** Apple HIG — Foundations > Accessibility; WCAG 2.2

### 4.4 Reduce Motion

**RULE: Respect the Reduce Motion setting.** When enabled: minimize parallax effects (critical for tvOS), replace sliding transitions with crossfades, and stop autoplay animations.
> **Source:** Apple HIG — Foundations > Accessibility > Motion

### 4.5 Focus & Navigation

**RULE: Ensure focus-based navigation is simple and intuitive** (tvOS). All interactive elements must be reachable via focus navigation.
> **Source:** Apple HIG — Inputs > Focus and selection

**RULE: Support Switch Control and AssistiveTouch** on watchOS for users with motor impairments.

---

## 5. CROSS-PLATFORM CONSISTENCY RULES

### 5.1 Shared Design Language

**RULE: Maintain visual consistency across platforms.** Use the same brand colors, iconography style, and information architecture whether the user is on Apple Watch or Apple TV.
> **Source:** Apple HIG — Platforms; Apple tvOS Get Started page

**RULE: Adapt, don't replicate.** The same feature should feel native on each platform. A tvOS grid becomes a watchOS list. A tvOS detail page becomes a watchOS summary card.

### 5.2 System Components

**RULE: Use native components as the default.** Tab bars, navigation stacks, lists, buttons, and alerts should use system-provided implementations. Customize appearance through tint colors and typography, not custom controls.
> **Source:** Apple HIG — Components

**RULE: Reserve custom controls for core differentiators.** Only build custom UI when your app's unique value proposition requires interaction patterns that system components cannot deliver.

### 5.3 SF Symbols

**RULE: Use SF Symbols for iconography.** The library of 6,900+ symbols is designed to integrate seamlessly with San Francisco fonts, automatically aligning with text and supporting nine weights and three scales.
> **Source:** Apple HIG — Foundations > Icons; Apple Design Resources
> **URL:** https://developer.apple.com/design/resources/

**RULE: SF Symbols adapt to Dynamic Type and accessibility settings** automatically, reducing implementation burden.

---

## 6. DESIGNER DECISION-MAKING SKILLS

### 6.1 Choosing Components

**DECISION FRAMEWORK: When deciding which component to use:**
1. Can a system component handle this? → **Use it.**
2. Can a customized system component handle this? → **Customize it.**
3. Does my core value proposition demand unique interaction? → **Build custom, but implement full accessibility.**

### 6.2 Prioritizing Readability (watchOS)

**DECISION FRAMEWORK: For small-screen content:**
1. What is the single most important piece of data? → **Show it largest and first.**
2. Can any text be replaced with an icon or color? → **Replace it.**
3. Does scrolling add value or friction? → **If friction, reduce content.**
4. Is this interaction taking more than 5 seconds? → **Simplify.**

### 6.3 Designing for Distance (tvOS)

**DECISION FRAMEWORK: For 10-foot UI:**
1. Can I read this from across the room? → **If no, increase size.**
2. Is the focused element immediately obvious? → **If no, increase contrast/scale.**
3. Can I tell where focus will move next? → **If no, fix the layout grid.**
4. Is there text that could be an image instead? → **Replace it.**

### 6.4 Adapting Features Across Platforms

**DECISION FRAMEWORK: When porting between watchOS and tvOS:**
- tvOS horizontal grid → watchOS vertical list
- tvOS detail page → watchOS summary card (2–3 key facts)
- tvOS search with keyboard → watchOS voice dictation
- tvOS tab bar with 5 tabs → watchOS 3 most-important tabs
- tvOS parallax imagery → watchOS static thumbnail
- tvOS long-form text → watchOS single-line summary

### 6.5 State Management

**DECISION FRAMEWORK: Every interactive element needs these states defined:**
1. **Default** — Normal resting appearance
2. **Focused** (tvOS) — Elevated, scaled, shadowed
3. **Pressed/Active** — Visual depression or highlight
4. **Disabled** — Reduced opacity (system standard: 0.3–0.4 alpha)
5. **Loading** — Placeholder or progress indicator
6. **Error** — Non-color-dependent indicator (icon + text, not just red)

---

## 7. COMPONENT BEHAVIOR REFERENCE

### 7.1 Buttons

| Property | tvOS | watchOS |
|----------|------|---------|
| Minimum touch target | Focus-based (no minimum) | 44×44pt equivalent |
| Focus state | Scale up, elevate, shadow | N/A |
| Label style | Verb or verb phrase | Verb or verb phrase |
| Capitalization | Title Case (every word except articles/prepositions ≤4 letters) | Title Case |
| Destructive actions | Label and confirm | Label and confirm |

> **Source:** Apple HIG — Components > Buttons

### 7.2 Lists / Collection Views

| Property | tvOS | watchOS |
|----------|------|---------|
| Layout | Grid (rows × columns) | Vertical list |
| Scrolling | Horizontal + Vertical | Vertical (Digital Crown) |
| Item spacing | 40pt+ horizontal | Minimal padding |
| Off-screen hint | Show 10–20% of next item | System scroll indicators |
| Empty state | Descriptive message + action | Short message |

### 7.3 Alerts & Confirmations

| Property | tvOS | watchOS |
|----------|------|---------|
| Max buttons | 2 preferred | 2 preferred |
| Destructive action | Red label, confirm step | Red label, confirm step |
| Dismissal | MENU button | Swipe down or tap Cancel |

---

## 8. TECHNICAL SPECIFICATIONS QUICK REFERENCE

### 8.1 tvOS Specifications

| Asset | Dimensions | Format | Notes |
|-------|-----------|--------|-------|
| App Icon (Home Screen) | 400×240 @1x / 800×480 @2x | PNG layers (2–5) | Layered, parallax mandatory |
| App Icon (App Store) | 1280×768 | PNG layers (2–5) | Layered |
| Top Shelf Standard | 1920×720 | PNG | Required |
| Top Shelf Wide | 2320×720 | PNG | Required since tvOS 10 |
| Launch Image | 1920×1080 | PNG | Static, not layered |
| Screen resolution | 1920×1080 @1x | — | Focus-based navigation |
| System font | SF Pro (Display ≥40pt, Text ≤39pt) | — | Auto-selected by system |

### 8.2 watchOS Specifications

| Asset | Dimensions | Format | Notes |
|-------|-----------|--------|-------|
| App Icon | 1024×1024 master | PNG | System generates all sizes |
| Complication | Varies by family | PNG or SwiftUI | Use ClockKit/WidgetKit |
| System font | SF Compact | — | Flat-sided for legibility |
| Background | Always black (#000000) | — | OLED optimization |
| Min touch target | ~44pt equivalent | — | Account for finger size on small screen |

---

## 9. SOURCE CITATIONS INDEX

All rules in this document are derived from these official Apple sources:

1. **Apple Human Interface Guidelines (2025)** — https://developer.apple.com/design/human-interface-guidelines/
2. **Designing for tvOS** — https://developer.apple.com/design/human-interface-guidelines/designing-for-tvos
3. **Designing for watchOS** — https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos
4. **App Icons (HIG)** — https://developer.apple.com/design/human-interface-guidelines/app-icons
5. **Typography (HIG)** — https://developer.apple.com/design/human-interface-guidelines/typography
6. **Color (HIG)** — https://developer.apple.com/design/human-interface-guidelines/color
7. **Accessibility (HIG)** — https://developer.apple.com/design/human-interface-guidelines/accessibility
8. **Motion (HIG)** — https://developer.apple.com/design/human-interface-guidelines/motion
9. **Focus and Selection (HIG)** — https://developer.apple.com/design/human-interface-guidelines/focus-and-selection
10. **Icons (HIG)** — https://developer.apple.com/design/human-interface-guidelines/icons
11. **Top Shelf (HIG)** — https://developer.apple.com/design/human-interface-guidelines/top-shelf
12. **Digital Crown (HIG)** — https://developer.apple.com/design/human-interface-guidelines/digital-crown
13. **Complications (HIG)** — https://developer.apple.com/design/human-interface-guidelines/complications
14. **Apple Design Resources** — https://developer.apple.com/design/resources/
15. **Apple Fonts** — https://developer.apple.com/fonts/
16. **tvOS Get Started** — https://developer.apple.com/tvos/get-started/
17. **WWDC 2016 Session 802 "Designing for tvOS"** — https://developer.apple.com/videos/play/wwdc2016/802/
18. **WWDC 2020 "The Details of UI Typography"** — https://developer.apple.com/videos/play/wwdc2020/10175/
19. **tvOS Guidelines Summary (BasThomas)** — https://github.com/BasThomas/tvOS-guidelines (derived from Apple HIG)
20. **Layered Image Generation (SRGSSR)** — https://github.com/SRGSSR/layered-image-generation-apple
21. **Platform Design Skills (ehmo)** — https://github.com/ehmo/platform-design-skills (distilled from Apple HIG PDF)

---

*Document version: 1.0 — March 2026*
*Compiled for use as a design governance reference in Cursor AI and development environments.*
*Review against Apple HIG quarterly, as Apple updates guidelines with each OS release.*
