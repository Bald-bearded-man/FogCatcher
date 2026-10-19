# Release (Google Play internal testing)

Package `com.baldman.fogcatcher`. The Play listing name is the pack's `appName`.

## One-time setup
1. Create the upload keystore (keep the passwords and file safe, never commit):
   ```
   mkdir -p ~/keys && chmod 700 ~/keys   # keytool does not create the folder
   keytool -genkey -v -keystore ~/keys/upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (git-ignored):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=<absolute path to>/keys/upload.jks
   ```
   Without this file, release builds are signed with the debug key (fine locally, rejected by Play).
3. Play Console: create the app (English, free, app).
4. App content: complete the forms, including the foreground service declaration (location, started by the user) and Data safety (no data collected or shared).
5. Testing > Internal testing: create a track, add tester emails (max 100) under a testers list.
6. Upload the first AAB, roll it out, then share the opt-in link with testers. They must accept it, then install from Play.

## Per release
```
flutter build appbundle --release --build-number N --build-name 1.0.N --dart-define=APP_VERSION=1.0.N+N --dart-define=DEBUG_PIN_SHA256=$DEBUG_PIN_SHA256
```
- Output: `build/app/outputs/bundle/release/app-release.aab`.
- Never reuse a versionCode (`N`); Play rejects it. Ranges:
  - Play and local releases: +1 per release, above every uploaded versionCode.
  - CI: `run_number + 1000` (artifact `app-release-aab`), so CI artifacts never collide with local ones. They are signed with the debug key unless CI has the upload key, so upload only locally signed builds.
- Console: Internal testing > Create new release > upload AAB > release notes > roll out. Testers update from Play.

## Side-by-side flavor
`APP_ID_SUFFIX` appends a suffix to the package, so a second build can sit next to the Play app on one phone (progress is separate):
```
APP_ID_SUFFIX=.alt flutter build apk --release --build-number N --build-name 1.0.N --dart-define=APP_VERSION=1.0.N+N --dart-define=DEBUG_PIN_SHA256=$DEBUG_PIN_SHA256
```
It gives package `com.baldman.fogcatcher.alt`. Use the same `N` as the matching Play release; different packages never clash.

## Hotfix
- [ ] Fix, run `scripts/ci-local.sh` until `GATE OK`
- [ ] Bump `N` above every uploaded versionCode
- [ ] Build the signed AAB (command above), check that no "debug key" warning appeared
- [ ] Upload to internal testing and roll out
- [ ] Tell testers to update from Play (updates can take a few minutes to appear)
- [ ] Confirm the version label on the About screen shows `1.0.N+N`

## Gotchas
- Re-running `flutter_native_splash` (also done by `tool/apply_pack.dart`) overwrites the `tools:targetApi` lint fix in `android/app/src/main/res/values*/styles.xml`; reapply it or `lintRelease` fails.
- Debug menu: tap the version label on the About screen 7 times, then enter the PIN (see below).

## Debug PIN
The debug menu (teleport, force find, reset, phase override) sits behind 7 taps on the About version label plus a PIN. Only the PIN's SHA-256 goes into the build, never the PIN.
```
read -rs PIN; export DEBUG_PIN_SHA256=$(printf '%s' "$PIN" | sha256sum | cut -d' ' -f1)
```
- `246810` is the test value used by the unit tests. It is public: production builds must use a different PIN.
- Use at least 6 digits. Five wrong tries lock the PIN dialog for 10 minutes (until the app restarts).
- Every release build must pass `--dart-define=DEBUG_PIN_SHA256=...` (the commands above do, and `scripts/ci-local.sh` forwards the env var). Without it the 7 taps do nothing and the debug menu is unreachable in that build.
- Keep the PIN with the upload-key passwords; changing it needs a new build.
