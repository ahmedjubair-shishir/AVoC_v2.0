# AVoC v2.0 — Screen flow & build status

Source of truth: Figma file "AVoC App" (page "Screens") + its "Prototype notes".

## Main flow
```
Splash ──2s / tap──▶ Onboarding 1 → 2 → 3 (first launch only) ──Skip / Get Started──▶ Home
Splash ──2s / tap──▶ Home (after first launch)

Home ── Add New ──▶ Mic permission (explain / denied) ──▶ Recording (Ready → Recording ⇄ Paused)
Recording ── Stop ──▶ Recording Preview ── Continue ──▶ Voice Selection ── Convert ──▶ Converting (≈2.5s)
Converting ──▶ Result ── Save ──▶ Save sheet (Rename sheet) ──▶ Saved ✓ ──▶ History
Result ── Try another voice ──▶ Voice Selection
Home ── See all / tab ──▶ History ── item ⋮ ──▶ Actions (play, rename, share, try another voice, delete)
Home ── ⚙ ──▶ Settings
```

## Back-button rules (Android)
- Recording and Preview ask before discarding ("Discard recording?").
- Result goes back without deleting.
- Sheets/dialogs: tapping the dimmed area = Cancel / Keep.

## Edge cases (Figma section 10)
Max length reached · No audio detected · Too short · Leave during recording ·
Conversion failed · Low storage · Export failed · Permission denied · Deleted / Renamed snackbars.

## Build status
| # | Figma section | Status |
|---|---|---|
| 09 | Splash & Onboarding | ✅ built |
| 01 | Home (+ empty) | ✅ built |
| 02 | Recording (+ permission) | ✅ built |
| 03 | Recording Preview | ✅ built |
| 04 | Voice Selection | ✅ built |
| 05 | Conversion | ✅ built |
| 06 | Result | ✅ built |
| 07 | Save & Export | ✅ built (WAV, see note) |
| 08 | History | ✅ built |
| 10 | Edge cases & feedback | ✅ built |
| 11 | Settings | ✅ built |
