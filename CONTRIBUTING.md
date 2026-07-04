# Contributing to Bank UI Kit

Thanks for your interest in improving Bank UI Kit! This document explains how
to set up the project, the conventions we follow, and how to get a change
merged.

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By
participating you are expected to uphold it. Please report unacceptable
behaviour to the maintainers.

## Project layout

```
lib/
  core.dart            # barrel: accounts, transactions, transfers, cards, auth…
  investing.dart       # barrel: wallets, holdings, charts
  credit.dart          # barrel: installments, subscriptions, perks
  saving.dart          # barrel: pots, round-ups, income sorter
  social.dart          # barrel: joint accounts, shared goals
  src/
    theme/             # design tokens, BankThemeData, presets, custom theming
    scope/             # BankUiScope + strings
    models/            # plain Dart data classes (Money, Transaction, …)
    <feature>/         # one folder per feature module
    controllers/       # headless flow controllers
example/               # component gallery + Revolut-style demo app
  lib/screens/         # one showcase screen per module
  lib/demo/            # full-app dashboard + sample data
  lib/screenshot_harness.dart  # URL-driven entrypoint for doc screenshots
tool/screenshots.mjs  # Playwright doc-screenshot generator
doc/screenshots/      # generated screenshots used by the README
```

## Getting started

```bash
flutter pub get
cd example && flutter pub get && cd ..

# Static analysis (must be clean)
flutter analyze

# Tests
flutter test

# Run the demo gallery
cd example && flutter run
```

The package targets **Flutter 3.27+ / Dart 3.5+**.

## Conventions

- **Theming.** Never hard-code colours, radii, spacing, or text styles in a
  widget. Read them from `BankThemeData.of(context)` and `BankTokens`. A widget
  that looks correct under all three presets (Studio, Voltage, Bloom) in both
  light and dark is the bar.
- **State-management agnostic.** Widgets are pure: data in via constructor,
  events out via callbacks. No provider/bloc/riverpod dependency in `lib/`.
- **Money.** All monetary values use the `Money` type (backed by `Decimal`).
  Never use `double` for amounts.
- **RTL & a11y.** Every widget must work under `TextDirection.rtl` and expose
  sensible `Semantics`. Tap targets are at least 44×44 logical pixels.
- **No bundled illustrations.** Widgets expose `Widget? illustration` slots;
  the host app supplies imagery. Do not commit raster/vector art.
- **Lints.** `analysis_options.yaml` is strict. Run `dart fix --apply` and
  `flutter analyze` before pushing; CI fails on any analyzer issue.

## Commit messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(cards): add metallic sweep surface to BankVirtualCardWidget
fix(theme): apply preset font family to Material text themes
docs(readme): regenerate component screenshots
```

## Regenerating screenshots

The README screenshots are produced from the real widgets rendered via Flutter
web:

```bash
cd example
flutter build web -t lib/screenshot_harness.dart --release --no-web-resources-cdn --no-tree-shake-icons
cd ..
npm i -D playwright      # or have a Chromium available
node tool/screenshots.mjs
```

## Pull requests

1. Fork and create a topic branch.
2. Make your change with tests and (if visual) regenerated screenshots.
3. Ensure `flutter analyze` and `flutter test` pass.
4. Open a PR using the template and describe the change and its rationale.

By contributing you agree that your contributions are licensed under the
project's [MIT License](LICENSE).

## Releasing to pub.dev

Publishing is fully automated and driven by the version in
`pubspec.yaml`. There are no stored credentials and no personal access
tokens: pub.dev trusts the workflow over OIDC.

1. Bump `version:` in `pubspec.yaml` and add a matching `CHANGELOG.md`
   entry under a bare `## <version>` heading (semantic versioning).
2. Merge that change to `main`.
3. `Release on version bump` (`.github/workflows/release.yml`) sees the
   new version, creates a GitHub Release and `v<version>` tag with the
   CHANGELOG section as notes, then dispatches the publisher against that
   tag with `gh workflow run publish.yml --ref v<version>`.
4. `Publish to pub.dev` (`.github/workflows/publish.yml`) runs the
   `dart-lang/setup-dart` reusable workflow, which sets up Flutter,
   dry-runs, and publishes over OIDC.

A merge that does not change the version, or one whose version is already
tagged, publishes nothing. You cannot republish an existing version, so
every release needs a version bump.

Why the explicit dispatch in step 3: a tag created with the built-in
`GITHUB_TOKEN` does not trigger another workflow's `push:` listener
(GitHub's loop-prevention rule). `workflow_dispatch` is the exemption,
and it must target the tag ref (`--ref v<version>`), never a branch,
because pub.dev's trusted publishing only accepts an OIDC token whose ref
has refType `tag`.

### One-time setup on pub.dev

Enable trusted publishing once at
`https://pub.dev/packages/bank_ui_kit/admin` under Automated publishing:

- Enable publishing from GitHub Actions.
- Repository: `sayed3li97/bank-ui-kit`.
- Tag pattern: `v{{version}}`.
- Enable publishing from push events: checked.
- Enable publishing from workflow_dispatch events: checked.

Prefer to cut a release by hand? `git tag vX.Y.Z && git push origin
vX.Y.Z` still works; the tag push (or a manual `workflow_dispatch` of
`publish.yml` against the tag) publishes with no other setup.
