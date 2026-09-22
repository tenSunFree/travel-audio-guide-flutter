# Changelog

---

## v1.1.0 - 2026-09-13

### Added
- Supabase authentication integrated with the Go backend profile API
- Guest-first login flow — logging in is now optional; the router only gates protected paths instead of the whole app
- Unified runtime environment configuration across local development and CI

### Fixed
- Hardened 401 sign-out handling, login state flags, and profile account isolation
- Addressed CodeRabbit review findings on the auth flow: 401 sign-out, signup session propagation, reactive auth state, and stale profile request handling
- Restored public constructor parameter names on `HomeRepository`, `ActivityRepositoryImpl`, `AudioGuideRepositoryImpl`, and `AudioGuideListController`, broken by the `flutter_riverpod` 3.x upgrade, and added test coverage for the resulting `AsyncValue` fallback branches

### Internal
- Upgraded `flutter_riverpod` to 3.x: migrated legacy `StateNotifier`/`StateNotifierProvider` usage to `package:flutter_riverpod/legacy.dart`, replaced `AsyncValue.valueOrNull` with `.value`, and updated tests for Riverpod 3's stricter provider-pause semantics
- Documented remaining legacy `StateNotifier` usage pending a follow-up migration to `Notifier`/`AsyncNotifier`
- Bumped the FVM-pinned Flutter SDK to 3.44.9, and upgraded the Flutter SDK used in CI and the Android build config to match
- Upgraded `share_plus`, `talker`, and `geolocator`, resolving `win32` version conflicts
- Bumped `meta` and `test_api` transitive dependency versions
- Added unit and widget tests for the auth and profile features

---

## v1.0.9 - 2026-08-16

### Fixed
- Guarded `StepTrackingController` initialization against dispose races, and exposed an `initialized` future so callers can safely await readiness before use
- Fixed CI, staging, RC, and production deployment workflows failing to resolve `packages/app_lints`, the project's standalone Dart Analyzer Plugin, before running static analysis

### Internal
- Added a project-owned Dart Analyzer Plugin (`packages/app_lints`) enforcing Clean Architecture dependency boundaries and team naming/logging conventions directly inside `flutter analyze`
- Adopted `very_good_analysis` as the project-wide lint baseline
- Configured Dependabot version updates for the `pub` and `github-actions` ecosystems, and added explicit `permissions` blocks to CI workflows
- Added `AnalyticsService` unit tests covering the success and failure logging paths, closing the last Codecov patch-coverage gap
- Added test coverage for splash screen particle animation, attraction/activity models, and the step tracking provider

---

## v1.0.8 - 2026-07-28

### Internal
- Integrated Codecov coverage reporting into CI pipeline, and strengthened Codecov coverage policy with stricter project/patch thresholds
- Decoupled Codecov status check from overall CI completion
- Added `flutter analyze` to the pre-commit hook (previously only ran at pre-push), catching lint issues before commit instead of after push
- Added coverage run on pre-push with local HTML report tooling for easier local inspection
- Extracted `NearbyAttractionTile` and `ActivityLinkRow` into standalone widgets, with accompanying widget tests
- Added `NotificationServiceImpl` unit tests
- Added `path_provider_platform_interface` and `plugin_platform_interface` as explicit dev dependencies
- Fixed `unnecessary_underscores` lint violations in test files
- Increased overall unit/widget test line coverage from 10% to 70.5% across multiple incremental batches (DI provider wiring, location controller, reminder/activity/attraction/audio_guide/home features, etc.)

No user-facing features or fixes in this release.

---

## v1.0.7 - 2026-07-10

### Internal
- Added pre-commit hook with Dart format check and gitleaks-backed staged secret scan
- Added fallback regex-based secret scanner for environments without gitleaks installed
- Added commit-msg hook to enforce Conventional Commits format
- Added bootstrap, doctor, format, codegen, secret-scan, and release scripts for local development workflow
- Added FVM support for consistent Flutter/Dart command execution across local scripts and hooks
- Updated README with pre-commit hook setup and gitleaks integration instructions

No user-facing features or fixes in this release.

## v1.0.6 - 2026-07-02

### Internal
- Moved firebase_options files from lib/ root into lib/config/firebase/ for better project structure
- Documented Firebase App Distribution workflow
- Refactored HomePage to use ConsumerStatefulWidget and improved location handling
- Fixed pre-push check to build staging APK instead of unflavored debug build

## v1.0.5 - 2026-06-27

### Internal
- Migrated SharedPreferences to SharedPreferencesWithCache, and refactored using the Repository pattern
- Set up an automated Firebase App Distribution pipeline to distribute staging and RC builds to testers (CI/CD only, no impact on app behavior)
- Fixed CI/CD workflow issues including incomplete Firebase config restoration and Dart format check failures

No user-facing features or fixes in this release.

## v1.0.4 - 2026-06-18

### Added
- Nearby attractions section on the home screen, auto-expanding search radius from 3km to 5km to 10km
- Distance labels on attraction, activity, and audio guide list items
- Nearest-first sorting for attractions, activities, and audio guides
- Distance filters: 500m, 1km, 3km, 5km, and unlimited
- Open-now + nearby compound filtering for attractions
- Today and upcoming status filtering for activities
- Fallback UI for denied, permanently denied, and disabled location service
- Coordinate validation to prevent crashes on missing or invalid location data
- Audio guide coordinate fallback through matched attraction
- Nearby enabled state persisted across app restarts

## v1.0.3 - 2026-06-13

### Fixed
- 修正 CD workflow 未還原 Firebase 設定檔，導致 release build 在靜態分析階段失敗的問題

## v1.0.2 - 2026-06-12

### Added
- 新增歡迎畫面與啟動畫面動畫
- 新增圖片快取機制，支援依顯示尺寸設定快取圖片大小，減少不必要的圖片解碼與記憶體消耗

## v1.0.1 - 2026-05-12

### Added
- 新增詳情頁導航與分享按鈕

## v1.0.0 - 2026-05-07

### Added
- 旅遊語音導覽核心功能
- 景點列表、搜尋、排序與篩選
- 活動列表與行事曆整合
- 語音導覽下載與離線播放
- 本機資料庫快取（Drift + SQLite）
- 背景資料同步機制
- GitHub Actions CI/CD 自動化流程
- 本機開發腳本（`scripts/check.ps1`、`scripts/codegen.ps1`、`scripts/release.ps1`）