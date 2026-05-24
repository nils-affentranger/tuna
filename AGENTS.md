# Tuna - Flutter Tuner App

## Cursor Cloud specific instructions

### Project overview
Tuna is a cross-platform musical instrument tuner built with Flutter. It targets Android, iOS, Linux, macOS, Web, and Windows. There is no backend, database, or external service dependency — it is a purely client-side Flutter app.

### Prerequisites
- Flutter SDK 3.44.0+ (installed at `~/flutter-sdk/flutter`, already on PATH via `~/.bashrc`)
- Dart SDK 3.12.0+ (bundled with Flutter)
- Chrome is available for web target testing

### Common commands
| Task | Command |
|---|---|
| Install dependencies | `flutter pub get` |
| Lint / static analysis | `flutter analyze` |
| Run tests | `flutter test` (no test directory exists yet) |
| Run web (dev) | `flutter run -d chrome --web-port=8080 --web-hostname=0.0.0.0` |
| Run Linux desktop (dev) | `flutter run -d linux` (requires GTK3 dev libs) |
| Build web | `flutter build web` |

### Gotchas
- The `test/` directory does not exist yet. `flutter test` will exit with code 1 and the message "Test directory 'test' not found." — this is expected, not a failure.
- The tuner screen currently uses a test slider (C4–C5) for frequency input; real microphone input is not wired up.
- For web development, pass `--web-hostname=0.0.0.0` to make the dev server accessible from outside localhost.
- `flutter run -d chrome` launches a Chrome instance automatically; you do not need to open Chrome separately.
- The project has custom icon fonts (Myna Outlined/Solid) in `assets/fonts/`; these are referenced in `pubspec.yaml` and should not be removed.
