import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/widgets/nearby_attraction_tile.dart';

void main() {
  testWidgets(
    'NearbyAttractionTile renders name and meta, and responds to tap',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NearbyAttractionTile(
              name: '測試景點',
              distric: '信義區',
              distanceLabel: '500m',
              imageUrl: null,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('測試景點'), findsOneWidget);
      expect(find.textContaining('500m'), findsOneWidget);
      expect(find.textContaining('信義區'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'NearbyAttractionTile falls back to placeholder icon when imageUrl is null',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NearbyAttractionTile(
              name: 'X',
              distric: '',
              distanceLabel: null,
              imageUrl: null,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    },
  );

  for (final isWeb in [false, true]) {
    testWidgets('Nearby image policy (isWeb=$isWeb)', (tester) async {
      const url = 'http://www.travel.taipei/nearby-test.jpg';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NearbyAttractionTile(
              name: '景點',
              distric: '',
              distanceLabel: null,
              imageUrl: url,
              onTap: () {},
              isWeb: isWeb,
            ),
          ),
        ),
      );
      final finder = find.byType(Image);
      final image = tester.widget<Image>(finder);
      final provider = image.image as NetworkImage;
      expect(provider.url, isWeb ? url.replaceFirst('http:', 'https:') : url);
      expect(
        provider.webHtmlElementStrategy,
        isWeb ? WebHtmlElementStrategy.fallback : WebHtmlElementStrategy.never,
      );
      final error =
          image.errorBuilder!(
                tester.element(finder),
                StateError('test'),
                null,
              )
              as Icon;
      expect(error.icon, Icons.place_outlined);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }
}
