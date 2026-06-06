import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// A centralized service for Firebase Analytics.
/// All feature layers log events through this service and do not directly depend on the firebase_analytics SDK.
/// Event naming convention: all lowercase + underscore (compliant with Firebase's official recommendations)
class AnalyticsService {
  const AnalyticsService._();

  static final _analytics = FirebaseAnalytics.instance;

  /// Observer instances provided for use by GoRouter observers
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Internal generic log method (prints to the console during debugging)
  static Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      if (kDebugMode) {
        debugPrint('[Analytics] $name | ${params ?? {}}');
      }
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e) {
      // Analytics failures should not affect the main workflow; handle them silently.
      if (kDebugMode) debugPrint('[Analytics] ERROR: $e');
    }
  }

  /// Page browsing (GoRouter observer will call this automatically; manually add tabs for switching)
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: 'Flutter',
    );
    if (kDebugMode) debugPrint('[Analytics] screen_view | $screenName');
  }

  // Tab Switching
  // Tab index: 0=Home, 1=Audio Guide, 2=Events & Performances, 3=Tourist Attractions, 4=My Trip
  static const _tabNames = [
    'home',
    'audio_guide',
    'activity',
    'attraction',
    'my_journey',
  ];

  static Future<void> logTabSelected(int index) async {
    final name = index < _tabNames.length ? _tabNames[index] : 'unknown';
    await _log('tab_selected', {'tab_name': name, 'tab_index': index});
    // Synchronize and update the current Firebase view (so that DebugView can also see it)
    await logScreenView(name);
  }

  /// Users enter the attraction details page
  static Future<void> logAttractionViewed({
    required int id,
    required String name,
  }) async {
    await _log('attraction_viewed', {
      'attraction_id': id,
      'attraction_name': name,
    });
  }

  /// Apply attraction filter criteria to the user (launched after clicking "Apply")
  static Future<void> logAttractionFiltered({
    required String sortOrder,
    required bool openNow,
    required String timeSlot,
    required int categoryCount,
    required String district,
  }) async {
    await _log('attraction_filtered', {
      'sort_order': sortOrder,
      'open_now': openNow ? 'true' : 'false',
      'time_slot': timeSlot.isEmpty ? 'all' : timeSlot,
      'category_count': categoryCount,
      'district': district.isEmpty ? 'all' : district,
    });
  }

  /// Users enter the audio guide details page
  static Future<void> logAudioGuideViewed({
    required int id,
    required String title,
  }) async {
    await _log('audio_guide_viewed', {'guide_id': id, 'guide_title': title});
  }

  /// Start downloading the audio guide
  static Future<void> logAudioGuideDownloadStart({
    required int id,
    required String title,
  }) async {
    await _log('audio_guide_download_start', {
      'guide_id': id,
      'guide_title': title,
    });
  }

  /// Download successful
  static Future<void> logAudioGuideDownloadSuccess({
    required int id,
    required String title,
  }) async {
    await _log('audio_guide_download_success', {
      'guide_id': id,
      'guide_title': title,
    });
  }

  /// Download failed
  static Future<void> logAudioGuideDownloadFailure({
    required int id,
    required String title,
    required String error,
  }) async {
    await _log('audio_guide_download_failure', {
      'guide_id': id,
      'guide_title': title,
      'error': error.length > 100 ? error.substring(0, 100) : error,
    });
  }

  /// User presses play
  static Future<void> logAudioGuidePlayed({
    required int id,
    required String title,
    required int positionSeconds,
  }) async {
    await _log('audio_guide_played', {
      'guide_id': id,
      'guide_title': title,
      'position_seconds': positionSeconds,
    });
  }

  /// The user presses pause
  static Future<void> logAudioGuidePaused({
    required int id,
    required String title,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    await _log('audio_guide_paused', {
      'guide_id': id,
      'guide_title': title,
      'position_seconds': positionSeconds,
      'duration_seconds': durationSeconds,
    });
  }

  /// The guided tour has finished playing (the entire audio message has been heard).
  static Future<void> logAudioGuideCompleted({
    required int id,
    required String title,
    required int durationSeconds,
    required int steps,
  }) async {
    await _log('audio_guide_completed', {
      'guide_id': id,
      'guide_title': title,
      'duration_seconds': durationSeconds,
      'steps': steps,
    });
  }

  /// Users apply voice navigation filter criteria
  static Future<void> logAudioGuideFiltered({
    required String sortOrder,
    required String filterType,
  }) async {
    await _log('audio_guide_filtered', {
      'sort_order': sortOrder,
      'filter_type': filterType,
    });
  }

  /// User-shared audio guide
  static Future<void> logAudioGuideShared({
    required int id,
    required String title,
  }) async {
    await _log('audio_guide_shared', {'guide_id': id, 'guide_title': title});
  }

  /// Users enter the event details page
  static Future<void> logActivityViewed({
    required int id,
    required String title,
  }) async {
    await _log('activity_viewed', {'activity_id': id, 'activity_title': title});
  }

  /// User successfully added to calendar
  static Future<void> logActivityAddedToCalendar({
    required int id,
    required String title,
  }) async {
    await _log('activity_added_to_calendar', {
      'activity_id': id,
      'activity_title': title,
    });
  }

  /// User sharing activity
  static Future<void> logActivityShared({
    required int id,
    required String title,
  }) async {
    await _log('activity_shared', {'activity_id': id, 'activity_title': title});
  }

  /// Users apply activity filter criteria
  static Future<void> logActivityFiltered({
    required String sortOrder,
    required String statusFilter,
    required String feeFilter,
    required String district,
  }) async {
    await _log('activity_filtered', {
      'sort_order': sortOrder,
      'status_filter': statusFilter,
      'fee_filter': feeFilter,
      'district': district.isEmpty ? 'all' : district,
    });
  }

  /// User successfully set up reminder
  static Future<void> logReminderCreated({
    required String sourceType, // 'activity' | 'attraction' | 'audioGuide'
    required String sourceId,
    required String title,
    required int remindBeforeSeconds,
  }) async {
    await _log('reminder_created', {
      'source_type': sourceType,
      'source_id': sourceId,
      'item_title': title,
      'remind_before_seconds': remindBeforeSeconds,
    });
  }

  /// User-shared attractions
  static Future<void> logAttractionShared({
    required int id,
    required String name,
  }) async {
    await _log('attraction_shared', {
      'attraction_id': id,
      'attraction_name': name,
    });
  }

  /// The user clicks the "Start Navigation" button (callback after the map app launches).
  static Future<void> logNavigationRequested({
    required int id,
    required String name,
    required String sourceType, // 'attraction' | 'activity' | 'audioGuide'
  }) async {
    await _log('navigation_requested', {
      'item_id': id,
      'place_name': name,
      'source_type': sourceType,
    });
  }
}
