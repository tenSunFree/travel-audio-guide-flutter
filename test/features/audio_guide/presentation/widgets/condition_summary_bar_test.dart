import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/enums/sort_filter_enums.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/widgets/condition_summary_bar.dart';

Widget _wrap({
  SortOrder sortOrder = SortOrder.dateNewest,
  FilterType filterType = FilterType.all,
  bool isNonDefault = false,
  VoidCallback? onReset,
}) {
  return MaterialApp(
    home: Material(
      child: Scaffold(
        body: ConditionSummaryBar(
          sortOrder: sortOrder,
          filterType: filterType,
          isNonDefault: isNonDefault,
          onReset: onReset ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  group('ConditionSummaryBar — 顯示', () {
    testWidgets('預設顯示 sortOrder.label ・ filterType.label', (tester) async {
      await tester.pumpWidget(
        _wrap(sortOrder: SortOrder.dateNewest, filterType: FilterType.all),
      );
      expect(find.textContaining('日期（新→舊）'), findsOneWidget);
      expect(find.textContaining('全部'), findsOneWidget);
    });
    testWidgets('sortOrder=nameAZ 時顯示對應 label', (tester) async {
      await tester.pumpWidget(_wrap(sortOrder: SortOrder.nameAZ));
      expect(find.textContaining('名稱 A-Z'), findsOneWidget);
    });
    testWidgets('filterType=downloaded 時顯示「已下載」', (tester) async {
      await tester.pumpWidget(_wrap(filterType: FilterType.downloaded));
      expect(find.textContaining('已下載'), findsOneWidget);
    });
    testWidgets('filterType=notDownloaded 時顯示「未下載」', (tester) async {
      await tester.pumpWidget(_wrap(filterType: FilterType.notDownloaded));
      expect(find.textContaining('未下載'), findsOneWidget);
    });
    testWidgets('顯示 tune icon', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });
    testWidgets('isNonDefault=false → 不顯示「重設」按鈕', (tester) async {
      await tester.pumpWidget(_wrap(isNonDefault: false));
      expect(find.text('重設'), findsNothing);
    });
    testWidgets('isNonDefault=true → 顯示「重設」按鈕', (tester) async {
      await tester.pumpWidget(_wrap(isNonDefault: true));
      expect(find.text('重設'), findsOneWidget);
    });
  });
  group('ConditionSummaryBar — 互動', () {
    testWidgets('點擊「重設」觸發 onReset callback', (tester) async {
      var resetCalled = false;

      await tester.pumpWidget(
        _wrap(isNonDefault: true, onReset: () => resetCalled = true),
      );
      // Use the GestureDetector key or tap the GestureDetector widget directly
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(resetCalled, isTrue);
    });
    testWidgets('點擊兩次各自觸發 callback', (tester) async {
      var count = 0;
      await tester.pumpWidget(
        _wrap(isNonDefault: true, onReset: () => count++),
      );
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(count, 1);
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(count, 2);
    });
  });
}
