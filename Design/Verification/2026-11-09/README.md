# Verification, 2026-11-09 (branch claude/backfill-lock)

Simulator: iPhone 18 Pro, iOS 27.2, app launched with `-StorkInMemoryStore 1`. Debug launch arguments used:
`-StorkSeedWrapSample 1`, `-StorkSeedPastBirths 1`, `-StorkImportCSVPath <file>`, `-requireBiometricLock YES`.

| File | What it shows |
| --- | --- |
| `widget-career-total-logo.png` | Career Total widget in the gallery with the storkicon logo rendering (was blank before). |
| `lock-screen.png` | Face ID lock cover after cancelling the system prompt (stork logo via `storkicon`, Unlock button). |
| `dashboard-toolbar-before.png` | Dashboard toolbar on main: unlabeled sparkles and reorder buttons plus Add. |
| `dashboard-toolbar-after.png` | Toolbar now: one More button plus Add. |
| `dashboard-toolbar-after-menu.png` | The More menu: Year in Births… and Reorder Cards…. |
| `settings-data-privacy.png` | Settings: Roles collapsed to one row, Data section with Past Births & Import, start of Privacy. |
| `settings-privacy-faceid.png` | Privacy section with Require Face ID on, Lock After picker and the trust screen link. |
| `past-births-hub.png` | Past Births & Import hub (Add Past Births, Import from CSV). |
| `add-past-births.png` | Add Past Births form, 2021 to 2025 at 150 a year, live summary. |
| `deliveries-estimated.png` | Deliveries list with the Earlier Career (Estimated) cards. |
| `csv-import-preview.png` | CSV preview: counts, dropped identifier columns, per-row errors. |
| `identifier-warning.png` | Inline identifier warning above the note field (keyboard dismissed). |
| `identifier-warning-keyboard.png` | Same with the keyboard up: the keyboard toolbar hint is the only part visible. |

Not captured: the Face ID system sheet itself (simulator enrolment worked, but the sheet is system UI) and the Lock Screen widgets (Pro-locked in the gallery).
