# Outspire UI Overhaul — Liquid Glass, 2025-09-03

## Objectives
- Replace custom gradient backgrounds. Adopt with system-first design using Liquid Glass (iOS 26+) and Materials.
- Simplify and modernize Today and main feature screens: content-first, minimal motion, consistent typography, high contrast.
- Unify shared components and remove duplication; reduce visual and state complexity.
- Achieve Telegram-grade polish: fast, stable, predictable interactions; subtle micro-animations only where they add clarity.

## Principles
- System-first: prefer default navigation/toolbar/sheet appearances and behaviors; avoid custom backgrounds behind bars.
- Content over chrome: cards and overlays use `.ultraThinMaterial` or `glassEffect` sparingly; no large hero gradients.
- Minimal motion: remove fly-ins; gate remaining animations using `accessibilityReduceMotion`.
- Consistent typography: primarily `.body` and `.footnote`; headers/titles are `.body.bold()`.
- Single source of truth: one shared “glass card” style; one typography helper; no duplicate variants.

## References
- Liquid Glass overview: https://developer.apple.com/documentation/technologyoverviews/liquid-glass/
- Adopting Liquid Glass: https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass/
- Applying Liquid Glass to custom views: https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views/
- Materials & vibrancy: https://developer.apple.com/documentation/swiftui/material/
- Reduce Motion env: https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion/

## Current State (Summary)
- Global ColorfulX gradient backdrops in Today/NavSplit/other views reduce legibility and fight system bars/scroll-edge effects.
- TodayView has multiple fly-in/scale transitions and custom nav bar appearance; reported iPad glitches during sheet transitions.
- Typography mixes many sizes (`.system(size:)`, `.title*`, `.headline`, `.subheadline`, `.caption`) and appears “old style”.
- Duplicate card modifiers and duplicated Today content increase maintenance and inconsistency.

## Scope
This overhaul covers the entire app UI: Today, NavSplit root, Academic (Score), CAS, Lunch Menu, School Arrangements, Settings, and all shared UI components. Functional services (auth, networking, data) remain unchanged unless required for UI simplification.

App-wide goals:
- Flatten information architecture where possible; reduce nested options and screens.
- Standardize on one card/list visual language and spacing rhythm across features.
- Prefer progressive disclosure (detail on demand) to minimize on-screen complexity.

## Deliverables
1) Rebuilt TodayView layout (Liquid Glass-ready), 2) Unified Card + Typography system, 3) App-wide removal of ColorfulX backgrounds, 4) Cleaned duplication, 5) HIG-aligned motion, 6) Updated design guidelines in AGENTS.md.

## Phased Plan

### Phase 1 — Stabilize and Modernize Today
- Remove ColorfulX background in `TodayView`; revert to system background; keep content edge-to-edge as appropriate.
- Remove `toolbarBackground(.hidden, for: .navigationBar)` and custom nav bar appearance overrides.
- Replace card fly-in/scale transitions with:
  - Stable layout (no offset-based entrance),
  - Numeric text transitions for countdown,
  - Subtle opacity where necessary,
  - Respect `accessibilityReduceMotion`.
- Keep only one Today content implementation (remove embedded `MainContentView` duplicate and rely on `TodayMainContentView`).
- Acceptance: no flicker on iPad sheet present/dismiss; no visible “fly-in”; consistent nav/scroll-edge behavior.

#### Today Primary Card Redesign (simple, clean, performant)
- One compact “Class” card: title (subject) + time + status chip; teacher/room as meta lines.
- Countdown uses numeric text transition only; optional tiny ring progress or time-left label (no per-frame animations).
- No dynamic gradient updates per second; update context colors only at class boundary or on meaningful state changes.
- Remove internal timers where possible; prefer `TimelineView(.periodic)` for time-bound UI.
- Avoid `.id()` forced re-creation on subviews unless necessary; reduce state fan-out and `.onChange` chains.

### Phase 2 — Unify Components
- Remove duplicate `GlassmorphicCard` in `Features/Main/Views/Cards/Cards.swift`; standardize on `UI/Components/GlassmorphicComponents.swift`.
- Introduce `Typography.swift` helper with a minimal set:
  - `AppText.title = .body.bold()`
  - `AppText.body = .body`
  - `AppText.meta = .footnote`
  - Provide secondary foreground styles via `.foregroundStyle(.secondary)`; avoid `.system(size:)`.
- Refactor InfoRow, TodayHeader, ScheduleRow, cards to use the shared card modifier and typography.
- Acceptance: one card style used everywhere; no `.system(size:)` in feature views; font set ≤ 3 text styles per screen.

### Phase 3 — Remove ColorfulX App‑Wide
- Delete/refrain from `ColorfulView` in NavSplit, Help, Score, Lunch Menu, Club* views; preserve system bars, sheets, popovers.
- Constrain `GradientManager` to accent/subject coloration only (if needed). Deprecate `GradientSettingsView` (or hide behind debug flag) and eliminate user-facing gradient presets.
- Acceptance: `rg "ColorfulView\("` returns 0 in `Outspire/Features`; bars/sheets adopt system materials.

### Phase 4 — Liquid Glass Adoption (iOS 18+)
- For marquee surfaces (e.g., Class card, key headers), use `glassEffect(_:in:)` and `GlassEffectContainer` gated by availability.
- Fallback to `.ultraThinMaterial` on older OS.
- Do not apply Liquid Glass to every component; limit to key interactive elements per HIG.
- Acceptance: app builds for min supported iOS; Liquid Glass applies only on iOS 18+ with graceful fallback.

### Phase 4b — Feature Screen Simplification
- Score: one primary “GPA/summary” card + list of recent scores; move charts to a secondary screen.
- CAS: unify “activities & reflections” with a simple segmented control; list-first layout, cards adopt shared style.
- Lunch Menu/Arrangements: single hero summary + list of items; PDF/preview behind a tap.
- Settings: collapse seldom-used sections; remove gradient tuning from user-facing menu; keep essentials only.

### Phase 5 — Polish & QA
- Motion/accessibility audit: verify large motion is gated; verify contrast in light/dark; verify dynamic type scaling.
- Performance: ensure no timer-driven layout thrash; avoid redundant state refreshes.
- UI tests for Today sheet presentation on iPad; snapshot tests for typography consistency (optional).

## Layout/Structure (Today)
- Header: greeting + date + small weather indicator (no layout jumps; temperature uses monospaced digits). Title and subtext use `AppText.title/body/meta`.
- Primary Card: “Current/Upcoming Class” single glass card. No fly-in; only numeric countdown transition; subtle circular progress if current class.
- Info Card: Arrival/Assembly, optional travel info (no forced animations; appear/disappear with fade only).
- Schedule Summary: up to 3 items + expand; same card style; consistent iconography.
- Map: optional separate card only when appropriate (and permitted); not stacked with heavy transitions.

## Modern Fluent Layout (All Screens)
- One primary surface per screen: a single dominant card or list; secondary content is limited to 1–2 supporting elements.
- Reduce on-screen variety: avoid mixing many distinct component types at once (e.g., map + multiple cards + dense lists).
- Keep copy short: ≤2 lines of primary text and ≤2 lines of secondary text per card; move details behind a tap.
- Progressive disclosure: show summaries by default; reveal details on demand.
- Standard navigation: prefer default toolbars, lists, and sections to inherit Liquid Glass behavior automatically.

## Content Density & Simplicity (Today targets)
- In the initial viewport (typical iPhone), show:
  - Header
  - One primary class card
  - One supporting info item (either schedule summary or travel info) — not both stacked by default
- Place additional items below the fold (e.g., Expand Schedule, Show Map).
- Ensure one primary CTA is visible at a time; avoid competing actions.

## Animation Guidelines (Replace “cheap” animations)
- No entrance fly-ins, no appear-scale pops, no stagger cascades on first render.
- Default durations: 0.2–0.35s; use `.easeInOut` or light spring for small state changes.
- Prefer content transitions: `.contentTransition(.numericText)` for countdown; `.opacity` for reveal/hide.
- Button feedback: small press scale via a lightweight button style; avoid animating layout during presses.
- Respect `accessibilityReduceMotion`: animate opacity only; disable non-essential movement.
- Avoid animating during sheet/popup transitions to prevent iPad flicker.

## Interaction & Accessibility
- Large, consistent tap targets; clear primary action placement; predictable icons (SF Symbols).
- Dynamic Type: text styles only (body, footnote); no fixed sizes for copy.
- Contrast: verify light/dark readability; avoid low-contrast overlays on materials.
- Motion: verify with Reduce Motion enabled; no layout-shifting timers.

## Iconography & Theming
- Use SF Symbols with hierarchical/palette modes as appropriate; keep iconography consistent across similar actions.
- Replace subject/background gradients with subtle accent tints or chips; no full-screen gradients.

## KPIs (Design)
- iPad sheet present/dismiss: no visible flicker.
- Cold open to content paint: no cascading entrance animations; first frame stable.
- Viewport simplicity: ≤1 primary, ≤2 supporting elements visible at once on Today.
- Typography: ≤3 text styles per screen.

## Performance & Architecture Targets
- Rendering
  - First meaningful paint: no cascading entrance animations; initial layout stable.
  - Avoid timers that trigger full recomposition; prefer `TimelineView` or throttled publishers.
  - Use `.equatable()` or state normalization to prevent redundant updates on unchanged data.
- State
  - Reduce `.onChange` chains; consolidate into the view model and emit minimal, denormalized state for views.
  - Throttle Live Activity start/updates; trigger only on class boundary or explicit user action.
- Layout
  - Eliminate view re-creation via `.id()` except for intentional resets.
  - Keep lists/cards to a consistent spacing scale; avoid nested stacks that cause deep layout passes.
- Battery/CPU
  - No per-frame animations; countdown updates at 1s cadence only.
  - Background work (weather, location) only on significant changes; no periodic polling in views.

## Component Inventory
- `GlassCard`: `.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))` + subtle border + shadow (existing shared component retained; remove duplicate).
- `Typography.swift`: expose `AppText.title`, `AppText.body`, `AppText.meta`.
- `Haptics`: keep light taps; avoid repeated haptics during animated state changes.

## Deprecations
- ColorfulX usage in all features.
- `GradientSettingsView` (user-facing gradient presets); future-proof as dev-only if needed.
- Duplicate modifiers/components (e.g., `GlassmorphicCard` in `Cards.swift`) and duplicated Today content (`MainContentView` inside `TodayView`).

## Acceptance Criteria (Global)
- Grep checks:
  - `rg "ColorfulView\("` in `Outspire/Features` → 0 matches.
  - `rg "\.system\(size:"` in features → 0 matches (allow in rare platform-specific code, not UI text).
  - `rg "toolbarBackground\(\.hidden"` in features → 0 matches (unless for special cases justified in code).
- Visual:
  - No full-screen gradient backdrops; content over chrome; bars/sheets use system materials.
  - ≤ 3 text styles per screen; titles are `.body.bold()`.
  - No fly-in/scale entrance animations on Today.
  - iPad: presenting/dismissing sheets doesn’t cause flicker.

## Risks & Mitigations
- Perceived loss of “brand” color from gradients: retain subject-accented chips/labels; optional subtle accent tints.
- OS availability for Liquid Glass: gate with `@available(iOS 18.0, *)`, fallback to Materials.
- User expectations: communicate in release notes “cleaner, calmer visuals aligned with iOS design”.

## Implementation Checklist (File-level)
- Today
  - Remove ColorfulX bg: `Outspire/Features/Main/Views/TodayView.swift`.
  - Remove nav overrides: custom `UINavigationBarAppearance` and `.toolbarBackground(.hidden, ...)`.
  - Remove fly-in animations from content blocks and transitions.
  - Keep `contentTransition(.numericText)` for countdown only; gate remaining animations by `accessibilityReduceMotion`.
  - Remove embedded `MainContentView` duplicate.
- Shared UI
  - Remove duplicate `GlassmorphicCard` in `Outspire/Features/Main/Views/Cards/Cards.swift` and migrate usages to `UI/Components/GlassmorphicComponents.swift`.
  - Add `Outspire/UI/Components/Typography.swift` (AppText).
  - Refactor InfoRow/TodayHeader/ScheduleRow to use AppText + single card style.
- NavSplit
  - Remove ColorfulX backdrop, rely on system default list background + materials.
- Other Features (Score, Lunch, CAS, Arrangements)
  - Remove ColorfulX bg and ensure cards use shared card style + AppText.

## Rollout & Testing
- Phase-by-phase PRs with screenshots and short videos on iPhone and iPad.
- Validate Reduce Motion and Dynamic Type in Accessibility Inspector.
- Run UI tests: Today sheet present/dismiss; ensure no opacity flicker.

## Post-Overhaul Tasks
- Update AGENTS.md with: Backgrounds, Cards, Motion, Typography, Navigation, Consistency guidelines.
- Remove deprecated gradient settings from Settings UI (or hide behind debug).

---

Changelog Intent: design-only overhaul; no behavior changes to services or data.
