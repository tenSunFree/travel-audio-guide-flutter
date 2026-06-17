enum ActivitySortOrder {
  beginAsc,
  beginDesc,
  nameAZ,
  distanceAsc;

  String get label => switch (this) {
    ActivitySortOrder.beginAsc => '開始日期（近→遠）',
    ActivitySortOrder.beginDesc => '開始日期（遠→近）',
    ActivitySortOrder.nameAZ => '名稱 A-Z',
    ActivitySortOrder.distanceAsc => '離我最近',
  };
}

enum ActivityStatusFilter {
  all,
  ongoing,
  upcoming,
  today;

  String get label => switch (this) {
    ActivityStatusFilter.all => '全部活動',
    ActivityStatusFilter.ongoing => '正在舉辦',
    ActivityStatusFilter.upcoming => '即將開始（2小時內）',
    ActivityStatusFilter.today => '今日活動',
  };

  static ActivityStatusFilter fromQuery(String? value) {
    return switch (value) {
      'ongoing' => ActivityStatusFilter.ongoing,
      'upcoming' => ActivityStatusFilter.upcoming,
      'today' => ActivityStatusFilter.today,
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
