import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../attraction/di/attraction_providers.dart';
import '../../../attraction/domain/entities/attraction.dart';
import '../../../reminder/presentation/utils/detail_schedule_actions.dart';
import '../../../step_tracking/di/step_tracking_providers.dart';
import '../../../step_tracking/presentation/widgets/session_summary_card.dart';
import '../../domain/entities/audio_guide.dart';
import '../../domain/entities/audio_playback_state.dart';
import '../controllers/audio_player_controller.dart';
import '../../../../core/widgets/common_app_bar.dart';
import '../widgets/guide_image_section.dart';
import '../widgets/playback_card.dart';
import '../widgets/practical_info_section.dart';
import '../widgets/introduction_section.dart';
import '../widgets/step_count_badge.dart';
import '../../../../core/widgets/detail_action_buttons.dart';

class AudioGuideDetailPage extends ConsumerStatefulWidget {
  const AudioGuideDetailPage({super.key, required this.guide});

  final AudioGuide guide;

  @override
  ConsumerState<AudioGuideDetailPage> createState() =>
      _AudioGuideDetailPageState();
}

class _AudioGuideDetailPageState extends ConsumerState<AudioGuideDetailPage> {
  // guide.url is an MP3 file link, not suitable for external sharing;
  // Prioritize using the official website of the matched attraction, and omit links if necessary.
  String _buildGuideShareText(String pageTitle, Attraction? attraction) {
    return [
      pageTitle,
      if (attraction?.address.isNotEmpty ?? false) '地址：${attraction!.address}',
      if (attraction?.officialSite.isNotEmpty ?? false)
        attraction!.officialSite,
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final localPath = widget.guide.localFilePath;
    if (localPath == null) {
      return Scaffold(
        appBar: CommonAppBar(title: widget.guide.title),
        body: const Center(child: Text('找不到本地音訊檔')),
      );
    }
    final attractionAsync = ref.watch(attractionsStreamProvider);
    final Attraction? attraction = _resolveAttraction(attractionAsync);
    final pageTitle = attraction?.name ?? widget.guide.title;
    final scheduleItem = DetailScheduleItem(
      sourceType: 'audioGuide',
      sourceId: widget.guide.id.toString(),
      title: pageTitle,
      subtitle: attraction?.address,
      imageUrl: (attraction?.firstImageUrl.isNotEmpty ?? false)
          ? attraction!.firstImageUrl
          : null,
      address: attraction?.address,
      description: _resolveIntroduction(attraction, widget.guide),
      location: attraction?.address,
      allDay: false,
    );
    final playerState = ref.watch(audioPlayerControllerProvider(localPath));
    final controller = ref.read(
      audioPlayerControllerProvider(localPath).notifier,
    );
    final stepState = ref.watch(stepTrackingControllerProvider);
    final stepController = ref.read(stepTrackingControllerProvider.notifier);
    ref.listen(audioPlayerControllerProvider(localPath), (previous, next) {
      if (next.isPlaying && !(previous?.isPlaying ?? false)) {
        stepController.onPlaybackStarted(pageTitle);
      } else if (!next.isPlaying && (previous?.isPlaying ?? false)) {
        final isCompleted =
            next.status == AudioPlaybackStatus.stopped &&
            next.duration > Duration.zero &&
            next.position >= next.duration;
        if (isCompleted) {
          _onGuideCompleted(context);
        } else {
          stepController.onPlaybackPaused();
        }
      }
    });
    return Scaffold(
      appBar: CommonAppBar(title: pageTitle),
      body: ListView(
        children: [
          GuideImageSection(attraction: attraction),
          PlaybackCard(
            title: pageTitle,
            playerState: playerState,
            onTogglePlayPause: playerState.isReady
                ? controller.togglePlayPause
                : null,
            onSeek: controller.seek,
          ),
          PracticalInfoSection(attraction: attraction),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DetailActionButtons(
              navigateName: attraction?.name ?? pageTitle,
              navigateLat: attraction?.nlat,
              navigateLng: attraction?.elong,
              shareText: _buildGuideShareText(pageTitle, attraction),
              shareLabel: '分享導覽',
              onReminderPressed: () => DetailScheduleActions.addReminder(
                context: context,
                ref: ref,
                item: scheduleItem,
              ),
              onCalendarPressed: () => DetailScheduleActions.addToCalendar(
                context: context,
                item: scheduleItem,
              ),
            ),
          ),
          if (stepState.isAvailable &&
              stepState.hasHealthConnectPermission &&
              stepState.hasSensorPermission)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: StepCountBadge(
                steps: stepState.steps,
                distance: stepState.distance,
              ),
            ),
          IntroductionSection(
            pageTitle: pageTitle,
            text: _resolveIntroduction(attraction, widget.guide),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '資料來源：台北旅遊網',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                if (widget.guide.modified.isNotEmpty)
                  Text(
                    '音訊更新：${widget.guide.modified.split(' ').first}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Attraction? _resolveAttraction(AsyncValue<List<Attraction>> async) {
    final all = async.valueOrNull ?? const <Attraction>[];
    final matched = all
        .where((item) => _isSamePlace(item.name, widget.guide.title))
        .toList();
    return matched.isNotEmpty ? matched.first : null;
  }

  bool _isSamePlace(String attractionName, String guideTitle) {
    final a = _normalize(attractionName);
    final g = _normalize(guideTitle);
    return a.isNotEmpty && g.isNotEmpty && (g.contains(a) || a.contains(g));
  }

  String _normalize(String value) => value
      .replaceAll('.mp3', '')
      .replaceAll('語音導覽', '')
      .replaceAll('導覽', '')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();

  String _resolveIntroduction(Attraction? attraction, AudioGuide guide) {
    final intro = attraction?.introduction.trim() ?? '';
    if (intro.isNotEmpty) return intro;
    final summary = guide.summary?.trim() ?? '';
    if (summary.isNotEmpty) return summary;
    return '目前沒有景點介紹';
  }

  Future<void> _onGuideCompleted(BuildContext context) async {
    final stepController = ref.read(stepTrackingControllerProvider.notifier);
    final summary = await stepController.onPlaybackCompleted();
    if (summary == null || !context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SessionSummaryCard(summary: summary),
    );
  }
}
