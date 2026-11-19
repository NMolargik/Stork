# Stork 4.0 base inventory

Branch `claude/v4`, cut from `main` (538096f) with `claude/duo-pass` merged (fast-forward, no conflicts), version 4.0.0 / build 400, `FoldAwareness.swift` and `Company.swift` added. Line numbers refer to this branch.

## a. "Molargik" / "molargiksoftware"

Case-insensitive search over source, string catalogs, plists, entitlements, docs, pbxproj, storekit.

### (i) User-visible names and links, to become Farside (14 places)
| Where | What |
|---|---|
| `Packages/Stork/Sources/StorkFeatureSettings/SettingsView.swift:500` | `Link("Molargik Software LLC", ... https://www.molargiksoftware.com)` About |
| `SettingsView.swift:496` | `Link("Nick Molargik", ... linkedin.com/in/nicholas-molargik)` personal credit (decide: keep as a person credit or drop) |
| `SettingsView.swift:507` | Share app `ShareLink` item `https://molargiksoftware.com/go/stork?ct=share_app` (needs a Farside `/go/stork` redirect or switch to `Company.appPage`) |
| `Packages/Stork/Sources/StorkFeaturePro/StorkProPaywallView.swift:24` | `privacyPolicyURL = https://molargiksoftware.com/privacy` |
| `Packages/Stork/Sources/StorkFeatureSettings/PrivacyTrustView.swift:28` | English sentence "...Molargik Software cannot see it..." (this literal is the catalog key) |
| `Packages/Stork/Sources/StorkFeatureSettings/Localizable.xcstrings:560` | key "Molargik Software LLC" (en, es, fr-CA, ja values at 565/571/577) |
| same file `:582` | key "Nick Molargik" (values 587/593/599) |
| same file `:2982` | key for the privacy sentence above, with es/fr-CA/ja translations at 2987/2993/2999 (all mention Molargik Software) |
| `LICENSE:3` | "Copyright (c) 2025 Molargik Software LLC" |
| `README.md:155` | "Molargik Software LLC" footer |

Count: 10 source/doc locations (the 3 catalog keys, 12 catalog lines in total). No other string catalog, no Info.plist, InfoPlist.xcstrings, AppShortcuts.xcstrings, or settings bundle mentions it (settings bundle: not found).

### (ii) Identifiers that must NEVER change (about 45 lines)
- Bundle IDs (pbxproj, 16 lines): `com.nickmolargik.stork` (app, 2), `com.nickmolargik.stork.watchkitapp` (2), `com.nickmolargik.stork.StorkWidgets` (2), `WKCompanionAppBundleIdentifier = com.nickmolargik.stork` (2); test targets `com.molargiksoftware.StorkTests`, `.StorkUITests`, `StorkWatch-Watch-AppTests`, `StorkWatch-Watch-AppUITests` (2 each).
- App group `group.com.molargiksoftware.Stork`: `StorkCore/Persistence/AppGroup.swift:13`; entitlements `Stork/Stork.entitlements:21`, `StorkWatch Watch App/StorkWatch Watch App.entitlements:19`, `StorkWatch Watch App/StorkWatch.entitlements:7`, `StorkWidgets/StorkWidgets.entitlements:15`, `StorkWidgetsExtension.entitlements:7`, `StorkWatchWidgetsExtension.entitlements:7`.
- iCloud container `iCloud.com.molargiksoftware.Stork`: `StorkData/StorkStore.swift:16`; entitlements `Stork/Stork.entitlements:11`, `StorkWatch Watch App.entitlements:11`, `StorkWidgets.entitlements:7`.
- StoreKit product `com.nickmolargik.stork.pro.lifetime`: `StorkCore/Domain/ProFeature.swift:59`, `Stork/Configuration.storekit:16`, `Tests/StorkCoreTests/ProTests.swift:59` (also docs: `CLAUDE.md:9`, `README.md:64`, `Design/Verification/2026-11-07/README.md:9-11` as defaults domain).
- URL scheme `stork` (value; the scheme itself has no Molargik) with `CFBundleURLName com.molargiksoftware.Stork` at `Stork/Info.plist:9`.
- Keychain groups: not found (no keychain entitlement).
- `StorkCore/Logging/Log.swift:13` os_log subsystem `com.molargiksoftware.Stork` (harmless to change, but log filters and scripts use it; leave).

### (iii) Unclear
- 13 "Created by Nick Molargik on ..." header comments (watch app, widgets, UI tests). Not user visible; leave.
- `CLAUDE.md:76` (documents the iCloud container id) is documentation of an identifier; leave.

## b. Pro gating

- Catalog: `StorkCore/Domain/ProFeature.swift` lists 9 features: milestoneShareCards, pdfExport, csvExport, insightCards, calendarHeatMap, alternateAppIcons, weatherAtDelivery, lockScreenWidgets, interactiveWidgets. There is no `ProFeature` case for the jar.
- Environment: `StorkDesignSystem/Pro/ProEnvironment.swift` provides `\.isProUnlocked` and `\.requestProUpgrade(feature)`; `MainView` presents `StorkProPaywallView` from its root. View models take `any EntitlementProviding`. UI marks via `ProBadge` / `ProLockIcon` / `.proLocked` (`Pro/ProBadge.swift`).
- **Share Jar**: `StorkFeatureDashboard/Jar/JarLegendView.swift:58` (button), `share()` at ~91-105, card in `Jar/JarShareCardView.swift`. It is NOT Pro-gated: free users can share. It shows a `ProBadge` beside the label for free users (line 59) and renders at 1x for free, 3x for Pro (`renderer.scale = isProUnlocked ? 3.0 : 1.0`; `highResolution:` flag on the card). Tapping never opens the paywall. Accessibility hint: "Free users share a lower-resolution picture. Stork Pro shares full resolution."
- Other Pro share gating: milestone share cards are hard gated. `StorkFeatureExport/ShareCardView.swift:56-60` (free tap on a milestone calls `requestProUpgrade(.milestoneShareCards)`) and `StorkComposition/MainView.swift:~257-262` (`shareMilestone` guards `storeManager.isProUnlocked`, otherwise sets `paywallFeature = .milestoneShareCards`). PDF/CSV export gated at `ExportView.swift:31,34`. Year Wrap share (`YearWrapView.swift:76`) is free by policy.
- README / CLAUDE.md lists: `CLAUDE.md:9` says free forever = deliveries, basic stat cards, **the marble jar**, calendar, Watch app, basic widgets, Spotlight, Siri; Pro = milestone share cards, PDF/CSV export, insight cards, calendar heat map, alternate icons, weather, Lock Screen + interactive widgets; Wrap free "shareable acquisition hook, never gate". `README.md` has no explicit free/Pro list beyond mentioning Pro on weather (line 37) and the IAP (line 64). So the docs put the jar in the free list but do not mention jar sharing specifically. Today's behaviour is a soft gate (resolution only) with a Pro badge on a button that does work, which is the odd part.

## c. Launch screen

- No storyboard in the repo (`*.storyboard`: not found). `Stork/Info.plist` has no `UILaunchScreen` dictionary. The launch screen is generated by build setting `INFOPLIST_KEY_UILaunchScreen_Generation = YES` (`project.pbxproj:816` for the app target, no other launch keys), so it is a blank system-background screen: no colour, no image, no name.
- Widget and watch targets: no launch screen config (not needed).
- Nothing references a missing image. Not out of date, but it is empty and unbranded, so the transition into the in-app splash is white/black flash then `SplashView`.
- In-app splash: `StorkFeatureOnboarding/SplashView.swift` (94 lines): "Stork" title (60pt, 90pt at regular width), subtitle "for labor & delivery professionals", pulsing `Image("icon-purple-preview")` (the purple icon PNG, `Stork/Assets.xcassets/icon-purple-preview.imageset`), purple "Get Started" button. Shown at `RootView.swift:31-32` only when onboarding is incomplete; returning users go straight to `.main` (`RootView.swift:65`).

## d. Onboarding and landing

Flow (`StorkComposition/RootView.swift`, `AppStage`: splash, onboarding, main): Splash, then `OnboardingView` (`StorkFeatureOnboarding/OnboardingView.swift`, steps from `StorkCore/Enumerations/OnboardingStep.swift`):
1. Privacy: `OnboardingPrivacyPage.swift` (SF Symbol `lock.shield.fill`, feature rows).
2. Step Count: `OnboardingHealthPage.swift` (HealthKit, skipped on visionOS or when unsupported).
3. You're All Set: `OnboardingCompletePage.swift` (checkmark, feature list, "Enter Stork").
Model: `OnboardingModel.swift`; row view `OnboardingFeatureRow.swift`. Art: SF Symbols only on the three pages; the only bitmap is the purple icon preview on Splash. No onboarding mention of Pro, no location page by design.
Landing after onboarding: `MainView` (Dashboard tab first).

## e. Settings

`StorkFeatureSettings/SettingsView.swift` is one `Form` (hosted in a `NavigationStack` in `MainView.swift:177`), sections in order: ProSection (92), PreferencesSection (123), RolesSection (140, NavigationLink to an inline Roles page), AppIconSection (187, horizontal scroller of 4 icon previews), SyncSection (279), DataSection (342, links: Export & Share, Past Births & Import), PrivacySection (363, link to `PrivacyTrustView`, app lock toggle), DangerZoneSection (425), DebugSection (452, DEBUG), AboutSection (489, includes Rate/Share rows and the Molargik links), AttributionsSection (516).
Sub-pages: Roles Counted in Totals (inline), `ExportView` (supplied by caller; leads to PDF options, CSV options, `ShareCardView`), `PastBirthsHubView` then `AddPastBirthsView` / `CSVImportView`, `PrivacyTrustView`. Navigation is plain push `NavigationLink` rows inside one NavigationStack; no split view, no `navigationDestination(for:)` for settings (only the DEBUG push at line 63). Duo-aware: no; `PhoneDuo` / `containerLayoutProbe` from FoldAwareness are not used anywhere yet.

## f. Size classes, Duo, tab structure

- Main structure: `MainView.swift:150-190` one `TabView(.sidebarAdaptable)` with 4 tabs (`AppTab`: dashboard, list, calendar, settings), each wrapped in its own `NavigationStack` (list has a `NavigationPath`). Bottom accessory step pill on Dashboard only (`tabViewBottomAccessoryIfAvailable`). iPad/Mac get the adaptable sidebar; there is no `NavigationSplitView`. Delivery detail is pushed in the same stack, not a detail column.
- `horizontalSizeClass` users: `DashboardView.swift:17` (line 39 switches to a two-column card layout at regular), `Jar/JarView.swift:46` (onChange at 96), `Cards/BabyCountCard.swift:13`, `Toast/ToastView.swift:95` (top-leading anchor at regular, from duo-pass), `SplashView.swift:19`.
- `GeometryReader`: `AnimatedStatViews.swift:127`, `JarView.swift:54`, `YearWrapView.swift:146,249`, `CardImageRenderer.swift:143`, `MilestoneCelebrationView.swift:35,147`. `MarbleScene.swift:24` scales with scene size (duo-pass).
- `UIDevice` idiom checks: none left in package sources.
- DEBUG launch flags (`StorkCore/Domain/DebugLaunchOptions.swift`): StorkDebugNow, StorkInMemoryStore, StorkSeedWrapSample, StorkSeedPastBirths, StorkOpenWrap, StorkWrapPage, StorkWrapIncludeRemembrance, StorkImportCSVPath, StorkOpenLink, StorkOpenSheet, StorkSettingsPush, StorkExportWrapImages. Consumers: `MainView.swift:119-122`, `DeliveryListView.swift:45`, `SettingsView.swift:27,63`, `DashboardView.swift:60`, `CSVImportView.swift:59`, `SessionController.swift:116,176,181`.
- Duo-pass changes (merged): toolbar items now carry symbol plus title; toast and marble sizing use size class/geometry.

## g. Icon and old stork artwork in the UI

Asset catalogs (identical copies in `Stork/`, `StorkWidgets/`, `StorkWatch Watch App/`): `stork`, `beak`, `sack` (svg), `storkicon` (svg), `icon-{blue,orange,pink,purple}-preview` (png), `appleHealth`, plus colour sets. Icon files: `Stork/AppIcon.icon` and `Stork/Resources/Icon{Blue,Orange,Pink,Purple}.icon` (pbxproj 794-795, 846-847: primary `IconPurple`, alternates IconBlue/IconOrange/IconPink; lines 974, 1014 AppIcon for other targets).
Uses (all unqualified names, resolved from each target's own catalog; package code resolves from main bundle):
- `storkicon`: `AppLockView.swift:22`, `JarShareCardView.swift:58`, `CardImageRenderer.swift:99`, `MilestoneCardView.swift:27`, `MilestoneCelebrationView.swift:82`, watch `Views/TodayStatsView.swift:54`, widgets `CareerTotalWidget.swift:77`, `InteractiveWidget.swift:150`, `LockScreenWidgets.swift:104,127,167,292`.
- `stork` (template): `YearWrapShareView.swift:116`.
- `beak`, `sack`: no references found in Swift code (unused assets).
- `icon-purple-preview`: `SplashView.swift:44`; all four previews: `SettingsView.swift:204-207` (AppIconSection).
- `IconManager.swift:23-25` maps colour names to alternate icon names.

## h. Screenshots and store assets

- `Screenshots/`: `StorkArtboards.afdesign`, `Raw/` (iPhone 7, iPad 6, Watch 3, Apple Vision Pro 3), `Framed/` (iPhone 7, iPad 6, Watch 3), `Professional/` (iPhone 5, iPad 6, Watch 3, Combined.png). 51 files. No Duo set. Appears to be 3.0-era art.
- `Design/Verification/` dated folders 2026-11-07 (jar, roles, export; 18 files plus README), 2026-11-08 (Year Wrap pages and share images), 2026-11-09 (past births, import, toolbar before/after); 65 files total, verification captures only, no marketing art.
- `Icons/`: 2 files (`AppIcon.png`, `AppIcon-iOS-Default-1024@1x.png`); the layered icon sources are the `.icon` bundles under `Stork/`.

## i. Test and build status

- `swift test` in `Packages/Stork`: 96 tests in 16 suites, all pass.
- `swift build`: clean.
- `xcodebuild build -workspace Stork.xcworkspace -scheme Stork -destination 'generic/platform=iOS Simulator'`: BUILD SUCCEEDED, 16 warning lines (3 distinct: unused `dateColumn` `DeliveryCSVImport.swift:236`, unused `url` in `CSVExportOptionsView.swift:78` and `PDFReportOptionsView.swift:61`), all pre-existing.
