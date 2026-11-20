# Stork 4.0: plan and shared rules for every agent

Base branch `claude/v4` (version 4.0.0, build 400). Read `CLAUDE.md`, this file and `Docs/v4-inventory.md` before you start.

## Where you work
- Make your own worktree and branch from `claude/v4` and work ONLY there:
  `git -C "/Users/nickmolargik/Developer/Molargik Software LLC/Apps/Stork" worktree add ".claude/worktrees/v4-<pkg>" -b "claude/v4-<pkg>" claude/v4`
- Never edit the main checkout (it holds uncommitted Xcode noise; leave it), another worktree, or any other repo. Other repos named below are READ-ONLY references.
- Commit to your branch in small, described commits ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never push. Never change version or build numbers.
- Only edit the files your package owns (table below). If you must touch a file another package owns, keep the change minimal and say so in your report.
- Work only inside this repository: never open, read or build unrelated projects on this Mac.

## Builds and simulators
- Package: `cd Packages/Stork && swift build && swift test`. App: `xcodebuild build -workspace Stork.xcworkspace -scheme Stork -destination 'platform=iOS Simulator,id=<your sim>' -derivedDataPath .build-dd` (`.build-dd` stays untracked).
- Use the dedicated Stork simulators (Nick, 2026-11-19), never clones: "Stork iPhone" `F380D8AF-FDF6-4BD9-A548-32C179BBCAEE` and "Stork iPad" `E7DDE14C-62A0-4EBB-89CD-DC4CE176A5BC` (iOS 27.2); Duo checks use the stock "iPhone Duo" `0DDC8DB3-61F0-4CA3-90A7-3CDC07DA6E5A`. They are shared: if one is busy, wait and retry. Never erase or reset them, and never use, modify or delete simulators that belong to other projects.
- No Mac apps, no desktop capture, no computer-use tools. Simulators only.
- The iPhone Duo simulator boots FOLDED and cannot be unfolded from the command line. Check the folded Duo, iPhone and iPad yourself. For the unfolded Duo, build the layout from the `FoldAwareness` helpers and the reference code, render what you can (SwiftUI previews at the unfolded size, or the DEBUG launch flags), and say plainly what is unverified. The lead does the unfolded check with Nick afterwards.
- Screenshots of every visual change go to `/Users/nickmolargik/Developer/Molargik Software LLC/Marketing/Stork 4.0/verification/<pkg>/` with descriptive names (before and after where it helps).

## House style (decisions already made in the other apps; follow them)
- Farside names and links: user-visible company name "Farside Software", legal "Farside Software LLC", links from `StorkCore/Persistence/Company.swift` (farsidesoftware.com, /stork, /support, /privacy). Identifiers never change: bundle IDs, `group.com.molargiksoftware.*`, `iCloud.com.molargiksoftware.Stork`, the StoreKit product `com.nickmolargik.stork.pro.lifetime`, URL scheme. Leave "Created by" file header comments alone.
- iPhone Duo: unfolded it is one wide screen with a hinge down the middle. Use `FoldAwareness` (`StorkDesignSystem/FoldAwareness.swift`) so content sits in two equal columns either side of the hinge and nothing important crosses it. Folded it behaves like an iPhone. iPad in regular width should get the same two-column layouts where they help.
- Do not add new toasts; they are being removed in wave 2 (inline status instead).
- Every toolbar item has a symbol AND a title (the Duo's vertical toolbar strip shows them).
- Data is never locked behind Pro. The year-end Wrap is free. Pro gates: milestone share cards, PDF/CSV export, insight cards, heat map, weather, Lock Screen/interactive widgets, and (new in 4.0) sharing the jar image.
- Alternate app icons are REMOVED in 4.0 (Nick, 2026-11-19): no icon picker, no alternate icon files or previews, not a Pro feature any more. Anyone who had picked an alternate icon falls back to the primary icon.
- Use the app's existing brand colours (`storkPurple`, `storkPink`, `storkBlue`, `storkOrange`, accent `#E8672B`) and existing components; do not invent a new palette.
- Never edit `.icon` files (except deleting the four alternates, `shell` only), `Icons/`, or the primary app-icon images. The new icon is a marble jar, being finished separately; in-app art uses a code-drawn `StorkMark` of that jar.
- Every new user-facing string goes through the String Catalog with an English value; leave translations to a later pass but do not delete existing ones. For any count + unit string, add English plural variants (one/other).
- No new third-party dependencies.

## Reference code (read-only)
- Opalite (layout style for landing/onboarding, Settings split view, Duo shell): `/Users/nickmolargik/Developer/Farside Software/Apps/Opalite/Packages/Opalite/Sources/` — `OpaliteFeatureOnboarding/`, `OpaliteFeatureSettings/SettingsSplitView.swift`, `OpaliteComposition/MainView.swift`, `OpaliteDesignSystem/FoldAwareness.swift`.
- Mygra 3.0 (same pattern, already ported to a second app): `/Users/nickmolargik/Developer/Farside Software/Apps/Mygra/Packages/Mygra/Sources/` — `MygraFeatureOnboarding/`, `MygraComposition/SplashView.swift`, `MygraDesignSystem/MygraMark.swift`, `MygraFeatureSettings/SettingsSplitView.swift`, `MygraComposition/MainView.swift`.

## Packages (wave 1)
| Package | Owns |
|---|---|
| `brand` | Farside names and links outside Settings (paywall, `PrivacyTrustView`, widgets, watch, `LICENSE`, `README`, App Intents strings), switching call sites to `Company`; the paywall's feature list (drop alternate icons, add jar sharing); gating Share Jar behind Pro in `JarLegendView.swift` (+ a `ProFeature` case for it); the three existing unused-variable warnings |
| `shell` | `StorkComposition` (MainView, tab/sidebar structure, Duo shell), all of `StorkFeatureSettings` (split-view Settings on the unfolded Duo and iPad, plus the three Molargik links and catalog keys in Settings), removing alternate icons (Settings section, `ProFeature` case, `Stork/Resources/Icon*.icon`, `icon-*-preview` image sets in every asset catalog, the alternate-icon build settings in `project.pbxproj`, any `setAlternateIconName` code) |
| `content` | Duo and iPad layouts for `StorkFeatureDashboard` (except `JarLegendView.swift`), `StorkFeatureDeliveries` (list, detail, entry, calendar), `StorkFeatureExport` |
| `onboarding` | `StorkFeatureOnboarding`, the splash, the launch screen, a new code-drawn `StorkMark` (the marble jar) in `StorkDesignSystem`, and replacing the old icon art (`storkicon`, icon previews) wherever it is shown in the app, widgets and watch |

Wave 2 (after merging): integration, toasts replaced by inline status like Opalite and Mygra (Nick, 2026-11-19: "Yes, like Opalite": status in the navigation subtitle, alerts for real failures, Pro limits straight to the paywall; remove the toast stack), translations of new strings, visual vetting on iPhone, Duo (folded and unfolded with Nick) and iPad, store copy, icon replacement everywhere, Affinity store set.

## Final report (under 300 words)
Branch and commits; what changed, item by item; what you verified and on which simulator; what is unverified (always the unfolded Duo unless the lead did it); design decisions Nick should confirm; any persisted-model change (CloudKit schema impact: there must be none without asking). Then stop: no further work, and do not resend the report.
