import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/monitoring/monitoring_service.dart';
import '../../di/audio_guide_providers.dart';
import '../../domain/entities/audio_playback_state.dart';
import '../../domain/services/audio_playback_service.dart';

final audioPlayerControllerProvider = StateNotifierProvider.autoDispose
    .family<AudioPlayerController, AudioPlaybackState, String>((ref, path) {
      final service = ref.watch(audioPlaybackServiceProvider(path));
      return AudioPlayerController(service, path);
    });

class AudioPlayerController extends StateNotifier<AudioPlaybackState> {
  AudioPlayerController(this._service, this._path)
    : super(const AudioPlaybackState()) {
    _init();
  }

  final AudioPlaybackService _service;
  final String _path;

  StreamSubscription<AudioPlaybackState>? _subscription;

  // Critical business path: Player initialization
  // - Breadcrumb records the start of initialization
  // - MonitorFuture establishes a performance transaction (operation: audio.player.initialize)
  // - Failure: Do not rethrow (change to updating state), and simultaneously captureException report.
  Future<void> _init() async {
    // First listen to the stream to ensure that all state changes during the initialization process are captured.
    _subscription = _service.stateStream.listen((playbackState) {
      final previous = state;
      state = playbackState;
      // Tracking playback state transitions (also tracked via ref.listen in AudioGuideDetailPage)
      // Because the guide id/title is unavailable here, playback tracking is moved to ref.listen on the detail page.
      // Detection can still be done here (only the duration is passed).
      _detectCompletion(previous, playbackState);
    });
    await MonitoringService.addBreadcrumb(
      message: 'Start audio player initialization',
      category: 'audio.player',
      data: {'file_path': _path},
    );
    try {
      await MonitoringService.monitorFuture<void>(
        name: 'Audio Player Initialization',
        operation: 'audio.player.initialize',
        description: _path,
        extras: {'file_path': _path},
        action: () => _service.initialize(_path),
      );
      await MonitoringService.addBreadcrumb(
        message: 'Audio player initialization success',
        category: 'audio.player',
        data: {'file_path': _path},
      );
    } catch (e) {
      // Player initialization failure is a user-visible error and should not cause the controller to crash.
      if (mounted) {
        state = state.copyWith(
          status: AudioPlaybackStatus.error,
          errorMessage: '播放器初始化失敗：$e',
        );
      }
    }
  }

  // Playback complete detection (guide id, duration is sufficient)
  void _detectCompletion(AudioPlaybackState previous, AudioPlaybackState next) {
    final wasPlaying = previous.isPlaying;
    final isNowStopped =
        !next.isPlaying &&
        next.status == AudioPlaybackStatus.stopped &&
        next.duration > Duration.zero &&
        next.position >= next.duration;
    if (wasPlaying && isNowStopped) {
      MonitoringService.addBreadcrumb(
        message: 'Audio playback completed',
        category: 'audio.player',
        data: {'file_path': _path, 'duration_seconds': next.duration.inSeconds},
      );
    }
  }

  Future<void> togglePlayPause() async {
    if (!state.isReady) return;
    if (state.isPlaying) {
      await _service.pause();
      return;
    }
    if (state.status == AudioPlaybackStatus.stopped &&
        state.duration > Duration.zero &&
        state.position >= state.duration) {
      await _service.seek(Duration.zero);
    }
    await _service.play();
  }

  Future<void> seek(Duration position) async {
    if (!state.isReady) return;
    await _service.seek(position);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
