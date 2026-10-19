# Contributing

Thanks for helping. Bug reports, fixes and small features are welcome. By taking part you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Setup

- Flutter 3.44.3 (pinned, the gate fails on any other version), JDK 17, Android SDK 36.
- `flutter pub get && flutter gen-l10n`
- `flutter run` on an Android device or emulator. See [README.md](README.md#run) for the version and debug-menu flags.

## Before you open a PR

Run the quality gate and make sure it ends with `GATE OK`:

```sh
scripts/ci-local.sh --quick   # format, analyze, metrics, pack check, tests with coverage
scripts/ci-local.sh           # same plus the release build and Android lint
```

CI runs the full script on every push and PR.

## Tests

Every change ships with tests: new features get at least one test, changed behavior updates its tests, and bug fixes get a regression test that fails before the fix.

- No mocking library. Use hand-written fakes and Riverpod overrides.
- All time goes through `package:clock`, so tests can control it.
- Test fixtures use neutral site ids: `demo_park`, `test_site`.

## Copy

- All user-facing text is English and lives in `lib/l10n/app_en.arb`. No hardcoded strings in widgets or notifications.
- After editing the ARB file, run `flutter gen-l10n` and commit `lib/l10n/generated/` (the gate fails if it is stale).
- Use the `{appName}` placeholder instead of a literal app name; the name comes from the content pack.

## Content packs

- `lib/config/pack.g.dart` is generated. Never edit it by hand: change `pack/pack.json`, then run `dart run tool/apply_pack.dart`.
- Never commit a private pack. Keep it in the git-ignored `packs/` directory or a separate repo. See [docs/content-packs.md](docs/content-packs.md).
- Each `assets/sites/<id>/` must be declared in `pubspec.yaml` (`tool/new_site.dart` and `tool/apply_pack.dart` do it for you).

## Location and permissions

These are hard rules; PRs that break them will not be merged.

- The location foreground service starts only from a user tap ("Start exploring") and stops on "Stop exploring". Never start it automatically, not even after a process death.
- No boot receiver.
- No `ACCESS_BACKGROUND_LOCATION`, no `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
- The release manifest must not declare `INTERNET`. The app has no backend and no network at runtime; only the offline tools under `tool/` use the network.

## Issues and pull requests

1. Open an issue first for anything bigger than a small fix, so we can agree on the approach.
2. Fork, create a branch, and keep the PR small and focused on one change.
3. Update the docs (README, `docs/`, tool READMEs) when the change affects how someone uses, runs or extends the code.
4. Fill in the PR template and link the issue.

Security problems: do not open a public issue, see [SECURITY.md](SECURITY.md).
