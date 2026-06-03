enum ActivitySortOrder {
  // Start Date: Nearest → Oldest (Default)
  beginAsc,
  // Start Date: Farthest → Nearest
  beginDesc,
  // Name A-Z
  nameAZ;

  String get label => switch (this) {
    ActivitySortOrder.beginAsc => '開始日期（近→遠）',
    ActivitySortOrder.beginDesc => '開始日期（遠→近）',
    ActivitySortOrder.nameAZ => '名稱 A-Z',
  };
}

/// Activity Status Filter
/// ongoing → Available now (now between begin and end)
/// upcoming → Coming soon (starting in 7 days)
enum ActivityStatusFilter {
  all,
  ongoing,
  upcoming;

  String get label => switch (this) {
    ActivityStatusFilter.all => '全部活動',
    ActivityStatusFilter.ongoing => '現在可參加',
    ActivityStatusFilter.upcoming => '即將開始',
  };

  /// Convert the GoRouter query param string back to enum
  static ActivityStatusFilter fromQuery(String? value) {
    return switch (value) {
      'ongoing' => ActivityStatusFilter.ongoing,
      'upcoming' => ActivityStatusFilter.upcoming,
      _ => ActivityStatusFilter.all,
    };
  }
}

enum ActivityFeeFilter {
  all,
  free,
  paid;

  String get label => switch (this) {
    ActivityFeeFilter.all => '全部',
    ActivityFeeFilter.free => '免費',
    ActivityFeeFilter.paid => '付費',
  };
}
