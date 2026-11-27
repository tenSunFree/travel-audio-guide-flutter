import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity.dart';
import 'package:flutter_travel_audio_guide/features/activity/presentation/pages/activity_detail_page.dart';

import '../../../../test_helpers/activity_fixtures.dart';

Widget buildSubject(Activity activity, {bool isWeb = false}) {
  return ProviderScope(
    child: MaterialApp(
      home: ActivityDetailPage(activity: activity, isWeb: isWeb),
    ),
  );
}

void main() {
  testWidgets('顯示活動標題、展期、主辦單位與地點', (tester) async {
    final activity = buildTestActivity();
    await tester.pumpWidget(buildSubject(activity));
    await tester
        .pump(); // allow the AnalyticsService call in initState to complete one cycle
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('台北燈節'), findsOneWidget);
    expect(find.text('2026/08/01 ～ 2026/08/10'), findsOneWidget);
    expect(find.text('臺北市政府'), findsOneWidget);
    expect(find.text('台北市中正區'), findsOneWidget);
    expect(find.text('地點'), findsOneWidget);
  });

  testWidgets('地址為空時不顯示地點列，但主辦單位仍會顯示', (tester) async {
    final activity = buildTestActivity(address: '', organizer: '文化局');
    await tester.pumpWidget(buildSubject(activity));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('地點'), findsNothing);
    expect(find.text('主辦'), findsOneWidget);
    expect(find.text('文化局'), findsOneWidget);
  });

  testWidgets('點擊收藏會切換圖示與提示文字', (tester) async {
    final activity = buildTestActivity();
    await tester.pumpWidget(buildSubject(activity));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text('已加入收藏'), findsOneWidget);
  });

  testWidgets('票價與電話存在時會顯示對應資訊列', (tester) async {
    final activity = buildTestActivity(tel: '0223456789', ticket: r'NT$100');
    await tester.pumpWidget(buildSubject(activity));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('電話'), findsOneWidget);
    expect(find.text('0223456789'), findsOneWidget);
    expect(find.text('票價'), findsOneWidget);
    expect(find.text(r'NT$100'), findsOneWidget);
  });

  for (final isWeb in [false, true]) {
    testWidgets('HTML network image policy (isWeb=$isWeb)', (tester) async {
      final activity = buildTestActivity(
        description:
            '<p>活動內容</p>'
            '<img src="http://www.travel.taipei/html-test.jpg" '
            'width="120" height="60" alt="活動圖片">',
      );
      await tester.pumpWidget(buildSubject(activity, isWeb: isWeb));
      await tester.pump();
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;
      expect(
        provider.url,
        isWeb
            ? 'https://www.travel.taipei/html-test.jpg'
            : 'http://www.travel.taipei/html-test.jpg',
      );
      expect(
        provider.webHtmlElementStrategy,
        isWeb ? WebHtmlElementStrategy.fallback : WebHtmlElementStrategy.never,
      );
      expect(image.semanticLabel, '活動圖片');
      expect(find.byType(AspectRatio), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }

  testWidgets('Web HTML resolves an unquoted relative image source', (
    tester,
  ) async {
    final activity = buildTestActivity(
      description: '<p>活動內容</p><img src=/media/relative.jpg alt="圖片">',
    );
    await tester.pumpWidget(buildSubject(activity, isWeb: true));
    await tester.pump();
    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as NetworkImage;
    expect(provider.url, 'https://www.travel.taipei/media/relative.jpg');
    expect(provider.webHtmlElementStrategy, WebHtmlElementStrategy.fallback);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
