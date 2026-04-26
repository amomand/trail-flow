# TrailFlow

A SwiftUI iOS app for scrolling back through trail runs in TokyoNight terminal aesthetics. Read-only companion to Apple Fitness, side-loaded via Xcode (not for App Store distribution).

Sibling app to [IronFlow](../iron-flow). Same visual language, different domain — IronFlow is during-exercise, TrailFlow is post-exercise review.

## What it does

Pulls running workouts from HealthKit and renders them as terminal-style log entries. Each row shows date, distance, duration, elevation gain, an inline pace sparkline, and a tiny cyan route polyline. Tap a row for the full detail view: cyan polyline on a muted MapKit base, pace and elevation charts (Swift Charts), per-km splits, and HR.

## Stack

- Pure SwiftUI, no external dependencies
- iOS 18+ deployment target (built/tested on iPhone Air, iOS 26)
- `@Observable` state, SwiftData for local mirror
- HealthKit (read-only) for source of truth
- MapKit + Swift Charts for the detail view

## Project layout

```
TrailFlow/
├── TrailFlowApp.swift              # @main, ModelContainer, onboarding gate
├── TrailFlow.entitlements          # HealthKit capability
├── Theme/
│   ├── TokyoNightColors.swift      # TN palette
│   ├── Theme.swift                 # Theme env value
│   └── TerminalStyle.swift         # mono font, button, card, section header
├── Models/
│   ├── Run.swift                   # SwiftData @Model mirroring HKWorkout headlines
│   └── RunMetrics.swift            # splits, pace buckets, elevation profile
├── Storage/
│   ├── AppSettings.swift           # start date, hasOnboarded (UserDefaults)
│   ├── HealthKitService.swift      # async wrappers around HK queries
│   ├── SyncCoordinator.swift       # incremental sync, upsert into SwiftData
│   └── RouteCache.swift            # in-memory route + sparkline cache
└── Views/
    ├── FirstLaunchView.swift       # permissions + start-date picker
    ├── RunListView.swift           # @Query on Run, pull-to-refresh
    ├── RunRowView.swift            # terminal-style card + lazy sparkline/thumbnail
    ├── SparklineView.swift         # hand-drawn pace canvas
    ├── RoutePolylineThumbnailView.swift
    ├── RunDetailView.swift         # MapKit polyline, charts, splits, HR
    └── SettingsView.swift          # change start date, re-sync, perms link
```

## Sync strategy

- On launch and on pull-to-refresh, query HealthKit for `.running` workouts since `max(latestStoredStartDate, userStartDate)`
- Upsert into SwiftData keyed by `HKWorkout.uuid`
- The list view reads SwiftData only — never blocks on HealthKit
- Route + HR samples are fetched lazily per row/detail view and cached in memory for the process lifetime (`RouteCache`)

## Build

```bash
xcodebuild -project TrailFlow.xcodeproj -scheme TrailFlow \
  -destination 'platform=iOS Simulator,name=iPhone Air' build
```

Open `TrailFlow.xcodeproj` in Xcode, select an iPhone Air destination, run.

The simulator has no HealthKit running data, so on-device install is needed to actually see runs.

## First-launch flow

1. Request HealthKit permissions (workouts, route, HR, distance)
2. Pick a start date — defaults to **2026-04-26**
3. Initial sync populates SwiftData
4. Land in the list view

The start date can be changed later in Settings (gear icon, top-right).
