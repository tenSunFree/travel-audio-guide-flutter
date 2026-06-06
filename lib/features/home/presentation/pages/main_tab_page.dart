import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../activity/presentation/pages/activity_list_page.dart';
import '../../../attraction/presentation/pages/attraction_list_page.dart';
import '../../../audio_guide/presentation/pages/audio_guide_list_page.dart';
import '../../../reminder/presentation/pages/my_journey_page.dart';
import 'home_page.dart';

/// MainTabPage accepts initial filter values from GoRouter query params.
/// - After clicking "View All" on the homepage, GoRouter pushes a new route with the query,
/// The corresponding builder creates a MainTabPage with initial parameters.
/// - Normal entry points (homepage tabs) use the default builder without any initial filter.
class MainTabPage extends StatefulWidget {
  const MainTabPage({
    super.key,
    this.initialIndex = 0,
    this.attractionInitialTimeSlot,
    this.attractionInitialOpenNow = false,
    this.activityInitialStatus,
  });

  /// Preset which tab to display
  /// (0=Home, 1=AudioGuide, 2=Events & Performances, 3=Recreational Attractions, 4=MyJourney)
  final int initialIndex;

  /// Initial time slot filtering for recreational attractions
  /// (query value: morning/afternoon/evening/night)
  final String? attractionInitialTimeSlot;

  /// Initial "Available Now" filter for recreational attractions
  final bool attractionInitialOpenNow;

  /// Initial status filtering for event presentations
  /// (query value: ongoing/upcoming)
  final String? activityInitialStatus;

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Tracking: Records the first tab entered
    AnalyticsService.logTabSelected(_currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic pages: Pass the initial filter parameters from the homepage to the list page
    final pages = [
      const HomePage(),
      const AudioGuideListPage(),
      ActivityListPage(initialStatus: widget.activityInitialStatus),
      AttractionListPage(
        initialTimeSlot: widget.attractionInitialTimeSlot,
        initialOpenNow: widget.attractionInitialOpenNow,
      ),
      const MyJourneyPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              heroTag: 'debug_log',
              backgroundColor: Colors.red,
              child: const Icon(Icons.bug_report, color: Colors.white),
              onPressed: () => context.push(AppRoutes.appLog),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          // Avoid duplicate records
          if (index == _currentIndex) return;
          // Tracking: Tab toggle
          AnalyticsService.logTabSelected(index);
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首頁',
          ),
          NavigationDestination(
            icon: Icon(Icons.headphones_outlined),
            selectedIcon: Icon(Icons.headphones),
            label: '語音導覽',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: '活動展演',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: '遊憩景點',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_travel_outlined),
            selectedIcon: Icon(Icons.card_travel),
            label: '我的旅程',
          ),
        ],
      ),
    );
  }
}
