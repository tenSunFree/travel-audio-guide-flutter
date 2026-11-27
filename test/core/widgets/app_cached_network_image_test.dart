import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/widgets/app_cached_network_image.dart';

void main() {
  testWidgets('Web image preserves size, fit, clipping and custom states', (
    tester,
  ) async {
    final radius = BorderRadius.circular(8);
    const placeholder = Text('loading');
    const error = Text('failed');
    const child = SizedBox();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCachedNetworkImage(
            imageUrl: 'http://www.travel.taipei/web-test.jpg',
            width: 80,
            height: 60,
            fit: BoxFit.contain,
            borderRadius: radius,
            placeholder: placeholder,
            errorWidget: error,
            isWeb: true,
          ),
        ),
      ),
    );

    final finder = find.byType(Image);
    final image = tester.widget<Image>(finder);
    final provider = image.image as NetworkImage;
    final context = tester.element(finder);
    expect(provider.url, 'https://www.travel.taipei/web-test.jpg');
    expect(provider.webHtmlElementStrategy, WebHtmlElementStrategy.fallback);
    expect(image.width, 80);
    expect(image.height, 60);
    expect(image.fit, BoxFit.contain);
    expect(
      tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius,
      radius,
    );
    expect(image.frameBuilder!(context, child, null, false), placeholder);
    expect(image.frameBuilder!(context, child, 0, false), child);
    expect(image.frameBuilder!(context, child, null, true), child);
    expect(image.errorBuilder!(context, StateError('test'), null), error);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('Web image uses default placeholder and error without clipping', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCachedNetworkImage(
            imageUrl: 'https://example.com/web-default.jpg',
            width: 80,
            height: 60,
            isWeb: true,
          ),
        ),
      ),
    );
    final finder = find.byType(Image);
    final image = tester.widget<Image>(finder);
    final context = tester.element(finder);
    const child = SizedBox();
    final loading = image.frameBuilder!(context, child, null, false);
    final error = image.errorBuilder!(context, StateError('test'), null);
    expect(find.byType(ClipRRect), findsNothing);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: loading)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: error)));
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });
}
