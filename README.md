# Nice Pro Portions

[![CI](https://github.com/dkelertas-homelab/good-pro-portion/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/dkelertas-homelab/good-pro-portion/actions/workflows/ci.yml)
[![Release](https://github.com/dkelertas-homelab/good-pro-portion/actions/workflows/release.yml/badge.svg)](https://github.com/dkelertas-homelab/good-pro-portion/actions/workflows/release.yml)

A free Android home-workout app for short, quiet bodyweight sessions — plus simple “eat simple” meal ideas with hand-portion guides.

**No subscriptions. No quiz funnels.** Free with ads later; optional one-off “Remove ads” upgrade planned.

## What’s in this repo

Flutter app skeleton (Phase 2):

- Bundled content (`assets/content.json`): 15 bodyweight moves, Quiet morning A / B routines (~10 min, warm-up + 40s/20s work/rest, no cool-down), and 5 meal ideas
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

Sideload the debug APK onto a device to try Quiet morning A / B.

## CI/CD

GitHub Actions runs the PR checks (format, analyze, test, debug APK artifact) and builds tagged `v*` releases into a GitHub Release with the APK attached. How it works, the Azure DevOps mapping and the one-time signing setup are in [`docs/ci-cd-walkthrough.md`](docs/ci-cd-walkthrough.md).

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

## Release builds

- Release builds need `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`; git-ignored). Without it, `flutter build apk/appbundle --release` fails on purpose; there is no debug-signed fallback. Debug builds don't need it.
- Upload to a Play testing track with `tool/play_upload.py` (internal, alpha or beta only; draft by default; version taken from `pubspec.yaml`). Run it with `--help` for options.
