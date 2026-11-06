# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Stork is an app for labor & delivery nurses to track the deliveries they perform while staying HIPAA-conscious (no patient-identifying data, no hospital/location correlation). SwiftUI + SwiftData with iCloud/CloudKit private-database sync.

**Business model (3.0+):** free download with a one-time **Stork Pro** unlock (`com.nickmolargik.stork.pro.lifetime`, non-consumable, Family Sharing). Free forever: logging deliveries (every field, any past date), basic stat cards, the marble jar, calendar, Watch app, basic Home Screen widgets, Spotlight, Siri. Pro: career milestone share cards, PDF/CSV export, insight cards, calendar heat map, alternate app icons, weather-at-delivery, Lock Screen + interactive widgets. **Data is never locked.** Pre-3.0 buyers are grandfathered (see Stork Pro below).

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
   │ Onboarding ·     │   │ + StoreManager  │   │ (CloudKit) ·   │
   │ Settings · Export│   │ + their seams   │   │ seam impls ·   │
   │ · Pro (paywall)  │   └────────┬────────┘   │ CloudSync      │
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
`WeatherManager` (1/hour cooldown; conforms to Core's `DeliveryWeatherCapturing` — the **only** caller of location), `LocationManager` (one-shot, when-in-use only — never continuous updates or Always), `HealthManager` (gated `#if canImport(HealthKit) && !os(visionOS)`), `StoreManager` (StoreKit 2, see Stork Pro), their seams (`WeatherProviding`, `LocationProviding`, `StepCountReading`), weather/location errors, `WeatherCondition` styling. `CloudSyncManager` also lives here.

### Stork Pro (entitlements)
- **Core**: `EntitlementProviding` seam (`isProUnlocked`), `ProFeature` catalog + `StorkProProduct.id`, `DashboardCard.requiresPro`, `GrandfatherPolicy`/`VersionNumber` (pure), `MilestoneShareReviewPolicy`, `DeliveryDateRule`, `DeliveryWeather` (+ three optional columns on `Delivery`).
- **Services**: `StoreManager: EntitlementProviding` — purchase/restore, `Transaction.updates`, caches the verdict in `UserDefaults`, mirrors `isProUnlocked` into the app group (`SharedDefaultsKey.isProUnlocked`) for the widget extension, runs the grandfather check once via `AppTransaction`.
- **Grandfathering**: `originalAppVersion` on iOS is the *build number*. Paid-era builds were < 300; 3.0 ships as build **300** and every later build must stay ≥ 300. Only `environment == .production` qualifies (sandbox/TestFlight report placeholders). One-time thank-you sheet (`GrandfatherThankYouView`).
- **Gating pattern**: every feature view model takes `entitlement: any EntitlementProviding` (tests use a fake) and exposes `isProUnlocked`/`isLocked(...)`. Views mark locked controls with `ProBadge`/`ProLockIcon`/`.proLocked(_:feature:)` (DesignSystem) and call `@Environment(\.requestProUpgrade)` — the composition root (`MainView`) presents `StorkProPaywallView` (StorkFeaturePro) from its stable root. Never present the paywall from inside a list row or tab accessory.
- **Widgets** read the app-group flag; Lock Screen + Quick Start widgets render `ProLockedWidgetView` (links `stork://pro`) when locked.
- **Review prompts**: 5th delivery (repository) and the first completed milestone-card share (`MilestoneShareReviewPolicy`, fed by `ShareSheet`'s completion). No others.
- Local testing: `Stork/Configuration.storekit` is attached to the `Stork` scheme.

### StorkDesignSystem (depends on Core)
Brand colors (`storkBlue`/`storkPink`/`storkPurple`/`storkOrange`, defined in code on `ShapeStyle where Self == Color` so they work as both `Color` and in `.foregroundStyle`/`.fill`/`.tint`); `DeliveryMethod.accentColor`, `Sex.color`, `DeliveryTag.color`, `Color(hex:)`; `AdaptiveGlassModifier`, `Haptics`, the toast stack (`ToastManager`/`ToastItem`/`ToastView`/`.toastContainer()`), animated stat views, `DetailRowView`, `TagChipView`/`FlowLayout`, `SparkleText`, shared view modifiers.

### StorkFeature* (one per area, depend on Core + DesignSystem [+ Services])
`Deliveries`, `Dashboard` (cards + SpriteKit Jar + Calendar), `Onboarding`, `Settings`, `Export`, `Pro` (paywall + grandfather thank-you; depends on Services for `StoreManager`). Each screen is a `#if os(iOS)` SwiftUI view backed by a **cross-platform `@Observable` view model** that depends on use-case *protocols* — never SwiftData, `@Query`, or `modelContext` directly. View files are iOS-gated so host `swift test` runs simulator-free; view models stay cross-platform.

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
- Languages: en (source), es, fr-CA, ja via String Catalogs — one `Localizable.xcstrings` **per package module** (`Packages/Stork/Sources/<Module>/Localizable.xcstrings`), plus per-target catalogs and `AppShortcuts.xcstrings`/`InfoPlist.xcstrings` in the app/widget/watch targets.
- **Policy for package strings:** every module owns its strings and resolves them in its own bundle. SwiftUI's key-based initializers default to `Bundle.main`, so package call sites must name the bundle: `Text("Key", bundle: .module)` where a bundle parameter exists; otherwise wrap the key — `Label(String(localized: "Key", bundle: .module), systemImage:)`, `.navigationTitle(Text("Key", bundle: .module))`, etc. String-typed component parameters (`title:`, `label:`, …) localize at the **call site** (the module whose catalog holds the key), not inside the component. Core/Services enums (`displayName`/`description`) return `String(localized:bundle:)`; `AppTab.localizedTitle` builds `LocalizedStringResource(_, bundle: .atURL(Bundle.module.bundleURL))`.
- **After adding user-facing strings to package code:** add the key + es/fr-CA/ja translations to that module's `Localizable.xcstrings`, then run `python3 Scripts/check_module_strings.py` — it reports keys missing from a module catalog, call sites that forgot `bundle: .module`, and entries missing a language.
- **Don't reword existing keys casually** — the English literal *is* the catalog key; changing one character orphans three translations. Watch/widget strings live in their own targets and catalogs and extract automatically.
- **Never build plurals by interpolating suffixes** — use `^[\(n) baby](inflect: true)` or full alternates.
- Domain glossary in the catalogs (es: parto/PVDC/UCIN; fr-CA: accouchement/AVAC/USIN; ja: 分娩/帝王切開/NICU).
- Accessibility: stat clusters combine into one element with label+value; decorative symbols `.accessibilityHidden(true)`; icon-only buttons get labels; widgets read as a single element.

## Gotchas
- All iPhone orientations enabled; keep layouts flexible (iOS 27 dynamic resizing). Don't reference `UIScreen.main` — use `onScrollVisibilityChange` / GeometryReader.
- WeatherKit calls cooled to 1/hour (`WeatherManager.refreshCooldownInterval`) — don't add extra refresh triggers. Weather (and therefore location) is fetched **only** when a Pro user taps "Add Weather Snapshot" in the delivery form; there is no launch-time weather, no onboarding location page, no `location` background mode, and no `NSLocationAlwaysAndWhenInUseUsageDescription`. Keep it that way — the privacy nutrition label says location is not linked and not used in the background.
- Deliveries can be dated any time in the past (`DeliveryDateRule`): no lower bound, upper bound = the moment the form opened.
- The hospital feature was deliberately removed for privacy (HIPAA). Don't reintroduce facility tracking.
- Weeks are Sunday–Saturday on a pinned `en_US_POSIX` calendar (`WeekMath.sundayFirstCalendar`) — locale-default calendars break widget/app agreement.
- Widget + watch targets `import` package products (no more `membershipExceptions` for shared code). If a target needs another module, add it to that target's `packageProductDependencies` in `project.pbxproj`.
- **visionOS:** feature view files are gated `#if os(iOS)`. The app runs on visionOS today via iPad compatibility (where `os(iOS)` is true). A *native* visionOS target would need those gates widened to `#if os(iOS) || os(visionOS)`.
