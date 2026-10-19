# Security policy

## Supported versions

Only the latest `main` is supported. Fixes land there and in the next release.

## Reporting a vulnerability

Report privately through GitHub private vulnerability reporting:
<https://github.com/Bald-bearded-man/FogCatcher/security/advisories/new>

Do not open a public issue or PR for a security problem. Include the affected version (shown in About), steps to reproduce and the impact you expect.

## Scope

FogCatcher has no backend, no account and no network access at runtime (the release build does not declare `INTERNET`). The scope is:

- the Android app itself (permissions, the location foreground service, local data on the device);
- the offline tools under `tool/` and `scripts/` (for example OpenStreetMap downloads and content-pack processing).
