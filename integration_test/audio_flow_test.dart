import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/widgets/audio_guide_tile.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/widgets/playback_card.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'helpers/fakes.dart';
import 'helpers/fixtures.dart';
import 'helpers/pump_until.dart';
import 'helpers/test_app.dart';

/// Critical journey #3 — Audio guide.
///
/// List -> Download (fake HTTP, REAL file write via path_provider) ->
/// Drift marks it downloaded -> Detail page -> Play -> Pause
///
/// Spans UI, controllers, repository, file system, Drift and the playback
/// service boundary in one run.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Downloads land in the real app documents directory, which survives
  // between test runs on the same device. Remove only the one file this test
  // creates, before and after: a leftover file would make the app skip the
  // download entirely, but other downloads on the device must stay untouched.
  setUp(_deleteTestAudioFile);
  tearDown(_deleteTestAudioFile);

  testWidgets('語音導覽：下載 → 寫入本機檔案 → 播放 → 暫停', (tester) async {
    final app = await pumpTestApp(
      tester,
      api: FakeTravelApi(audioGuides: [audioGuideJson()]),
    );

    await tester.pumpUntilFound(find.byType(NavigationBar));
    await tester.tap(findTab('語音導覽'));

    // 1. The synced guide shows up with a "下載" action.
    final tile = find.widgetWithText(AudioGuideTile, fixtureAudioGuideTitle);
    await tester.pumpUntilFound(tile);
    final downloadButton = find.descendant(
      of: tile,
      matching: find.text('下載'),
    );
    expect(downloadButton, findsOneWidget);

    // 2. Download. '下載完成' is reliable once the page no longer re-reads
    //    controller state after download (see audio_guide_list_page.dart);
    //    the '播放' label then confirms Drift's watch stream picked it up.
    await tester.tap(downloadButton);
    await tester.pumpUntilFound(find.text('下載完成'));
    final playButton = find.descendant(of: tile, matching: find.text('播放'));
    await tester.pumpUntilFound(playButton);

    // The bytes really went through the repository to disk, and Drift
    // recorded the local path.
    expect(app.api.requestedPathEndingWith('/audio/9001.mp3'), isTrue);
    final saved = await app.db.audioGuideDao.findById(fixtureAudioGuideId);
    expect(saved, isNotNull);
    expect(saved!.isDownloaded, isTrue);
    final file = File(saved.localFilePath!);
    expect(file.existsSync(), isTrue);
    expect(file.readAsBytesSync(), fakeMp3Bytes);

    // 3. Open the detail page; wait until the player is ready
    //    (the slider only renders once a duration is known).
    await tester.tap(playButton);
    final card = find.byType(PlaybackCard);
    await tester.pumpUntilFound(
      find.descendant(of: card, matching: find.byType(Slider)),
    );
    expect(app.playback.initializedPath, saved.localFilePath);

    // 4. Play.
    await tester.tap(
      find.descendant(
        of: card,
        matching: find.byIcon(Icons.play_arrow_rounded),
      ),
    );
    await tester.pumpUntilFound(
      find.descendant(of: card, matching: find.byIcon(Icons.pause_rounded)),
    );
    expect(app.playback.playCallCount, 1);

    // 5. Pause.
    await tester.tap(
      find.descendant(of: card, matching: find.byIcon(Icons.pause_rounded)),
    );
    await tester.pumpUntilFound(
      find.descendant(
        of: card,
        matching: find.byIcon(Icons.play_arrow_rounded),
      ),
    );
    expect(app.playback.pauseCallCount, 1);
  });
}

/// Deletes only the fixture guide's file.
///
/// Mirrors `AudioGuideLocalDataSource._buildFileName`: `{id}_{title}.mp3`.
/// [fixtureAudioGuideTitle] must therefore stay free of characters that the
/// app sanitises (whitespace and `\ / : * ? " < > |`).
Future<void> _deleteTestAudioFile() async {
  final documents = await getApplicationDocumentsDirectory();
  final file = File(
    p.join(
      documents.path,
      'audio_guides',
      '${fixtureAudioGuideId}_$fixtureAudioGuideTitle.mp3',
    ),
  );
  if (file.existsSync()) {
    await file.delete();
  }
}
