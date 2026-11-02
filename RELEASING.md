# Releasing kumo_flutter

## First release (manual, once)

pub.dev only allows automated publishing for packages that already exist, so 0.1.0 is published by hand.

1. Sign in to https://pub.dev with the Google account that should own the package.
2. Locally, on a clean `main`:
   ```sh
   flutter pub get
   flutter analyze
   flutter test
   (cd example && flutter test)
   flutter pub publish --dry-run   # must report 0 warnings
   flutter pub publish             # opens a browser to authorize, then asks for confirmation
   ```
3. Tag the release so GitHub matches pub.dev:
   ```sh
   git tag v0.1.0
   git push origin v0.1.0
   gh release create v0.1.0 --title "v0.1.0" --notes-file CHANGELOG.md
   ```
   The tag also triggers `.github/workflows/publish.yml`; until step 4 is done that run fails harmlessly because pub.dev rejects it.
4. Enable automated publishing on pub.dev: package page, **Admin** tab, **Automated publishing**, **Enable publishing from GitHub Actions**:
   - Repository: `mralifakbar/kumo_flutter`
   - Tag pattern: `v{{version}}`
   - Require GitHub Actions environment: `pub.dev`
5. Optional but recommended: create a verified publisher (Admin, **Publisher**) for a domain you own and transfer the package to it, so the package page shows a verified badge instead of an email address.

## Every later release

1. Bump `version:` in `pubspec.yaml` following semver. While below 1.0.0, breaking changes bump the minor version (0.1.x to 0.2.0).
2. Add a `## <version>` section at the top of `CHANGELOG.md`.
3. Commit on `main`, wait for CI to pass.
4. Tag and push: `git tag v<version> && git push origin v<version>`.
5. The publish workflow runs analyze and tests, then publishes. Approve the `pub.dev` environment run if you added required reviewers.
6. Create the GitHub release: `gh release create v<version> --generate-notes`.

## Regenerating derived files

Run these when Kumo or Phosphor change. They read checkouts of github.com/cloudflare/kumo and github.com/phosphor-icons/web (plus `src/icons.ts` from github.com/phosphor-icons/core for tags):

```sh
dart run tool/generate_theme.dart <kumo>/packages/kumo/src/styles
dart run tool/generate_icons.dart <phosphor-web>/src <phosphor-core>/src/icons.ts
dart run tool/generate_llms.dart
python3 tool/check_doc_snippets.py
```

After regenerating colors, run `flutter test test/foundation/oklch_test.dart test/foundation/theme_test.dart`: they pin known Tailwind and Kumo values, so an upstream change shows up as a failing expectation you can review.
