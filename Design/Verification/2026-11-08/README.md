# Year Wrap verification, 2026-11-08

Debug sample data: `DebugSampleBirths.twoYears` (deterministic, Mar 2025 to Nov 2026, roles, twins, a triplet set, nurse catches, a few losses).
Launch arguments: `-isOnboardingComplete 1 -StorkInMemoryStore 1 -StorkDebugNow 2026-12-05 -StorkSeedWrapSample 1 -StorkOpenWrap 2026 -StorkWrapPage N`.

| File | What it shows |
| --- | --- |
| iphone-dashboard-card.png | Seasonal "Your Year in Births" card (date override Dec 5) and the sparkles toolbar menu, iPhone 18 Pro |
| iphone-wrap-page0..5.png | Story pages: intro, who arrived, your role, your rhythm, comparison, summary + share controls |
| ipad-dashboard-card.png, ipad-wrap-page0..5.png | Same on iPad Pro 11-inch (M5); the Wrap uses a page-sized sheet |
| wrap-2026-square.png (1080x1080), wrap-2026-story.png (1080x1920) | Share images as rendered, default: no remembrance line |
| wrap-2026-square-remembrance.png, wrap-2026-story-remembrance.png | Same with the opt-in "Remembered: N" line |

The sample year shows "Remembered: 6" in-app on the summary page while the default share images contain no loss information.
Findings fixed during review: white wordmark glyph (now template-tinted), iPad sheet too small (page sizing), summary crowding the page dots.
