# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Stork is an app for labor & delivery nurses to track the deliveries they perform while staying HIPAA-conscious (no patient-identifying data, no hospital/location correlation). SwiftUI + SwiftData with iCloud/CloudKit private-database sync.

The app is a **thin app target on top of an SPM umbrella package** (`Packages/Stork`) of layered, single-responsibility modules — clean architecture in the style of StreetIQ's SCOUT. Dependencies point **inward**: features depend on the design system and core; data implements core's protocols; **core depends on nothing** (Foundation + SwiftData only).

## Build & Run

**Open `Stork.xcworkspace`** (not the bare `.xcodeproj`) — it resolves the local package. No external dependencies. Built against the iOS 27 / watchOS 27 SDKs (Xcode 27 beta). If `xcodebuild` fails with a CommandLineTools error, prefix commands with `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`.

**Swift 6 language mode**, MainActor default isolation everywhere: app/widget/watch targets set `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; package targets use `swiftSettings: [.defaultIsolation(MainActor.self)]`. Pure value types used from nonisolated contexts (enums for App Intents/widgets, `WeekMath`, `UnitConversion`, keys) are marked `nonisolated` explicitly. XCTest/XCUITest targets stay on nonisolated default.

Fast iteration — the package builds and tests on the macOS host, simulator-free:
```
cd Packages/Stork && swift build && swift test          # domain/data/services/export logic
```
Verify iOS UI compiles (feature view files are gated `#if os(iOS)`):
```
xcodebuild build -scheme StorkComposition -destination 'generic/platform=iOS Simulator'
```
Build the whole app (also builds the embedded widget + watch):
```
xcodebuild build -workspace Stork.xcworkspace -scheme Stork \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**App targets:** `Stork` (iOS/iPadOS/visionOS — thin shell + App Intents), `StorkWidgetsExtension`, `StorkWatch Watch App` (thin shell: `WatchSession` composition root + `WatchDeliveryModel` on use-cases — **no direct SwiftData**; watch saves run the shared repository side effects), `StorkTests` (app-glue only), `StorkUITests`, watch test targets.

## Architecture — `Packages/Stork`

```
        ┌──────────── Stork (app target — thin) ─────────────┐
        │  StorkApp (@main) builds SessionController · Intents │
        └───────────────────────┬─────────────────────────────┘
                                 │ hosts RootView, registers session
        ┌────────────────────────▼────────────────────────────┐
        │  StorkComposition  — SessionController (composition   │
        │  root) + RootView/MainView + view-model factories     │
        └───┬───────────────────────────────────┬──────────────┘
   ┌────────▼─────────┐   ┌─────────────────┐   ┌▼───────────────┐
   │ StorkFeature*    │   │ StorkServices   │   │ StorkData      │
   │ Deliveries ·     │   │ Weather/Location│   │ Default*Repo · │
   │ Dashboard ·      │   │ /Health managers│   │ StorkStore     │
   │ Onboarding ·     │   │ + their seams   │   │ (CloudKit) ·   │
   │ Settings · Export│   └────────┬────────┘   │ seam impls ·   │
   │ (views + VMs)    │            │            │ CloudSync      │
   └───┬──────────┬───┘            │            └───────┬────────┘
       │ uses     │ uses           │ implements         │ implements
   ┌───▼──────┐ ┌─▼────────────────▼────────────────────▼───────┐
   │ StorkDS  │ │ StorkCore (pure domain)                        │
   │ colors · │ │ @Model types · enums · domain (stats/filter/   │
   │ glass ·  │ │ milestones/weekmath/units) · navigation        │
   │ haptics ·│ │ (AppRouter/AppTab/DeepLink) · repository &      │
   │ toast    │ │ use-case PROTOCOLS · service seams · Log        │
   └──────────┘ └────────────────────────────────────────────────┘
```

### StorkCore (pure — Foundation + SwiftData only, host-tested)
- **Models** (`@Model`): `Delivery`, `Baby`, `DeliveryTag`. CloudKit-friendly (defaults on all properties, optional relationships). `.sample` factories are `#if DEBUG`.
- **Enumerations** (`nonisolated`): `DeliveryMethod`, `Sex`, `AppStage`, `ToastStyle`, `OnboardingStep`, `DashboardCard`, `ExportDateRange`/`CSVRowFormat`.
- **Domain**: `DeliveryStatistics` (every dashboard stat, pure static funcs with injectable `Calendar`/`Date`), `DeliveryFilter` + `+Matching`, `MilestoneTracker` (persists behind `KeyValueStoring`), `WeekMath` (the single source of truth for Sunday–Saturday weeks, `nonisolated`), `UnitConversion`.
- **Navigation**: `AppTab`, `DeepLink`, `AppURLScheme`, `AppRouter` (`@Observable`).
- **Services (protocols only)**: `DeliveryRepository`/`TagRepository` + single-verb use-cases (`LoadDeliveries`, `LogDelivery`, `UpdateDelivery`, `DeleteDelivery`, `DeleteAllDeliveries`, `LoadCareerTotals`, `LoadTags`, `SaveTag`, `DeleteTag` — each a `protocol` + `…UseCase` struct with `callAsFunction`); `CareerTotals` value type; seams `KeyValueStoring`, `WidgetTimelineReloading`, `DeliveryIndexing`, `ReviewRequesting`. Nothing outside the composition root touches a repository directly — always go through a use-case (even App Intents).
- **Typed errors**: the whole persistence boundary declares `throws(PersistenceError)` (`.fetchFailed`/`.saveFailed`) — new repository/use-case methods must keep the typed signature so view models catch a concrete, `Equatable` error.
- **Change stream**: `DeliveryChangeCenter` + `ObserveDeliveryChanges` — the repository notifies on every successful write and `CloudSyncManager` notifies on CloudKit imports, so screens observe one multicast `AsyncStream` (`for await _ in session.observeDeliveryChanges() { reload() }`). Never add per-screen refresh callbacks.
- **Persistence keys**: `AppGroup`/`SharedDefaultsKey`/`WidgetKind`/`AppStorageKeys`; the `UserDefaults: KeyValueStoring` conformance.
- `Log` — `os.Logger` per category. **Never `print`.** Files calling `Log` need their own `import os`.

### StorkData (persistence impl, depends on Core)
`DefaultDeliveryRepository` (owns the `ModelContext`; runs every save's side effects in one place — app-group fallback counts, widget refresh, Spotlight reindex, review-at-5th — and returns a crossed `MilestoneCelebration`), `DefaultTagRepository`, `StorkStore.makeContainer(inMemory:)` (CloudKit private DB; container id `iCloud.com.molargiksoftware.Stork`), seam impls (`WidgetCenterReloader`, `AppStoreReviewRequester`), `CloudSyncManager`.

### StorkServices (system-framework managers, depend on Core)
`WeatherManager` (1/hour cooldown), `LocationManager`, `HealthManager` (gated `#if canImport(HealthKit) && !os(visionOS)`), their seams (`WeatherProviding`, `LocationProviding`, `StepCountReading`), weather/location errors, `WeatherCondition` styling. `CloudSyncManager` also lives here.

### StorkDesignSystem (depends on Core)
Brand colors (`storkBlue`/`storkPink`/`storkPurple`/`storkOrange`, defined in code on `ShapeStyle where Self == Color` so they work as both `Color` and in `.foregroundStyle`/`.fill`/`.tint`); `DeliveryMethod.accentColor`, `Sex.color`, `DeliveryTag.color`, `Color(hex:)`; `AdaptiveGlassModifier`, `Haptics`, the toast stack (`ToastManager`/`ToastItem`/`ToastView`/`.toastContainer()`), animated stat views, `DetailRowView`, `TagChipView`/`FlowLayout`, `SparkleText`, shared view modifiers.

### StorkFeature* (one per area, depend on Core + DesignSystem [+ Services])
`Deliveries`, `Dashboard` (cards + SpriteKit Jar + Calendar), `Onboarding`, `Settings`, `Export`. Each screen is a `#if os(iOS)` SwiftUI view backed by a **cross-platform `@Observable` view model** that depends on use-case *protocols* — never SwiftData, `@Query`, or `modelContext` directly. View files are iOS-gated so host `swift test` runs simulator-free; view models stay cross-platform.

### StorkComposition (top of graph — the composition root)
`SessionController` (`@MainActor @Observable`) builds the whole dependency graph in `init` (container → repositories → use-cases → managers → cloud sync) and vends per-screen view models via `make…Model()` factories. `RootView` (splash → onboarding → main) and `MainView` (the one adaptive `TabView`) live here, plus the bottom-accessory pills. App-specific seams that need app-target types (the Spotlight indexer) are injected in.

### App target (`Stork/`) — thin
`StorkApp` (~40 lines): builds `SessionController(indexer: SpotlightDeliveryIndexer())`, registers it with `AppDependencyManager` for App Intents, hosts `RootView`. Plus `QuickActions`, `StorkCommands`, and `Intents/`. The package products are linked in `project.pbxproj` (`packageProductDependencies` + `XCSwiftPackageProductDependency` + `XCLocalSwiftPackageReference`); the app folder is still folder-synchronized but now contains only the shell.

## App Intents — `Stork/Intents/`
`LogDeliveryIntent` (background logging via `session.logDelivery`; `donate(reflecting:)` on manual UI saves so Siri learns usage — never donate from `perform()`), `BabiesThisWeekIntent` / `CareerTotalsIntent` (read-only stats), `StartDeliveryEntryIntent` + `OpenDeliveryIntent` (`stork://` scheme), `StorkShortcuts`. Intents read the session via `@Dependency var session: SessionController`.

`DeliveryEntity` is the Siri/Spotlight representation — **aggregate fields only (date, counts, method, epidural); never notes or tags** (HIPAA). App Intents can't synthesize `AppEnum` metadata for a package enum, so intents use the app-target `DeliveryMethodAppEnum` mirror (bridge via `.core`/`init(_:)`). `SpotlightDeliveryIndexer` (app target, conforms to the `DeliveryIndexing` seam, injected into `SessionController`) keeps the semantic index in sync.

## View conventions
- Pattern: `FeatureView.swift` + `FeatureModel.swift` (`@Observable`, depends on use-case protocols; heavy logic stays in Core).
- Reusable UI lives in **StorkDesignSystem**; extract there before duplicating.
- **Navigation is one adaptive `TabView(.sidebarAdaptable)`** in `MainView` (tab bar iPhone, switchable sidebar iPad/Mac). Deep links route through `AppRouter`.
- Wide layouts cap scrolling content at 700–1000pt and center it — never stretch rows across a full iPad/Mac window.
- **Delivery-method colors come from `DeliveryMethod.accentColor`**; user-facing names from `displayName`/`description` — never hardcode colors or show `rawValue`.
- Search + the filter sheet feed one `DeliveryFilter` pipeline; an active filter matching nothing shows "No Matches"/`ContentUnavailableView.search`, never the unfiltered list.
- **Toolbars**: semantic placements; one prominent action per screen (`AddDeliveryToolbarButton`, borderedProminent + storkBlue); destructive buttons use `Button(role: .destructive)`; Cancel/close stay untinted; `keyboardShortcut`s + `.hoverEffect`.
- **Never apply `.tint` to containers** (TabView/NavigationStack/List) — it cascades into toolbars and overrides destructive red. The `AccentColor` asset is the only global accent.

## Testing
- Swift Testing (`@Suite`, `@Test`, `#expect`). The real suite is in `Packages/Stork/Tests` (`swift test`, host, simulator-free): `StorkCoreTests`, `StorkDataTests` (repository behavior over an on-disk store + fake seams), `StorkServicesTests`, and per-feature **view-model tests over fake use-cases** (`StorkFeatureDeliveriesTests`, `StorkFeatureDashboardTests`, `StorkFeatureSettingsTests`, `StorkFeatureExportTests`). `StorkTests` (app target) covers only app glue.
- View models are cross-platform on purpose so they test on the host: substitute the use-case protocols with in-memory fakes (see `StorkFeatureDeliveriesTests/FakeUseCases.swift`) — no `ModelContainer`, no simulator.
- New logic goes into Core (pure) first with tests, then a repository/use-case in Data, then the feature view model **with its own fake-driven tests**.
- View models surface failures (`lastError` / throwing `save()`) — never swallow errors with `try?` on user-initiated writes.

## Localization & accessibility
- Languages: en (source), es, fr-CA, ja via String Catalogs — `Localizable.xcstrings` per target plus `AppShortcuts.xcstrings`/`InfoPlist.xcstrings` in the app.
- **Policy for package strings:** SwiftUI's key-based initializers resolve in `Bundle.main` at runtime, so translations for strings rendered by package modules live in the **app target's** `Stork/Localizable.xcstrings` — by design, not accident. Those entries are pinned `extractionState: "manual"` + `shouldGenerateSymbol: false` (Xcode's auto-extraction only scans app-target sources and would otherwise flag them stale; symbol generation is `NO` everywhere because manual entries with case-colliding keys — "Babies"/"babies" — fail the build).
- **After adding user-facing strings to package code:** add the key + es/fr-CA/ja translations to `Stork/Localizable.xcstrings` by hand, then run `python3 Scripts/pin_package_strings.py` — it pins package-referenced entries, rescues stale ones, and reports package literals missing from the catalog.
- **Don't reword existing keys casually** — the English literal *is* the catalog key; changing one character orphans three translations. Watch/widget strings live in their own targets and catalogs and extract automatically.
- **Never build plurals by interpolating suffixes** — use `^[\(n) baby](inflect: true)` or full alternates.
- Domain glossary in the catalogs (es: parto/PVDC/UCIN; fr-CA: accouchement/AVAC/USIN; ja: 分娩/帝王切開/NICU).
- Accessibility: stat clusters combine into one element with label+value; decorative symbols `.accessibilityHidden(true)`; icon-only buttons get labels; widgets read as a single element.

## Gotchas
- All iPhone orientations enabled; keep layouts flexible (iOS 27 dynamic resizing). Don't reference `UIScreen.main` — use `onScrollVisibilityChange` / GeometryReader.
- WeatherKit calls cooled to 1/hour (`WeatherManager.refreshCooldownInterval`) — don't add extra refresh triggers.
- The hospital feature was deliberately removed for privacy (HIPAA). Don't reintroduce facility tracking.
- Weeks are Sunday–Saturday on a pinned `en_US_POSIX` calendar (`WeekMath.sundayFirstCalendar`) — locale-default calendars break widget/app agreement.
- Widget + watch targets `import` package products (no more `membershipExceptions` for shared code). If a target needs another module, add it to that target's `packageProductDependencies` in `project.pbxproj`.
- **visionOS:** feature view files are gated `#if os(iOS)`. The app runs on visionOS today via iPad compatibility (where `os(iOS)` is true). A *native* visionOS target would need those gates widened to `#if os(iOS) || os(visionOS)`.
