# Outspire — Liquid Glass Redesign Proposal (2025‑09‑03)

## Summary
- Goal: Deliver an Apple‑style, iOS 26‑ready redesign using Liquid Glass; simplify layouts, reduce motion, and unify typography and components across the entire app.
- Approach: Adopt system‑first materials and new Liquid Glass APIs, reference Apple’s Landmarks sample patterns, and remove custom gradient backdrops in favor of toolbar/sheet/Material behavior.

## References (Apple docs)
- Adopting Liquid Glass: https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass
- Applying Liquid Glass to custom views: https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views/
- Landmarks: Refining Liquid Glass in toolbars: https://developer.apple.com/documentation/swiftui/landmarks-refining-the-system-provided-glass-effect-in-toolbars
- Landmarks: Background extension effect: https://developer.apple.com/documentation/swiftui/landmarks-applying-a-background-extension-effect
- Landmarks: Extend horizontal scrolling under sidebar: https://developer.apple.com/documentation/swiftui/landmarks-extending-horizontal-scrolling-under-a-sidebar-or-inspector
- Landmarks: Custom activity badges (morph): https://developer.apple.com/documentation/swiftui/landmarks-displaying-custom-activity-badges

## Investigation Findings (Before)
- Visual weight and inconsistency:
  - Full‑screen ColorfulX gradients conflicted with Material/Liquid Glass layering and reduced readability.
  - Many entrance animations caused layout jitter and iPad sheet flicker.
  - Duplicated glass modifiers and Today content fragments increased complexity.
- Typography:
  - Mixed `.system(size:)`, `.title*`, `.headline/subheadline/caption` led to “old style” feel and inconsistent scaling.
- Architecture:
  - Global gradient/theme code pushing dynamic backgrounds everywhere; toolbar customizations hid system behaviors.

## Design Direction (Apple‑style)
- System‑first materials: Let toolbars/sheets use system Liquid Glass; use `.ultraThinMaterial` or `glassEffect` only on key surfaces.
- Minimal motion: No fly‑ins; small, purposeful transitions; respect Reduce Motion.
- Unified typography: AppText styles — `title = .body.bold()`, `body = .body`, `meta = .footnote`.
- Progressive disclosure: One primary surface per screen, concise copy, optional details below the fold.
- Landmarks patterns: Toolbar grouping with fixed spacers; background extension effect on hero; horizontal scroll that extends under sidebar; optional badge morphs via GlassEffectContainer.

## What’s Implemented
- Navigation
  - New 4‑tab layout (Today, Class, Activities, Search) via `RootTabView` and NavigationStack per tab.
  - “Search/Extra” tab as a consolidated, searchable entry to secondary features (School Arrangements, Lunch Menu, Grades, Clubs, Reflections, Settings) with glass hero and iPad background extension support.
- Liquid Glass components
  - Shared glass card style: iOS 26+ uses `glassEffect`; older versions fall back to `.ultraThinMaterial`.
  - `glassContainer(spacing:)`: iOS 26+ wraps groups in `GlassEffectContainer`; else `VStack`.
- Today
  - Removed ColorfulX background and custom nav appearances; stable first paint.
  - Toolbar refined on iOS 26+: refresh + `ToolbarSpacer(.fixed)` + schedule button to produce clean Liquid Glass groups.
  - Main content wrapped in `glassContainer` to prepare for future morph/blend.
- App‑wide cleanup
  - Removed ColorfulX backdrops from Help, Score, Classtable, CAS, School Arrangements, Lunch Menu.
  - Consolidated glass modifier usage into shared UI component.
  - Introduced `AppText` and applied to updated components (Today header, InfoRow, EnhancedClassCard).

## What’s Next (Prioritized)
1) Today & Extras — Landmarks Effects
   - Add an optional Today hero surface (image or branded card) aligned to container edges and apply `.backgroundExtensionEffect()` on iOS 26 iPad (regular width).
   - Apply `ToolbarSpacer(.fixed)` grouping patterns across major screens.
2) Typography Pass (Consistency)
   - Convert `ScheduleRow`, `SchoolInfoCard`, `DailyScheduleCard`, and key Settings rows to `AppText`.
   - Limit to ≤ 3 text styles per screen.
3) Badge Morph (Optional, iOS 26+)
   - For class actions (Live Activity/Calendar/Map), build a compact cluster using `GlassEffectContainer + glassEffectID` with `withAnimation` to demonstrate Liquid Glass morph.
4) Search/Extra
   - Add basic in‑app query routing (e.g., highlight/filter rows, quick links to common destinations).
5) Deprecation & Settings
   - Hide the gradient tuning UI from user‑facing settings (keep under DEBUG if needed); limit `GradientManager` to accents only.
6) QA & Performance
   - iPad sheet transitions, Reduce Motion, Dynamic Type, battery/CPU checks; no timer‑driven layout thrash; use TimelineView when appropriate.

## Acceptance Criteria / KPIs
- Visual
  - No full‑screen gradients; bars/sheets show system Liquid Glass/materials.
  - Toolbar actions grouped with fixed spacers on iOS 26+; look consistent with Landmarks.
  - ≤ 3 text styles per screen using `AppText`.
  - Today initial viewport: Header + one primary card + one supporting element; no entrance fly‑ins.
- Behavior
  - iPad: No flicker when presenting/dismissing sheets.
  - Reduce Motion: Opacity/numeric transitions only; no large motion.
  - Liquid Glass morphs only when they add clarity; gated by availability.

## Risks & Mitigations
- Perceived brand loss from gradients: retain accent chips/subject tints; optional subtle hero imagery.
- iOS 26 availability: gate Liquid Glass APIs (`glassEffect`, `GlassEffectContainer`, `backgroundExtensionEffect`) and ensure `.ultraThinMaterial` fallback.
- Toolbar grouping support: Feature‑gate with `#available(iOS 26, *)` and retain consistent behavior on earlier OS.

## Phased Plan (Execution)
- Phase A: Landmarks effects — Today hero background extension, toolbar grouping across main screens.
- Phase B: Typography pass on `ScheduleRow`, `SchoolInfoCard`, `DailyScheduleCard`, Settings.
- Phase C: Badge morph cluster on Today (iOS 26+), wired with concise actions.
- Phase D: Extra tab query routing and suggestions.
- Phase E: Settings cleanup (hide gradient presets), QA pass (motion, contrast, iPad sheets), showcase build.

## Completed File Changes (Key)
- Root tabs: `Outspire/Features/Main/Views/RootTabView.swift` (new), `Outspire/OutspireApp.swift` (uses TabView root)
- Extra screen: `Outspire/Features/Main/Views/ExtraView.swift` (new, searchable)
- Liquid Glass helpers: `Outspire/UI/Components/GlassmorphicComponents.swift` (updated), `Outspire/UI/Components/Typography.swift` (new)
- Today refinements: `Outspire/Features/Main/Views/TodayView.swift`, `Outspire/Features/Main/Views/Components/TodayMainContentView.swift`, `TodayHeaderView.swift`
- CAS/Score/Arrangements: Removed ColorfulX backdrops in views; rely on system materials.

---

Owner: Outspire UI
Status: In progress (A0). Pending: Landmarks hero/background effects, typography pass, badge morph.

