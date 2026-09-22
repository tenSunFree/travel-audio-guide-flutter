# travel-audio-guide-flutter

[![CI](https://github.com/tenSunFree/travel-audio-guide-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/tenSunFree/travel-audio-guide-flutter/actions/workflows/ci.yml)
[![CD](https://github.com/tenSunFree/travel-audio-guide-flutter/actions/workflows/cd.yml/badge.svg)](https://github.com/tenSunFree/travel-audio-guide-flutter/actions/workflows/cd.yml)
[![Staging Distribution](https://github.com/tenSunFree/travel-audio-guide-flutter/actions/workflows/deploy-staging.yml/badge.svg)](https://github.com/tenSunFree/travel-audio-guide-flutter/actions/workflows/deploy-staging.yml)
[![RC Distribution](https://github.com/tenSunFree/travel-audio-guide-flutter/actions/workflows/deploy-rc.yml/badge.svg)](https://github.com/tenSunFree/travel-audio-guide-flutter/actions/workflows/deploy-rc.yml)
[![codecov](https://codecov.io/gh/tenSunFree/travel-audio-guide-flutter/graph/badge.svg)](https://codecov.io/gh/tenSunFree/travel-audio-guide-flutter)
[![Flutter](https://img.shields.io/badge/Flutter-3.44.9-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.0-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2B%20Feature--First-4CAF50)](#architecture)
[![State](https://img.shields.io/badge/State-Riverpod-1565C0)](https://riverpod.dev)
[![Data](https://img.shields.io/badge/Data-Offline--First%20%2B%20Drift-009688)](#offline-first-experience)
[![Auth](https://img.shields.io/badge/Auth-Supabase-3FCF8E?logo=supabase&logoColor=white)](#authentication--profile)
[![Interop](https://img.shields.io/badge/Interop-Pigeon-673AB7)](https://pub.dev/packages/pigeon)
[![Testing](https://img.shields.io/badge/Testing-Unit%20%2B%20Widget-FF9800)](#testing)
[![Monitoring](https://img.shields.io/badge/Monitoring-Sentry-362D59?logo=sentry&logoColor=white)](#observability-and-analytics)
[![Analytics](https://img.shields.io/badge/Analytics-Firebase-FFCA28?logo=firebase&logoColor=black)](#observability-and-analytics)
[![Distribution](https://img.shields.io/badge/Distribution-Firebase%20App%20Distribution-FFCA28?logo=firebase&logoColor=black)](#git-workflow--cicd)
[![CodeRabbit Reviews](https://img.shields.io/badge/Code%20Review-CodeRabbit-FF6B35)](https://coderabbit.ai)
[![Dependabot](https://img.shields.io/badge/Dependencies-Dependabot-025E8C?logo=dependabot&logoColor=white)](https://github.com/tenSunFree/travel-audio-guide-flutter/security/dependabot)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

---

## Introduction

Travel audio guide app with local content caching, offline browsing, audio download, offline
playback, and a built-in media player, built using Riverpod, Drift, and Clean Architecture.

This project is for learning and technical practice.

See [CHANGELOG.md](./CHANGELOG.md) for release history.

---

## Related Backend

This app connects to a Go backend for authentication-aware profile management:

- [travel-audio-guide-go](https://github.com/tenSunFree/travel-audio-guide-go)

The backend provides a RESTful API built with Go, chi, PostgreSQL, pgxpool, sqlc, Supabase JWT (
ES256/JWKS), and Docker.
It handles JWT verification and user profile management.

The Flutter client authenticates directly against Supabase Auth, then attaches the resulting session
JWT to every request sent to this backend. See [Authentication & Profile](#authentication--profile)
below for how the two sides fit together.

---

## Preview

<p align="left">
  <img src="https://i.postimg.cc/zGzpG1Kv/Screenshot-20260609-220517.png" width="160"/>
  <img src="https://i.postimg.cc/jSMcWk4v/Screenshot-20260609-220206.png" width="160"/>
</p> 
<p align="left">
  <img src="https://i.postimg.cc/DZNmrcFJ/Screenshot-20260510-130756.png" width="160"/>
  <img src="https://i.postimg.cc/V6h5qF1f/Screenshot-20260510-130807.png" width="160"/>
  <img src="https://i.postimg.cc/RFYq7T9t/Screenshot-20260510-130814.png" width="160"/>
  <img src="https://i.postimg.cc/wvr3XkH3/Screenshot-20260510-130835.png" width="160"/>
</p> 
<p align="left">
  <img src="https://i.postimg.cc/brv12g1R/Screenshot-20260506-015654.png" width="160"/>
  <img src="https://i.postimg.cc/HnLbKD1R/Screenshot-20260506-014008.png" width="160"/>
  <img src="https://i.postimg.cc/NGb45rYP/368017.jpg" width="160"/>
  <img src="https://i.postimg.cc/PJ26XgL1/Screenshot-20260512-214659.png" width="160"/>
  <img src="https://i.postimg.cc/0j8WqkNk/Screenshot-20260512-214724.png" width="160"/>
</p> 
<p align="left">
  <img src="https://i.postimg.cc/J0hjBxjq/Screenshot-20260506-014016.png" width="160"/>
  <img src="https://i.postimg.cc/MTyvdBRR/Screenshot-20260603-233535.png" width="160"/>
  <img src="https://i.postimg.cc/3w8WGKTT/2.png" width="160"/>
  <img src="https://i.postimg.cc/YSd0fJpV/3.png" width="160"/>
  <img src="https://i.postimg.cc/QM8V7X3r/4.png" width="160"/>
</p> 
<p align="left">
  <img src="https://i.postimg.cc/zvfTR7T0/Screenshot-20260506-014013.png" width="160"/>
  <img src="https://i.postimg.cc/CLdwKD1R/Screenshot-20260603-233849.png" width="160"/>
  <img src="https://i.postimg.cc/5Ns3cK1B/368412.jpg" width="160"/>
  <img src="https://i.postimg.cc/2y2Hksq4/Screenshot-20260512-214810.png" width="160"/>
</p> 
<p align="left">
  <img src="https://i.postimg.cc/9fmz9WjS/5.png" width="160"/>
  <img src="https://i.postimg.cc/k5RgrwK1/Screenshot-20260514-125214.png" width="160"/>
</p> 

---

## Features

### Travel Content

- Browse attractions, audio guides, and activities from the Taipei Travel Open API
- Home page displays time-based recommendations, currently open attractions, and ongoing activities
  with direct navigation to filtered list views
- View attraction and activity detail pages with HTML description rendering
- Display activity metadata including event period, organizer, venue, ticket information, and
  related links
- Tap venue phone numbers to launch the native dialer
- Open external links and related URLs via `url_launcher`
- Network images loaded with disk caching and pixel-ratio-aware memory decoding to reduce redundant
  downloads and memory usage

### Offline-First Experience

- Cache-first architecture: serve content from the local Drift database instantly, then refresh from
  remote APIs
- Paginated API synchronization with upsert to keep local data up to date
- Offline browsing for previously synced travel content
- Reactive UI updates driven by Drift DAO streams
- Skeleton loading placeholders while remote data is loading and the local cache is empty

### Audio Guide

- Audio guide detail page with cover image, introduction, practical information, and playback
  controls
- Local `.mp3` download with file existence detection to avoid redundant downloads
- Offline playback for downloaded audio guides
- In-app audio player with play / pause state management
- Live step counting via Android sensor integration during audio guide playback
- Post-walk session summary after completing an audio guide walk

### Activity Integration

- Add activity dates to the native calendar as all-day events
- Correctly handle long-running exhibitions by applying an end-date offset for iOS all-day calendar
  events
- Share activity details through the native system share sheet

### Filtering and UX

- Sort and filter bottom sheets for attractions, audio guides, and activities
- Attraction list supports open status filter (currently open) and time slot recommendation filter (
  morning / afternoon / evening / night)
- Activity list supports activity status filter (all / currently available / coming soon within 7
  days)
- Home section action buttons navigate directly to filtered list pages with query parameters
- Active filter summary bars showing current filter conditions
- Consistent loading, empty state, and error state handling across all list pages

### Authentication & Profile

- Guest-first: attractions, activities, audio guides, offline playback, nearby recommendations, and
  the local journey/reminder list all work without signing in — the app's default route is Home, not
  Login
- Login is an optional feature, reachable from the account icon on the "My Journey" tab (or
  automatically when a route explicitly requires an account); it is never the app's forced entrance
- Email/password authentication via Supabase Auth, with sign-up and sign-in flows
- Session persistence across app restarts through the Supabase Flutter SDK; no manual token refresh
  logic required
- A dedicated `backendDioProvider` automatically attaches the current Supabase session's JWT as an
  `Authorization: Bearer` header on every request to the Go backend, kept as a separate Dio client
  from the one used for the Taipei Travel Open API; when signed out, requests are simply sent without
  the header instead of being blocked
- GoRouter redirect rules are whitelist-based: only routes explicitly listed in `protectedPaths`
  (`lib/core/router/auth_redirect.dart`) require a signed-in user — currently empty, reserved for
  future cloud-sync / personalization features. A signed-out user hitting a protected route is sent
  to `/login?from=<original path>` so they land back where they started after signing in
- Post-login navigation is owned entirely by `LoginPage`, not the router: it `pop`s back when pushed
  manually, or `go`s to the `from` route when redirected from a protected page. The router
  intentionally does not also redirect a signed-in user away from `/login`, to avoid both sides
  navigating on the same auth-state change
- User profile (`display_name`, `avatar_url`, `preferred_language`) is fetched from and updated
  through the Go backend's `GET`/`PUT /api/v1/me` endpoints only when signed in; the backend
  auto-creates a profile on first sign-in
- The Flutter client never sends `user_id` directly — it is derived server-side from the verified
  JWT's `claims.sub`

### Architecture

- Clean Architecture with separation of data, domain, and presentation layers
- Feature-first project structure
- State management with `flutter_riverpod` (`^3.4.2`); a handful of controllers still use the
  legacy `StateNotifier`/`StateNotifierProvider` API via `package:flutter_riverpod/legacy.dart`
  pending a follow-up migration to `Notifier`/`AsyncNotifier`
- Immutable domain entities, API models, and UI states with Freezed
- Local persistence with Drift and generated DAOs
- HTTP client with Dio and centralized request / response logging via Talker
- Type-safe Android native method channels generated with Pigeon
- Selected Clean Architecture boundaries and team conventions are enforced at analysis time through
  a project-owned Dart Analyzer Plugin (`packages/app_lints`) rather than relying solely on
  documentation and code review — see [Architecture Enforcement](#architecture-enforcement)

### Testing

- Unit tests for domain use cases and data repositories across activity, attraction, and audio guide
  features
- Mocked repository, remote data source, and local data source dependencies with `mocktail`
- Verified Model → Entity mapping, pagination behavior, download flow, local file existence checks,
  and exception propagation
- Widget tests for `AudioGuideListPage` covering loading state, populated list, empty state, error
  state, download/play button rendering, AppBar display, and reactive stream updates
- Widget tests for `AudioGuideTile` and `ConditionSummaryBar` covering display states, label
  rendering, reset button visibility, and tap callback behavior
- Shared test infrastructure in `test/test_helpers` with reusable entity fixtures, fake remote data
  sources, in-memory Drift database setup with provider overrides, and a fake playback service for
  isolating audio controller tests
- Local CI check script (`scripts/check.sh`) — run automatically via the `pre-push` hook — validates
  formatting, static analysis, tests with coverage enabled, and a staging debug APK build, and
  verifies that `coverage/lcov.info` is generated and contains valid source-file records
- Local coverage tooling (`scripts/coverage.sh`) generates LCOV coverage data and an HTML coverage
  report via `genhtml` or `lcov-viewer` for file-by-file and line-by-line inspection
- Test coverage is tracked via Codecov and uploaded automatically from CI (
  `flutter test --coverage` → `coverage/lcov.info`)

### Code Quality

- Static analysis baseline upgraded from `flutter_lints` to [
  `very_good_analysis`](https://pub.dev/packages/very_good_analysis) (10.2.0), a stricter,
  community-adopted Dart/Flutter lint set
- Generated files (`*.g.dart`, `*.freezed.dart`, per-flavor Firebase config) are excluded from
  analysis to keep signal-to-noise high
- Static analysis runs through the standard `flutter analyze` command; the standalone
  `packages/app_lints` package resolves its own dependencies before analysis in both CI and
  `scripts/check.sh`
- Lint violations are enforced in CI (`Static analysis` step in `ci.yml`) and locally via
  `scripts/check.sh` and the `pre-push` git hook
- A project-owned [`analysis_server_plugin`](https://pub.dev/packages/analysis_server_plugin)-based
  analyzer plugin (`packages/app_lints`) enforces selected Clean Architecture dependency rules and
  team naming/logging conventions directly inside `flutter analyze` —
  see [Architecture Enforcement](#architecture-enforcement)
- `pubspec.yaml` dependency ordering is enforced by the built-in `sort_pub_dependencies` lint and
  can be auto-fixed on demand by `scripts/quality/sort_pubspec_dependencies.py`

### Architecture Enforcement

The project includes a custom [
`analysis_server_plugin`](https://pub.dev/packages/analysis_server_plugin)-based Dart Analyzer
Plugin under `packages/app_lints/`.

It converts selected architecture boundaries and team conventions into diagnostics reported directly
through the standard analyzer pipeline. The same rules are available during local development and
enforced by the existing `flutter analyze` CI step without introducing a separate lint command.

#### Enabled rules

- `avoid_domain_data_import` — prevents domain code from importing the data layer, keeping
  dependency direction pointed inward toward domain abstractions
- `avoid_domain_flutter_import` — prevents domain code from importing `package:flutter/*`, keeping
  business logic independent from the Flutter framework
- `avoid_presentation_data_import` — prevents production presentation code from importing data-layer
  implementations directly; presentation should depend on domain abstractions such as UseCases or
  repository interfaces, while DI wires concrete implementations
- `avoid_debug_print` — prevents direct top-level `print()` / `debugPrint()` calls in favor of the
  centralized `AppLogger`, keeping application logging consistent through Talker
- `usecase_naming_convention` — enforces the `*UseCase` suffix for UseCase classes under
  `domain/usecases/`, while allowing supported helper types such as `*Params`, `*Result`, and
  `*Command`

#### Temporarily disabled rule

- `avoid_cross_feature_import` — implemented and verified, but currently disabled while the existing
  cross-feature dependency graph is reviewed and explicit policies are defined for legitimate
  composition points such as the app shell, navigation, DI, and public feature APIs

Tests remain fully analyzed by Dart and `very_good_analysis`. Architecture-specific custom
diagnostics may selectively exclude test paths where unit, widget, or integration tests need to
compose collaborators differently from production code.

Rules are registered in `packages/app_lints/lib/main.dart` and enabled individually through the root
`analysis_options.yaml`:

```yaml
plugins:
  app_lints:
    path: packages/app_lints
    diagnostics:
      avoid_domain_data_import: true
      avoid_domain_flutter_import: true
      avoid_presentation_data_import: true
      avoid_debug_print: true
      usecase_naming_convention: true
      avoid_cross_feature_import: false
```

`packages/app_lints` is a standalone Dart package with its own `pubspec.yaml` and
`analysis_options.yaml` — it is loaded through the analyzer `plugins:` configuration rather than as
a regular `pubspec.yaml` dependency of the main app. Because it is an independent Dart package, its
dependencies are resolved separately with `dart pub get`; both GitHub Actions CI and
`scripts/check.sh` perform this step before analysis.

Because it is a separate package, its `package:app_lints/...` self-imports only resolve once
`dart pub get` has been run **inside `packages/app_lints`**, not just at the repository root. If you
ever run analysis outside of the CI/`scripts/check.sh` entry points and see `uri_does_not_exist`
errors scoped to `packages/app_lints`, run `(cd packages/app_lints && fvm dart pub get)` once and
retry.

### Developer Experience

- Local CI check script (`scripts/check.sh`) mirrors the main GitHub Actions validation pipeline:
  dependency installation for both the main app and `packages/app_lints`, format check, static
  analysis, tests with coverage, LCOV report validation, and staging flavor debug APK build —
  validates only and never rewrites source files
- Local coverage tooling (`scripts/coverage.sh`) runs `flutter test --coverage`, verifies that
  `coverage/lcov.info` was generated, and produces an HTML coverage report via `genhtml` (lcov) or
  `lcov-viewer` (npm) when available; the report opens automatically in the default browser unless
  `NO_OPEN=1` is set
- Coverage exclusions reported to Codecov are maintained centrally in `codecov.yml`. Locally,
  `coverage/lcov.info` stays unfiltered (used by `scripts/check.sh` and uploaded as-is to Codecov);
  `scripts/coverage.sh` additionally produces a filtered `coverage/lcov.filtered.info`, used only
  for the local HTML report, to exclude generated files (`*.g.dart`, `*.freezed.dart`,
  `firebase_options_*.dart`) from local viewing
- Auto-formatting script (`scripts/format.sh`) runs `dart format` and writes changes directly, kept
  as a separate command from `check.sh` so CI can never silently rewrite source code
- Pubspec dependency sorter (`scripts/quality/sort_pubspec_dependencies.py`) auto-fixes ordering in
  `dependencies`, `dev_dependencies`, and `dependency_overrides` across project `pubspec.yaml`
  files; the built-in `sort_pub_dependencies` analyzer lint remains the source of truth for
  validation
- Environment health check script (`scripts/doctor.sh`) verifies required tooling (Git, Flutter,
  Dart), optional tooling (Java, FVM, gitleaks), `env/` configuration files, FVM version pinning,
  and installed Git hooks before development starts
- One-command onboarding script (`scripts/bootstrap.sh`) runs the environment check, installs
  Flutter dependencies, creates `env/dev.json` from the template if missing, and installs Git hooks
- Deterministic Android version code calculation (`scripts/compute_android_version.sh`) derives both
  `versionName` and `versionCode` from the git tag (e.g. `v1.0.8-rc.2` → version `1.0.8`, code
  `1000802`), shared by both `deploy-rc.yml` and `cd.yml` so RC and production builds never produce
  a lower version code than a previously distributed build
- Full-repository secret scan script (`scripts/secret-scan.sh`) runs `gitleaks detect` across the
  entire working tree and Git history, complementing the staged-only scan in the pre-commit hook
- Git hook automation (`scripts/setup-hooks.sh`) installs local quality gates in one command; hook
  templates live under `scripts/hooks/` and are copied into `.git/hooks/`:
  - `pre-commit`: Dart format check and a staged-changes secret scan (
    uses [gitleaks](https://github.com/gitleaks/gitleaks) when available, falling back to a
    built-in regex scanner otherwise)
  - `commit-msg`: validates commit messages against
    the [Conventional Commits](https://www.conventionalcommits.org/) format; branch names follow
    the same `<type>/description` convention (
    see [Git Workflow & CI/CD](#git-workflow--cicd))
  - `pre-push`: runs `scripts/check.sh`, including tests with coverage and LCOV validation, before
    code is pushed
- Code generation script (`scripts/codegen.sh`) runs `build_runner` for Drift, Freezed, and Riverpod
  Generator in a single command
- Development runner (`scripts/run_dev.sh`) injects environment config via `--dart-define-from-file`
  using the `staging` flavor (`lib/main_staging.dart`) by default, matching how the Android project
  declares product flavors, and supports optional device targeting
- CI-only runtime configuration script (`scripts/create_runtime_env.sh`) combines GitHub Actions
  Environment Variables/Secrets into a transient `env/ci.json`, so the three deployment workflows
  build with `--dart-define-from-file` instead of scattered per-flag `--dart-define` values, keeping
  local and CI configuration on the same mechanism
- Release build script (`scripts/build_release.sh`) validates that `env/release.json` exists before
  producing the release APK, with clear setup instructions on failure
- Optional Flutter version pinning via [FVM](https://fvm.app/): a shared helper (`scripts/_fvm.sh`)
  is sourced by every script under `scripts/`, so they all automatically switch from `flutter`/
  `dart` to `fvm flutter`/`fvm dart` once `.fvmrc` is present
- `Makefile` wraps the most common scripts (`make setup`, `make format`, `make check`,
  `make coverage`, `make secret-scan`, `make doctor`) for a shorter command surface

### Git Workflow & CI/CD

- Adopted a feature branch workflow with `develop`, `main`, and `release/*` protected branches
- Branch names are prefixed with the same type used in `commit-msg` (`feat/`, `fix/`, `chore/`,
  `docs/`, `refactor/`, `test/`, ...), e.g. `feat/supabase-auth-integration`,
  `fix/reminder-duplicate-schedule` — keeping branch names and commit types aligned makes it obvious
  what kind of change a branch introduces before opening the PR
- Enforced branch protection rules on `develop`, `main`, and `release/*`, blocking direct pushes and
  requiring Pull Requests with passing CI checks before merge
- Automated AI-assisted code review via CodeRabbit on every Pull Request to identify potential bugs,
  security concerns, maintainability issues, and consistency violations before merging
- Automated dependency updates via Dependabot for Flutter/Dart packages (`pub`) and GitHub Actions,
  with minor/patch updates grouped into a single PR, major version bumps deferred for manual review,
  and all updates gated behind the same required CI checks as manual PRs
  (security advisories always target `main` directly, per Dependabot's default behavior, while
  routine version updates target `develop`)
- Configured GitHub Actions CI for Pull Requests, including Dart format checks, static analysis,
  unit tests, and debug APK builds for both `staging` and `production` flavors
- Configured merge requirements so CI checks must pass and branches must be up to date before
  merging
- Built a release flow using `release/x.x.x` branches, version tags, automated release APK builds,
  and GitHub Releases
- Added a Pull Request template to standardize change summaries, test plans, and related issue
  tracking
- Set up Android `staging` and `production` product flavors with separate application IDs, enabling
  both builds to be installed side by side on the same device
- Automated staging build distribution via Firebase App Distribution on every push to `develop`
- Automated Release Candidate build distribution via Firebase App Distribution on `v*.*.*-rc.*` tag
  pushes
- Separated RC distribution from official production release tags to prevent accidental production
  releases
- Android `versionCode` is deterministically derived from the release tag (
  `scripts/compute_android_version.sh`) rather than the CI workflow run number, ensuring RC and
  production builds always compare correctly for in-place upgrades regardless of which workflow
  produced them
- Restored per-flavor Firebase configuration files, service account credentials, and the Android
  signing keystore from GitHub Secrets in CI, keeping sensitive files out of the repository
- Client-safe runtime configuration (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `BACKEND_BASE_URL`)
  is sourced from GitHub Environment Variables (`staging` / `production`) rather than Secrets, since
  these values are embedded in the shipped APK and are not confidential; only genuinely sensitive
  values (`SENTRY_DSN`, keystore credentials, Firebase service account) remain in Secrets
- Organized per-flavor Firebase Dart configuration files under `lib/config/firebase/` for a cleaner
  project structure

### Observability and Analytics

- Integrated Sentry for production-style error tracking and performance monitoring
- Wrapped Sentry SDK behind a centralized `MonitoringService` to keep feature code decoupled from
  third-party observability SDKs
- Instrumented key business flows with performance transactions: audio guide download, offline Drift
  cache synchronization, and audio player initialization
- Captured contextual breadcrumbs and exception metadata to support debugging of user-facing
  failures
- HTTP request breadcrumbs, failed request capture, and network tracing via `sentry_dio` — the
  authenticated `backendDioProvider` client omits request headers from Talker/Sentry logging to
  avoid capturing the Supabase JWT
- GoRouter navigation breadcrumbs and navigation-related performance traces via
  `SentryNavigatorObserver`
- Integrated Firebase Analytics to track key user interactions and understand how users navigate the
  app
- Centralized all event logging behind `AnalyticsService` to keep feature code decoupled from the
  Firebase SDK
- Automatic screen view tracking via `FirebaseAnalyticsObserver` registered in GoRouter alongside
  Sentry
- Custom events covering tab selection, content detail views, audio guide download outcomes,
  playback lifecycle events, list filter usage, share actions, calendar additions, navigation
  requests, and reminder creation
- Playback analytics include play, pause, and complete events with playback duration and step count
  metadata
- Firebase configuration files are restored in CI via GitHub Secrets to avoid exposing app
  configuration files in the public repository
- All runtime configuration, including the Sentry DSN, is injected at build time via
  `--dart-define-from-file` (`env/dev.json` / `env/release.json` locally, a CI-generated `env/ci.json`
  in GitHub Actions); local environment files are excluded from version control

### Journey Reminder

- Set local reminders for activities and manage them in a personal journey list
- Persist reminder records in the local Drift database for offline access and state recovery
- Schedule offline-capable local notifications for upcoming activities
- Support preset reminder lead times (on time, 5 minutes, 15 minutes, 30 minutes, 1 hour, or 1 day
  before) and a custom duration input
- Validate activity date ranges to prevent reminders from being created after an event has ended
- Handle Android exact alarm restrictions by falling back to inexact scheduling when exact alarm
  permission is unavailable
- Restore scheduled notifications after device reboot through Android boot receiver configuration

### Onboarding Experience

- Animated splash screen with staggered logo drop, text fade, and map-themed background
- First-launch welcome page introducing core features with sequential entry animations
- Persist onboarding completion state locally via SharedPreferences
- GoRouter `refreshListenable` integration for declarative redirect after onboarding; auth state is
  only consulted for explicitly protected routes (see [Authentication & Profile](#authentication--profile))
- Returning users — signed in or as a guest — skip onboarding and navigate directly to the home
  screen; authentication is never required to reach it

### Nearby Recommendations

- Nearby attractions and audio guides on the home screen with distance labels and nearest-first
  sorting
- Distance filters for attractions, activities, and audio guides: 500m, 1km, 3km, 5km, and unlimited
- Fallback UI for denied permission, permanently denied permission, and disabled location services
- Distance calculations are performed locally using Drift-cached data
- No background location tracking or additional backend geo-query APIs are required

---

## Tech Stack

- Clean Architecture  
  Layered software design (Independent domain logic, high testability, and strict separation of
  concerns)
- flutter_riverpod  
  Reactive state management & dependency injection (Compile-safe providers, automatic lifecycle
  management, and improved testability)
- Freezed  
  Code generation for immutable data models and sealed UI states (Eliminates hand-written
  `copyWith`, `==`, and `hashCode` boilerplate; keeps domain entities, API response models, and
  presentation states consistent and immutable)
- Dio  
  Robust HTTP client (Handles API communication, file downloading, and standardized request
  handling)
- supabase_flutter  
  Official Supabase client SDK (Handles email/password authentication, session persistence, and
  automatic token refresh; the current session's JWT is attached to Go backend requests via a
  dedicated Dio interceptor, kept separate from the Dio client used for the Taipei Travel Open API)
- audioplayers  
  Audio playback library (Manages local audio playback, playback state streams, and media controls)
- path_provider  
  File system utility (Provides application-specific directories for storing and retrieving
  downloaded `.mp3` files)
- cached_network_image + flutter_cache_manager  
  Network image caching (Replaces Image.network across all features, caches images to disk with a
  configurable stale period, applies pixel-ratio-aware memory decoding, and provides placeholder and
  error fallback widgets through a unified AppCachedNetworkImage component)
- Pigeon  
  Type-safe platform interop code generation (Bridges Flutter and native APIs with strongly typed
  messages, minimizes platform channel boilerplate, and improves maintainability for platform
  integration)
- Drift  
  Local persistence layer built on SQLite (Provides typed DAOs, reactive database streams, local
  caching, and offline browsing support)
- go_router  
  Declarative routing solution (Centralizes navigation logic, manages detail page routing via
  `extra` object passing, drives onboarding-aware and whitelist-based auth redirects, and improves
  maintainability across feature modules)
- sentry_flutter  
  Error and performance monitoring SDK (Captures unhandled exceptions, breadcrumbs, app start
  metrics, slow and frozen frames, and custom transactions for key business flows)
- sentry_dio  
  Official Dio integration for Sentry (Captures HTTP breadcrumbs, failed requests, and network
  tracing data with Sentry performance tracing support)
- firebase_core / firebase_analytics  
  Firebase initialization and user behavior tracking (Initializes Firebase through FlutterFire CLI
  configuration; tracks screen views, tab selections, content detail views, audio guide download
  outcomes, playback lifecycle events with duration and step count metadata, list filter usage,
  share and navigation actions, and reminder creation via a centralized `AnalyticsService`)
- flutter_local_notifications  
  Local notification scheduling (Schedules offline-capable activity reminders with timezone-aware
  delivery and Android alarm mode handling)
- timezone  
  Timezone-aware scheduling utility (Ensures reminder times are converted and scheduled consistently
  in the local timezone)
- permission_handler  
  Permission handling utility (Manages runtime permission requests for calendar write access when
  adding activity events to the native calendar)
- flutter_test  
  Official Flutter testing framework (Provides unit and widget testing utilities for validating
  business logic, UI behavior, and regression scenarios)
- mocktail  
  Mock library for Dart unit testing (Stubs repository and data source dependencies to isolate
  domain and data layer logic; verifies interaction behavior with `verify` and `verifyNever` without
  code generation)
- very_good_analysis  
  Stricter Dart/Flutter static analysis baseline, replacing the default `flutter_lints` set (
  Enforced through the standard `flutter analyze` command in CI and the `pre-push` hook; generated
  files are excluded from analysis)
- analysis_server_plugin (`packages/app_lints`)  
  Project-owned Dart analyzer plugin that turns selected Clean Architecture dependency rules and
  team conventions into native `flutter analyze` diagnostics
- shared_preferences  
  Lightweight local key-value storage (Persists onboarding completion state to control first-launch
  welcome flow and subsequent app startup routing)
- geolocator  
  Provides one-time foreground location retrieval and permission handling for nearby
  recommendations. Location is used only for local distance calculation against Drift-cached data,
  without background tracking or backend geo-query APIs.
- GitHub Actions  
  Pull Request validation, flavor-aware debug builds, release APK builds, and automated GitHub
  Releases
- Firebase App Distribution  
  Automated pre-release distribution for `staging` and Release Candidate builds via GitHub Actions
  and the Firebase CLI
- GitHub Branch Protection  
  Protected `develop`, `main`, and `release/*` branches with required PR checks before merge

---

## Environment

- Flutter SDK: `3.44.9`
- Dart SDK: `3.12.0`
- Flutter version pinning is optional via [FVM](https://fvm.app/).
  See [Local Development](#local-development) below.

### Runtime Configuration

The app reads the following values via `--dart-define` / `--dart-define-from-file` at build/run
time:

| Variable                   | Required | Notes                                                                                                    |
|-----------------------------|----------|------------------------------------------------------------------------------------------------------------|
| `SUPABASE_URL`              | Yes      | Your Supabase project URL                                                                                 |
| `SUPABASE_PUBLISHABLE_KEY`  | Yes      | Supabase publishable key. Safe to expose client-side by design — it is not a secret and relies on Supabase Row Level Security, not obscurity |
| `BACKEND_BASE_URL`          | Yes in CI / optional locally | CI (`scripts/create_runtime_env.sh`) requires this to be explicitly set — no silent fallback for staging/RC/production builds. Local `flutter run` without this key in `env/dev.json` falls back to `http://localhost:8080`. Use `http://10.0.2.2:8080` on the Android emulator to reach the host machine's backend; use your machine's LAN IP for physical device testing |
| `SENTRY_DSN`                | No       | Existing Sentry configuration                                                                              |

Values that must **never** be embedded in the Flutter app: the Supabase `service_role` / `secret`
key, and any backend-only JWT signing material. Those stay server-side in the
[travel-audio-guide-go](https://github.com/tenSunFree/travel-audio-guide-go) backend only.

If you use `env/dev.json` (see [Local Development](#local-development)), add the variables above to
your local copy; `env/example.json` should list them (without real values) so new contributors know
what to fill in.

In CI, the same variables are sourced from GitHub Environment **Variables** (`staging` and
`production` environments) — not Secrets, since `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` /
`BACKEND_BASE_URL` are all client-exposed by design. `scripts/create_runtime_env.sh` combines them
into a transient `env/ci.json`, consumed the same way as local `env/dev.json` / `env/release.json`
via `--dart-define-from-file`, so local and CI runtime configuration share one mechanism.

---

## Local Development

After cloning the repository, run one command to set up everything:

```bash
bash scripts/bootstrap.sh
```

This checks your local environment, installs Flutter dependencies, creates `env/dev.json` from
`env/example.json` if missing, and installs Git hooks.

### Useful commands

```bash
bash scripts/format.sh       # auto-format Dart files (modifies files)
bash scripts/check.sh        # local CI checks with coverage validation — never modifies files
bash scripts/coverage.sh     # generate coverage + local HTML report when tooling is available
bash scripts/secret-scan.sh  # full repo + git-history secret scan
bash scripts/doctor.sh       # check local environment
python scripts/quality/sort_pubspec_dependencies.py            # auto-fix pubspec.yaml dependency ordering
python scripts/quality/sort_pubspec_dependencies.py --dry-run  # preview pubspec.yaml sorting
```

Or via `Makefile`:

```bash
make setup
make format
make check
make coverage
make secret-scan
make doctor
```

### Static Analysis

This project uses [`very_good_analysis`](https://pub.dev/packages/very_good_analysis) as its lint
baseline (`analysis_options.yaml`), replacing the default `flutter_lints` set that ships with new
Flutter projects.

The project-local `packages/app_lints` Dart Analyzer Plugin participates in the same analyzer
pipeline for project-specific architecture and convention diagnostics.

```bash
flutter analyze
```

- Generated files (`*.g.dart`, `*.freezed.dart`, per-flavor Firebase config under
  `lib/config/firebase/`) are excluded from analysis
- A small set of rules are temporarily relaxed while the codebase catches up with the stricter
  baseline (see comments in `analysis_options.yaml`); new code is still expected to stay clean
- No separate custom-lint command is required — both the baseline and enabled `app_lints`
  diagnostics are reported through `flutter analyze`
- Because `packages/app_lints` is a standalone Dart package, its dependencies are resolved
  separately with `dart pub get`; this is handled automatically by GitHub Actions CI and
  `scripts/check.sh` — if you ever see `uri_does_not_exist` errors scoped to `packages/app_lints`,
  run `(cd packages/app_lints && fvm dart pub get)` once
- After changing `analysis_options.yaml` or `packages/app_lints`, restart the Dart Analysis Server
  if IDE diagnostics appear stale; command-line analysis can be rerun directly with
  `flutter analyze`

### Local Coverage Report

Run the coverage helper to generate an LCOV report and inspect coverage locally:

```bash
make coverage
```

or:

```bash
bash scripts/coverage.sh
```

The script:

- Runs `flutter test --coverage`
- Verifies that `coverage/lcov.info` was generated and contains source records
- Filters out generated files (`*.g.dart`, `*.freezed.dart`, `firebase_options_*.dart`) into
  `coverage/lcov.filtered.info`, for local HTML viewing only
- Generates `coverage/html/index.html` from the filtered report using `genhtml` (lcov) when
  available
- Falls back to `lcov-viewer` when `genhtml` is not installed
- Opens the HTML report automatically in the default browser

To generate the report without opening the browser:

```bash
NO_OPEN=1 make coverage
```

`coverage/lcov.info` itself stays unfiltered — it's what `scripts/check.sh` validates and what gets
uploaded to Codecov. `codecov.yml` remains the single source of truth for exclusions reported on the
Codecov dashboard; the local filtering only affects what you see in the local HTML report.

> `scripts/check.sh` already runs the test suite with coverage and validates the generated LCOV
> report during pre-push checks. `scripts/coverage.sh` is intended for interactive local coverage
> inspection and is not called by the pre-push hook, avoiding a duplicate full test run.

### Formatting Policy

- `format.sh` modifies files — run it locally whenever you want to auto-fix formatting
- `check.sh` only validates and never modifies files — used in `pre-push` and CI

This mirrors how CI should behave: CI passes or fails, it never silently rewrites source code.

### Line Endings

This repository includes a `.gitattributes` configuration that enforces LF line endings for shell
scripts, Git hook scripts, and the `Makefile`, regardless of the local Git `core.autocrlf` setting.

This keeps executable scripts consistent across operating systems and prevents Bash failures caused
by CRLF line endings, such as:

```text
scripts/_fvm.sh: line 17: $'\r': command not found
```

This is especially useful when the repository is checked out or edited in Windows environments while
scripts are executed through Bash, Git Bash, WSL, macOS, or Linux.

### Git Hooks

Hook templates live under `scripts/hooks/` and are installed into `.git/hooks/` with:

```bash
bash scripts/setup-hooks.sh
```

Installed hooks:

**`pre-commit`**

Runs fast, staged-only checks before every commit:

- Dart format validation for `lib`, `test`, and `pigeons`
- Secret scan on staged changes:
  - Uses `gitleaks` when it is installed
  - Falls back to a lightweight built-in regex-based scanner with a warning when `gitleaks` is not
    available

The regex-based fallback is intended as a basic local guard. For stronger secret detection, install
`gitleaks`.

**`commit-msg`**

Validates commit messages against the [Conventional Commits](https://www.conventionalcommits.org/)
format (`feat:`, `fix:`, `docs:`, `refactor:`, ...), so history stays readable and changelogs can be
generated automatically.

Merge and revert commits are exempt.

**`pre-push`**

Runs the local check script before every push:

```bash
bash scripts/check.sh
```

The local check script validates:

- Dependency installation / resolution (main app and `packages/app_lints`)
- Dart format validation
- Static analysis
- Unit tests
- Staging flavor debug APK build

This mirrors the main GitHub Actions CI checks locally, so common issues can be caught before
pushing.

Bypass any hook (not recommended): `git commit --no-verify` / `git push --no-verify`.

**Optional: Install `gitleaks`**

For stronger local secret detection:

```bash
brew install gitleaks                         # macOS
winget install --id Gitleaks.Gitleaks -e      # Windows
```

If you already use Scoop on Windows:

```bash
scoop install gitleaks
```

### Flutter Version Pinning (FVM)

This project can optionally pin its Flutter version with [FVM](https://fvm.app/) to keep local dev,
teammates, and CI on the same version:

```bash
dart pub global activate fvm
fvm install <version>      # e.g. the version matching pubspec.yaml's sdk constraint
fvm use <version> --pin    # creates .fvmrc
```

Once `.fvmrc` exists and `fvm` is installed, every script under `scripts/` automatically switches
from `flutter`/`dart` to `fvm flutter`/`fvm dart` (see `scripts/_fvm.sh`). No other configuration is
needed.

---

## Credits

This project is created for independent learning and demonstration purposes.
Special thanks to the original author for their open-source contribution.

---

## Notes

Image resources are for learning and purposes only. Please do not use them for commercial purposes.

If there is any infringement, please contact me for removal. Thank you.

---

## License

This repository is intended for learning and demonstration.

If you plan to open-source it, please choose a license and confirm third-party asset usage rights.

---

## Project Structure

> This is a high-level overview, not an exhaustive file listing — each feature under `lib/features/`
> follows the same `data / di / domain / presentation` layering shown for `activity` below. Run
`tree -L 4 --gitignore lib test` locally for the full, up-to-date tree.

```text
travel-audio-guide-flutter
├─ android
│  └─ app
│     └─ src
│        └─ main
│           └─ kotlin/com/tensunfree/flutter_travel_audio_guide/flutter_travel_audio_guide
│              ├─ HealthConnectApi.g.kt
│              ├─ HealthConnectManager.kt
│              ├─ MainActivity.kt
│              └─ StepSensorManager.kt
├─ ios
├─ linux / macos / web
├─ lib
│  ├─ app.dart
│  ├─ bootstrap.dart
│  ├─ main.dart
│  ├─ main_staging.dart
│  ├─ main_production.dart
│  ├─ config
│  │  └─ firebase
│  │     ├─ firebase_options_staging.dart
│  │     └─ firebase_options_production.dart
│  ├─ core                          # Cross-feature shared capabilities
│  │  ├─ analytics                  # AnalyticsService (Firebase wrapper)
│  │  ├─ constants                  # API constants (Taipei Travel Open API + Go backend), app colors
│  │  ├─ database                   # Drift AppDatabase, DAOs, tables
│  │  ├─ debug                      # Debug-only app options
│  │  ├─ error                      # Shared exception types
│  │  ├─ image                      # Cached network image manager
│  │  ├─ monitoring                 # MonitoringService (Sentry wrapper)
│  │  ├─ nearby                     # Location controller, nearby models/utils
│  │  ├─ network                    # Dio clients, Supabase JWT auth interceptor, log filter
│  │  ├─ preferences                # SharedPreferences provider
│  │  ├─ router                     # GoRouter config + route loaders (onboarding redirect; guest-first,
│  │  │                             # whitelist-based auth redirect via protectedPaths)
│  │  ├─ sync                       # Cross-feature Drift sync service
│  │  ├─ theme                      # AppTheme
│  │  ├─ utils                      # AppLogger, in-app log viewer
│  │  └─ widgets                    # Shared widgets (app bar, image, skeleton...)
│  └─ features
│     ├─ activity                   # Full data/di/domain/presentation layering
│     │  ├─ data
│     │  │  ├─ datasources
│     │  │  ├─ models
│     │  │  └─ repositories
│     │  ├─ di
│     │  ├─ domain
│     │  │  ├─ entities
│     │  │  ├─ repositories
│     │  │  └─ usecases
│     │  └─ presentation
│     │     ├─ controllers
│     │     ├─ enums
│     │     ├─ pages
│     │     └─ widgets
│     ├─ attraction                 # Same layering as activity
│     ├─ audio_guide                # Same layering, plus domain/services for playback
│     ├─ auth                       # Supabase email/password auth, session state
│     │  ├─ data
│     │  │  ├─ datasources          # SupabaseAuthDataSource
│     │  │  └─ repositories
│     │  ├─ di                      # authRepositoryProvider, authStateChangesProvider, isSignedInProvider
│     │  ├─ domain
│     │  │  ├─ entities             # AppUser
│     │  │  └─ repositories
│     │  └─ presentation
│     │     ├─ controllers          # LoginController
│     │     └─ pages                # LoginPage (optional feature page, not the app entrance)
│     ├─ home                       # Full layering: home feed + nearby recommendations
│     ├─ onboarding                 # Splash → welcome → home (guest-first) flow
│     ├─ profile                    # Calls Go backend GET/PUT /api/v1/me
│     │  ├─ data
│     │  │  ├─ datasources
│     │  │  ├─ models               # ProfileModel
│     │  │  └─ repositories
│     │  ├─ di                      # profileRepositoryProvider (backendDioProvider-backed)
│     │  ├─ domain
│     │  │  ├─ entities             # Profile
│     │  │  └─ repositories
│     │  └─ presentation
│     │     └─ controllers          # ProfileController (AsyncNotifier)
│     ├─ reminder                   # Journey reminders, local notifications; MyJourney also hosts
│     │                             # the optional account entry point into LoginPage
│     ├─ splash                     # Animated splash screen widgets
│     └─ step_tracking              # Android step sensor integration (Pigeon-based)
├─ packages
│  └─ app_lints                     # Project-local Dart Analyzer Plugin
│     ├─ analysis_options.yaml      # Static-analysis config for the plugin package
│     ├─ pubspec.yaml
│     └─ lib
│        ├─ main.dart               # Plugin entry point and rule registration
│        └─ src
│           ├─ path_utils.dart      # Shared path / feature helpers
│           ├─ architecture         # Architecture dependency diagnostics
│           └─ conventions          # Naming and logging diagnostics
├─ pigeons
│  └─ health_connect_api.dart
├─ scripts
│  ├─ hooks
│  │  ├─ commit-msg
│  │  ├─ pre-commit
│  │  └─ pre-push
│  ├─ quality
│  │  └─ sort_pubspec_dependencies.py   # Auto-fixes pubspec.yaml dependency ordering
│  ├─ _fvm.sh
│  ├─ bootstrap.sh
│  ├─ build_release.sh
│  ├─ check.sh
│  ├─ codegen.sh
│  ├─ create_runtime_env.sh             # CI-only: builds env/ci.json from GitHub vars/secrets
│  ├─ doctor.sh
│  ├─ format.sh
│  ├─ release.sh
│  ├─ run_dev.sh
│  ├─ secret-scan.sh
│  └─ setup-hooks.sh
├─ test
│  ├─ core                          # Mirrors lib/core/ (database, network, nearby, sync, widgets...)
│  ├─ features                      # Mirrors lib/features/, one subtree per feature
│  │  ├─ activity
│  │  ├─ attraction
│  │  ├─ audio_guide
│  │  ├─ home
│  │  ├─ onboarding
│  │  ├─ reminder
│  │  └─ step_tracking
│  ├─ app
│  │  └─ app_smoke_test.dart
│  └─ test_helpers                  # Shared fixtures, fakes, in-memory DB setup
├─ Makefile
├─ pubspec.lock
├─ pubspec.yaml
├─ analysis_options.yaml
└─ README.md
```