enum SortOrder {
  dateNewest,
  dateOldest,
  nameAZ,
  downloadedFirst,
  distanceAsc;

  String get label => switch (this) {
    SortOrder.dateNewest => '日期（新→舊）',
    SortOrder.dateOldest => '日期（舊→新）',
    SortOrder.nameAZ => '名稱 A-Z',
    SortOrder.downloadedFirst => '已下載優先',
    SortOrder.distanceAsc => '離我最近',
  };
}

enum FilterType {
  all,
  downloaded,
  notDownloaded;

  String get label => switch (this) {
    FilterType.all => '全部',
    FilterType.downloaded => '已下載',
    FilterType.notDownloaded => '未下載',
  };
}
