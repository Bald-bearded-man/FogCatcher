## Summary

<!-- What does this change and why? Link the issue (Fixes #123). -->

## Checklist

- [ ] Tests added or updated (regression test for a bug fix)
- [ ] `scripts/ci-local.sh --quick` passed (`GATE OK`)
- [ ] Docs updated (README, `docs/`, tool READMEs) if usage changed
- [ ] If copy changed: edited `lib/l10n/app_en.arb` and ran `flutter gen-l10n`
- [ ] If `pack/pack.json` changed: ran `dart run tool/apply_pack.dart` (never hand-edit `lib/config/pack.g.dart`)
- [ ] No private pack content, no new permissions (`INTERNET`, background location, boot receiver)
