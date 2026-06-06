# travel-audio-guide-flutter

[![CI](https://github.com/tenSunFree/travel-audio-guide-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/tenSunFree/travel-audio-guide-flutter/actions/workflows/ci.yml)
[![CD](https://github.com/tenSunFree/travel-audio-guide-flutter/actions/workflows/cd.yml/badge.svg)](https://github.com/tenSunFree/travel-audio-guide-flutter/actions/workflows/cd.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.10-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.9-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2B%20Feature--First-4CAF50)](#architecture)
[![State](https://img.shields.io/badge/State-Riverpod-1565C0)](https://riverpod.dev)
[![Data](https://img.shields.io/badge/Data-Offline--First%20%2B%20Drift-009688)](#offline-first-experience)
[![Interop](https://img.shields.io/badge/Interop-Pigeon-673AB7)](https://pub.dev/packages/pigeon)
[![Testing](https://img.shields.io/badge/Testing-Unit%20%2B%20Widget-FF9800)](#testing)
[![Monitoring](https://img.shields.io/badge/Monitoring-Sentry-362D59?logo=sentry&logoColor=white)](#observability-and-analytics)
[![Analytics](https://img.shields.io/badge/Analytics-Firebase-FFCA28?logo=firebase&logoColor=black)](#observability-and-analytics)

---

## Introduction

Travel audio guide app with local content caching, offline browsing, audio download, offline playback, and a built-in media player, built using Riverpod, Drift, and Clean Architecture.

This project is for learning and technical practice.

---

## Preview

<p align="left">
  <img src="https://i.postimg.cc/DZNmrcFJ/Screenshot-20260510-130756.png" width="160"/>
  <img src="https://i.postimg.cc/V6h5qF1f/Screenshot-20260510-130807.png" width="160"/>
  <img src="https://i.postimg.cc/RFYq7T9t/Screenshot-20260510-130814.png" width="160"/>
  <img src="https://i.postimg.cc/wvr3XkH3/Screenshot-20260510-130835.png" width="160"/>
</p> 
<p align="left">
  <img src="https://i.postimg.cc/brv12g1R/Screenshot-20260506-015654.png" width="160"/>
  <img src="https://i.postimg.cc/HnLb7zbw/Screenshot-20260506-014008.png" width="160"/>
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
- Home page displays time-based recommendations, currently open attractions, and ongoing activities with direct navigation to filtered list views
- View attraction and activity detail pages with HTML description rendering
- Display activity metadata including event period, organizer, venue, ticket information, and related links
- Tap venue phone numbers to launch the native dialer
- Open external links and related URLs via `url_launcher`

### Offline-First Experience

- Cache-first architecture: serve content from the local Drift database instantly, then refresh from remote APIs
- Paginated API synchronization with upsert to keep local data up to date
- Offline browsing for previously synced travel content
- Reactive UI updates driven by Drift DAO streams
- Skeleton loading placeholders while remote data is loading and the local cache is empty

### Audio Guide

- Audio guide detail page with cover image, introduction, practical information, and playback controls
- Local `.mp3` download with file existence detection to avoid redundant downloads
- Offline playback for downloaded audio guides
- In-app audio player with play / pause state management
- Live step counting via Android sensor integration during audio guide playback
- Post-walk session summary after completing an audio guide walk

### Activity Integration

- Add activity dates to the native calendar as all-day events
- Correctly handle long-running exhibitions by applying an end-date offset for iOS all-day calendar events
- Share activity details through the native system share sheet

### Filtering and UX

- Sort and filter bottom sheets for attractions, audio guides, and activities
- Attraction list supports open status filter (currently open) and time slot recommendation filter (morning / afternoon / evening / night)
- Activity list supports activity status filter (all / currently available / coming soon within 7 days)
- Home section action buttons navigate directly to filtered list pages with query parameters
- Active filter summary bars showing current filter conditions
- Consistent loading, empty state, and error state handling across all list pages

### Architecture

- Clean Architecture with separation of data, domain, and presentation layers
- Feature-first project structure
- State management with `flutter_riverpod`
- Immutable domain entities, API models, and UI states with Freezed
- Local persistence with Drift and generated DAOs
- HTTP client with Dio and centralized request / response logging via Talker
- Type-safe Android native method channels generated with Pigeon

### Testing

- Unit tests for domain use cases and data repositories across activity, attraction, and audio guide features
- Mocked repository, remote data source, and local data source dependencies with `mocktail`
- Verified Model → Entity mapping, pagination behavior, download flow, local file existence checks, and exception propagation
- Local CI check script for formatting, static analysis, unit tests, and debug APK build validation

### Observability and Analytics

- Integrated Sentry for production-style error tracking and performance monitoring
- Wrapped Sentry SDK behind a centralized `MonitoringService` to keep feature code decoupled from third-party observability SDKs
- Instrumented key business flows with performance transactions: audio guide download, offline Drift cache synchronization, and audio player initialization
- Captured contextual breadcrumbs and exception metadata to support debugging of user-facing failures
- HTTP request breadcrumbs, failed request capture, and network tracing via `sentry_dio`
- GoRouter navigation breadcrumbs and navigation-related performance traces via `SentryNavigatorObserver`
- Integrated Firebase Analytics to track key user interactions and understand how users navigate the app
- Centralized all event logging behind `AnalyticsService` to keep feature code decoupled from the Firebase SDK
- Automatic screen view tracking via `FirebaseAnalyticsObserver` registered in GoRouter alongside Sentry
- Custom events covering tab selection, content detail views, audio guide download outcomes, playback lifecycle events, list filter usage, share actions, calendar additions, navigation requests, and reminder creation
- Playback analytics include play, pause, and complete events with playback duration and step count metadata
- Firebase configuration files are restored in CI via GitHub Secrets to avoid exposing app configuration files in the public repository
- Sentry DSN is injected at build time via `--dart-define-from-file`; local environment files are excluded from version control

### Journey Reminder

- Set local reminders for activities and manage them in a personal journey list
- Persist reminder records in the local Drift database for offline access and state recovery
- Schedule offline-capable local notifications for upcoming activities
- Support preset reminder lead times (on time, 5 minutes, 15 minutes, 30 minutes, 1 hour, or 1 day before) and a custom duration input
- Validate activity date ranges to prevent reminders from being created after an event has ended
- Handle Android exact alarm restrictions by falling back to inexact scheduling when exact alarm permission is unavailable
- Restore scheduled notifications after device reboot through Android boot receiver configuration

---

## Tech Stack

- Clean Architecture  
  Layered software design (Independent domain logic, high testability, and strict separation of concerns)
- flutter_riverpod  
  Reactive state management & dependency injection (Compile-safe providers, automatic lifecycle management, and improved testability)
- Freezed  
  Code generation for immutable data models and sealed UI states (Eliminates hand-written `copyWith`, `==`, and `hashCode` boilerplate; keeps domain entities, API response models, and presentation states consistent and immutable)
- Dio  
  Robust HTTP client (Handles API communication, file downloading, and standardized request handling)
- audioplayers  
  Audio playback library (Manages local audio playback, playback state streams, and media controls)
- path_provider  
  File system utility (Provides application-specific directories for storing and retrieving downloaded `.mp3` files)  
- Pigeon  
  Type-safe platform interop code generation (Bridges Flutter and native APIs with strongly typed messages, minimizes platform channel boilerplate, and improves maintainability for platform integration)
- Drift  
  Local persistence layer built on SQLite (Provides typed DAOs, reactive database streams, local caching, and offline browsing support)
- go_router  
  Declarative routing solution (Centralizes navigation logic, manages detail page routing via `extra` object passing, and improves maintainability across feature modules)
- sentry_flutter  
  Error and performance monitoring SDK (Captures unhandled exceptions, breadcrumbs, app start metrics, slow and frozen frames, and custom transactions for key business flows)
- sentry_dio  
  Official Dio integration for Sentry (Captures HTTP breadcrumbs, failed requests, and network tracing data with Sentry performance tracing support)
- firebase_core / firebase_analytics  
  Firebase initialization and user behavior tracking (Initializes Firebase through FlutterFire CLI configuration; tracks screen views, tab selections, content detail views, audio guide download outcomes, playback lifecycle events with duration and step count metadata, list filter usage, share and navigation actions, and reminder creation via a centralized `AnalyticsService`)
- flutter_local_notifications  
  Local notification scheduling (Schedules offline-capable activity reminders with timezone-aware delivery and Android alarm mode handling)
- timezone  
  Timezone-aware scheduling utility (Ensures reminder times are converted and scheduled consistently in the local timezone)
- permission_handler  
  Permission handling utility (Manages runtime permission requests for calendar write access when adding activity events to the native calendar)
- flutter_test  
  Official Flutter testing framework (Provides unit and widget testing utilities for validating business logic, UI behavior, and regression scenarios)
- mocktail  
  Mock library for Dart unit testing (Stubs repository and data source dependencies to isolate domain and data layer logic; verifies interaction behavior with `verify` and `verifyNever` without code generation)

---

## Environment

- Flutter SDK: `3.38.10`
- Dart SDK: `3.10.9`

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

```
travel_audio_guide_flutter
...
├─ android
│  ...
│  ├─ app
│  │  ├─ build.gradle.kts
│  │  └─ src
│  │     ...
│  │     │  ├─ kotlin
│  │     │  │  └─ com
│  │     │  │     └─ tensunfree
│  │     │  │        └─ flutter_travel_audio_guide
│  │     │  │           └─ flutter_travel_audio_guide
│  │     │  │              ├─ HealthConnectApi.g.kt
│  │     │  │              ├─ HealthConnectManager.kt
│  │     │  │              ├─ MainActivity.kt
│  │     │  │              └─ StepSensorManager.kt
│  │  ...
├─ ios
│  ├─ ...
├─ lib
│  ├─ app.dart
│  ├─ core
│  │  ├─ constants
│  │  │  ├─ api_constants.dart
│  │  │  └─ app_colors.dart
│  │  ├─ database
│  │  │  ├─ app_database.dart
│  │  │  ├─ app_database.g.dart
│  │  │  ├─ daos
│  │  │  │  ├─ activity_dao.dart
│  │  │  │  ├─ activity_dao.g.dart
│  │  │  │  ├─ attraction_dao.dart
│  │  │  │  ├─ attraction_dao.g.dart
│  │  │  │  ├─ audio_guide_dao.dart
│  │  │  │  ├─ audio_guide_dao.g.dart
│  │  │  │  ├─ sync_meta_dao.dart
│  │  │  │  └─ sync_meta_dao.g.dart
│  │  │  ├─ database_provider.dart
│  │  │  └─ tables
│  │  │     ├─ activity_table.dart
│  │  │     ├─ attraction_table.dart
│  │  │     ├─ audio_guide_table.dart
│  │  │     └─ sync_meta_table.dart
│  │  ├─ error
│  │  │  └─ exceptions.dart
│  │  ├─ network
│  │  │  ├─ dio_log_filter.dart
│  │  │  └─ network_providers.dart
│  │  ├─ sync
│  │  │  ├─ app_sync_service.dart
│  │  │  └─ sync_providers.dart
│  │  ├─ theme
│  │  │  └─ app_theme.dart
│  │  └─ utils
│  │     ├─ app_logger.dart
│  │     └─ app_log_page.dart
│  ├─ features
│  │  ├─ activity
│  │  │  ├─ data
│  │  │  │  ├─ datasources
│  │  │  │  │  └─ activity_remote_data_source.dart
│  │  │  │  ├─ models
│  │  │  │  │  ├─ activity_model.dart
│  │  │  │  │  └─ activity_page_model.dart
│  │  │  │  └─ repositories
│  │  │  │     └─ activity_repository_impl.dart
│  │  │  ├─ di
│  │  │  │  └─ activity_providers.dart
│  │  │  ├─ domain
│  │  │  │  ├─ entities
│  │  │  │  │  ├─ activity.dart
│  │  │  │  │  └─ activity_page.dart
│  │  │  │  ├─ repositories
│  │  │  │  │  └─ activity_repository.dart
│  │  │  │  └─ usecases
│  │  │  │     └─ get_activities_usecase.dart
│  │  │  └─ presentation
│  │  │     ├─ controllers
│  │  │     │  └─ activity_list_controller.dart
│  │  │     ├─ enums
│  │  │     │  └─ activity_sort_filter_enums.dart
│  │  │     ├─ pages
│  │  │     │  ├─ activity_detail_page.dart
│  │  │     │  └─ activity_list_page.dart
│  │  │     └─ widgets
│  │  │        ├─ activity_condition_summary_bar.dart
│  │  │        ├─ activity_sort_filter_bottom_sheet.dart
│  │  │        └─ activity_tile.dart
│  │  ├─ attraction
│  │  │  ├─ data
│  │  │  │  ├─ datasources
│  │  │  │  │  └─ attraction_remote_data_source.dart
│  │  │  │  ├─ models
│  │  │  │  │  ├─ attraction_model.dart
│  │  │  │  │  └─ attraction_page_model.dart
│  │  │  │  └─ repositories
│  │  │  │     └─ attraction_repository_impl.dart
│  │  │  ├─ di
│  │  │  │  └─ attraction_providers.dart
│  │  │  ├─ domain
│  │  │  │  ├─ entities
│  │  │  │  │  ├─ attraction.dart
│  │  │  │  │  └─ attraction_page.dart
│  │  │  │  ├─ repositories
│  │  │  │  │  └─ attraction_repository.dart
│  │  │  │  └─ usecases
│  │  │  │     ├─ get_attractions_usecase.dart
│  │  │  │     └─ get_attraction_categories_usecase.dart
│  │  │  └─ presentation
│  │  │     ├─ controllers
│  │  │     │  └─ attraction_list_controller.dart
│  │  │     ├─ enums
│  │  │     │  └─ attraction_sort_filter_enums.dart
│  │  │     ├─ pages
│  │  │     │  ├─ attraction_detail_page.dart
│  │  │     │  └─ attraction_list_page.dart
│  │  │     └─ widgets
│  │  │        ├─ attraction_condition_summary_bar.dart
│  │  │        ├─ attraction_sort_filter_bottom_sheet.dart
│  │  │        └─ attraction_tile.dart
│  │  ├─ audio_guide
│  │  │  ├─ data
│  │  │  │  ├─ datasources
│  │  │  │  │  ├─ audio_guide_local_data_source.dart
│  │  │  │  │  └─ audio_guide_remote_data_source.dart
│  │  │  │  ├─ models
│  │  │  │  │  ├─ audio_guide_model.dart
│  │  │  │  │  └─ audio_guide_page_model.dart
│  │  │  │  ├─ repositories
│  │  │  │  │  └─ audio_guide_repository_impl.dart
│  │  │  │  └─ services
│  │  │  │     └─ audio_playback_service_impl.dart
│  │  │  ├─ di
│  │  │  │  └─ audio_guide_providers.dart
│  │  │  ├─ domain
│  │  │  │  ├─ entities
│  │  │  │  │  ├─ audio_guide.dart
│  │  │  │  │  ├─ audio_guide_page.dart
│  │  │  │  │  └─ audio_playback_state.dart
│  │  │  │  ├─ repositories
│  │  │  │  │  └─ audio_guide_repository.dart
│  │  │  │  ├─ services
│  │  │  │  │  └─ audio_playback_service.dart
│  │  │  │  └─ usecases
│  │  │  │     ├─ download_audio_guide_usecase.dart
│  │  │  │     └─ get_audio_guides_usecase.dart
│  │  │  └─ presentation
│  │  │     ├─ controllers
│  │  │     │  ├─ audio_guide_list_controller.dart
│  │  │     │  └─ audio_player_controller.dart
│  │  │     ├─ enums
│  │  │     │  └─ sort_filter_enums.dart
│  │  │     ├─ pages
│  │  │     │  ├─ audio_guide_detail_page.dart
│  │  │     │  └─ audio_guide_list_page.dart
│  │  │     └─ widgets
│  │  │        ├─ audio_guide_tile.dart
│  │  │        ├─ common_app_bar.dart
│  │  │        ├─ condition_summary_bar.dart
│  │  │        └─ sort_filter_bottom_sheet.dart
│  │  ├─ home
│  │  │  └─ presentation
│  │  │     └─ pages
│  │  │        └─ main_tab_page.dart
│  │  └─ step_tracking
│  │     ├─ data
│  │     │  ├─ health_connect_api.g.dart
│  │     │  └─ services
│  │     │     └─ step_tracking_service_impl.dart
│  │     ├─ di
│  │     │  └─ step_tracking_providers.dart
│  │     ├─ domain
│  │     │  ├─ entities
│  │     │  │  └─ exercise_summary_data.dart
│  │     │  └─ services
│  │     │     └─ step_tracking_service.dart
│  │     └─ presentation
│  │        ├─ controllers
│  │        │  └─ step_tracking_controller.dart
│  │        ├─ enums
│  │        │  └─ step_tracking_source.dart
│  │        └─ widgets
│  │           └─ session_summary_card.dart
│  └─ main.dart
├─ linux
│  ...
├─ macos
│  ...
├─ pigeons
│  └─ health_connect_api.dart
├─ pubspec.lock
├─ pubspec.yaml
├─ README.md
├─ test
│  ├─ app
│  │  └─ app_smoke_test.dart
│  ├─ features
│  │  ├─ activity
│  │  │  ├─ data
│  │  │  │  └─ repositories
│  │  │  │     └─ activity_repository_impl_test.dart
│  │  │  └─ domain
│  │  │     └─ get_activities_usecase_test.dart
│  │  ├─ attraction
│  │  │  ├─ data
│  │  │  │  └─ repositories
│  │  │  │     └─ attraction_repository_impl_test.dart
│  │  │  └─ domain
│  │  │     └─ get_attractions_usecase_test.dart
│  │  └─ audio_guide
│  │     ├─ data
│  │     │  ├─ models
│  │     │  │  └─ audio_guide_model_test.dart
│  │     │  └─ repositories
│  │     │     └─ audio_guide_repository_impl_test.dart
│  │     ├─ domain
│  │     │  ├─ audio_guide_domain_test.dart
│  │     │  └─ audio_guide_usecase_test.dart
│  │     └─ presentation
│  │        ├─ controllers
│  │        │  ├─ audio_guide_list_controller_test.dart
│  │        │  ├─ audio_guide_list_state_test.dart
│  │        │  └─ audio_player_controller_test.dart
│  │        ├─ pages
│  │        │  └─ audio_guide_list_page_test.dart
│  │        └─ widgets
│  │           ├─ audio_guide_tile_test.dart
│  │           └─ condition_summary_bar_test.dart
│  └─ test_helpers
│     ├─ app_test_harness.dart
│     ├─ audio_guide_fakes.dart
│     └─ audio_guide_fixtures.dart
├─ web
│  ...
```
