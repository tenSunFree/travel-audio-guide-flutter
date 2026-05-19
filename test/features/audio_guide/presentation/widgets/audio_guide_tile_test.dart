import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/widgets/audio_guide_tile.dart';

class _MockCallback extends Mock {
  void call();
}

AudioGuide _buildGuide({
  int id = 1,
  String title = '大稻埕語音導覽',
  bool isDownloaded = false,
  String modified = '2026-05-01',
  String? localFilePath,
}) {
  return AudioGuide(
    id: id,
    title: title,
    url: 'https://example.com/$id.mp3',
    modified: modified,
    isDownloaded: isDownloaded,
    localFilePath: localFilePath,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AudioGuideTile — 顯示', () {
    testWidgets('顯示語音導覽標題', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AudioGuideTile(
            guide: _buildGuide(title: '象山步道語音導覽'),
            isDownloading: false,
            onActionPressed: () {},
          ),
        ),
      );
      expect(find.text('象山步道語音導覽'), findsOneWidget);
    });
    testWidgets('顯示「更新於」日期文字', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AudioGuideTile(
            guide: _buildGuide(modified: '2026-01-15'),
            isDownloading: false,
            onActionPressed: () {},
          ),
        ),
      );
      expect(find.textContaining('更新於 2026-01-15'), findsOneWidget);
    });
    testWidgets('未下載 → 顯示「下載」與 download icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AudioGuideTile(
            guide: _buildGuide(isDownloaded: false),
            isDownloading: false,
            onActionPressed: () {},
          ),
        ),
      );
      expect(find.text('下載'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });
    testWidgets('已下載 → 顯示「播放」與 play_arrow icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AudioGuideTile(
            guide: _buildGuide(isDownloaded: true),
            isDownloading: false,
            onActionPressed: () {},
          ),
        ),
      );
      expect(find.text('播放'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
    testWidgets('isDownloading=true → 顯示「下載中」與 CircularProgressIndicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AudioGuideTile(
            guide: _buildGuide(),
            isDownloading: true,
            onActionPressed: () {},
          ),
        ),
      );
      expect(find.text('下載中'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
  group('AudioGuideTile — 互動', () {
    testWidgets('正常狀態下點擊 OutlinedButton 觸發 onActionPressed 一次', (tester) async {
      final cb = _MockCallback();
      await tester.pumpWidget(
        _wrap(
          AudioGuideTile(
            guide: _buildGuide(),
            isDownloading: false,
            onActionPressed: cb.call,
          ),
        ),
      );
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
      verify(() => cb()).called(1);
    });
    testWidgets('isDownloading=true 時點擊按鈕不觸發 onActionPressed', (tester) async {
      final cb = _MockCallback();
      await tester.pumpWidget(
        _wrap(
          AudioGuideTile(
            guide: _buildGuide(),
            isDownloading: true,
            onActionPressed: cb.call,
          ),
        ),
      );
      // OutlinedButton.onPressed is null, so it cannot be triggered.
      await tester.tap(find.byType(OutlinedButton), warnIfMissed: false);
      await tester.pump();
      verifyNever(() => cb());
    });
    testWidgets('點擊整個 InkWell 區域（正常狀態）也觸發 onActionPressed', (tester) async {
      final cb = _MockCallback();
      await tester.pumpWidget(
        _wrap(
          AudioGuideTile(
            guide: _buildGuide(),
            isDownloading: false,
            onActionPressed: cb.call,
          ),
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      verify(() => cb()).called(1);
    });
    testWidgets('isDownloading=true 時 InkWell tap 不觸發 onActionPressed', (
      tester,
    ) async {
      final cb = _MockCallback();
      await tester.pumpWidget(
        _wrap(
          AudioGuideTile(
            guide: _buildGuide(),
            isDownloading: true,
            onActionPressed: cb.call,
          ),
        ),
      );
      await tester.tap(find.byType(InkWell).first, warnIfMissed: false);
      await tester.pump();
      verifyNever(() => cb());
    });
  });
  group('AudioGuideTile — Layout', () {
    testWidgets('超長標題不 overflow', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 350,
            child: AudioGuideTile(
              guide: _buildGuide(title: 'A' * 200),
              isDownloading: false,
              onActionPressed: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
