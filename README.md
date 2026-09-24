# Nice Pro Portions

A free Android home-workout app for short, quiet bodyweight sessions — plus simple “eat simple” meal ideas with hand-portion guides.

**No subscriptions. No quiz funnels.** Free with ads later; optional one-off “Remove ads” upgrade planned.

## What’s in this repo

Flutter app skeleton (Phase 2):

- Bundled content (`assets/content.json`): 15 bodyweight moves, Day A / Day B routines (~9 min, warm-up + 40s/20s work/rest, no cool-down), and 5 meal ideas
- Screens: Home, Routine overview, Exercise detail, Timer (warm-up → work/rest), Done, Meal ideas, Settings
- Themes: light teal default and dark coral, following the system setting
- Own flat SVG exercise figures

**Not yet:** ads, billing, notifications, analytics (tracked as TODOs for later phases).

Approved design mockups live under [`docs/mockups/`](docs/mockups/).

Product and coding rules: [`docs/GUIDE.md`](docs/GUIDE.md).

## Requirements

- Flutter stable (3.x)
- Android SDK (for APK builds)
- JDK 17

## Build

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Sideload the debug APK onto a device to try Day A / Day B.

```bash
flutter run
```

## Package

- Application id: `space.d11s.niceproportions`
- Display name: Nice Pro Portions ;-)

## License

License: TBD (private for now)

## Status

Phase 2 — tech choice and code skeleton. Default branch for day-to-day work is `dev`; `main` is reserved for releases.
