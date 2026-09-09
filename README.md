# TaashOnline Android frontend

Native Flutter app, package `com.sheraztech.taash`. This implementation uses the supplied Go service contracts. The workspace currently defaults to an existing mock preview for profile and catalog screens. Preview balances/rankings are fixtures. Use `--dart-define=MOCK_BACKEND=false` for real backend behavior; mock preview is not evidence of multiplayer integration.

## Run locally

The workspace SDK is Flutter 3.47.2 / Dart 3.13.2. From this directory:

```sh
../tools/flutterw pub get
../tools/flutterw analyze
../tools/flutterw test --dart-define=MOCK_BACKEND=false --reporter expanded
../tools/flutterw run --dart-define-from-file=config/local.json
```

Copy `config/local.example.json` to the ignored `config/local.json`, then supply the development backend and Firebase project API key. Android emulator `10.0.2.2` reaches a backend on the host computer. HTTP needs the explicit development opt-in. Production must use HTTPS. No working authenticated service configuration was supplied during implementation; an unconfigured real-backend build explains this and permits offline rules practice.

The wrapper uses `.tooling/flutter`, an isolated package/Gradle cache, Android Studio's JBR and `$HOME/Library/Android/sdk`. Override `ANDROID_HOME`, `TAASH_JAVA_HOME` and `TAASH_NDK_PATH` as needed. A verified workspace NDK in `.tooling/android-ndk-r28c` is detected automatically. On another machine, install the matching Flutter SDK at that path or invoke your own Flutter executable. No runtime toolchains are intended to be committed.

For a local visual preview without credentials:

```sh
../tools/flutterw run --dart-define=MOCK_BACKEND=true
```

See [the commercial remake research](../docs/frontend/06_COMMERCIAL_REMAKE.md) for the inspected official galleries and design decisions.

## Verification and screenshots

With mock mode disabled, tests use injected HTTP/socket transports and isolated rendering fixtures in `test/`. They cover credentials, read-only retry, mutation uncertainty, admission, reconnect limits, stale projections, personalized hand privacy, rules guidance, ranks, avatars and UI behavior.

The violet-and-gold commercial UI remake has screenshot baselines in `test/goldens/`. Tests explicitly await raster asset decoding before capturing. Ordinary tests compare against these files; update them only for intended, visually reviewed design changes:

```sh
../tools/flutterw test --dart-define=MOCK_BACKEND=false test/visual_qa_test.dart test/game_visual_qa_test.dart test/secondary_visual_qa_test.dart --update-goldens
../tools/flutterw test --dart-define=MOCK_BACKEND=false --reporter expanded
```

Rendering tests cover four lobby sizes, 200% text, four games at small/normal/large-text sizes, waiting/results, bottom navigation, scrolled game controls and secondary screens at normal/200% text. Fixture rendering is not a substitute for authenticated gameplay or device performance measurement. See `../docs/frontend/QA_LEDGER.md` for executed evidence and outstanding cases, and `../docs/frontend/VISUAL_REVIEW.md` for the screenshot index. See the dated verification checkpoint in the delivery status for the latest test and build results.

## Android release

Compile/target API 36; minimum API 24; Java 17; portrait and edge-to-edge configuration. The owner must supply an upload keystore and ignored `android/key.properties` with `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`. Relative keystore paths resolve from `android/app`. Release signing never falls back to a debug key.

```sh
../tools/flutterw build appbundle --release --dart-define-from-file=config/production.json
```

The expected output after a successful build is `build/app/outputs/bundle/release/app-release.aab`. No successful AAB build, 16 KB inspection or signed release is claimed yet. Supply real production configuration and policy/support URLs, verify 64-bit/16 KB packaging, complete device QA and Play declarations, and resolve the server release blockers before distribution.

## Source map

- `lib/core/`: configuration, typed contracts, secure session storage, HTTP, WebSocket state, preferences and design system.
- `lib/features/`: authentication, lobby, room admission, four game interfaces, chat/reactions, profile, shop, leaderboard, learning and settings.
- `lib/l10n/`: English copy and translation catalog; remaining inline strings are tracked in the dependency notes.
- `assets/`: catalogs, supplied cards/backs, portraits, reaction GIFs, brand files and licensed DM Sans. Game scenes combine provided artwork with Flutter gradients and framing.
- `../docs/frontend/`: contract audit, research, design, licensing, implementation, backend gaps and QA.

## Current limits

The backend remains unchanged. Its identity, disconnect, billing, settlement and final-result defects prevent a production-readiness claim. See `../docs/frontend/BACKEND_GAPS.md`. Audio playback awaits a licensed asset pack and implementation. Brand provenance, corrected rank thresholds, policy URLs, signing credentials, live service integration and physical-device performance remain outstanding.
