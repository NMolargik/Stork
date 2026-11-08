# Stork verification — 2026-11-07 (jar categories + role on birth)

Device: iPhone 18 Pro simulator (iOS 27), build of `main` after commit aa0c998.

## Enabling Pro in the simulator (no debug switch exists in the app)
Write the cached entitlement flags, then launch. `StoreManager` reads them at init and the
grandfather check is already marked done, so nothing overwrites them:

    xcrun simctl spawn <udid> defaults write com.nickmolargik.stork StorkPro.isGrandfathered -bool true
    xcrun simctl spawn <udid> defaults write com.nickmolargik.stork StorkPro.didCheckGrandfather -bool true
    xcrun simctl spawn <udid> defaults write com.nickmolargik.stork StorkPro.didShowGrandfatherThankYou -bool true

Settings then shows "Stork Pro — Unlocked".

## Data
1 delivery logged through the UI (boy, vaginal, Primary Nurse). 11 more were inserted with a
temporary launch-argument seed (reverted, not committed): both sexes, a loss, a nurse catch,
two sets of twins, C-section / vaginal / VBAC, every role plus "not recorded".

## Files
01–03 jar, legend filter, share image · 04–05 list row + detail role · 06–07 stats cards
08–12 settings and headline-total toggle (Deliveries 12→9, Babies 14→10 with Primary Nurse off)
13 CSV (role column) · 14 PDF (My Role section) · 15 Watch app launch
