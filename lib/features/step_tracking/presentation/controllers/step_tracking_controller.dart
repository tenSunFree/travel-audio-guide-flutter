import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/domain/entities/exercise_summary_data.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/domain/services/step_tracking_service.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/presentation/enums/step_tracking_source.dart';

class StepTrackingState {
  const StepTrackingState({
    this.isAvailable = false,
    this.hasHealthConnectPermission = false,
    this.hasSensorPermission = false,
    this.source = StepTrackingSource.sensor, // Preset sensor
    this.steps = 0,
    this.distance = 0.0,
    this.isTracking = false,
  });

  final bool isAvailable;
  final bool hasHealthConnectPermission;
  final bool hasSensorPermission;
  final StepTrackingSource source;
  final int steps;
  final double distance;
  final bool isTracking;

  // Convenience for external callers to determine whether the current
  // source is ready
  bool get isReady => source == StepTrackingSource.sensor
      ? isAvailable && hasSensorPermission
      : isAvailable && hasHealthConnectPermission;

  StepTrackingState copyWith({
    bool? isAvailable,
    bool? hasHealthConnectPermission,
    bool? hasSensorPermission,
    StepTrackingSource? source,
    int? steps,
    double? distance,
    bool? isTracking,
  }) {
    return StepTrackingState(
      isAvailable: isAvailable ?? this.isAvailable,
      hasHealthConnectPermission:
          hasHealthConnectPermission ?? this.hasHealthConnectPermission,
      hasSensorPermission: hasSensorPermission ?? this.hasSensorPermission,
      source: source ?? this.source,
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      isTracking: isTracking ?? this.isTracking,
    );
  }
}

class StepTrackingController extends StateNotifier<StepTrackingState> {
  StepTrackingController(this._service) : super(const StepTrackingState()) {
    // Save the Future returned by _init() so external callers (especially tests)
    // can explicitly wait for initialization to complete instead of guessing
    // with microtasks/milliseconds.
    initialized = _init();
  }

  final StepTrackingService _service;
  Timer? _timer;
  DateTime? _sessionStart;
  String? _guideName;

  /// Signal that initialization is complete. Tests can `await controller.initialized;`
  /// to ensure all awaits inside `_init()` have finished before making assertions.
  late final Future<void> initialized;

  Future<void> _init() async {
    final available = await _service.checkAvailability();
    // After each await, verify the controller is still mounted. This prevents
    // writing to a disposed state if an autoDispose provider or widget was
    // unmounted while awaiting, which would cause "Tried to use StepTrackingController after dispose was called".
    if (!mounted) return;
    state = state.copyWith(isAvailable: available);
    // Health Connect permission
    var hcGranted = await _service.hasPermissions();
    if (!mounted) return;
    if (!hcGranted) {
      hcGranted = await _service.requestPermissions();
      if (!mounted) return;
    }
    state = state.copyWith(hasHealthConnectPermission: hcGranted);
    // Sensor permission
    var sensorGranted = await _service.hasActivityRecognitionPermission();
    if (!mounted) return;
    if (!sensorGranted) {
      sensorGranted = await _service.requestActivityRecognitionPermission();
      if (!mounted) return;
    }
    state = state.copyWith(hasSensorPermission: sensorGranted);
  }

  /// Called by the detail page whenever playback transitions to playing.
  void onPlaybackStarted(String guideName) {
    if (!state.isReady) return;
    _guideName = guideName;
    if (state.source == StepTrackingSource.sensor) {
      if (_sessionStart == null) {
        _service.startStepSensorTracking(); // start a new session
      } else {
        _service
            .resumeStepSensorTracking(); // pause then resume — Pigeon does not support resume
        // In practice startStepSensorTracking resets counts to zero on each call.
        // pause/resume should call the corresponding methods instead (see note below).
      }
    }
    _sessionStart ??= DateTime.now();
    _startTimer();
    // if (!state.isAvailable || !state.hasPermission) return;
    // _guideName = guideName;
    // _sessionStart ??= DateTime.now();
    // _startTimer();
  }

  /// Called by the detail page whenever playback pauses or stops.
  void onPlaybackPaused() {
    _stopTimer();
    if (state.source == StepTrackingSource.sensor) {
      _service.pauseStepSensorTracking();
    }
  }

  /// Called when the guide finishes playing. Writes an exercise session and
  /// returns the summary data (or null if tracking was not active).
  Future<ExerciseSummaryData?> onPlaybackCompleted() async {
    _stopTimer();
    final start = _sessionStart;
    if (start == null || !state.isReady) return null;
    final end = DateTime.now();
    int steps;
    double distance;
    if (state.source == StepTrackingSource.sensor) {
      steps = await _service.stopStepSensorTracking();
      distance = steps * 0.78; // estimated average stride length
    } else {
      steps = await _service.getStepsBetween(start, end);
      distance = await _service.getDistanceBetween(start, end);
    }
    if (!mounted) return null;
    state = state.copyWith(steps: steps, distance: distance);
    final summary = ExerciseSummaryData(
      guideName: _guideName ?? '導覽',
      startTime: start,
      endTime: end,
      steps: steps,
      distanceMeters: distance,
    );
    await _service.writeExerciseSession(summary);
    _sessionStart = null;
    _guideName = null;
    return summary;
  }

  void _startTimer() {
    _timer?.cancel();
    // Fetch immediately, then every 30 s.
    _fetchMetrics();
    // Poll Health Connect every 5 s while a session is active so the UI stays responsive.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchMetrics());
    state = state.copyWith(isTracking: true);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isTracking: false);
  }

  Future<void> _fetchMetrics() async {
    if (_sessionStart == null) return;
    if (state.source == StepTrackingSource.sensor) {
      try {
        final steps = await _service.getCurrentSensorSteps();
        final distance = steps * 0.78;
        if (mounted) state = state.copyWith(steps: steps, distance: distance);
      } catch (_) {}
    } else {
      // Health Connect logic remains unchanged
      final start = _sessionStart;
      if (start == null) return;
      final now = DateTime.now();
      try {
        final steps = await _service.getStepsBetween(start, now);
        if (mounted) state = state.copyWith(steps: steps);
      } catch (_) {
        // Silently ignore transient Health Connect errors.
      }
      try {
        final distance = await _service.getDistanceBetween(start, now);
        if (mounted) state = state.copyWith(distance: distance);
      } catch (_) {
        // Silently ignore transient Health Connect errors.
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
