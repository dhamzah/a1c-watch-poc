# A1C Insights for Apple Watch — POC

Standalone watchOS app (SwiftUI, watchOS 10+) proving the PRD v0.1 concept:

- **Glance**: glucose, trend arrow, 3-hour graph with 70–140 band, Body Battery, Readiness
- **Complications** (WidgetKit): glucose circular / rectangular / inline / corner, Body Battery, Readiness. 5-min timeline; reading greys out after 15 min
- **Alerts**: rising fast, dropping fast, below target, **spike** (+30 mg/dL above the 60-min baseline, or crossing 140). Local notifications with Log food / Walk 10 min / Snooze actions
- **Voice logging**: dictation → parsed food (with carb estimate) / activity / water / 0Spike / symptom → confirm card → saved; a food log relabels the open spike ("Spike after Nasi padang")
- **Spike recap**: peak, rise, minutes above 140, likely cause

Data sources: `Demo day` (built-in CGM day with a lunch spike) or `Live (Sally key)` → `POST https://sally.a1c.io/v1/skills/health_sync` (same backend the iOS app syncs to).

## Build

```bash
brew install xcodegen
xcodegen generate
open A1CWatch.xcodeproj      # run the A1CWatch scheme on an Apple Watch simulator
```

CI (`.github/workflows/build.yml`) builds for the simulator and uploads screenshots of every screen (`scripts/screenshots.sh`, launch arg `-screen glance|rising|spike|voice|confirm|recap|complications|nocgm|settings`).

## What engineering needs to change for production

| POC | Production |
|---|---|
| Sally API key typed on the watch | A1C account sign-in (token endpoint on the A1C backend) |
| Alert + spike rules run on the watch (`Shared/AlertEngine.swift`) | Same rules on the backend, sent as APNs pushes (category `GLUCOSE_ALERT`, same actions) |
| Keyword food parser (`Shared/LogParser.swift`) | Sally LLM parse endpoint (e.g. `POST /v1/voice-log`), logs written to the user's A1C timeline |
| Logs saved locally | Synced to backend |
| Ad-hoc signing, no team | A1C Pte Ltd team, bundle IDs `io.a1c.watch.*`, App Group `group.io.a1c.watch.poc` |
| Standalone app | Optionally embed as the Watch app of the Swift iOS app and push readings via WatchConnectivity |

## Known limits
- watchOS rations background refresh and complication reloads; expect 5–15 min freshness unless pushes are used.
- Glucose is only as fresh as the iPhone app's upload to the backend.
- Wellness positioning: alerts are informational, "Not for treatment decisions".

## Fonts

The a1c.io display font, Chillax (Fontshare), is under the ITF Free Font License. That license allows embedding it in an app but not redistributing the font files, so they are not in this repo. The POC uses SF Rounded instead. To use Chillax in a private build, download it from fontshare.com, put Chillax-{Light,Regular,Medium}.otf in Shared/Fonts, add them to UIAppFonts for both targets in project.yml, and set `A1CFont.useChillax = true` in Shared/Theme.swift.
